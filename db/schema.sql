PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS paciente (
    rut                 TEXT PRIMARY KEY,
    nombre              TEXT NOT NULL,
    fecha_nacimiento    DATE
);

CREATE TABLE IF NOT EXISTS hospitalizacion (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    rut_paciente        TEXT NOT NULL,
    fecha_ingreso       DATE NOT NULL,
    fecha_egreso        DATE,
    FOREIGN KEY (rut_paciente) REFERENCES paciente (rut)
);

CREATE INDEX IF NOT EXISTS idx_hospitalizacion_rut
    ON hospitalizacion (rut_paciente);
