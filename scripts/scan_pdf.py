#!/usr/bin/env python3
"""
scan_pdf.py — Convierte un PDF de fotos de documentos en un PDF escaneado limpio.

Por cada página:
1. Extrae la imagen del PDF
2. Detecta los bordes del documento (contorno rectangular más grande)
3. Aplica corrección de perspectiva (deskew)
4. Mejora contraste y blanquea el fondo (efecto escáner)
5. Genera un PDF de salida con todas las páginas procesadas

Uso:
    python scripts/scan_pdf.py input.pdf [output.pdf]
    python scripts/scan_pdf.py input.pdf --dpi 200 --no-crop
    python scripts/scan_pdf.py input.pdf --method soft --margin 30
"""

import sys
import argparse
import numpy as np
import cv2
import fitz  # PyMuPDF
from pathlib import Path


def extract_page_image(doc, page_num, dpi=300):
    """Extrae una página del PDF como imagen numpy (BGR)."""
    page = doc[page_num]
    zoom = dpi / 72
    mat = fitz.Matrix(zoom, zoom)
    pix = page.get_pixmap(matrix=mat)
    img = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.h, pix.w, pix.n)
    if pix.n == 4:
        img = cv2.cvtColor(img, cv2.COLOR_RGBA2BGR)
    elif pix.n == 3:
        img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
    return img


def order_points(pts):
    """Ordena 4 puntos: top-left, top-right, bottom-right, bottom-left."""
    rect = np.zeros((4, 2), dtype="float32")
    s = pts.sum(axis=1)
    rect[0] = pts[np.argmin(s)]
    rect[2] = pts[np.argmax(s)]
    d = np.diff(pts, axis=1)
    rect[1] = pts[np.argmin(d)]
    rect[3] = pts[np.argmax(d)]
    return rect


def find_document_contour(img, margin=20):
    """Detecta el contorno rectangular más grande (el documento).

    Estrategia: convertir a gris, umbralizar para separar papel blanco
    del fondo oscuro (mesa), luego encontrar el contorno más grande.
    """
    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Estrategia 1: Umbral para separar papel (claro) del fondo (oscuro)
    blurred = cv2.GaussianBlur(gray, (11, 11), 0)

    # Umbral adaptativo: el papel es significativamente más claro que la mesa
    _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # Cerrar huecos en el papel
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (15, 15))
    closed = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel, iterations=3)

    contours, _ = cv2.findContours(closed, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    if not contours:
        return None

    # Buscar el contorno más grande que sea razonablemente rectangular
    contours = sorted(contours, key=cv2.contourArea, reverse=True)

    for contour in contours[:5]:
        area = cv2.contourArea(contour)
        img_area = h * w

        if area < 0.25 * img_area:
            continue

        # Intentar aproximar a 4 puntos
        peri = cv2.arcLength(contour, True)
        approx = cv2.approxPolyDP(contour, 0.02 * peri, True)

        if len(approx) == 4:
            pts = approx.reshape(4, 2).astype("float32")
            # Aplicar margen hacia adentro para cortar bordes del papel
            return _apply_margin(pts, margin, h, w)

        # Si no es exactamente 4 puntos, usar el rectángulo mínimo rotado
        rect = cv2.minAreaRect(contour)
        box = cv2.boxPoints(rect)
        box = box.astype("float32")

        rect_area = cv2.contourArea(box.astype(int))
        if rect_area > 0.25 * img_area:
            return _apply_margin(box, margin, h, w)

    return None


def _apply_margin(pts, margin, h, w):
    """Aplica un margen interior a los 4 puntos del documento."""
    ordered = order_points(pts)
    center = ordered.mean(axis=0)

    # Mover cada punto ligeramente hacia el centro
    for i in range(4):
        direction = center - ordered[i]
        norm = np.linalg.norm(direction)
        if norm > 0:
            ordered[i] += direction / norm * margin

    # Clamp
    ordered[:, 0] = np.clip(ordered[:, 0], 0, w - 1)
    ordered[:, 1] = np.clip(ordered[:, 1], 0, h - 1)

    return ordered


def perspective_transform(img, pts):
    """Aplica transformación de perspectiva para enderezar el documento."""
    rect = order_points(pts.astype("float32"))
    (tl, tr, br, bl) = rect

    width_top = np.linalg.norm(tr - tl)
    width_bottom = np.linalg.norm(br - bl)
    max_width = int(max(width_top, width_bottom))

    height_left = np.linalg.norm(bl - tl)
    height_right = np.linalg.norm(br - tr)
    max_height = int(max(height_left, height_right))

    # Forzar aspecto carta/oficio si es razonable
    aspect = max_height / max_width if max_width > 0 else 1.4
    if 1.2 < aspect < 1.6:
        # Parece carta, forzar 8.5x11
        target_aspect = 11 / 8.5
        if aspect < target_aspect:
            max_height = int(max_width * target_aspect)
        else:
            max_width = int(max_height / target_aspect)

    dst = np.array([
        [0, 0],
        [max_width - 1, 0],
        [max_width - 1, max_height - 1],
        [0, max_height - 1]
    ], dtype="float32")

    M = cv2.getPerspectiveTransform(rect, dst)
    warped = cv2.warpPerspective(img, M, (max_width, max_height),
                                  borderMode=cv2.BORDER_CONSTANT,
                                  borderValue=(255, 255, 255))
    return warped


def enhance_scan(img, method="soft"):
    """Mejora la imagen para parecer escaneada."""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    if method == "soft":
        # Eliminar ruido suavemente
        denoised = cv2.fastNlMeansDenoising(gray, h=8)

        # Normalizar iluminación: dividir por fondo estimado
        blur = cv2.GaussianBlur(denoised, (91, 91), 0)
        normalized = cv2.divide(denoised, blur, scale=255)

        # Estirar contraste
        p2 = np.percentile(normalized, 2)
        p98 = np.percentile(normalized, 98)
        stretched = np.clip((normalized.astype(float) - p2) / (p98 - p2) * 255, 0, 255).astype(np.uint8)

        # CLAHE suave para realzar texto
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        result = clahe.apply(stretched)

    elif method == "clean":
        # Binarización limpia (B/N puro)
        denoised = cv2.fastNlMeansDenoising(gray, h=12)
        blur = cv2.GaussianBlur(denoised, (91, 91), 0)
        normalized = cv2.divide(denoised, blur, scale=255)
        _, result = cv2.threshold(normalized, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    elif method == "adaptive":
        denoised = cv2.fastNlMeansDenoising(gray, h=10)
        blur = cv2.GaussianBlur(denoised, (91, 91), 0)
        normalized = cv2.divide(denoised, blur, scale=255)

        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(normalized)

        thresh = cv2.adaptiveThreshold(
            enhanced, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            31, 15
        )
        result = cv2.addWeighted(thresh, 0.6, enhanced, 0.4, 0)

    else:
        result = gray

    return result


def process_page(img, crop=True, method="soft", margin=20):
    """Procesa una página: detecta documento, corrige perspectiva, mejora."""
    if crop:
        contour = find_document_contour(img, margin=margin)
        if contour is not None:
            img = perspective_transform(img, contour)

    enhanced = enhance_scan(img, method=method)
    return enhanced


def main():
    parser = argparse.ArgumentParser(
        description="Convierte PDF de fotos de documentos en PDF escaneado limpio"
    )
    parser.add_argument("input", help="PDF de entrada")
    parser.add_argument("output", nargs="?", help="PDF de salida (default: input_scanned.pdf)")
    parser.add_argument("--dpi", type=int, default=250, help="Resolución (default: 250)")
    parser.add_argument("--no-crop", action="store_true", help="No recortar bordes")
    parser.add_argument("--margin", type=int, default=30, help="Margen interior de recorte en px (default: 30)")
    parser.add_argument("--method", choices=["soft", "clean", "adaptive"],
                        default="soft",
                        help="soft (default, escáner natural), clean (B/N puro), adaptive (mixto)")
    parser.add_argument("--quality", type=int, default=85, help="Calidad JPEG 1-100 (default: 85)")

    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: {input_path} no existe")
        sys.exit(1)

    output_path = Path(args.output) if args.output else input_path.with_name(f"{input_path.stem}_scanned.pdf")

    print(f"Input:   {input_path}")
    print(f"Output:  {output_path}")
    print(f"DPI: {args.dpi} | Crop: {not args.no_crop} | Método: {args.method} | JPEG Q: {args.quality}")

    doc = fitz.open(str(input_path))
    total_pages = len(doc)
    print(f"Páginas: {total_pages}")

    out_doc = fitz.open()

    for i in range(total_pages):
        print(f"  Página {i+1}/{total_pages}...", end=" ", flush=True)

        img = extract_page_image(doc, i, dpi=args.dpi)
        result = process_page(img, crop=not args.no_crop, method=args.method, margin=args.margin)

        # Codificar como JPEG (mucho más pequeño que PNG)
        encode_params = [cv2.IMWRITE_JPEG_QUALITY, args.quality]
        success, buf = cv2.imencode(".jpg", result, encode_params)
        if not success:
            print("ERROR")
            continue

        img_bytes = buf.tobytes()
        h, w = result.shape[:2]
        scale = 72 / args.dpi
        page_w = w * scale
        page_h = h * scale
        page = out_doc.new_page(width=page_w, height=page_h)
        page.insert_image(fitz.Rect(0, 0, page_w, page_h), stream=img_bytes)

        print(f"OK ({len(img_bytes)//1024} KB)")

    out_doc.save(str(output_path), deflate=True, garbage=4)
    out_doc.close()
    doc.close()

    size_in = input_path.stat().st_size / 1024 / 1024
    size_out = output_path.stat().st_size / 1024 / 1024
    print(f"\nListo: {output_path}")
    print(f"Tamaño: {size_in:.1f} MB → {size_out:.1f} MB ({size_out/size_in*100:.0f}%)")


if __name__ == "__main__":
    main()
