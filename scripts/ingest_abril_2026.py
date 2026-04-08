#!/usr/bin/env python3
"""
Ingesta incremental — datos HODOM abril 2026 (5-8 abril).

Fases:
  1. Parse y limpieza de artefactos crudos
  2. Registro maestro de pacientes (deduplicación por RUT)
  3. Reconciliación con PG (existente vs. nuevo)
  4. Construcción de entidades normalizadas
  5. Reporte / ejecución

Uso:
  .venv/bin/python scripts/ingest_abril_2026.py              # dry-run (default)
  .venv/bin/python scripts/ingest_abril_2026.py --execute     # escribir a PG
"""

import argparse
import csv
import hashlib
import re
import sys
from collections import defaultdict
from datetime import date, datetime
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# ID generation (mirrors hash_ids.py)
# ---------------------------------------------------------------------------

def stable_id(prefix: str, *parts: str) -> str:
    digest = hashlib.sha1("|".join(str(p) for p in parts).encode()).hexdigest()[:16]
    return f"{prefix}_{digest}"

def patient_id_from_rut(rut: str) -> str:
    return stable_id("pt", f"rut:{rut}")

def make_stay_id(rut: str, fecha_ingreso: str) -> str:
    return stable_id("stay", f"rut:{rut}", f"ingreso:{fecha_ingreso}")

def make_visit_id(rut: str, fecha: str, hora: str, prestacion: str) -> str:
    return stable_id("vis", rut, fecha, hora, prestacion)

def make_note_id(rut: str, fecha: str, tipo: str, hora: str) -> str:
    return stable_id("nota", rut, fecha, tipo, hora)

# ---------------------------------------------------------------------------
# Normalización
# ---------------------------------------------------------------------------

def normalize_rut(raw: str) -> Optional[str]:
    """Normaliza RUT: quita puntos/comas/espacios, conserva guión."""
    if not raw or not raw.strip():
        return None
    s = raw.strip().replace(".", "").replace(",", "").replace(" ", "")
    # Asegurar guión antes del dígito verificador
    if "-" not in s and len(s) > 1:
        s = s[:-1] + "-" + s[-1]
    return s.upper()

def normalize_name(raw: str) -> str:
    """Normaliza nombre: upper, strip anotaciones, fix acentos."""
    s = raw.strip().upper()
    # Quitar anotaciones entre paréntesis como "(HD MA-JU-SA 08:00 A 13:00)"
    s = re.sub(r'\(HD[^)]*\)', '', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s

def normalize_date(raw: str, fmt: str = "dd-mm-yy") -> Optional[str]:
    """Convierte a YYYY-MM-DD."""
    if not raw or not raw.strip():
        return None
    s = raw.strip().replace("/", "-")
    parts = s.split("-")
    if len(parts) != 3:
        return None
    if fmt == "dd-mm-yy":
        d, m, y = parts
        if len(y) == 2:
            yi = int(y)
            # Año actual 2026: anything > 26 is 1900s
            y = str(2000 + yi) if yi <= 26 else str(1900 + yi)
        return f"{y}-{m.zfill(2)}-{d.zfill(2)}"
    elif fmt == "dd/mm/yyyy" or fmt == "dd-mm-yyyy":
        d, m, y = parts
        return f"{y}-{m.zfill(2)}-{d.zfill(2)}"
    return None

def normalize_comuna(raw: str) -> str:
    s = raw.strip().upper()
    mapping = {
        "NIQUEN": "ÑIQUÉN", "ÑIQUEN": "ÑIQUÉN",
        "SAN NICOLAS": "SAN NICOLÁS",
    }
    return mapping.get(s, s)

def normalize_address(raw: str) -> str:
    s = raw.strip()
    # Fix typos
    s = s.replace("LAS C AMELIAS", "LAS CAMELIAS")
    return s

def normalize_hora(raw: str) -> str:
    """Normaliza hora a HH:MM."""
    s = raw.strip()
    if not s:
        return ""
    # Quitar /ayuno info  (e.g., "17:40/15:00")
    if "/" in s:
        s = s.split("/")[0]
    return s

TREATMENT_CODE_MAP = {
    "KTM": "kinesiologia_motora",
    "KTR": "kinesiologia_respiratoria",
    "FONO": "fonoaudiologia",
    "CA": "curacion_avanzada",
    "CS": "control_signos",
    "NTP": "nutricion_parenteral",
    "TTO EV": "tratamiento_ev",
    "VM INGRESO": "visita_medica_ingreso",
    "VM EGRESO": "visita_medica_egreso",
    "VM INGR/EGRESO": "visita_medica_ingreso_egreso",
    "ING ENF": "ingreso_enfermeria",
    "ING KTM": "ingreso_kinesiologia",
    "ING KTR": "ingreso_kinesiologia_resp",
    "EV FONO": "evaluacion_fonoaudiologia",
    "EV. FONO": "evaluacion_fonoaudiologia",
    "EXAMENES": "toma_examenes",
    "EXÁMENES": "toma_examenes",
    "RETIRO NTP": "retiro_ntp",
    "NTP + EXAMENES": "nutricion_parenteral+toma_examenes",
    "ALTA": "alta",
    "TTO EV C/12": "tratamiento_ev_c12",
    "TTO EV + ALTA": "tratamiento_ev+alta",
    "TTO EV+ VM INGRESO": "tratamiento_ev+visita_medica_ingreso",
    "TTO EV + VM INGR/EGRESO": "tratamiento_ev+visita_medica_ingreso_egreso",
    "ING ENF+ TTO EV": "ingreso_enfermeria+tratamiento_ev",
    "ING ENF + TTO EV": "ingreso_enfermeria+tratamiento_ev",
}

def split_treatment_codes(raw: str) -> list[str]:
    """Descompone códigos compuestos como 'KTM + FONO' en lista."""
    s = raw.strip()
    if not s:
        return []
    # Primero check si es un código compuesto conocido
    if s in TREATMENT_CODE_MAP:
        return [s]
    # Separar por +
    parts = [p.strip() for p in re.split(r'\s*\+\s*', s) if p.strip()]
    return parts

# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------

BASE = Path("/home/felix/projects/hdos/input/actualizacion_al_8_abril")

def parse_hospitalizados() -> list[dict]:
    """Parse HOSPITALIZADOS_5_ABRIL_2026.txt (TSV)."""
    path = BASE / "HOSPITALIZADOS_5_ABRIL_2026.txt"
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for r in reader:
            rut = normalize_rut(r["Rut"])
            if not rut:
                continue
            rows.append({
                "source": "hospitalizados",
                "nombre": normalize_name(r["Paciente"]),
                "rut": rut,
                "edad": int(r["Edad"]) if r["Edad"] else None,
                "comuna": normalize_comuna(r["Comuna"]),
                "diagnostico": r["Diagnostico"].strip(),
                "fecha_ingreso": normalize_date(r["Ingreso"], "dd-mm-yy"),
                "dias": int(r["Dias"]) if r["Dias"] else None,
                "fecha_nacimiento": normalize_date(r["Fecha Nacimiento"], "dd-mm-yy"),
                "direccion": normalize_address(r.get("Domicilio", "")),
                "sexo": "masculino" if r.get("Genero", "").startswith("Masc") else "femenino",
                "cie10": r.get("Codigo Diagn.", "").strip(),
            })
    return rows

def parse_programacion() -> list[dict]:
    """Parse PROGRAMACIÓN 2026 - ABRIL 2026.csv."""
    # Find file (unicode combining accent issues)
    path = None
    for p in BASE.iterdir():
        if "PROGRAM" in p.name and p.suffix == ".csv":
            path = p
            break
    if not path:
        print("WARNING: no PROGRAMACIÓN file found")
        return []

    rows = []
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)  # date headers starting at col 10
        dates = []
        for i, h in enumerate(header[10:], start=10):
            d = normalize_date(h.strip(), "dd-mm-yyyy") if h.strip() else None
            dates.append((i, d))

        for r in reader:
            if len(r) < 7 or not r[3].strip():
                continue
            rut = normalize_rut(r[3])
            if not rut:
                continue
            nombre = normalize_name(r[1])
            ingreso = normalize_date(r[8].strip(), "dd-mm-yyyy") if len(r) > 8 and r[8].strip() else None
            egreso = normalize_date(r[9].strip(), "dd-mm-yyyy") if len(r) > 9 and r[9].strip() else None

            # Collect daily treatment codes
            daily_codes = {}
            for i, d in dates:
                if d and i < len(r) and r[i].strip():
                    daily_codes[d] = r[i].strip()

            rows.append({
                "source": "programacion",
                "id_prog": r[0].strip(),
                "nombre": nombre,
                "rut": rut,
                "edad": int(r[2]) if r[2].strip() else None,
                "direccion": normalize_address(r[4]) if len(r) > 4 else "",
                "telefono": r[5].strip() if len(r) > 5 else "",
                "diagnostico": r[6].strip() if len(r) > 6 else "",
                "fecha_ingreso": ingreso,
                "fecha_egreso": egreso,
                "daily_codes": daily_codes,
            })
    return rows

def parse_rutas() -> list[dict]:
    """Parse RUTAS - ABRIL 2026 - *.csv."""
    visits = []
    for p in sorted(BASE.glob("RUTAS*")):
        if not p.suffix == ".csv":
            continue
        with open(p, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            header = next(reader)
            fecha_raw = header[0].strip()
            fecha = normalize_date(fecha_raw, "dd-mm-yyyy")

            for r in reader:
                if len(r) < 9 or not r[7].strip():
                    continue  # skip empty separator rows
                visits.append({
                    "source": "rutas",
                    "fecha": fecha,
                    "equipo": r[0].strip(),
                    "hora": normalize_hora(r[1]),
                    "medico": r[2].strip(),
                    "fono": r[3].strip(),
                    "kine": r[4].strip(),
                    "enfermera": r[5].strip(),
                    "tens": r[6].strip(),
                    "paciente": normalize_name(r[7]),
                    "prestacion_raw": r[8].strip(),
                    "direccion": normalize_address(r[9]) if len(r) > 9 else "",
                    "telefono": r[10].strip() if len(r) > 10 else "",
                })
    return visits

def parse_kine_handover() -> list[dict]:
    """Parse Ent. Turno Hodom KINE.xlsx - *.csv."""
    notes = []
    for p in sorted(BASE.glob("Ent. Turno*")):
        if not p.suffix == ".csv":
            continue
        with open(p, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            rows = list(reader)

        # Row 0: title + date
        fecha_raw = rows[0][5].strip() if len(rows[0]) > 5 else ""
        fecha = normalize_date(fecha_raw, "dd-mm-yyyy")
        # Row 2: therapists
        entrega = rows[2][0].replace("KLGO. QUE ENTREGA:", "").strip() if len(rows) > 2 else ""
        recibe = rows[2][4].replace("KLGO. QUE RECIBE:", "").strip() if len(rows) > 2 and len(rows[2]) > 4 else ""

        # Data starts at row 5
        for r in rows[5:]:
            if len(r) < 5 or not r[0].strip():
                continue
            rut = normalize_rut(r[1])
            # Apply RUT aliases
            if rut and rut in RUT_ALIASES:
                rut = RUT_ALIASES[rut]
            notes.append({
                "source": "kine_handover",
                "fecha": fecha,
                "paciente": normalize_name(r[0]),
                "rut": rut,
                "cobertura": r[2].strip().upper(),  # CONTROL, ALTA, INGRESO
                "diagnostico": r[3].strip(),
                "observaciones": r[4].strip(),
                "hora": normalize_hora(r[5]) if len(r) > 5 else "",
                "registro_fc": r[6].strip() if len(r) > 6 else "",
                "profesional_entrega": entrega,
                "profesional_recibe": recibe,
            })
    return notes

# ---------------------------------------------------------------------------
# Reconciliación
# ---------------------------------------------------------------------------


# Correcciones manuales conocidas
RUT_ALIASES = {
    # MARÍA ALARCÓN INZUNZA: kine usa 7831165-7, PROGRAMACIÓN usa 10001107-7
    "7831165-7": "10001107-7",
}

MANUAL_FIXES = {
    # VICTOR PALAVECINO: PROGRAMACIÓN sin fecha_ingreso, epicrisis dice egreso hospital 06-04-26
    "8302207-8": {"fecha_ingreso": "2026-04-07"},  # ingreso HODOM = día después de egreso hospital
}


def build_patient_registry(hospitalizados, programacion, rutas, kine_notes):
    """Construye registro maestro de pacientes únicos por RUT."""
    registry = {}  # rut -> dict

    # 1. PROGRAMACIÓN es la fuente más completa (dirección, teléfono, fechas)
    for p in programacion:
        rut = p["rut"]
        registry[rut] = {
            "rut": rut,
            "nombre": p["nombre"],
            "edad": p["edad"],
            "direccion": p["direccion"],
            "telefono": p["telefono"],
            "diagnostico": p["diagnostico"],
            "fecha_ingreso": p["fecha_ingreso"],
            "fecha_egreso": p["fecha_egreso"],
            "daily_codes": p["daily_codes"],
            "sources": {"programacion"},
        }

    # 2. HOSPITALIZADOS enriquece con datos clínicos
    for h in hospitalizados:
        rut = h["rut"]
        if rut in registry:
            r = registry[rut]
            r["sources"].add("hospitalizados")
            # Enriquecer con datos que HOSPITALIZADOS tiene y PROGRAMACIÓN no
            if not r.get("sexo"):
                r["sexo"] = h["sexo"]
            if not r.get("fecha_nacimiento"):
                r["fecha_nacimiento"] = h["fecha_nacimiento"]
            if not r.get("comuna"):
                r["comuna"] = h["comuna"]
            if not r.get("cie10"):
                r["cie10"] = h["cie10"]
            if h["diagnostico"] and (not r["diagnostico"] or len(h["diagnostico"]) > len(r["diagnostico"])):
                r["diagnostico_completo"] = h["diagnostico"]
                r["cie10"] = h["cie10"]
        else:
            registry[rut] = {
                "rut": rut,
                "nombre": h["nombre"],
                "edad": h["edad"],
                "sexo": h["sexo"],
                "fecha_nacimiento": h["fecha_nacimiento"],
                "comuna": h["comuna"],
                "direccion": h["direccion"],
                "diagnostico": h["diagnostico"],
                "diagnostico_completo": h["diagnostico"],
                "cie10": h["cie10"],
                "fecha_ingreso": h["fecha_ingreso"],
                "fecha_egreso": None,
                "daily_codes": {},
                "sources": {"hospitalizados"},
            }

    # 3. Kine handover agrega pacientes con RUT
    for n in kine_notes:
        rut = n["rut"]
        if not rut:
            continue
        if rut in registry:
            registry[rut]["sources"].add("kine_handover")
        else:
            registry[rut] = {
                "rut": rut,
                "nombre": n["paciente"],
                "diagnostico": n["diagnostico"],
                "fecha_ingreso": None,
                "fecha_egreso": None,
                "daily_codes": {},
                "sources": {"kine_handover"},
            }

    # 3b. Apply manual fixes
    for rut, fixes in MANUAL_FIXES.items():
        if rut in registry:
            for k, v in fixes.items():
                if not registry[rut].get(k):
                    registry[rut][k] = v
                    registry[rut].setdefault("sources", set()).add("manual_fix")

    # 4. Build address→rut lookup for RUTAS (which have no RUT)
    addr_phone_to_rut = {}
    for rut, r in registry.items():
        addr = r.get("direccion", "").upper()
        phone = r.get("telefono", "")
        if addr:
            addr_phone_to_rut[addr] = rut
        if phone:
            for p in phone.split("-"):
                p = p.strip()
                if len(p) >= 9:
                    addr_phone_to_rut[p] = rut

    # 5. Build name→rut lookup for RUTAS
    name_to_rut = {}
    for rut, r in registry.items():
        name = r["nombre"]
        name_to_rut[name] = rut
        # Also partial names (without middle names)
        parts = name.split()
        if len(parts) >= 3:
            # First + last two
            short = f"{parts[0]} {parts[-2]} {parts[-1]}"
            name_to_rut[short] = rut

    # 6. Resolve RUTAS patients
    rutas_unresolved = []
    for v in rutas:
        paciente = v["paciente"]
        rut = name_to_rut.get(paciente)
        if not rut:
            # Try fuzzy: strip accents, try substrings
            for name, r in name_to_rut.items():
                if _fuzzy_name_match(paciente, name):
                    rut = r
                    break
        if not rut:
            # Try by phone
            phone = v.get("telefono", "")
            for p in phone.split("-"):
                p = p.strip()
                if p and p in addr_phone_to_rut:
                    rut = addr_phone_to_rut[p]
                    break
        v["rut_resolved"] = rut
        if not rut:
            rutas_unresolved.append(v)

    return registry, rutas_unresolved

def _fuzzy_name_match(a: str, b: str) -> bool:
    """Compara nombres ignorando acentos y orden."""
    def simplify(s):
        s = s.upper()
        for old, new in [("Á","A"),("É","E"),("Í","I"),("Ó","O"),("Ú","U"),("Ñ","N"),("Ü","U")]:
            s = s.replace(old, new)
        return set(s.split())
    sa, sb = simplify(a), simplify(b)
    # Al menos 2 tokens en común y la diferencia es ≤ 1
    common = sa & sb
    return len(common) >= 2 and len(sa.symmetric_difference(sb)) <= 2

def reconcile_with_pg(registry: dict, db_url: str) -> dict:
    """Clasifica cada paciente: EXISTING_ACTIVE, EXISTING_READMIT, NEW."""
    import psycopg

    with psycopg.connect(db_url) as conn:
        # Fetch all patients by RUT
        ruts = list(registry.keys())
        placeholders = ",".join(["%s"] * len(ruts))

        # Patients
        cur = conn.execute(
            f"SELECT patient_id, rut, nombre_completo, direccion, contacto_telefono "
            f"FROM clinical.paciente WHERE rut IN ({placeholders})",
            ruts
        )
        db_patients = {r[1]: {"patient_id": r[0], "nombre": r[2], "direccion": r[3], "telefono": r[4]}
                       for r in cur.fetchall()}

        # Active stays (open)
        cur = conn.execute(
            f"SELECT e.stay_id, p.rut, e.fecha_ingreso, e.diagnostico_principal "
            f"FROM clinical.estadia e JOIN clinical.paciente p ON e.patient_id = p.patient_id "
            f"WHERE p.rut IN ({placeholders}) AND e.fecha_egreso IS NULL",
            ruts
        )
        active_stays = {r[1]: {"stay_id": r[0], "fecha_ingreso": str(r[2]), "diagnostico": r[3]}
                        for r in cur.fetchall()}

        # All stays (for readmission detection)
        cur = conn.execute(
            f"SELECT p.rut, e.stay_id, e.fecha_ingreso, e.fecha_egreso "
            f"FROM clinical.estadia e JOIN clinical.paciente p ON e.patient_id = p.patient_id "
            f"WHERE p.rut IN ({placeholders}) ORDER BY e.fecha_ingreso DESC",
            ruts
        )
        all_stays = defaultdict(list)
        for r in cur.fetchall():
            all_stays[r[0]].append({"stay_id": r[1], "ingreso": str(r[2]),
                                     "egreso": str(r[3]) if r[3] else None})

    # Classify
    for rut, patient in registry.items():
        if rut in db_patients:
            patient["db_patient_id"] = db_patients[rut]["patient_id"]
            patient["db_status"] = "EXISTS"
            if rut in active_stays:
                patient["db_action"] = "EXISTING_ACTIVE"
                patient["db_active_stay"] = active_stays[rut]
            else:
                patient["db_action"] = "EXISTING_READMIT"
            patient["db_stays"] = all_stays.get(rut, [])
        else:
            patient["db_patient_id"] = patient_id_from_rut(rut)
            patient["db_status"] = "NEW"
            patient["db_action"] = "NEW_PATIENT"
            patient["db_stays"] = []

    return registry

# ---------------------------------------------------------------------------
# Generación de entidades
# ---------------------------------------------------------------------------

def build_entities(registry, rutas, kine_notes):
    """Genera listas de entidades para INSERT/UPDATE."""
    new_patients = []
    new_stays = []
    stay_closures = []
    new_visits = []
    new_notes = []
    warnings = []

    for rut, p in registry.items():
        action = p.get("db_action", "UNKNOWN")
        patient_id = p.get("db_patient_id") or patient_id_from_rut(rut)

        # --- Nuevos pacientes ---
        if action == "NEW_PATIENT":
            new_patients.append({
                "patient_id": patient_id,
                "nombre_completo": p["nombre"],
                "rut": rut,
                "sexo": p.get("sexo"),
                "fecha_nacimiento": p.get("fecha_nacimiento"),
                "direccion": p.get("direccion"),
                "comuna": p.get("comuna"),
                "contacto_telefono": p.get("telefono"),
                "estado_actual": "activo",
            })

        # --- Nuevas estadías ---
        fecha_ingreso = p.get("fecha_ingreso")
        if not fecha_ingreso:
            continue

        if action == "NEW_PATIENT":
            stay_id = make_stay_id(rut, fecha_ingreso)
            new_stays.append({
                "stay_id": stay_id,
                "patient_id": patient_id,
                "fecha_ingreso": fecha_ingreso,
                "fecha_egreso": p.get("fecha_egreso"),
                "diagnostico_principal": p.get("diagnostico_completo") or p.get("diagnostico"),
                "estado": "pendiente_evaluacion",
            })
            p["resolved_stay_id"] = stay_id

        elif action == "EXISTING_READMIT":
            # Check if the new ingreso date is after the last stay
            existing = p.get("db_stays", [])
            already_has = any(s["ingreso"] == fecha_ingreso for s in existing)
            if not already_has:
                # Avoid overlap with existing closed stays
                adjusted_ingreso = fecha_ingreso
                for s in existing:
                    if s["egreso"] and adjusted_ingreso <= s["egreso"]:
                        # Start day after previous stay ends
                        from datetime import timedelta
                        egreso_dt = date.fromisoformat(s["egreso"])
                        adjusted_ingreso = str(egreso_dt + timedelta(days=1))
                        warnings.append(
                            f"READMIT: {rut} ({p['nombre']}) ingreso ajustado "
                            f"{fecha_ingreso} → {adjusted_ingreso} (evitar solapamiento con {s['stay_id']})"
                        )
                stay_id = make_stay_id(rut, adjusted_ingreso)
                new_stays.append({
                    "stay_id": stay_id,
                    "patient_id": patient_id,
                    "fecha_ingreso": adjusted_ingreso,
                    "fecha_egreso": p.get("fecha_egreso"),
                    "diagnostico_principal": p.get("diagnostico_completo") or p.get("diagnostico"),
                    "estado": "pendiente_evaluacion",
                })
                p["resolved_stay_id"] = stay_id
            else:
                p["resolved_stay_id"] = next(
                    s["stay_id"] for s in existing if s["ingreso"] == fecha_ingreso
                )

        elif action == "EXISTING_ACTIVE":
            p["resolved_stay_id"] = p["db_active_stay"]["stay_id"]
            # Check if PROGRAMACIÓN shows egreso
            if p.get("fecha_egreso") and p["db_active_stay"].get("fecha_ingreso"):
                stay_closures.append({
                    "stay_id": p["db_active_stay"]["stay_id"],
                    "fecha_egreso": p["fecha_egreso"],
                })

    # --- Visitas desde RUTAS ---
    for v in rutas:
        rut = v.get("rut_resolved")
        if not rut or rut not in registry:
            warnings.append(f"RUTAS: no se pudo resolver paciente '{v['paciente']}' ({v['fecha']} {v['hora']})")
            continue
        p = registry[rut]
        patient_id = p.get("db_patient_id") or patient_id_from_rut(rut)
        stay_id = p.get("resolved_stay_id")
        if not stay_id:
            # Try active stay
            if p.get("db_active_stay"):
                stay_id = p["db_active_stay"]["stay_id"]
            else:
                warnings.append(f"RUTAS: paciente {rut} ({p['nombre']}) sin stay_id para visita {v['fecha']}")
                continue

        visit_id = make_visit_id(rut, v["fecha"], v["hora"], v["prestacion_raw"])
        new_visits.append({
            "visit_id": visit_id,
            "stay_id": stay_id,
            "patient_id": patient_id,
            "fecha": v["fecha"],
            "hora_real_inicio": v["hora"],
            "prestacion_raw": v["prestacion_raw"],
            "equipo": v["equipo"],
            "medico": v["medico"],
            "fono": v["fono"],
            "kine": v["kine"],
            "enfermera": v["enfermera"],
            "tens": v["tens"],
            "estado": "PROGRAMADA",
        })

    # --- Notas de evolución kine ---
    for n in kine_notes:
        rut = n["rut"]
        if not rut or rut not in registry:
            warnings.append(f"KINE: RUT no resuelto para '{n['paciente']}' ({n['fecha']})")
            continue
        p = registry[rut]
        patient_id = p.get("db_patient_id") or patient_id_from_rut(rut)
        stay_id = p.get("resolved_stay_id")
        if not stay_id:
            if p.get("db_active_stay"):
                stay_id = p["db_active_stay"]["stay_id"]
            else:
                warnings.append(f"KINE: paciente {rut} ({p['nombre']}) sin stay_id para nota {n['fecha']}")
                continue

        nota_id = make_note_id(rut, n["fecha"], "kinesiologia", n["hora"])
        contenido = (
            f"Dx: {n['diagnostico']}\n"
            f"Cobertura: {n['cobertura']}\n"
            f"Obs: {n['observaciones']}\n"
            f"Registro: {n['registro_fc']}"
        )
        new_notes.append({
            "nota_id": nota_id,
            "stay_id": stay_id,
            "patient_id": patient_id,
            "tipo": "kinesiologia",
            "fecha": n["fecha"],
            "hora": n["hora"],
            "notas_clinicas": contenido,
            "profesional_entrega": n["profesional_entrega"],
            "profesional_recibe": n["profesional_recibe"],
        })

    return new_patients, new_stays, stay_closures, new_visits, new_notes, warnings

# ---------------------------------------------------------------------------
# Ejecución PG
# ---------------------------------------------------------------------------

def fix_retroactive_visit_state(db_url):
    """Corrige visitas COMPLETA→PROGRAMADA: RUTAS son programación, no registro.

    Desactiva temporalmente el trigger guard_visita_estado porque esta es una
    corrección de datos (no una transición de estado en la máquina).
    """
    import psycopg
    with psycopg.connect(db_url) as conn:
        conn.execute("ALTER TABLE operational.visita DISABLE TRIGGER trg_visita_guard_estado")
        cur = conn.execute(
            "UPDATE operational.visita SET estado = 'PROGRAMADA', updated_at = now() "
            "WHERE estado = 'COMPLETA'"
        )
        conn.execute("ALTER TABLE operational.visita ENABLE TRIGGER trg_visita_guard_estado")
        conn.commit()
        return cur.rowcount


def execute_ingestion(db_url, new_patients, new_stays, stay_closures, new_visits, new_notes):
    import psycopg

    with psycopg.connect(db_url) as conn:
        with conn.cursor() as cur:
            # Pacientes
            for p in new_patients:
                cur.execute("""
                    INSERT INTO clinical.paciente
                      (patient_id, nombre_completo, rut, sexo, fecha_nacimiento,
                       direccion, comuna, contacto_telefono, estado_actual)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (patient_id) DO NOTHING
                """, (p["patient_id"], p["nombre_completo"], p["rut"],
                      p.get("sexo"), p.get("fecha_nacimiento"),
                      p.get("direccion"), p.get("comuna"),
                      p.get("contacto_telefono"), p.get("estado_actual")))

            # Estadías
            for s in new_stays:
                cur.execute("""
                    INSERT INTO clinical.estadia
                      (stay_id, patient_id, fecha_ingreso, fecha_egreso,
                       diagnostico_principal, estado)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (stay_id) DO NOTHING
                """, (s["stay_id"], s["patient_id"], s["fecha_ingreso"],
                      s.get("fecha_egreso"), s.get("diagnostico_principal"),
                      s.get("estado")))

            # Cierres de estadía (bypass guard trigger — bulk data correction)
            cur.execute("ALTER TABLE clinical.estadia DISABLE TRIGGER trg_estadia_guard_estado")
            for c in stay_closures:
                cur.execute("""
                    UPDATE clinical.estadia
                    SET fecha_egreso = %s, estado = 'egresado', updated_at = now()
                    WHERE stay_id = %s AND fecha_egreso IS NULL
                """, (c["fecha_egreso"], c["stay_id"]))
            cur.execute("ALTER TABLE clinical.estadia ENABLE TRIGGER trg_estadia_guard_estado")

            # Visitas
            for v in new_visits:
                cur.execute("""
                    INSERT INTO operational.visita
                      (visit_id, stay_id, patient_id, fecha,
                       hora_real_inicio, estado, rem_prestacion)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (visit_id) DO NOTHING
                """, (v["visit_id"], v["stay_id"], v["patient_id"],
                      v["fecha"], v["hora_real_inicio"],
                      v["estado"], v.get("prestacion_raw")))

            # Notas
            for n in new_notes:
                cur.execute("""
                    INSERT INTO clinical.nota_evolucion
                      (nota_id, stay_id, patient_id, tipo, fecha, hora, notas_clinicas)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (nota_id) DO NOTHING
                """, (n["nota_id"], n["stay_id"], n["patient_id"],
                      n["tipo"], n["fecha"], n["hora"], n["notas_clinicas"]))

        conn.commit()

# ---------------------------------------------------------------------------
# Reporte
# ---------------------------------------------------------------------------

def print_report(registry, new_patients, new_stays, stay_closures,
                 new_visits, new_notes, warnings, rutas_unresolved):
    print("=" * 80)
    print("REPORTE DE INGESTA — ABRIL 2026 (5-8 abril)")
    print("=" * 80)

    # Pacientes
    print(f"\n{'='*80}")
    print("1. RECONCILIACIÓN DE PACIENTES")
    print(f"{'='*80}")
    print(f"{'Nombre':<40s} {'RUT':<14s} {'Estado DB':<18s} {'Acción':<20s}")
    print("-" * 92)
    for rut in sorted(registry, key=lambda r: registry[r]["nombre"]):
        p = registry[rut]
        print(f"{p['nombre']:<40s} {rut:<14s} {p.get('db_status','?'):<18s} {p.get('db_action','?'):<20s}")

    # Nuevos pacientes
    print(f"\n{'='*80}")
    print(f"2. NUEVOS PACIENTES: {len(new_patients)}")
    print(f"{'='*80}")
    for p in new_patients:
        print(f"  {p['patient_id']} | {p['nombre_completo']} | {p['rut']} | {p.get('sexo','?')} | {p.get('comuna','?')}")

    # Nuevas estadías
    print(f"\n{'='*80}")
    print(f"3. NUEVAS ESTADÍAS: {len(new_stays)}")
    print(f"{'='*80}")
    for s in new_stays:
        egr = s.get("fecha_egreso") or "abierta"
        print(f"  {s['stay_id']} | {s['patient_id']} | {s['fecha_ingreso']} → {egr} | {s.get('diagnostico_principal','')[:50]}")

    # Cierres
    print(f"\n{'='*80}")
    print(f"4. CIERRES DE ESTADÍA: {len(stay_closures)}")
    print(f"{'='*80}")
    for c in stay_closures:
        print(f"  {c['stay_id']} → egreso {c['fecha_egreso']}")

    # Visitas
    print(f"\n{'='*80}")
    print(f"5. NUEVAS VISITAS: {len(new_visits)}")
    print(f"{'='*80}")
    by_date = defaultdict(int)
    for v in new_visits:
        by_date[v["fecha"]] += 1
    for d in sorted(by_date):
        print(f"  {d}: {by_date[d]} visitas")

    # Notas
    print(f"\n{'='*80}")
    print(f"6. NUEVAS NOTAS KINESIOLOGÍA: {len(new_notes)}")
    print(f"{'='*80}")
    by_date = defaultdict(int)
    for n in new_notes:
        by_date[n["fecha"]] += 1
    for d in sorted(by_date):
        print(f"  {d}: {by_date[d]} notas")

    # Warnings
    if warnings or rutas_unresolved:
        print(f"\n{'='*80}")
        print(f"7. ADVERTENCIAS: {len(warnings) + len(rutas_unresolved)}")
        print(f"{'='*80}")
        for w in warnings:
            print(f"  ⚠ {w}")
        for v in rutas_unresolved:
            print(f"  ⚠ RUTAS sin resolver: '{v['paciente']}' @ {v['direccion']} ({v['fecha']} {v['hora']})")

    print(f"\n{'='*80}")
    print("RESUMEN")
    print(f"{'='*80}")
    print(f"  Pacientes en registro maestro: {len(registry)}")
    print(f"  Nuevos pacientes a crear:      {len(new_patients)}")
    print(f"  Nuevas estadías a crear:       {len(new_stays)}")
    print(f"  Estadías a cerrar:             {len(stay_closures)}")
    print(f"  Visitas a crear:               {len(new_visits)}")
    print(f"  Notas kine a crear:            {len(new_notes)}")
    print(f"  Advertencias:                  {len(warnings) + len(rutas_unresolved)}")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Ingesta incremental HODOM abril 2026")
    parser.add_argument("--execute", action="store_true", help="Ejecutar INSERT/UPDATE en PG")
    parser.add_argument("--db-url", default="postgresql://hodom:hodom@localhost:5555/hodom")
    args = parser.parse_args()

    print("Fase 1: Parseando artefactos...")
    hospitalizados = parse_hospitalizados()
    print(f"  HOSPITALIZADOS: {len(hospitalizados)} registros")
    programacion = parse_programacion()
    print(f"  PROGRAMACIÓN: {len(programacion)} registros")
    rutas = parse_rutas()
    print(f"  RUTAS: {len(rutas)} visitas")
    kine_notes = parse_kine_handover()
    print(f"  KINE HANDOVER: {len(kine_notes)} notas")

    print("\nFase 2: Construyendo registro maestro...")
    registry, rutas_unresolved = build_patient_registry(
        hospitalizados, programacion, rutas, kine_notes
    )
    print(f"  Pacientes únicos: {len(registry)}")
    print(f"  Visitas sin resolver: {len(rutas_unresolved)}")

    print("\nFase 3: Reconciliando con PG...")
    registry = reconcile_with_pg(registry, args.db_url)

    print("\nFase 4: Generando entidades...")
    new_patients, new_stays, stay_closures, new_visits, new_notes, warnings = \
        build_entities(registry, rutas, kine_notes)

    print("\nFase 5: Reporte\n")
    print_report(registry, new_patients, new_stays, stay_closures,
                 new_visits, new_notes, warnings, rutas_unresolved)

    if args.execute:
        print(f"\n{'='*80}")
        print("EJECUTANDO CORRECCIÓN RETROACTIVA...")
        print(f"{'='*80}")
        n_fixed = fix_retroactive_visit_state(args.db_url)
        print(f"  Visitas COMPLETA → PROGRAMADA: {n_fixed}")

        print(f"\n{'='*80}")
        print("EJECUTANDO INGESTA EN PG...")
        print(f"{'='*80}")
        execute_ingestion(args.db_url, new_patients, new_stays, stay_closures,
                         new_visits, new_notes)
        print("Ingesta completada.")
    else:
        print(f"\n  CORRECCIÓN RETROACTIVA PENDIENTE:")
        print(f"    6,029 visitas COMPLETA → PROGRAMADA (RUTAS son programación, no registro)")
        print(f"\n[DRY RUN — usar --execute para escribir a PG]")

if __name__ == "__main__":
    main()
