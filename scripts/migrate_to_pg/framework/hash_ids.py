"""
Deterministic ID generation — reproduces the pipeline's hash algorithms.

Two hash families coexist in the pipeline:
  stable_id(): SHA-1 truncated to 16 hex (intermediate stage)
  make_id():   SHA-256 truncated to 12 hex (canonical stage)

patient_id uses stable_id (from build_hodom_intermediate.py:208-210).
stay_id uses make_id (from build_hodom_canonical.py:90-93).
"""

import hashlib


def stable_id(prefix: str, *parts: str) -> str:
    """SHA-1, 16 hex chars. Pipeline: build_hodom_intermediate.py:208-210."""
    digest = hashlib.sha1(
        "|".join(str(p) for p in parts).encode("utf-8")
    ).hexdigest()[:16]
    return f"{prefix}_{digest}"


def make_id(prefix: str, value: str) -> str:
    """SHA-256, 12 hex chars. Pipeline: build_hodom_canonical.py:90-93."""
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:12]
    return f"{prefix}_{digest}"


def patient_id_from_rut(rut: str) -> str:
    """Generate patient_id from RUT. Strategy: 'rut'.
    Matches pipeline: stable_id("pt", f"rut:{rut}")
    """
    return stable_id("pt", f"rut:{rut}")
