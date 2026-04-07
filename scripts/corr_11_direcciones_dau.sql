-- CORR-11: Direcciones recuperadas del DAU hospitalario (CLI h)
-- Fuente: texto_resumen del DAU (SGH Hospital San Carlos)
-- Recuperadas: 28 de 33 pacientes sin dirección

BEGIN;

-- DAU: 10435000-3 — orig: La Ribera De Ñuble
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Ribera De Ñuble S/N', localidad = 'La Ribera', updated_at = NOW() WHERE localizacion_id = 'loc_002b4f7a79c3';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_002b4f7a79c3', 'dau', 'SGH_DAU', '10435000-3', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 11567612-1 — orig: villa la virgen san juan 1547 FUNCIONARIO
UPDATE territorial.localizacion SET direccion_texto = 'Villa La Virgen San Juan 1547', updated_at = NOW() WHERE localizacion_id = 'loc_e7cb957633ab';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e7cb957633ab', 'dau', 'SGH_DAU', '11567612-1', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 22967820-5 — orig: CATALUÑA 048 V ESPAÑA
UPDATE territorial.localizacion SET direccion_texto = 'Cataluña 048 V España', updated_at = NOW() WHERE localizacion_id = 'loc_7132359d6018';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7132359d6018', 'dau', 'SGH_DAU', '22967820-5', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 23135794-7 — orig: VISTA BELLA PUENTE ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Vista Bella Puente Ñuble', updated_at = NOW() WHERE localizacion_id = 'loc_d9f2a6f81d61';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d9f2a6f81d61', 'dau', 'SGH_DAU', '23135794-7', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 3362648-7 — orig: Los Naranjos Camino A Ribera
UPDATE territorial.localizacion SET direccion_texto = 'Los Naranjos Camino A Ribera', localidad = 'La Ribera', updated_at = NOW() WHERE localizacion_id = 'loc_ae27359819e6';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ae27359819e6', 'dau', 'SGH_DAU', '3362648-7', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 3702621-2 — orig: TORRECILLAS ACT
UPDATE territorial.localizacion SET direccion_texto = 'Sector Torrecillas S/N', localidad = 'Torrecillas', updated_at = NOW() WHERE localizacion_id = 'loc_d2c15000c2b2';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d2c15000c2b2', 'dau', 'SGH_DAU', '3702621-2', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 3908885-1 — orig: OSSA 35
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ossa 35', updated_at = NOW() WHERE localizacion_id = 'loc_26df407296da';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_26df407296da', 'dau', 'SGH_DAU', '3908885-1', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 4038136-8 — orig: SAN ROQUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Roque S/N', localidad = 'San Roque', updated_at = NOW() WHERE localizacion_id = 'loc_48eee6ffe108';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_48eee6ffe108', 'dau', 'SGH_DAU', '4038136-8', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 5104628-5 — orig: CACHAPOAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cachapoal S/N', localidad = 'Cachapoal', updated_at = NOW() WHERE localizacion_id = 'loc_71c2d59e127e';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_71c2d59e127e', 'dau', 'SGH_DAU', '5104628-5', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 5556271-7 — orig: BULI CASERIO ACT//
UPDATE territorial.localizacion SET direccion_texto = 'Sector Buli Caserio S/N', localidad = 'Buli', updated_at = NOW() WHERE localizacion_id = 'loc_c39fa368dcbe';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c39fa368dcbe', 'dau', 'SGH_DAU', '5556271-7', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 5564758-5 — orig: CHACABUCO 414
UPDATE territorial.localizacion SET direccion_texto = 'Calle Chacabuco 414', updated_at = NOW() WHERE localizacion_id = 'loc_832c3b7fcecf';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_832c3b7fcecf', 'dau', 'SGH_DAU', '5564758-5', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 5753173-8 — orig: FLOR DE QUIHUA CACHAPOAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector Flor De Quihua Cachapoal S/N', localidad = 'Cachapoal', updated_at = NOW() WHERE localizacion_id = 'loc_b0c31bb2e99f';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b0c31bb2e99f', 'dau', 'SGH_DAU', '5753173-8', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 6160571-1 — orig: 11 SEPT PATAGUAS 1018 ACT
UPDATE territorial.localizacion SET direccion_texto = '11 Sept Pataguas 1018', updated_at = NOW() WHERE localizacion_id = 'loc_82f9f8569e5e';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_82f9f8569e5e', 'dau', 'SGH_DAU', '6160571-1', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 6203209-K — orig: GENERAL PARRA 383 ACT
UPDATE territorial.localizacion SET direccion_texto = 'Calle General Parra 383', updated_at = NOW() WHERE localizacion_id = 'loc_25d97d68d3c1';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_25d97d68d3c1', 'dau', 'SGH_DAU', '6203209-K', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 6230047-7 — orig: MERCURIO S/N PUENTE nIBLE **
UPDATE territorial.localizacion SET direccion_texto = 'Calle Mercurio S/N Puente Ñuble', updated_at = NOW() WHERE localizacion_id = 'loc_0adc0c3fbbf0';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0adc0c3fbbf0', 'dau', 'SGH_DAU', '6230047-7', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 6335989-0 — orig: EL ESPINAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Espinal S/N', localidad = 'El Espinal', updated_at = NOW() WHERE localizacion_id = 'loc_351a54398a73';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_351a54398a73', 'dau', 'SGH_DAU', '6335989-0', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 6524855-7 — orig: NINQUIHUE 001
UPDATE territorial.localizacion SET direccion_texto = 'Ninquihue 001', localidad = 'Ninquihue', updated_at = NOW() WHERE localizacion_id = 'loc_a23d8bc30271';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a23d8bc30271', 'dau', 'SGH_DAU', '6524855-7', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 6546644-9 — orig: TIUQUILEMU
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tiuquilemu S/N', localidad = 'Tiuquilemu', updated_at = NOW() WHERE localizacion_id = 'loc_f9e1957242ef';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f9e1957242ef', 'dau', 'SGH_DAU', '6546644-9', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 6634137-2 — orig: LAS ARBOLEDAS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Arboledas S/N', localidad = 'Las Arboledas', updated_at = NOW() WHERE localizacion_id = 'loc_eef87bb36a0b';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eef87bb36a0b', 'dau', 'SGH_DAU', '6634137-2', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 6967360-0 — orig: CHACABUCO 912
UPDATE territorial.localizacion SET direccion_texto = 'Calle Chacabuco 912', updated_at = NOW() WHERE localizacion_id = 'loc_f344f3307b67';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f344f3307b67', 'dau', 'SGH_DAU', '6967360-0', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 7234181-3 — orig: PARQUE NORTE NIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Parque Norte Niquen', updated_at = NOW() WHERE localizacion_id = 'loc_b6d48d47d666';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b6d48d47d666', 'dau', 'SGH_DAU', '7234181-3', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 7651320-1 — orig: CATALINA VELA 0556 PORTAL DEL SUR
UPDATE territorial.localizacion SET direccion_texto = 'Calle Catalina Vela 0556 Portal Del Sur', updated_at = NOW() WHERE localizacion_id = 'loc_ff4f0fa0ae27';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ff4f0fa0ae27', 'dau', 'SGH_DAU', '7651320-1', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 8620152-6 — orig: MONTELEON
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monteleon S/N', localidad = 'Monteleon', updated_at = NOW() WHERE localizacion_id = 'loc_2908cfff9472';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2908cfff9472', 'dau', 'SGH_DAU', '8620152-6', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 9201236-0 — orig: LOS MAGNOLIOS 904 VILLA NAVIDAD
UPDATE territorial.localizacion SET direccion_texto = 'Los Magnolios 904 Villa Navidad', updated_at = NOW() WHERE localizacion_id = 'loc_af6a0023022d';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_af6a0023022d', 'dau', 'SGH_DAU', '9201236-0', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 9242550-9 — orig: PJE EL LANALHUE 067 VILLA PADRE HURTADO //
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje El Lanalhue 067 Villa Padre Hurtado', updated_at = NOW() WHERE localizacion_id = 'loc_72926f089e42';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_72926f089e42', 'dau', 'SGH_DAU', '9242550-9', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 9273208-8 — orig: CASAS DE POMUYETO MONTE BLANCO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Casas De Pomuyeto Monte Blanco S/N', localidad = 'Pomuyeto', updated_at = NOW() WHERE localizacion_id = 'loc_82eb640d5bed';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_82eb640d5bed', 'dau', 'SGH_DAU', '9273208-8', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 9533630-2 — orig: MONTELEON LOS AROMOS VILLA LOS ALAMOS
UPDATE territorial.localizacion SET direccion_texto = 'Monteleon Los Aromos Villa Los Alamos', localidad = 'Monteleon', updated_at = NOW() WHERE localizacion_id = 'loc_b186159ed6cc';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b186159ed6cc', 'dau', 'SGH_DAU', '9533630-2', 'CORR-11', 'direccion_texto', NOW());

-- DAU: 9627637-0 — orig: TRILICO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Trilico S/N', localidad = 'Trilico', updated_at = NOW() WHERE localizacion_id = 'loc_27acb0737e56';

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_27acb0737e56', 'dau', 'SGH_DAU', '9627637-0', 'CORR-11', 'direccion_texto', NOW());

COMMIT;