#!/usr/bin/env python3
"""CORR-09: Normalizar direcciones de pacientes HODOM.

Lee 482 localizaciones desde /tmp/hdos_locs_to_normalize.csv y aplica
reglas de normalización IDE Chile 2023 / INE Censo 2017 para producir:
  - direccion_texto:  dirección estructurada (tipo vía + nombre + número)
  - localidad:        nombre INE canónico si es zona rural conocida
  - referencia:       indicaciones de orientación extraídas

Genera: scripts/corr_09_normalizar_direcciones.sql

Run: .venv/bin/python scripts/corr_09_normalizar_direcciones.py
"""
import csv
import re
import unicodedata
from datetime import datetime

# ── Paths ─────────────────────────────────────────────────────────────────
INPUT_CSV = "/tmp/hdos_locs_to_normalize.csv"
REF_LOCALIDADES = "/tmp/hdos_ref_localidades.txt"
SQL_OUTPUT = "scripts/corr_09_normalizar_direcciones.sql"

# ── Text helpers ──────────────────────────────────────────────────────────

def strip_accents(text: str) -> str:
    """Remove diacritics but preserve Ñ/ñ."""
    out = []
    for ch in unicodedata.normalize("NFD", text):
        if unicodedata.category(ch) == "Mn":
            # Keep combining tilde on N (for Ñ)
            if ch == "\u0303" and out and out[-1].upper() == "N":
                out.append(ch)
            continue
        out.append(ch)
    return unicodedata.normalize("NFC", "".join(out))


def norm_key(text: str) -> str:
    """Uppercase, accent-stripped key for dictionary matching."""
    return strip_accents(text.strip().upper())


PARTICLES = {"de", "del", "la", "las", "los", "el", "y", "a", "en", "al", "sin"}


def title_case_es(text: str) -> str:
    """Title-case a Spanish phrase, keeping particles lowercase except first word."""
    words = text.strip().split()
    result = []
    for i, w in enumerate(words):
        wl = w.lower()
        if i == 0 or wl not in PARTICLES:
            result.append(w.capitalize())
        else:
            result.append(wl)
    return " ".join(result)


def title_case_phrase(text: str) -> str:
    """Title-case, preserve known acronyms uppercase (S/N, KM)."""
    words = text.strip().split()
    result = []
    UPPER_ALWAYS = {"S/N", "SN", "KM"}
    for i, w in enumerate(words):
        wu = w.upper()
        if wu in UPPER_ALWAYS:
            result.append(wu if wu != "SN" else "S/N")
        elif i == 0 or w.lower() not in PARTICLES:
            result.append(w.capitalize())
        else:
            result.append(w.lower())
    return " ".join(result)


def esc_sql(text: str) -> str:
    """Escape single quotes for SQL string literals."""
    return text.replace("'", "''")


# ── Load INE localidades reference ───────────────────────────────────────

def load_ine_localidades(path: str) -> dict[str, str]:
    """
    Returns: { norm_key(localidad_name): title_cased_name }
    Built from column 1 (LOCALIDAD) of the semicolon-separated file.
    """
    locs: dict[str, str] = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split(";")
            if len(parts) < 2:
                continue
            localidad = parts[1].strip()
            if localidad and localidad.upper() != "INDETERMINADA":
                key = norm_key(localidad)
                if key not in locs:
                    # Store in title case
                    locs[key] = title_case_es(localidad.lower())
    return locs


INE_LOCALIDADES: dict[str, str] = {}  # populated in main()


# ── Known urban streets (San Carlos + other communes) ────────────────────
# Ordered longest-first to avoid premature partial matches
_URBAN_STREETS_RAW: list[str] = [
    "27 DE ABRIL", "GENERAL TENIENTE MERINO", "FRANCISCO PUELMA",
    "FRANCISCO PEREIRA", "HERNAN CORTES CONTRERAS", "LUIS CRUZ MARTINEZ",
    "VALENTINA TERESHKOVA", "MEDARDO VENEGAS", "BALDOMERO SILVA",
    "JOAQUIN DEL PINO", "VICUÑA MACKENNA", "VICUNA MACKENNA",
    "VICUÑA MACKENA", "VARIANTE SAN AGUSTIN", "TENIENTE MERINO",
    "GENERAL VENEGAS", "PADRE ELOY", "LUIS ACEVEDO", "ARTURO PRAT",
    "DIEGO PORTALES", "PEDRO LAGOS", "RAMON DIAZ", "SARGENTO ALDEA",
    "SAGENTO ALDEA", "H. MONROY", "H MONROY",
    "TOMAS YAVAR", "TAMAS YAVAR",  # typo variants — normalized later
    "INDEPENDENCIA", "LLANQUIHUE", "CHACABUCO", "BALMACEDA",
    "COLOMBIA", "BRASIL", "CARRERA", "RIQUELME", "FREIRE", "MATTA",
    "BILBAO", "GAZMURI", "NAVOTAVO", "PUELMA", "OSSA", "REYMAN",
    "SERRANO", "LAUTARO", "MAIPÚ", "MAIPU", "LURIN",
    "OHIGGINS", "O'HIGGINS",
    "ÑUBLE", "NUBLE",   # urban section of Ñuble river road
    "LAUREL", "ROBLE",  # trees — both urban street and rural area; prioritize urban
]
URBAN_STREETS_SET: set[str] = {norm_key(s) for s in _URBAN_STREETS_RAW}

# Display corrections for specific streets
_STREET_DISPLAY: dict[str, str] = {
    "OHIGGINS": "O'Higgins",
    "O'HIGGINS": "O'Higgins",
    "TAMAS YAVAR": "Tomás Yavar",
    "TOMAS YAVAR": "Tomás Yavar",
    "VICUÑA MACKENA": "Vicuña Mackenna",
    "VICUNA MACKENNA": "Vicuña Mackenna",
    "SAGENTO ALDEA": "Sargento Aldea",
    "H. MONROY": "H. Monroy",
    "H MONROY": "H. Monroy",
    "27 DE ABRIL": "27 de Abril",
    "MAIPU": "Maipú",
    "NUBLE": "Ñuble",
    "ÑUBLE": "Ñuble",
}


def get_street_display(street_key: str) -> str:
    """Return display name for a known street key."""
    if street_key in _STREET_DISPLAY:
        return _STREET_DISPLAY[street_key]
    return title_case_es(street_key.lower())


# ── Known villa/población names ──────────────────────────────────────────
_VILLAS_RAW: list[str] = [
    "11 DE SEPTIEMBRE", "11 SEPTIEMBRE", "11 SEPT",
    "NUEVA ESPERANZA", "PUESTA DEL SOL", "VILLA LOS ANDES",
    "NUEVA VIDA", "NVA VIDA", "NVA. VIDA",
    "LAS ARBOLEDAS", "VISIÓN MUNDIAL", "VISION MUNDIAL",
    "ESMERALDA", "PORTAL DE LA LUNA", "VILLA EL BOSQUE",
    "VILLA LA VIRGEN", "LOS POETAS", "ARAUCANIA", "ARAUCANÍA",
    "PERDICES", "LOS AROMOS", "LAS NUBES", "LOS NARANJOS",
    "QUECHEREGUA",
    # Additional villas from data
    "VALLE HONDO", "PORTAL DEL SUR", "LAGOS DE CHILE",
    "VILLA LAS AMERICAS", "LAS AMERICAS",
    "VILLA LOS JARDINES", "AIRES DE LURIN", "AIRES DE LAURIN",
    "VILLA BAENA", "VILLA BALMACEDA", "VILLA SANTA MARIA",
    "VILA VIRGEN DEL CAMINO", "VILLA VIRGEN DEL CAMINO",
    "BOSQUES DE ALGARROBAL", "NVA ATARDECER",
    "VILLA SAN CARLOS", "VILLA LOS CARACOLES",
]
VILLAS_SET: set[str] = {norm_key(v) for v in _VILLAS_RAW}

_VILLA_DISPLAY: dict[str, str] = {
    "11 DE SEPTIEMBRE": "Población 11 de Septiembre",
    "11 SEPTIEMBRE": "Población 11 de Septiembre",
    "11 SEPT": "Población 11 de Septiembre",
    "NUEVA ESPERANZA": "Villa Nueva Esperanza",
    "PUESTA DEL SOL": "Villa Puesta del Sol",
    "VILLA LOS ANDES": "Villa Los Andes",
    "NUEVA VIDA": "Villa Nueva Vida",
    "NVA VIDA": "Villa Nueva Vida",
    "NVA. VIDA": "Villa Nueva Vida",
    "LAS ARBOLEDAS": "Villa Las Arboledas",
    "VISION MUNDIAL": "Villa Visión Mundial",
    "VISIÓN MUNDIAL": "Villa Visión Mundial",
    "ESMERALDA": "Población Esmeralda",
    "QUECHEREGUA": "Población Esmeralda",
    "PORTAL DE LA LUNA": "Villa Portal de la Luna",
    "VILLA EL BOSQUE": "Villa El Bosque",
    "PERDICES": "Villa El Bosque",
    "VILLA LA VIRGEN": "Villa La Virgen",
    "LOS POETAS": "Villa Los Poetas",
    "ARAUCANIA": "Población Araucanía",
    "ARAUCANÍA": "Población Araucanía",
    "LOS AROMOS": "Población Los Aromos",
    "LAS NUBES": "Villa Nueva Vida",
    "LOS NARANJOS": "Sector Los Naranjos",
    "VALLE HONDO": "Población Valle Hondo",
    "PORTAL DEL SUR": "Villa Portal del Sur",
    "LAGOS DE CHILE": "Villa Lagos de Chile",
    "LAS AMERICAS": "Villa Las Américas",
    "VILLA LAS AMERICAS": "Villa Las Américas",
    "VILLA LOS JARDINES": "Villa Los Jardines",
    "AIRES DE LURIN": "Villa Aires de Lurín",
    "AIRES DE LAURIN": "Villa Aires de Lurín",
    "VILLA BAENA": "Villa Baena",
    "VILLA BALMACEDA": "Villa Balmaceda",
    "VILLA SANTA MARIA": "Villa Santa María",
    "VILA VIRGEN DEL CAMINO": "Villa Virgen del Camino",
    "VILLA VIRGEN DEL CAMINO": "Villa Virgen del Camino",
    "BOSQUES DE ALGARROBAL": "Bosques de Algarrobal",
    "NVA ATARDECER": "Villa Nuevo Atardecer",
    "VILLA SAN CARLOS": "Villa San Carlos",
    "VILLA LOS CARACOLES": "Villa Los Caracoles",
}


def get_villa_display(villa_key: str) -> str:
    if villa_key in _VILLA_DISPLAY:
        return _VILLA_DISPLAY[villa_key]
    return title_case_es(villa_key.lower())


# ── Pre-processing: abbreviation expansions applied to full address ───────
# Ordered by specificity (longer patterns first)
# Each entry: (regex_pattern, replacement)
_ABBR_EXPAND: list[tuple] = [
    # "P DEL SOL" / "P. DEL SOL" → Puesta del Sol
    (re.compile(r'\bP\.?\s+DEL\s+SOL\b', re.I), "Villa Puesta del Sol"),
    # "P DEL SUR" → Portal del Sur
    (re.compile(r'\bP\.?\s+DEL\s+SUR\b', re.I), "Villa Portal del Sur"),
    # "TTE MERINO" / "TTE. MERINO" → Teniente Merino
    (re.compile(r'\bTTE\.?\s+MERINO\b', re.I), "Teniente Merino"),
    # "GRAL VENEGAS" / "GRAL. VENEGAS" → General Venegas
    (re.compile(r'\bGRAL\.?\s+VENEGAS\b', re.I), "General Venegas"),
    # "L C MARTINEZ" → Luis Cruz Martínez
    (re.compile(r'\bL\.?\s*C\.?\s+MARTINEZ\b', re.I), "Luis Cruz Martínez"),
    # "J MONTES" → José Montes (Los Poetas context)
    (re.compile(r'\bJ\.?\s+MONTES\b', re.I), "José Montes"),
    # "JP SUBERCASEUX" / "J P SUBERCASEAUX" → José Pedro Subercaseaux
    (re.compile(r'\bJP\s+SUBERCAS\w+\b', re.I), "José Pedro Subercaseaux"),
    # "NVA ATARDECER" → Nueva Atardecer
    (re.compile(r'\bNVA\.?\s+ATARDECER\b', re.I), "Nueva Atardecer"),
    # "NVA VIDA" / "NVA. VIDA" → Nueva Vida
    (re.compile(r'\bNVA\.?\s+VIDA\b', re.I), "Nueva Vida"),
    # "POBL\." / "POB " → Población
    (re.compile(r'\bPOBL?\.\s*', re.I), "Población "),
    # "PSJE\." → Pasaje
    (re.compile(r'\bPSJE?\.\s*', re.I), "Pasaje "),
    # "PJE\." → Pasaje
    (re.compile(r'\bPJE?\.\s*', re.I), "Pasaje "),
    # "KIM" (typo for KM)
    (re.compile(r'\bKIM\s*(\d)', re.I), r"KM \1"),
    # "ELEAM" normalization
    (re.compile(r'\bELEAM\b', re.I), "ELEAM"),
    # "AGUA BUENAKM" → "AGUA BUENA KM" (missing space before KM)
    (re.compile(r'([A-Za-záéíóúñÑ])(KM\d)', re.I), r'\1 \2'),
    # "KM3" → "KM 3" (no space between KM and digit)
    (re.compile(r'\b(KM)(\d)', re.I), r'\1 \2'),
]


def _preprocess(text: str) -> str:
    """Apply abbreviation expansions and light cleanup to raw address text."""
    # Period used as separator between address parts (e.g. "27 DE ABRIL. PJE")
    # Replace "word. UPPERCASE" with "word, UPPERCASE"
    text = re.sub(r'([A-Za-záéíóúñÑ0-9])\.(\s+[A-Z])', lambda m: m.group(1) + ',' + m.group(2), text)
    for pat, repl in _ABBR_EXPAND:
        text = pat.sub(repl, text)
    # Normalize multiple spaces
    text = re.sub(r'[ \t]+', ' ', text).strip()
    return text


# ── Manual locality overrides (not in INE or tricky to match) ─────────────
# key = norm_key of address prefix → (display_name, localidad)
# These handle cases where the INE lookup would fail or give wrong result
_MANUAL_LOCALITY: dict[str, tuple[str, str]] = {
    # Itihue - hamlet in San Carlos (El Treile sector in INE)
    "ITIHUE": ("Sector Itihue S/N", "Itihue"),
    # La Ribera / La Rivera — Ribera de Ñuble sector
    "LA RIBERA": ("Sector La Ribera S/N", "La Ribera"),
    "LA RIBERA S/N": ("Sector La Ribera S/N", "La Ribera"),
    "LA RIVERA": ("Sector La Ribera S/N", "La Ribera"),
    "RIVERA DE ÑUBLE": ("Sector Ribera de Ñuble S/N", "Ribera de Ñuble"),
    "RIBERA DE ÑUBLE": ("Sector Ribera de Ñuble S/N", "Ribera de Ñuble"),
    "RIBERA DE ÑUBLE S/N": ("Sector Ribera de Ñuble S/N", "Ribera de Ñuble"),
    # Montecillo / Monte Blanco
    "MONTECILLO": ("Sector Montecillo S/N", "Montecillo"),
    "MONTEBLANCO": ("Sector Monte Blanco S/N", "Monte Blanco"),
    "MONTEBLANCO S/N": ("Sector Monte Blanco S/N", "Monte Blanco"),
    "MONTE BLANCO": ("Sector Monte Blanco S/N", "Monte Blanco"),
    # Virguin / Virhuín (NIQUEN)
    "VIRGUIN": ("Sector Virhuín S/N", "Virhuín"),
    "VIRGUIN KM": ("Sector Virhuín S/N", "Virhuín"),   # incomplete "KM" without number
    "PUERTAS DE VIRGUIN": ("Sector Virhuín, Puertas de Virhuín S/N", "Virhuín"),
    # Miscellaneous rural spots in San Carlos / Ñiquén
    "CUADRANPANGUE": ("Sector Cuadrapangue S/N", "Cuadrapangue"),
    "CUADRAPANGUE CHICO S/N": ("Sector Cuadrapangue Chico S/N", "Cuadrapangue"),
    "CUADRAPANGUE CHICO": ("Sector Cuadrapangue Chico S/N", "Cuadrapangue"),
    "CUADRAPANGUE S/N KM 7.5": ("Sector Cuadrapangue, KM 7.5", "Cuadrapangue"),
    "LAS TOMAS DE CACHAPOAL": ("Sector Cachapoal, Las Tomas S/N", "Cachapoal"),
    "P DEL SOL E ABUKALIL": ("Pasaje E. Abukalil S/N, Villa Puesta del Sol", ""),
    "Las arboledas, a 50 metros frente al colegio.": ("Villa Las Arboledas S/N", ""),
    "OHIGGINS PASAJE COLO COLO": ("Pasaje Colo Colo S/N, Calle O'Higgins", ""),
    "CAM SAN AGUSTIN KM 2": ("Camino a San Agustín KM 2", ""),
    "SAN AGUSTIN KM 2 ( POR RUTA 5 SUR, PASAR PUENTE)": ("Camino a San Agustín KM 2", ""),
    "LA LENGA": ("Sector La Lenga S/N", "La Lenga"),
    "LENGA": ("Sector La Lenga S/N", "La Lenga"),
    "EL AROMO": ("Sector El Aromo S/N", "El Aromo"),
    "LOS MELLIZOS": ("Sector Los Mellizos S/N", "Los Mellizos"),
    "LOS CASTAÑOS": ("Sector Los Castaños S/N", "Los Castaños"),
    "LOS MAGNOLIOS": ("Sector Los Magnolios S/N", "Los Magnolios"),
    "LOS REGIDORES": ("Sector Los Regidores S/N", "Los Regidores"),
    "EL LAUREL": ("Sector El Laurel S/N", "El Laurel"),
    "SECTOR EL TRANQUE DE POMUYETO": ("Sector El Tranque de Pomuyeto S/N", "El Tranque de Pomuyeto"),
    "SECTOR IANSA, CHORILLO": ("Sector Iansa, Chorrillo S/N", "Iansa"),
    "CHORRILLO IANSA": ("Sector Chorrillo Iansa S/N", "Chorrillo Iansa"),
    "TRES ESQUINA DE CATO": ("Sector Tres Esquinas de Cato S/N", "Tres Esquinas"),
    "TRES ESQUINAS DE CATO": ("Sector Tres Esquinas de Cato S/N", "Tres Esquinas"),
    "TRES ESQUINA PASAJE LAS CAMELIAS": ("Pasaje Las Camelias S/N, Sector Tres Esquinas", "Tres Esquinas"),
    "SAN MANUEL DE VERQUICO": ("Sector San Manuel de Verquico S/N", "Verquico"),
    "QUINQUEHUA S/N": ("Sector Quinquegua S/N", "Quinquegua"),
    "QUINQUEHUA": ("Sector Quinquegua S/N", "Quinquegua"),
    "VISTA CORDILLERA, LA PRIMAVERA S/N": ("Sector La Primavera S/N, Vista Cordillera", "La Primavera"),
    # Ñiquén / Niquén
    "ÑIQUEN": ("Sector Ñiquén S/N", "Ñiquén"),
    "NIQUEN": ("Sector Ñiquén S/N", "Ñiquén"),
    "ÑIQUÉN": ("Sector Ñiquén S/N", "Ñiquén"),
    "LO MELLADO S/N": ("Sector Lo Mellado S/N", "Lo Mellado"),
    "LO MELLADO": ("Sector Lo Mellado S/N", "Lo Mellado"),
    # San Nicolas sector
    "LA QUINTRALA": ("Sector La Quintrala S/N", "La Quintrala"),
    "LA PRIMAVERA": ("Sector La Primavera S/N", "La Primavera"),
    "EL ORATORIO S/N": ("Sector El Oratorio S/N", "El Oratorio"),
    "EL ORATORIO": ("Sector El Oratorio S/N", "El Oratorio"),
    "EL MANZANO S/N": ("Sector El Manzano S/N", "El Manzano"),
    "EL MANZANO": ("Sector El Manzano S/N", "El Manzano"),
    "MONTE LEON S/N": ("Sector Monte León S/N", "Monte León"),
    "MONTE LEON": ("Sector Monte León S/N", "Monte León"),
    "HUAMPANGUE KM 1": ("Sector Huampangue, KM 1", "Huampangue"),
    "HUAMPANGUE": ("Sector Huampangue S/N", "Huampangue"),
    # San Carlos rural extras
    "EL CAPE": ("Sector El Capé S/N", "El Capé"),
    "EL CAPE SN": ("Sector El Capé S/N", "El Capé"),
    "EL CAPE S/N": ("Sector El Capé S/N", "El Capé"),
    "MUTIPIN KM 8.5": ("Sector Mutupín, KM 8.5", "Mutupín"),
    "MUTIPIN": ("Sector Mutupín S/N", "Mutupín"),
    "MONTECILLO KM 12": ("Sector Montecillo, KM 12", "Montecillo"),
    "MONTECILLO AGUA BUENAKM 1.6": ("Sector Montecillo, Agua Buena KM 1.6", "Montecillo"),
    "MONTEBLANCO, PARCELA 7": ("Sector Monte Blanco, Parcela 7", "Monte Blanco"),
    "MONTELEON EL SAUCE": ("Sector Monte León, El Sauce S/N", "Monte León"),
    "Monteleon El Sauce": ("Sector Monte León, El Sauce S/N", "Monte León"),
    "VERQICO S/N KM 6": ("Sector Verquico, KM 6", "Verquico"),
    "RAULI": ("Sector Raulí S/N", "Raulí"),
    "LAR ARBOLEDAS": ("Villa Las Arboledas S/N", ""),  # typo "LAR" → "LAS"
    "LOS LIBERTADORES, SAN MARTIN": ("Calle Los Libertadores S/N, San Martín", ""),
    "LA HIGUERA 874": ("Calle La Higuera 874", ""),
    "Estacion Ñiquen S/N": ("Sector Estación Ñiquén S/N", "Ñiquén"),
    "ESTACION ÑIQUEN S/N": ("Sector Estación Ñiquén S/N", "Ñiquén"),
    "EL ORATORIO CASA 15": ("Sector El Oratorio, Casa 15", "El Oratorio"),
    "GOLONDRINAS 0902 EL BOSQUE": ("Calle Golondrinas 0902, Villa El Bosque", ""),
    "HIOGAR BUEN PASTOR ÑUBLE": ("Hogar Buen Pastor, Ñuble S/N", ""),
    "HOGAR AMOR DE FAMILIA": ("Hogar Amor de Familia S/N", ""),
    "Hogar amor de familia": ("Hogar Amor de Familia S/N", ""),
    "CONDOMINIO LA MANTAÑA CASA 25": ("Condominio La Montaña, Casa 25", ""),
    "CASARES 2 BLOCK C DEPTO 33": ("Calle Casares 2, Block C Depto. 33", ""),
    "CASARES, BLOCK D DEPARTAMENTO": ("Calle Casares S/N, Block D Departamento", ""),
    "POB GRAL PARRA PSJE MATTA": ("Pasaje Matta S/N, Población General Parra", ""),
    "POBLACION TENIENTE MERINO VIA CENTRAL 035": ("Pasaje Vía Central 035, Población Teniente Merino", ""),
    "Puesta del Sol, José Gómez": ("Pasaje José Gómez S/N, Villa Puesta del Sol", ""),
    "Villa Balmaceda": ("Villa Balmaceda S/N", ""),
    "POBALCION MARTINEZ PASAJE PUENTE ÑUBLE, MARTA BRUNET": ("Pasaje Marta Brunet S/N, Población Ismael Martínez", ""),
    # Mixed-case keys (will be norm_key-normalized at init)
    "PUESTA DEL SOL, JOSE GOMEZ": ("Pasaje José Gómez S/N, Villa Puesta del Sol", ""),
    "VILLA BALMACEDA": ("Villa Balmaceda S/N", ""),
}
# Build a normalized version keyed by norm_key() for case/accent-insensitive lookup
_MANUAL_LOCALITY_NORM: dict[str, tuple[str, str]] = {}
# (populated in main() after norm_key is callable)


# ── Via type abbreviation table ──────────────────────────────────────────
VIA_ABBR: dict[str, str] = {
    "PSJE": "Pasaje",
    "PSJ": "Pasaje",
    "PJE": "Pasaje",
    "PASAJE": "Pasaje",
    "PASJE": "Pasaje",
    "AV": "Avenida",
    "AVDA": "Avenida",
    "AVENIDA": "Avenida",
    "CAM": "Camino",
    "CMO": "Camino",
    "CAMINO": "Camino",
    "CALLE": "Calle",
    "CALLEJON": "Callejón",
    "CALLEJÓN": "Callejón",
    "RUTA": "Ruta",
    "PTE": "Puente",
    "PUENTE": "Puente",
    # Población/Villa treated specially (not a via type per se)
    "PBL": "Población",
    "POBL": "Población",
    "POBLACION": "Población",
    "POBLACIÓN": "Población",
}

# Commune names to strip from end of address (in addition to row's own commune)
_COMMUNE_NAMES: list[str] = [
    "SAN CARLOS", "ÑIQUÉN", "NIQUEN", "SAN FABIAN", "SAN FABIÁN",
    "SAN NICOLAS", "SAN NICOLÁS", "BULNES", "CHILLAN", "CHILLÁN",
    "COIHUECO", "OTRO", "SAN CARLOS.",
]

# ── ELEAM / institutional addresses ─────────────────────────────────────
_ELEAM_KEYS: set[str] = {
    "ELEAM AMOR DE FAMILIA", "ELEAM NUEVA VIDA", "ELEAM NUEVO AMANECER",
    "ELEAM SAN AGUSTIN CAMINO A CAPE", "ELEAM SAN AGUSTIN CAPE",
    "HOGAR PADRE PIO", "HOGAR SAN CAMILO", "HOGAR BUEN PASTOR",
    "HOGAR NUEVA VIDA", "HOGAR JUAN BAUTISTA",
    "HOGAR DE FAMILIA",
}

# ══════════════════════════════════════════════════════════════════════════
#  Core normalizer
# ══════════════════════════════════════════════════════════════════════════

def normalize_address(raw: str, comuna: str) -> dict:
    """
    Normalize one address. Returns dict:
      changed, direccion_normalizada, localidad, referencia, method
    """
    original = raw.strip()
    _null = {
        "changed": False,
        "direccion_normalizada": original,
        "localidad": "",
        "referencia": "",
        "method": "no-change",
    }
    if not original:
        return _null

    # ── Phase 0: Manual lookup (exact full-address overrides) ─────────────
    manual_key = norm_key(original)
    if manual_key in _MANUAL_LOCALITY_NORM:
        disp, loc = _MANUAL_LOCALITY_NORM[manual_key]
        return _finalize(_null, original, disp, loc, "", "manual-lookup")

    # ── Phase 0b: Abbreviation expansion pre-processing ───────────────────
    pre = _preprocess(original)
    # Retry manual lookup after expansion
    if pre != original:
        pre_key = norm_key(pre)
        if pre_key in _MANUAL_LOCALITY_NORM:
            disp, loc = _MANUAL_LOCALITY_NORM[pre_key]
            return _finalize(_null, original, disp, loc, "", "manual-lookup")

    # Use pre-processed text for all further steps
    text = pre

    # ── Phase 1: Extract referencia (hints, parentheses, km) ──────────────
    text, referencia = _extract_referencia(text)

    # ── Phase 2: Strip trailing commune name ──────────────────────────────
    text = _strip_trailing_commune(text, comuna)

    # ── Phase 3: Normalize whitespace / punctuation ───────────────────────
    text = re.sub(r'[\t ]+', ' ', text).strip().rstrip(".,;").strip()
    # Collapse repeated spaces after comma
    text = re.sub(r',\s+', ', ', text)

    text_up = norm_key(text)

    if not text_up:
        return _null

    # ── Phase 4: Institutional / ELEAM addresses ─────────────────────────
    for ek in sorted(_ELEAM_KEYS, key=len, reverse=True):
        if text_up.startswith(norm_key(ek)):
            normalized = title_case_es(text.lower())
            return _finalize(_null, original, normalized, "", referencia, "institutional")

    # ── Phase 5: Road addresses (CAMINO / RUTA / paths with KM) ──────────
    if _is_road(text_up):
        normalized = _normalize_road(text)
        return _finalize(_null, original, normalized, "", referencia, "road")

    # ── Phase 6: Try explicit via-type prefix (PSJE, AV, CALLE…) ─────────
    # Split on first comma to allow "VILLA X, PSJE Y" patterns
    comma_parts = [p.strip() for p in text.split(",")]

    for part in comma_parts:
        part_up = norm_key(part)
        tokens = part.split()
        via, rest = _detect_via(tokens)
        if via and via != "Población":
            num, name_toks = _extract_number(rest)
            # Filter out commune name tokens from name
            name_toks = _filter_commune_tokens(name_toks, comuna)
            street_name = _build_name(name_toks)
            if not street_name:
                continue
            normalized = f"{via} {street_name} {num}"
            # Attach villa context if found in other parts
            villa = _find_villa_in_text(text_up)
            if villa:
                vname = get_villa_display(villa)
                if norm_key(vname) not in norm_key(normalized):
                    normalized = f"{normalized}, {vname}"
            return _finalize(_null, original, normalized, "", referencia, "explicit-via")

    # ── Phase 7: Known urban streets ──────────────────────────────────────
    # Try each comma-part and full text for a known street prefix
    for source_text in [text] + comma_parts:
        src_up = norm_key(source_text)
        match = _match_known_street(src_up)
        if match:
            street_key, street_disp, remainder_up = match
            # If the remainder starts with a via-type, this is a cross-street
            # e.g. "TOMAS YAVAR PASAJE BULNES" → remainder = "PASAJE BULNES"
            rem_tokens = remainder_up.split()
            sub_via, sub_rest = _detect_via(rem_tokens)
            if sub_via and sub_via != "Población" and sub_rest:
                # The named street is context; the pasaje/avenue is primary
                sub_num, sub_name_toks = _extract_number(sub_rest)
                sub_name = _build_name(sub_name_toks)
                if sub_name:
                    normalized = f"{sub_via} {sub_name} {sub_num}"
                    if street_disp:
                        normalized = f"{normalized}, {street_disp}"
                else:
                    normalized = f"Calle {street_disp} S/N, esquina {title_case_es(remainder_up.lower())}"
            else:
                num, complement = _parse_number_complement(remainder_up, source_text)
                normalized = f"Calle {street_disp} {num}"
                if complement:
                    normalized = f"{normalized}, {complement}"
            villa = _find_villa_in_text(text_up)
            if villa:
                vname = get_villa_display(villa)
                if norm_key(vname) not in norm_key(normalized):
                    normalized = f"{normalized}, {vname}"
            return _finalize(_null, original, normalized, "", referencia, "known-street")

    # ── Phase 8: Known INE rural locality ─────────────────────────────────
    # Search for the *longest* known locality that matches at the start of
    # (or equals) the text.  Exclude bare commune names (SAN CARLOS, ÑIQUÉN…)
    # to avoid false locality matches.
    loc_match = _match_ine_locality(text_up, text, comuna)
    if loc_match:
        normalized, canonical_loc = loc_match
        return _finalize(_null, original, normalized, canonical_loc, referencia, "rural-locality")

    # ── Phase 9: Known villa/población (urban) ────────────────────────────
    villa = _find_villa_in_text(text_up)
    if villa:
        normalized = title_case_es(text.lower())
        return _finalize(_null, original, normalized, "", referencia, "villa-only")

    # ── Phase 10a: Check manual lookup for remaining text (after preprocessing)
    text_up2 = norm_key(text)
    if text_up2 in _MANUAL_LOCALITY_NORM:
        disp, loc = _MANUAL_LOCALITY_NORM[text_up2]
        return _finalize(_null, original, disp, loc, referencia, "manual-lookup")

    # ── Phase 10b: General cleanup (title case + referencia strip) ─────────
    if text != original or referencia:
        # "SECTOR X" → preserve capitalization of Sector
        if text_up.startswith("SECTOR "):
            rest = text[7:].strip()
            normalized = "Sector " + title_case_es(rest.lower())
        else:
            normalized = title_case_phrase(text.lower())
        return _finalize(_null, original, normalized, "", referencia, "cleanup")

    return _null


# ══════════════════════════════════════════════════════════════════════════
#  Helper functions
# ══════════════════════════════════════════════════════════════════════════

def _extract_referencia(raw: str) -> tuple[str, str]:
    """Split navigational hints from main address text."""
    ref_parts: list[str] = []
    text = raw.strip()

    # 1. Parenthesised text → referencia
    for m in re.finditer(r'\([^)]*\)', text):
        content = m.group(0).strip("()").strip()
        if content:
            ref_parts.append(content)
    text = re.sub(r'\([^)]*\)', ' ', text).strip()

    # 2. Directional hints
    hints = [
        re.compile(r',?\s*(mano\s+(?:derecha|izquierda)\b.*)', re.I),
        re.compile(r',?\s*(frente\s+al?\s+[\w\s]+)', re.I),
        re.compile(r',?\s*(antes\s+de\b.*)', re.I),
        re.compile(r',?\s*(copa\s+de\s+agua\b.*)', re.I),
        re.compile(r',?\s*(hacia\s+el\s+\w+)', re.I),
        re.compile(r',?\s*(\d+\s+cuadras\s+\w+.*)', re.I),
    ]
    for pat in hints:
        m = pat.search(text)
        if m:
            ref_parts.append(m.group(1).strip())
            text = text[:m.start()].strip().rstrip(",;")

    ref = "; ".join(r for r in ref_parts if r)
    return text.strip(), ref


def _strip_trailing_commune(text: str, comuna: str) -> str:
    """Remove commune name (or abbreviation) from end of string.
    Only strips if the commune name is truly a trailing qualifier,
    i.e. appears after a comma or is the entire remaining text after a comma.
    We do NOT strip if the commune name is part of the address itself
    (e.g. "CAMINO SAN FABIAN" should not lose "SAN FABIAN").
    Strategy: only strip when preceded by comma (", SAN CARLOS")
    or when the text IS only the commune name.
    """
    all_names = sorted(
        [norm_key(comuna)] + [norm_key(c) for c in _COMMUNE_NAMES],
        key=len, reverse=True
    )
    text_up = norm_key(text)
    for name in all_names:
        # Only strip if: (a) followed only by whitespace, (b) preceded by comma+space
        # This prevents "CAMINO SAN FABIAN" → "CAMINO"
        pat = re.compile(r',\s+' + re.escape(name) + r'[\s.]*$', re.I)
        new = pat.sub('', text)
        if new != text:
            return new.strip().rstrip(",;. ").strip()
        # Also strip if the entire text IS the commune name (with optional punctuation)
        if text_up == name or text_up.rstrip(".") == name:
            return ""
    return text


def _is_road(text_up: str) -> bool:
    return bool(re.search(r'\b(CAMINO|RUTA\b)', text_up))


def _normalize_road(text: str) -> str:
    """Title-case road address, keeping KM uppercase."""
    # "KM" and numbers stay uppercase
    # Split and re-join with proper spacing
    parts = re.split(r'(\bKM\s*[\d,.]+\b)', text, flags=re.I)
    out = []
    for p in parts:
        p = p.strip()
        if not p:
            continue
        if re.match(r'KM\s*[\d,.]+', p, re.I):
            km_num = re.sub(r'[Kk][Mm]\s*', '', p).strip()
            out.append(f"KM {km_num}")
        else:
            out.append(title_case_es(p.lower()))
    # Join with ", " between parts (except when last part starts with "Sector")
    result = " ".join(out).strip()
    # Fix: "Camino X KM N Y" format - add comma before rest
    result = re.sub(r'(KM\s*[\d.,]+)\s+([A-Z])', r'\1, \2', result)
    # Fix "Sn" → "S/N" (SN normalized to S/N)
    result = re.sub(r'\bSn\b', 'S/N', result)
    result = re.sub(r'\bSN\b', 'S/N', result)
    result = re.sub(r'[\t ]+', ' ', result)
    return result


def _detect_via(tokens: list[str]) -> tuple[str, list[str]]:
    """Return (via_type, remaining_tokens) if first token is a via abbreviation."""
    if not tokens:
        return "", tokens
    first = tokens[0].rstrip(".").upper()
    first_na = strip_accents(first)
    if first_na in VIA_ABBR:
        return VIA_ABBR[first_na], tokens[1:]
    # "C." pattern
    if first_na == "C" and len(tokens) > 1:
        return "Calle", tokens[1:]
    return "", tokens


def _extract_number(tokens: list[str]) -> tuple[str, list[str]]:
    """Find and extract address number from token list."""
    for i, tok in enumerate(tokens):
        clean = tok.rstrip(".,/;")
        if re.match(r'^\d[\d/\\]*$', clean):
            num = re.sub(r'[/\\]+$', '', clean)
            return num, tokens[:i] + tokens[i+1:]
    return "S/N", tokens


def _filter_commune_tokens(tokens: list[str], comuna: str) -> list[str]:
    """Remove tokens that are just the commune name."""
    commune_words = set(norm_key(comuna).split())
    result = []
    for tok in tokens:
        if norm_key(tok) not in commune_words:
            result.append(tok)
    return result


def _build_name(tokens: list[str]) -> str:
    """Build a display street/place name from tokens."""
    raw = " ".join(tokens).strip().rstrip(",;.")
    if not raw:
        return ""
    key = norm_key(raw)
    # Typo corrections
    _TYPOS = {
        "OHIGGINS": "O'Higgins",
        "O'HIGGINS": "O'Higgins",
        "TAMAS YAVAR": "Tomás Yavar",
        "TOMAS YAVAR": "Tomás Yavar",
        "VICUÑA MACKENA": "Vicuña Mackenna",
        "VICUNA MACKENNA": "Vicuña Mackenna",
        "SAGENTO ALDEA": "Sargento Aldea",
        "VIRGUIN": "Virhuín",
    }
    if key in _TYPOS:
        return _TYPOS[key]
    return title_case_es(raw.lower())


def _match_known_street(text_up: str) -> tuple[str, str, str] | None:
    """
    Try to match beginning of text_up against known streets.
    Returns (street_key, street_display, remainder_upper) or None.
    Longest match wins.
    """
    for sk in sorted(URBAN_STREETS_SET, key=len, reverse=True):
        if text_up == sk or text_up.startswith(sk + " ") or text_up.startswith(sk + ","):
            remainder = text_up[len(sk):].strip().lstrip(",").strip()
            return sk, get_street_display(sk), remainder
    return None


def _parse_number_complement(remainder_up: str, original_part: str) -> tuple[str, str]:
    """
    From the remainder after a street name, extract number and complement.
    Returns (num, complement).
    """
    if not remainder_up:
        return "S/N", ""

    # S/N variants
    if re.match(r'^(S/N|SN|S N)\b', remainder_up):
        rest = remainder_up[3:].strip()
        if rest:
            return "S/N", title_case_es(rest.lower())
        return "S/N", ""

    # Number at start
    m = re.match(r'^(\d[\d/]*)\s*(.*)', remainder_up)
    if m:
        num = m.group(1).rstrip("/")
        complement_up = m.group(2).strip()
        if complement_up:
            # Filter out commune names from complement
            for cn in sorted(_COMMUNE_NAMES + _VILLAS_RAW, key=lambda x: -len(x)):
                if norm_key(complement_up) == norm_key(cn):
                    complement_up = ""
                    break
            if complement_up:
                return num, title_case_es(complement_up.lower())
        return num, ""

    # No number found
    complement = title_case_es(remainder_up.lower())
    return "S/N", complement if complement else ""


def _find_villa_in_text(text_up: str) -> str:
    """Return the longest matching villa key found anywhere in text_up."""
    for vk in sorted(VILLAS_SET, key=len, reverse=True):
        if vk in text_up:
            return vk
    return ""


def _match_ine_locality(text_up: str, text_orig: str, comuna: str) -> tuple[str, str] | None:
    """
    Try to find a known INE locality in text_up.
    Strategy:
    1. Try full text (maybe "AGUA BUENA" or "TIUQUILEMU")
    2. Try comma-separated parts
    3. Try longest-prefix match of words
    Returns (normalized_address, canonical_localidad) or None.

    IMPORTANT: Do NOT match bare commune names (SAN CARLOS, NIQUEN, etc.)
    as localities — they are separate administrative levels.
    """
    # Names that are commune-level, not localidad-level
    _COMMUNES_UPPER = {
        "SAN CARLOS", "NIQUEN", "ÑIQUEN", "SAN FABIAN", "SAN FABIÁN",
        "SAN NICOLAS", "SAN NICOLÁS", "BULNES", "CHILLAN", "CHILLÁN",
        "COIHUECO", "OTRO",
    }

    words = text_up.split()

    # Build candidates to try, longest first
    candidates = []

    # Full text
    candidates.append((text_up, text_orig))

    # Comma parts
    for part in text_up.split(","):
        p = part.strip()
        if p:
            candidates.append((p, p))

    # Progressive word-count prefixes (longest first)
    for n in range(len(words), 0, -1):
        prefix = " ".join(words[:n])
        if prefix not in [c[0] for c in candidates]:
            candidates.append((prefix, prefix))

    for (candidate_up, candidate_orig) in candidates:
        candidate_up = candidate_up.strip()
        if not candidate_up:
            continue
        if candidate_up in _COMMUNES_UPPER:
            continue  # skip bare commune names
        if candidate_up not in INE_LOCALIDADES:
            continue

        canonical = INE_LOCALIDADES[candidate_up]  # already title-cased

        # Determine what remains after the matched locality token
        remainder_up = text_up[len(candidate_up):].strip().lstrip(",").strip()

        # Remove commune trailing from remainder
        for cn in sorted(_COMMUNE_NAMES, key=len, reverse=True):
            if remainder_up == norm_key(cn) or remainder_up.endswith(", " + norm_key(cn)):
                remainder_up = remainder_up[: -(len(norm_key(cn)))].strip().rstrip(",").strip()
                break

        # S/N variants
        has_sn = bool(re.match(r'^(S/N|SN|S N)\b', remainder_up)) or not remainder_up
        has_num = bool(re.match(r'^\d', remainder_up))

        if not remainder_up or has_sn:
            normalized = f"Sector {canonical} S/N"
        elif has_num:
            # KM reference or numeric
            km_match = re.match(r'(KM\s*[\d,.]+)\s*(.*)', remainder_up, re.I)
            if km_match:
                normalized = f"Sector {canonical} {km_match.group(1).upper()}"
                extra = km_match.group(2).strip()
                if extra:
                    normalized += f", {title_case_es(extra.lower())}"
            else:
                num = remainder_up.split()[0]
                extra = remainder_up[len(num):].strip()
                normalized = f"Sector {canonical} {num}"
                if extra:
                    normalized += f", {title_case_es(extra.lower())}"
        else:
            # Sub-sector or qualifier
            extra = title_case_es(remainder_up.lower())
            # Remove S/N duplicate
            extra = re.sub(r'\bs/n\b', '', extra, flags=re.I).strip()
            if extra:
                normalized = f"Sector {canonical}, {extra}"
            else:
                normalized = f"Sector {canonical} S/N"

        return normalized, canonical

    return None


def _finalize(base: dict, original: str, normalized: str,
              localidad: str, referencia: str, method: str) -> dict:
    """Clean up and determine if the result is actually different."""
    normalized = re.sub(r'[\t ]+', ' ', normalized).strip().rstrip(".,;").strip()
    # Fix double commas: ", ," → ","
    normalized = re.sub(r',\s*,', ',', normalized)
    # Fix ", S/N" when number already present
    normalized = re.sub(r'(\d+)\s*,\s*S/N\b', r'\1', normalized)
    # "S/N" spacing
    normalized = re.sub(r'\s*S/N\b', ' S/N', normalized)
    normalized = normalized.strip()

    changed = (
        normalized != original
        or bool(localidad)
        or bool(referencia)
    )
    return {
        "changed": changed,
        "direccion_normalizada": normalized if changed else original,
        "localidad": localidad,
        "referencia": referencia,
        "method": method,
    }


# ══════════════════════════════════════════════════════════════════════════
#  Main entry point
# ══════════════════════════════════════════════════════════════════════════

def main():
    global INE_LOCALIDADES, _MANUAL_LOCALITY_NORM
    INE_LOCALIDADES = load_ine_localidades(REF_LOCALIDADES)
    print(f"Loaded {len(INE_LOCALIDADES)} INE localidades.")
    # Build normalized manual lookup dict (accent/case-insensitive keys)
    _MANUAL_LOCALITY_NORM = {norm_key(k): v for k, v in _MANUAL_LOCALITY.items()}

    rows = []
    with open(INPUT_CSV, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    print(f"Loaded {len(rows)} addresses to process.")

    # Process
    results = []
    for row in rows:
        loc_id = row["localizacion_id"].strip()
        raw = row["direccion_texto"].strip()
        comuna = row["comuna"].strip()
        r = normalize_address(raw, comuna)
        r["localizacion_id"] = loc_id
        r["original"] = raw
        r["comuna"] = comuna
        results.append(r)

    changed = [r for r in results if r["changed"]]
    method_counts: dict[str, int] = {}
    for r in changed:
        method_counts[r["method"]] = method_counts.get(r["method"], 0) + 1

    # ── Generate SQL ───────────────────────────────────────────────────────
    ts = datetime.now().strftime("%Y-%m-%d %H:%M")
    sql: list[str] = []
    sql.append("-- CORR-09: Normalización de direcciones de pacientes HODOM")
    sql.append(f"-- Generado: {ts}")
    sql.append(f"-- Total: {len(rows)}  |  Modificadas: {len(changed)}"
               f"  |  Sin cambio: {len(rows) - len(changed)}")
    sql.append("")
    sql.append("BEGIN;")
    sql.append("")
    sql.append("-- ── Actualizaciones territorial.localizacion ────────────────────────")
    sql.append("")

    for r in results:
        if not r["changed"]:
            continue
        loc_id = r["localizacion_id"]
        set_parts = [f"direccion_texto = '{esc_sql(r['direccion_normalizada'])}'"]
        if r["localidad"]:
            set_parts.append(f"localidad = '{esc_sql(r['localidad'])}'")
        if r["referencia"]:
            set_parts.append(f"referencia = '{esc_sql(r['referencia'])}'")
        sql.append(f"-- ORIG: {esc_sql(r['original'])}")
        sql.append(
            f"UPDATE territorial.localizacion SET {', '.join(set_parts)} "
            f"WHERE localizacion_id = '{loc_id}';"
        )
        sql.append("")

    sql.append("-- ── Proveniencia ────────────────────────────────────────────────────")
    sql.append("")
    for r in results:
        if not r["changed"]:
            continue
        loc_id = r["localizacion_id"]
        fields = ["direccion_texto"]
        if r["localidad"]:
            fields.append("localidad")
        if r["referencia"]:
            fields.append("referencia")
        for field in fields:
            sql.append(
                f"INSERT INTO migration.provenance "
                f"(target_table, target_pk, source_type, source_file, "
                f"source_key, phase, field_name, created_at) VALUES "
                f"('territorial.localizacion', '{loc_id}', 'correction', "
                f"'corr_09_normalizar_direcciones', '{loc_id}', "
                f"'CORR-09', '{field}', NOW());"
            )
        sql.append("")

    sql.append("COMMIT;")

    with open(SQL_OUTPUT, "w", encoding="utf-8") as f:
        f.write("\n".join(sql))

    # ── Report ─────────────────────────────────────────────────────────────
    print()
    print("=== CORR-09: Normalización de direcciones ===")
    print(f"Total:        {len(rows)}")
    print(f"Modificadas:  {len(changed)}")
    print(f"Sin cambio:   {len(rows) - len(changed)}")
    print()
    print("Métodos aplicados:")
    for m, c in sorted(method_counts.items(), key=lambda x: -x[1]):
        print(f"  {m:30s}: {c}")
    print()
    print(f"SQL escrito en: {SQL_OUTPUT}")
    print()

    # Sample of changes
    print("── Muestra de cambios (primeros 50) ────────────────────────────────")
    shown = 0
    for r in results:
        if not r["changed"]:
            continue
        print(f"  [{r['method']:20s}] {r['original']!r:60s}")
        print(f"  {'':22s}=> {r['direccion_normalizada']!r}")
        if r["localidad"]:
            print(f"  {'':22s}   localidad={r['localidad']!r}")
        if r["referencia"]:
            print(f"  {'':22s}   ref={r['referencia']!r}")
        shown += 1
        if shown >= 50:
            break

    unchanged = [r for r in results if not r["changed"]]
    print()
    print(f"── Sin cambio ({len(unchanged)}) ───────────────────────────────────")
    for r in unchanged:
        print(f"  [{r['comuna']:12s}] {r['original']!r}")


if __name__ == "__main__":
    main()
