---
name: No propagar patient_id redundante
description: Tablas nuevas con stay_id NOT NULL no deben incluir patient_id — es redundante por path equation conmutativa
type: feedback
---

Tablas nuevas con `stay_id NOT NULL` no deben incluir `patient_id` como FK directa. El paciente se obtiene vía `estadia.patient_id` (path equation conmutativa). 33 tablas existentes tienen esta redundancia pero no se refactorizan por blast radius.

**Why:** Auditoría categorial 2026-04-07 confirmó 0 violaciones. El trigger `check_stay_coherence` existe solo para mantener la redundancia. Eliminar el campo elimina la necesidad del trigger.

**How to apply:** Al crear DDL para nuevas tablas clínicas, usar solo `stay_id` y derivar paciente con JOIN. Ver `docs/audit-patient-id-redundancia.md`.
