-- CORR-10: Enriquecimiento de direcciones desde redundancia intermedia
-- Generado: 2026-04-07 17:24
-- Total mejoras: 265
--   added_number: 95
--   more_detail: 12
--   new_address: 158

BEGIN;

-- ── Actualizaciones territorial.localizacion ────────────────────────

-- ORIG: (vacío) -> HOGAR EL ALBA (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'HOGAR EL ALBA', updated_at = NOW() WHERE localizacion_id = 'loc_209b38c1f49e';

-- ORIG: (vacío) -> Calle Carrera 185 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera 185', updated_at = NOW() WHERE localizacion_id = 'loc_b3aca72037bb';

-- ORIG: (vacío) -> ESTANISLADO GODOY 606 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'ESTANISLADO GODOY 606', updated_at = NOW() WHERE localizacion_id = 'loc_7d912f298260';

-- ORIG: (vacío) -> 11 DE SEPT TOMAS YAYAR 648 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = '11 De Sept Tomas Yayar 648', updated_at = NOW() WHERE localizacion_id = 'loc_11c27e55ad47';

-- ORIG: (vacío) -> Calle Gazmuri 1045 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Gazmuri 1045', updated_at = NOW() WHERE localizacion_id = 'loc_d83f45ea4c29';

-- ORIG: Villa Visión Mundial Pasaje Amigo sin Frontera -> VILLA MISION MUNDIAL PSJE AMIGO SIN FRONTERA 0698 698 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Mision Mundial Pasaje Amigo Sin Frontera 0698', updated_at = NOW() WHERE localizacion_id = 'loc_9c05b69084b5';

-- ORIG: (vacío) -> Sector Las Miras S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Miras S/N', localidad = 'Las Miras', updated_at = NOW() WHERE localizacion_id = 'loc_6839bfc2dd97';

-- ORIG: Calle Tomás Yavar S/N -> Calle Tomás Yavar 630 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Tomás Yavar 630', updated_at = NOW() WHERE localizacion_id = 'loc_a7b3093f3d67';

-- ORIG: Pasaje Hugo Monroy S/N -> Pasaje Monroy 338 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Monroy 338', updated_at = NOW() WHERE localizacion_id = 'loc_e22e03ccfd18';

-- ORIG: (vacío) -> VILLA PARAISO CALLE LOS ANGELES 1233 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Paraiso Calle Los Angeles 1233', updated_at = NOW() WHERE localizacion_id = 'loc_cc0fbdea2f59';

-- ORIG: (vacío) -> Sector Ninquihue 00 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Ninquihue 00', localidad = 'Ninquihue', updated_at = NOW() WHERE localizacion_id = 'loc_844a448efdaf';

-- ORIG: (vacío) -> LLAHUIMNAVIDA ORIENTE S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'LLAHUIMNAVIDA ORIENTE S/N', updated_at = NOW() WHERE localizacion_id = 'loc_9cc97c4b8263';

-- ORIG: (vacío) -> Hogar el Alba, KM 6.5, Camino a San Fabian S/n (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Hogar el Alba, KM 6.5, Camino a San Fabian S/n', updated_at = NOW() WHERE localizacion_id = 'loc_b8b7cc6659fc';

-- ORIG: (vacío) -> Calle Carrera 651 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera 651', updated_at = NOW() WHERE localizacion_id = 'loc_5a4cf03896d1';

-- ORIG: Calle Ñuble S/N -> Calle Ñuble 201 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble 201', updated_at = NOW() WHERE localizacion_id = 'loc_68f1681c4891';

-- ORIG: Calle Lurin S/N -> Calle Lurin 459 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Lurin 459', updated_at = NOW() WHERE localizacion_id = 'loc_9edae02716b0';

-- ORIG: Calle Puelma S/N -> Calle Puelma 657 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma 657', updated_at = NOW() WHERE localizacion_id = 'loc_ef412e6f165a';

-- ORIG: (vacío) -> Calle Pedro Lagos 64 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos 64', updated_at = NOW() WHERE localizacion_id = 'loc_323c949b6f0f';

-- ORIG: Calle Arturo Prat S/N -> Calle Arturo Prat 130 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Arturo Prat 130', updated_at = NOW() WHERE localizacion_id = 'loc_e0efd220dd93';

-- ORIG: (vacío) -> LAS ALITAS EL CARBON (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Las Alitas El Carbon', updated_at = NOW() WHERE localizacion_id = 'loc_cce1c3c51269';

-- ORIG: Calle Padre Eloy S/N -> Calle Padre Eloy 147 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Padre Eloy 147', updated_at = NOW() WHERE localizacion_id = 'loc_fb808ea49b72';

-- ORIG: (vacío) -> Calle Ossa 365 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ossa 365', updated_at = NOW() WHERE localizacion_id = 'loc_e7c4eb91a105';

-- ORIG: (vacío) -> Pasaje Estrella Casa 1, Villa Portal de la Luna (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Estrella Casa 1, Villa Portal de la Luna', updated_at = NOW() WHERE localizacion_id = 'loc_7a2eda599082';

-- ORIG: (vacío) -> LAS TORTOLAS 961 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'LAS TORTOLAS 961', updated_at = NOW() WHERE localizacion_id = 'loc_0a98c5c48ea7';

-- ORIG: Portal del Sur, Mina Fritz -> Portal del Sur , Mina Fritz 464 464 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Portal del Sur, Mina Fritz 464', updated_at = NOW() WHERE localizacion_id = 'loc_452a41d729c7';

-- ORIG: (vacío) -> Zemita Camino el Nevao (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Zemita Camino el Nevao', updated_at = NOW() WHERE localizacion_id = 'loc_e223946c1aae';

-- ORIG: (vacío) -> Portal del Sur , Valentin Trujillo 479 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Portal del Sur, Valentin Trujillo 479', updated_at = NOW() WHERE localizacion_id = 'loc_b368875353c5';

-- ORIG: (vacío) -> Sector Millauquén S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Millauquén S/N', localidad = 'Millauquén', updated_at = NOW() WHERE localizacion_id = 'loc_c97f6a23720a';

-- ORIG: Sector San Manuel de Verquico S/N -> QUINQUEHUA CALLEJON LAS PALMERAS KM 13 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Quinquehua Callejon Las Palmeras KM 13', localidad = 'Verquico', updated_at = NOW() WHERE localizacion_id = 'loc_7c74ded6113c';

-- ORIG: (vacío) -> Los Bedules 105 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Los Bedules 105', updated_at = NOW() WHERE localizacion_id = 'loc_efa25fa022d9';

-- ORIG: (vacío) -> Calle Vicuña Mackenna 751 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 751', updated_at = NOW() WHERE localizacion_id = 'loc_5e5427553fc9';

-- ORIG: (vacío) -> Puente Ñuble Villa Illinois Calle Ñuble 15 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Puente Ñuble Villa Illinois Calle Ñuble 15', updated_at = NOW() WHERE localizacion_id = 'loc_d7c620fe0654';

-- ORIG: (vacío) -> Sector Las Rosas, De Cachapoal (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Rosas, De Cachapoal', localidad = 'Las Rosas', updated_at = NOW() WHERE localizacion_id = 'loc_55daef1bfddf';

-- ORIG: (vacío) -> Sector Carán S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Carán S/N', localidad = 'Carán', updated_at = NOW() WHERE localizacion_id = 'loc_44a0750a6358';

-- ORIG: (vacío) -> Calle Roble250 S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble250 S/N', updated_at = NOW() WHERE localizacion_id = 'loc_1ffe6515fd08';

-- ORIG: Calle Roble S/N -> Calle Roble S/N, San Carlos 132 132 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble S/N, San Carlos 132', updated_at = NOW() WHERE localizacion_id = 'loc_25115418cbef';

-- ORIG: Avenida Pte Ñuble S/N -> VILLAS LAS CAMELIAS , SAN NICOLAS 1050 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Villas Las Camelias, San Nicolas 1050', updated_at = NOW() WHERE localizacion_id = 'loc_01706ab816f4';

-- ORIG: Calle Bilbao S/N, Villa Puesta del Sol -> Calle Bilbao S/N, Villa Puesta el Sol 325 325 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao S/N, Villa Puesta el Sol 325', updated_at = NOW() WHERE localizacion_id = 'loc_c321e82a429f';

-- ORIG: Pasaje Buin S/N -> Pasaje Buin 134 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Buin 134', updated_at = NOW() WHERE localizacion_id = 'loc_dc9d74522686';

-- ORIG: (vacío) -> ANDALUCIA 212 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'ANDALUCIA 212', updated_at = NOW() WHERE localizacion_id = 'loc_a70ba2b2010b';

-- ORIG: (vacío) -> Sector Muticura S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Muticura S/N', localidad = 'Muticura', updated_at = NOW() WHERE localizacion_id = 'loc_7a6cf174ed4e';

-- ORIG: (vacío) -> Calle Pedro Lagos 274 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos 274', updated_at = NOW() WHERE localizacion_id = 'loc_22eab95df4dc';

-- ORIG: (vacío) -> 19 DE MAYO CASA 75 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = '19 DE MAYO CASA 75', updated_at = NOW() WHERE localizacion_id = 'loc_c5461f4efdf8';

-- ORIG: (vacío) -> Pasaje Las Garzas 1196 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Las Garzas 1196', updated_at = NOW() WHERE localizacion_id = 'loc_bc1f174eb363';

-- ORIG: Pasaje Bulnes S/N, Tomás Yavar -> Pasaje Bulnes 39, Tomás Yavar (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Bulnes 39, Tomás Yavar', updated_at = NOW() WHERE localizacion_id = 'loc_f1441479f75b';

-- ORIG: (vacío) -> OHHIGINS 321 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'OHHIGINS 321', updated_at = NOW() WHERE localizacion_id = 'loc_c394f4107802';

-- ORIG: Calle Baldomero Silva S/N -> Calle General Venegas 376 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle General Venegas 376', updated_at = NOW() WHERE localizacion_id = 'loc_af7e6a243a57';

-- ORIG: (vacío) -> Montecillo Camino a Sanfabian (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Montecillo Camino a Sanfabian', updated_at = NOW() WHERE localizacion_id = 'loc_abae8df7d209';

-- ORIG: (vacío) -> Sector San Fernando, Zemita (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Fernando, Zemita', localidad = 'San Fernando', updated_at = NOW() WHERE localizacion_id = 'loc_659eacb0079a';

-- ORIG: Calle Puelma S/N -> Calle Puelma 150 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma 150', updated_at = NOW() WHERE localizacion_id = 'loc_b2c9aa1fdfa5';

-- ORIG: (vacío) -> Calle Brasil 394 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil 394', updated_at = NOW() WHERE localizacion_id = 'loc_09c1f6f88446';

-- ORIG: (vacío) -> Sector El Sauce 11, De Septiembre 828 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Sauce 11, De Septiembre 828', localidad = 'El Sauce', updated_at = NOW() WHERE localizacion_id = 'loc_0674146cf6e3';

-- ORIG: (vacío) -> 11 de Septiembre, la Chinchilla 1187 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = '11 de Septiembre, la Chinchilla 1187', updated_at = NOW() WHERE localizacion_id = 'loc_af3dff331990';

-- ORIG: (vacío) -> Sector Cachapoal, Km 21 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cachapoal, Km 21', localidad = 'Cachapoal', updated_at = NOW() WHERE localizacion_id = 'loc_fee309029c19';

-- ORIG: (vacío) -> Sector Agua Buena, Montecillos (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena, Montecillos', localidad = 'Agua Buena', updated_at = NOW() WHERE localizacion_id = 'loc_97a4fd49a0e8';

-- ORIG: (vacío) -> HOGAR SAN PABLO (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Hogar San Pablo', updated_at = NOW() WHERE localizacion_id = 'loc_3df8f63b555a';

-- ORIG: (vacío) -> ERNESTO ZUÑIGA 298 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'ERNESTO ZUÑIGA 298', updated_at = NOW() WHERE localizacion_id = 'loc_6c76127ecb86';

-- ORIG: Sector Las Arboledas S/N -> Sector Las Arboledas, Pasaje 13 Ls Jaquez (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Arboledas, Pasaje 13 Ls Jaquez', localidad = 'Las Arboledas', updated_at = NOW() WHERE localizacion_id = 'loc_5f8e253e630d';

-- ORIG: Calle Freire S/N -> Calle Freire 1076 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire 1076', updated_at = NOW() WHERE localizacion_id = 'loc_4c5149ceeda6';

-- ORIG: Calle Chacabuco S/N -> Calle Chacabuco 153 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Chacabuco 153', updated_at = NOW() WHERE localizacion_id = 'loc_bd2581e4ec04';

-- ORIG: (vacío) -> Avenida Matta S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Avenida Matta S/N', updated_at = NOW() WHERE localizacion_id = 'loc_9117499cc087';

-- ORIG: (vacío) -> Sector San Pedro, Ñiquen 0 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Pedro, Ñiquen 0', localidad = 'San Pedro', updated_at = NOW() WHERE localizacion_id = 'loc_2bf598a19e8c';

-- ORIG: Calle Freire S/N -> Calle Freire 228 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire 228', updated_at = NOW() WHERE localizacion_id = 'loc_88c88d8c632c';

-- ORIG: Calle Luis Acevedo S/N -> Calle Luis Acevedo 656 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Luis Acevedo 656', updated_at = NOW() WHERE localizacion_id = 'loc_7bc77516af27';

-- ORIG: Calle Bilbao S/N -> Calle Bilbao Puesta del Sol 381, Villa Puesta del Sol (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao Puesta del Sol 381, Villa Puesta del Sol', updated_at = NOW() WHERE localizacion_id = 'loc_1b1078f7bf57';

-- ORIG: Calle Pedro Lagos S/N -> Calle Pedro Lagos 274 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos 274', updated_at = NOW() WHERE localizacion_id = 'loc_f2f2c0963f4a';

-- ORIG: (vacío) -> Valle Hondo (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Valle Hondo', updated_at = NOW() WHERE localizacion_id = 'loc_33e1540e1c9a';

-- ORIG: Villa Balmaceda S/N -> Villa Balmaceda 567 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Balmaceda 567', updated_at = NOW() WHERE localizacion_id = 'loc_6ec263b79ab1';

-- ORIG: Sector El Peumo S/N -> Sector El Peumo 858 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Peumo 858', localidad = 'El Peumo', updated_at = NOW() WHERE localizacion_id = 'loc_30ccb13f5655';

-- ORIG: (vacío) -> Sector El Manzano 1002 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Manzano 1002', localidad = 'El Manzano', updated_at = NOW() WHERE localizacion_id = 'loc_f70781f8bf50';

-- ORIG: (vacío) -> Sector Tiuquilemu, Arriba (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tiuquilemu, Arriba', localidad = 'Tiuquilemu', updated_at = NOW() WHERE localizacion_id = 'loc_78261f85d6a9';

-- ORIG: Calle Matta S/N -> Calle Matta 275 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta 275', updated_at = NOW() WHERE localizacion_id = 'loc_8dd945eb297c';

-- ORIG: (vacío) -> EL ALAMO 880 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'EL ALAMO 880', updated_at = NOW() WHERE localizacion_id = 'loc_c7beeb30ece0';

-- ORIG: Pasaje Los Andes S/N, Villa Las Américas -> Pasaje Andes 101, Villa Las Américas (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Andes 101, Villa Las Américas', updated_at = NOW() WHERE localizacion_id = 'loc_4bfefa0fa0c5';

-- ORIG: (vacío) -> GENERAL PARRA 212 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'GENERAL PARRA 212', updated_at = NOW() WHERE localizacion_id = 'loc_954319091562';

-- ORIG: Calle Teniente Merino S/N -> Calle Teniente Merino S/N, Casa 16 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Teniente Merino S/N, Casa 16', updated_at = NOW() WHERE localizacion_id = 'loc_56a319f50685';

-- ORIG: (vacío) -> PESOA VELIZ 236 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'PESOA VELIZ 236', updated_at = NOW() WHERE localizacion_id = 'loc_5af4bae8868a';

-- ORIG: Calle Matta S/N -> Calle Matta 565 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta 565', updated_at = NOW() WHERE localizacion_id = 'loc_1e44e9903a65';

-- ORIG: Calle Freire S/N -> Calle Freire 33 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire 33', updated_at = NOW() WHERE localizacion_id = 'loc_04328271ed84';

-- ORIG: (vacío) -> LO MELLADO 0 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'LO MELLADO 0', updated_at = NOW() WHERE localizacion_id = 'loc_01b46a997e3a';

-- ORIG: (vacío) -> Calle Gazmuri 994 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Gazmuri 994', updated_at = NOW() WHERE localizacion_id = 'loc_e73b126d75ae';

-- ORIG: (vacío) -> Poblacion Esmeralda 691 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Poblacion Esmeralda 691', updated_at = NOW() WHERE localizacion_id = 'loc_70ede1e9fbea';

-- ORIG: (vacío) -> BRAZIL 999 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'BRAZIL 999', updated_at = NOW() WHERE localizacion_id = 'loc_333ea9a21601';

-- ORIG: (vacío) -> 3 ESQUINAS S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = '3 ESQUINAS S/N', updated_at = NOW() WHERE localizacion_id = 'loc_8e56158110df';

-- ORIG: (vacío) -> Sector San Camilo, Km 2 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Camilo, Km 2', localidad = 'San Camilo', updated_at = NOW() WHERE localizacion_id = 'loc_7df1bce4a095';

-- ORIG: (vacío) -> Poblacion la Esmeralda (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Poblacion la Esmeralda', updated_at = NOW() WHERE localizacion_id = 'loc_ec9628742f0e';

-- ORIG: (vacío) -> Sector El Manzano 1018 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Manzano 1018', localidad = 'El Manzano', updated_at = NOW() WHERE localizacion_id = 'loc_0e0d3c171285';

-- ORIG: (vacío) -> Calle Ossa 53 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ossa 53', updated_at = NOW() WHERE localizacion_id = 'loc_9785188e119d';

-- ORIG: (vacío) -> Sector Monte León, Parcela 67 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte León, Parcela 67', localidad = 'Monte León', updated_at = NOW() WHERE localizacion_id = 'loc_fbcd5d477bf1';

-- ORIG: (vacío) -> PENCAHUE SN (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'PENCAHUE SN', updated_at = NOW() WHERE localizacion_id = 'loc_ab3c3a7a0072';

-- ORIG: (vacío) -> VILLA JUAN PABLO SEGUNDO , CARLOS OVIEDO 629 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Juan Pablo Segundo, Carlos Oviedo 629', updated_at = NOW() WHERE localizacion_id = 'loc_1a9b5dcf8bba';

-- ORIG: (vacío) -> Sector Quilelto, Sector la Estrella (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Quilelto, Sector la Estrella', localidad = 'Quilelto', updated_at = NOW() WHERE localizacion_id = 'loc_0c20a159b1c2';

-- ORIG: (vacío) -> ITIHUE 505 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'ITIHUE 505', updated_at = NOW() WHERE localizacion_id = 'loc_f8a305779fda';

-- ORIG: (vacío) -> VILLA LOS PRESIDENTES PSJE JUAN ANTONIO RIOS 41 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Los Presidentes Pasaje Juan Antonio Rios 41', updated_at = NOW() WHERE localizacion_id = 'loc_db384fe5cf22';

-- ORIG: (vacío) -> QUINQUEHUA KILOMETRO 5 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'QUINQUEHUA KILOMETRO 5', updated_at = NOW() WHERE localizacion_id = 'loc_cadf73161468';

-- ORIG: Villa los Poetas Manuel Contreras Pincheira -> Villa los Poetas Calle Manuel Contreras Pincheria 823 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Villa los Poetas Calle Manuel Contreras Pincheria 823', updated_at = NOW() WHERE localizacion_id = 'loc_c6e304f9d27a';

-- ORIG: (vacío) -> Sector El Carbón S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Carbón S/N', localidad = 'El Carbón', updated_at = NOW() WHERE localizacion_id = 'loc_c330364bf1f5';

-- ORIG: (vacío) -> VILLA SAN NICOLAS CALLE PABLO NERUDA 299 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Villa San Nicolas Calle Pablo Neruda 299', updated_at = NOW() WHERE localizacion_id = 'loc_19b9c62fc470';

-- ORIG: (vacío) -> Sector Las Garzas 1196 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Garzas 1196', localidad = 'Las Garzas', updated_at = NOW() WHERE localizacion_id = 'loc_610a1c7d9b74';

-- ORIG: (vacío) -> Sector Ribera de Ñuble, Calle Principal (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Ribera de Ñuble, Calle Principal', localidad = 'Ribera de Ñuble', updated_at = NOW() WHERE localizacion_id = 'loc_1217c880193a';

-- ORIG: Calle Freire S/N -> Calle Freire 1076 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire 1076', updated_at = NOW() WHERE localizacion_id = 'loc_4cc0c6dd8ea1';

-- ORIG: (vacío) -> Calle Brasil 63 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil 63', updated_at = NOW() WHERE localizacion_id = 'loc_6f4301b0bbd0';

-- ORIG: (vacío) -> Calle Brasil 058 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil 058', updated_at = NOW() WHERE localizacion_id = 'loc_c3212bb5e9af';

-- ORIG: (vacío) -> Sector Quilelto S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Quilelto S/N', localidad = 'Quilelto', updated_at = NOW() WHERE localizacion_id = 'loc_950ea85e1a8d';

-- ORIG: Los Queltehues, Villa el Bosque -> Los Queltehues, Villa el Bosque 821 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Los Queltehues, Villa el Bosque 821', updated_at = NOW() WHERE localizacion_id = 'loc_b327dd71188d';

-- ORIG: (vacío) -> Pasaje El Aromo 927 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje El Aromo 927', updated_at = NOW() WHERE localizacion_id = 'loc_04c9e7969c51';

-- ORIG: Perdices Villa el Bosque -> Las Perdices 11 de Sept 911 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Las Perdices 11 de Sept 911', updated_at = NOW() WHERE localizacion_id = 'loc_94ed42232d55';

-- ORIG: Lagos de Chile, T, los S -> Lagos de Chile Todos los Santos 0687 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Lagos de Chile Todos los Santos 0687', updated_at = NOW() WHERE localizacion_id = 'loc_b007c213d2f7';

-- ORIG: (vacío) -> Los Maitenes (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Los Maitenes', updated_at = NOW() WHERE localizacion_id = 'loc_d1f6076682a7';

-- ORIG: (vacío) -> Calle Pedro Lagos 64 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos 64', updated_at = NOW() WHERE localizacion_id = 'loc_f8adf5657943';

-- ORIG: (vacío) -> EL BOSQUE LAS TORTOLAS (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'El Bosque Las Tortolas', updated_at = NOW() WHERE localizacion_id = 'loc_ebd3a1c52a0d';

-- ORIG: (vacío) -> Sector La Gloria S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Gloria S/N', localidad = 'La Gloria', updated_at = NOW() WHERE localizacion_id = 'loc_63cb07e72972';

-- ORIG: Calle Balmaceda S/N -> Calle Balmaceda 371 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Balmaceda 371', updated_at = NOW() WHERE localizacion_id = 'loc_7b85bc2e8a4b';

-- ORIG: Calle Vicuña Mackenna S/N -> Calle Vicuña Mackenna 2116 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 2116', updated_at = NOW() WHERE localizacion_id = 'loc_9929584f53bd';

-- ORIG: Calle Reyman 754 -> Calle Reyman 754, Población Valle Hondo (type: more_detail)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Reyman 754, Población Valle Hondo', updated_at = NOW() WHERE localizacion_id = 'loc_ffa96fd1750e';

-- ORIG: (vacío) -> Sector Cocharcas S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cocharcas S/N', localidad = 'Cocharcas', updated_at = NOW() WHERE localizacion_id = 'loc_4a3ee7602da7';

-- ORIG: Calle Brasil S/N -> Calle Brasil 83 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil 83', updated_at = NOW() WHERE localizacion_id = 'loc_a90a7271d2bb';

-- ORIG: Calle Matta S/N -> Calle Matta 762 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta 762', updated_at = NOW() WHERE localizacion_id = 'loc_2dfad16b66ce';

-- ORIG: (vacío) -> Calle Bilbao #56 S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao #56 S/N', updated_at = NOW() WHERE localizacion_id = 'loc_4a00c2e9ef92';

-- ORIG: Calle Medardo Venegas S/N -> Puesta del Sol 183 183 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Puesta del Sol 183', updated_at = NOW() WHERE localizacion_id = 'loc_6d52773d5dd5';

-- ORIG: Calle Manuel Contreras S/N, Villa Aires de Lurín -> Calle Manuel Contreras Villa Aires de Lurin 792 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Manuel Contreras Villa Aires de Lurin 792', updated_at = NOW() WHERE localizacion_id = 'loc_4de834934748';

-- ORIG: (vacío) -> MANUEL RODRIGUEZ SAN NICOLAS 285 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Manuel Rodriguez San Nicolas 285', updated_at = NOW() WHERE localizacion_id = 'loc_529013984536';

-- ORIG: (vacío) -> Calle Germain de la Fuente S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Germain de la Fuente S/N', updated_at = NOW() WHERE localizacion_id = 'loc_8bab0e86807c';

-- ORIG: (vacío) -> Portal del Sur Felipe Camiroaga 61 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Portal del Sur Felipe Camiroaga 61', updated_at = NOW() WHERE localizacion_id = 'loc_d00068a90499';

-- ORIG: Sector Verquico S/N -> Verquico KM 7 , Camino a Toquihua S/n (type: more_detail)
UPDATE territorial.localizacion SET direccion_texto = 'Verquico KM 7, Camino a Toquihua S/n', localidad = 'Verquico', updated_at = NOW() WHERE localizacion_id = 'loc_f0d4bd6bf568';

-- ORIG: (vacío) -> SECTOR MENELHUE (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'SECTOR MENELHUE', updated_at = NOW() WHERE localizacion_id = 'loc_cc7b87d3d87a';

-- ORIG: (vacío) -> Psje, los Notros 928 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Psje, los Notros 928', updated_at = NOW() WHERE localizacion_id = 'loc_21af363cb87b';

-- ORIG: Calle Puelma S/N -> Calle Puelma S/N, Hogar Padre Pio (type: more_detail)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma S/N, Hogar Padre Pio', updated_at = NOW() WHERE localizacion_id = 'loc_1c7f21a29767';

-- ORIG: (vacío) -> Las Nubes 677 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Las Nubes 677', updated_at = NOW() WHERE localizacion_id = 'loc_f7564797f223';

-- ORIG: (vacío) -> Sector Montecillo S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Montecillo S/N', localidad = 'Montecillo', updated_at = NOW() WHERE localizacion_id = 'loc_0062bb4c3a43';

-- ORIG: (vacío) -> Sector Las Miras S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Miras S/N', localidad = 'Las Miras', updated_at = NOW() WHERE localizacion_id = 'loc_607c664d3512';

-- ORIG: Calle Carrera S/N -> Calle Carrera 447 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera 447', updated_at = NOW() WHERE localizacion_id = 'loc_271e76615f11';

-- ORIG: Calle Gazmuri S/N -> Calle Gazmuri 707 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Gazmuri 707', updated_at = NOW() WHERE localizacion_id = 'loc_575c43e05ed2';

-- ORIG: (vacío) -> Psje, los Castaños 1034 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Psje, los Castaños 1034', updated_at = NOW() WHERE localizacion_id = 'loc_d6ea084d4dc9';

-- ORIG: (vacío) -> Sector Cachapoal S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cachapoal S/N', localidad = 'Cachapoal', updated_at = NOW() WHERE localizacion_id = 'loc_15c0463a8063';

-- ORIG: Calle Vicuña Mackenna S/N -> Calle Vicuña Mackenna 1006 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 1006', updated_at = NOW() WHERE localizacion_id = 'loc_bdd3b0f74009';

-- ORIG: (vacío) -> Sector Millauquén, Km 10 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Millauquén, Km 10', localidad = 'Millauquén', updated_at = NOW() WHERE localizacion_id = 'loc_20996ee5919a';

-- ORIG: (vacío) -> EL GUINDO 1017 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'EL GUINDO 1017', updated_at = NOW() WHERE localizacion_id = 'loc_7f2cf0730832';

-- ORIG: Pasaje Mateo S/N, Villa La Virgen -> Villa la Virgen San Mateo 1608 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Villa la Virgen San Mateo 1608', updated_at = NOW() WHERE localizacion_id = 'loc_0dd83c742263';

-- ORIG: Calle Carrera S/N -> Calle Carrera 673 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera 673', updated_at = NOW() WHERE localizacion_id = 'loc_849f20da22fa';

-- ORIG: Calle Freire S/N -> Calle Freire 558 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire 558', updated_at = NOW() WHERE localizacion_id = 'loc_37aae9b329c6';

-- ORIG: (vacío) -> Sector Llahuimávida 1.5 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Llahuimávida 1.5', localidad = 'Llahuimávida', updated_at = NOW() WHERE localizacion_id = 'loc_9c6974c1fbc5';

-- ORIG: (vacío) -> LA RIBERA DE ÑUBLE (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'LA RIBERA DE ÑUBLE', updated_at = NOW() WHERE localizacion_id = 'loc_a1eb4850f5c2';

-- ORIG: Calle Bilbao S/N -> Calle Bilbao 517 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao 517', updated_at = NOW() WHERE localizacion_id = 'loc_ab928cb5c0fb';

-- ORIG: (vacío) -> Hogar San Agustin Camino Cape KM 1.6 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Hogar San Agustin Camino Cape KM 1.6', updated_at = NOW() WHERE localizacion_id = 'loc_a6e65c5490b6';

-- ORIG: Calle Tomás Yavar S/N -> Calle Tomás Yavar 14 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Tomás Yavar 14', updated_at = NOW() WHERE localizacion_id = 'loc_caa7f6671e2d';

-- ORIG: (vacío) -> Sector Virhuín S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Virhuín S/N', localidad = 'Virhuín', updated_at = NOW() WHERE localizacion_id = 'loc_267326f5991b';

-- ORIG: Puente Ñuble S/N -> Puente Ñuble Vista Bella 25 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Puente Ñuble Vista Bella 25', updated_at = NOW() WHERE localizacion_id = 'loc_84c57a846d37';

-- ORIG: Calle Riquelme S/N -> Calle Riquelme 497 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Riquelme 497', updated_at = NOW() WHERE localizacion_id = 'loc_f2c750d3fcdd';

-- ORIG: Calle Independencia S/N -> Calle Independencia 1519 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Independencia 1519', updated_at = NOW() WHERE localizacion_id = 'loc_4c62a0a7c146';

-- ORIG: (vacío) -> LAS ALITAS EL CARBON (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Las Alitas El Carbon', updated_at = NOW() WHERE localizacion_id = 'loc_3e493614e2da';

-- ORIG: Calle Carrera S/N -> Calle Carrera 12, 16 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera 12, 16', updated_at = NOW() WHERE localizacion_id = 'loc_9e4d6f67e105';

-- ORIG: Calle Vicuña Mackenna S/N -> Calle Vicuña Mackenna 892 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 892', updated_at = NOW() WHERE localizacion_id = 'loc_efa464617213';

-- ORIG: (vacío) -> EL LAUREL 11 DE SEPT 897 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'EL LAUREL 11 DE SEPT 897', updated_at = NOW() WHERE localizacion_id = 'loc_80cb6c97ed4d';

-- ORIG: (vacío) -> VIRGUIN S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'VIRGUIN S/N', updated_at = NOW() WHERE localizacion_id = 'loc_43c94cbdb0d0';

-- ORIG: (vacío) -> Sector Monte León S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte León S/N', localidad = 'Monte León', updated_at = NOW() WHERE localizacion_id = 'loc_8473edcd73f5';

-- ORIG: Calle Llanquihue S/N -> Calle Llanquihue 554 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Llanquihue 554', updated_at = NOW() WHERE localizacion_id = 'loc_7df136e984a1';

-- ORIG: Calle Vicuña Mackenna S/N -> Calle Vicuña Mackenna 1164 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 1164', updated_at = NOW() WHERE localizacion_id = 'loc_c76c053c9aae';

-- ORIG: (vacío) -> VILLA SAN NICOLAS SCTOR PUENTER ÑUBLE 179 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Villa San Nicolas Sctor Puenter Ñuble 179', updated_at = NOW() WHERE localizacion_id = 'loc_d460e79d307b';

-- ORIG: 11 Sept Cipres 1132 -> El Ciprés 1132, Población 11 de Septiembre (type: more_detail)
UPDATE territorial.localizacion SET direccion_texto = 'El Ciprés 1132, Población 11 de Septiembre', updated_at = NOW() WHERE localizacion_id = 'loc_79100519d152';

-- ORIG: Calle Brasil S/N -> Calle Brasil 24 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil 24', updated_at = NOW() WHERE localizacion_id = 'loc_2098a8c7bb45';

-- ORIG: (vacío) -> Sector La Primavera S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Primavera S/N', localidad = 'La Primavera', updated_at = NOW() WHERE localizacion_id = 'loc_ac279e97882c';

-- ORIG: (vacío) -> Calle Independencia 744 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Independencia 744', updated_at = NOW() WHERE localizacion_id = 'loc_729dc7a7b269';

-- ORIG: (vacío) -> Lagos de Chile 541 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Lagos de Chile 541', updated_at = NOW() WHERE localizacion_id = 'loc_2e90bdfec7db';

-- ORIG: (vacío) -> EL CEREZO 476 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'EL CEREZO 476', updated_at = NOW() WHERE localizacion_id = 'loc_0cb3c2c70c0b';

-- ORIG: (vacío) -> Calle Bilbao 517 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao 517', updated_at = NOW() WHERE localizacion_id = 'loc_bc69c45fda3c';

-- ORIG: Calle Balmaceda S/N -> Calle Balmaceda 376 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Balmaceda 376', updated_at = NOW() WHERE localizacion_id = 'loc_36f9a428e84d';

-- ORIG: (vacío) -> Pasaje Esmeralda S/N, Población Esmeralda (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Esmeralda S/N, Población Esmeralda', updated_at = NOW() WHERE localizacion_id = 'loc_a75bbfdbf307';

-- ORIG: Calle Ñuble S/N -> Calle Ñuble 392 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble 392', updated_at = NOW() WHERE localizacion_id = 'loc_fe51e90903ca';

-- ORIG: (vacío) -> Calle Gazmuri 80 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Gazmuri 80', updated_at = NOW() WHERE localizacion_id = 'loc_7c7ede1e2fb6';

-- ORIG: Calle Colombia S/N -> Calle Luis Acevedo 020 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Luis Acevedo 020', updated_at = NOW() WHERE localizacion_id = 'loc_b590f6e285a9';

-- ORIG: José Montes los Poetas -> José Montes los Poetas 157 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'José Montes los Poetas 157', updated_at = NOW() WHERE localizacion_id = 'loc_b2c026f14991';

-- ORIG: Calle Balmaceda S/N -> Calle Balmaceda 140, San Carlos 140 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Balmaceda 140, San Carlos 140', updated_at = NOW() WHERE localizacion_id = 'loc_4cdda427b7bc';

-- ORIG: Sector Llahuimávida S/N -> Sector Llahuimávida 44 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Llahuimávida 44', localidad = 'Llahuimávida', updated_at = NOW() WHERE localizacion_id = 'loc_0064a30f91fe';

-- ORIG: Calle Ñuble S/N -> Calle Ñuble 448 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble 448', updated_at = NOW() WHERE localizacion_id = 'loc_b3b6379409a2';

-- ORIG: (vacío) -> Calle Independencia 1165 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Independencia 1165', updated_at = NOW() WHERE localizacion_id = 'loc_f9923c364faf';

-- ORIG: Calle Maipú S/N -> Calle Maipú 980 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Maipú 980', updated_at = NOW() WHERE localizacion_id = 'loc_efe2212c1cb2';

-- ORIG: Calle Vicuña Mackenna S/N -> Calle Vicuña Mackenna 1170 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 1170', updated_at = NOW() WHERE localizacion_id = 'loc_62231d9c2de4';

-- ORIG: Calle Ñuble S/N -> Calle Ñuble 201 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble 201', updated_at = NOW() WHERE localizacion_id = 'loc_f218a66c039b';

-- ORIG: (vacío) -> SECTOR MONTE BLANCO (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte Blanco', updated_at = NOW() WHERE localizacion_id = 'loc_a9d33ef762fc';

-- ORIG: (vacío) -> Calle Ossa 1007 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ossa 1007', updated_at = NOW() WHERE localizacion_id = 'loc_f58268c96898';

-- ORIG: (vacío) -> Calle Puelma 150 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma 150', updated_at = NOW() WHERE localizacion_id = 'loc_41b43307b6fd';

-- ORIG: Población Nueva Esperanza Calle Violeta Parra -> POBLACION NUEVA ESPARANZA CALLE VIOLETA PARRA 34 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Poblacion Nueva Esparanza Calle Violeta Parra 34', updated_at = NOW() WHERE localizacion_id = 'loc_7762c7481bff';

-- ORIG: (vacío) -> Calle Puelma 237 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma 237', updated_at = NOW() WHERE localizacion_id = 'loc_46b9235d41b9';

-- ORIG: Sector El Sauce, Km 12.5 -> Sector El Sauce, Km 12.5 San Carlos (type: more_detail)
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Sauce, Km 12.5', localidad = 'El Sauce', updated_at = NOW() WHERE localizacion_id = 'loc_bd2918c99bef';

-- ORIG: (vacío) -> Calle Colombia 020 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Colombia 020', updated_at = NOW() WHERE localizacion_id = 'loc_5b23764614c9';

-- ORIG: (vacío) -> ELOY PARRA 172 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'ELOY PARRA 172', updated_at = NOW() WHERE localizacion_id = 'loc_edfdc742c02b';

-- ORIG: (vacío) -> LOS CASTAÑOS 928 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'LOS CASTAÑOS 928', updated_at = NOW() WHERE localizacion_id = 'loc_38d5f331dcbf';

-- ORIG: Calle Tomás Yavar S/N -> Calle Tomás Yavar 581 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Tomás Yavar 581', updated_at = NOW() WHERE localizacion_id = 'loc_d3104d6ad9b2';

-- ORIG: Puyehue, Lagos de Chile -> Puyehue Lagos de Chile 500 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Puyehue Lagos de Chile 500', updated_at = NOW() WHERE localizacion_id = 'loc_638947ff7d03';

-- ORIG: (vacío) -> Calle Tomás Yavar 772 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Tomás Yavar 772', updated_at = NOW() WHERE localizacion_id = 'loc_e4cbec7c48ef';

-- ORIG: 5 de Abril, Valle Hondo -> 5 de Abril Valle Hondo 925 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = '5 de Abril Valle Hondo 925', updated_at = NOW() WHERE localizacion_id = 'loc_e1be519a51dc';

-- ORIG: (vacío) -> Sector El Torreón S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Torreón S/N', localidad = 'El Torreón', updated_at = NOW() WHERE localizacion_id = 'loc_834fc86f2722';

-- ORIG: (vacío) -> LOS CAQUIS 949 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'LOS CAQUIS 949', updated_at = NOW() WHERE localizacion_id = 'loc_e41e90bd48be';

-- ORIG: (vacío) -> Pasaje La Luna Puente Ñuble 53 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje La Luna Puente Ñuble 53', updated_at = NOW() WHERE localizacion_id = 'loc_9223e52761df';

-- ORIG: (vacío) -> Calle Roble 250 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble 250', updated_at = NOW() WHERE localizacion_id = 'loc_03d6d7f996fc';

-- ORIG: (vacío) -> VILLA ESPAÑA CATALUÑA 47 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'VILLA ESPAÑA CATALUÑA 47', updated_at = NOW() WHERE localizacion_id = 'loc_7de6bcc6e7a9';

-- ORIG: (vacío) -> Psje, Rene Cerda 0532 Parque Bilbao (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Psje, Rene Cerda 0532 Parque Bilbao', updated_at = NOW() WHERE localizacion_id = 'loc_e4de90659c27';

-- ORIG: (vacío) -> LAS ALITAS EL CARBON (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Las Alitas El Carbon', updated_at = NOW() WHERE localizacion_id = 'loc_bc71cb1e9209';

-- ORIG: Calle Luis Cruz Martinez S/N -> Calle Luis Cruz Martinez 158 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Luis Cruz Martinez 158', updated_at = NOW() WHERE localizacion_id = 'loc_b70cdc3995c4';

-- ORIG: (vacío) -> Calle Matta 843 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta 843', updated_at = NOW() WHERE localizacion_id = 'loc_c353b9d8949f';

-- ORIG: Pasaje La Union S/N, Villa Los Caracoles -> Villa los Caracoles Psje la Union 575 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Villa los Caracoles Psje la Union 575', updated_at = NOW() WHERE localizacion_id = 'loc_7357025e0774';

-- ORIG: (vacío) -> LOS ALERCES 1055 , 11 DE SEPT (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Los Alerces 1055, 11 De Sept', updated_at = NOW() WHERE localizacion_id = 'loc_6f9db068e094';

-- ORIG: (vacío) -> B Correa Caro , los Cipreces 95 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'B Correa Caro, los Cipreces 95', updated_at = NOW() WHERE localizacion_id = 'loc_bb7c58bea77b';

-- ORIG: (vacío) -> Sector El Carbón S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Carbón S/N', localidad = 'El Carbón', updated_at = NOW() WHERE localizacion_id = 'loc_4204198cc320';

-- ORIG: (vacío) -> Avenida Prat 839 839 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Avenida Prat 839', updated_at = NOW() WHERE localizacion_id = 'loc_c2ac4e37154b';

-- ORIG: (vacío) -> Calle Diego Portales 127 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Diego Portales 127', updated_at = NOW() WHERE localizacion_id = 'loc_c3469fe021c6';

-- ORIG: Pasaje Yungay S/N -> Pasaje Jungay 372 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Jungay 372', updated_at = NOW() WHERE localizacion_id = 'loc_ea0ea6f91afb';

-- ORIG: (vacío) -> V MACKENNA 2236 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'V MACKENNA 2236', updated_at = NOW() WHERE localizacion_id = 'loc_88e5147fd1dd';

-- ORIG: (vacío) -> Calle Brasil 450 450 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil 450', updated_at = NOW() WHERE localizacion_id = 'loc_701ae2a903ed';

-- ORIG: (vacío) -> Calle General Venegas 520 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle General Venegas 520', updated_at = NOW() WHERE localizacion_id = 'loc_fc4249da0bd4';

-- ORIG: Callejón Los Palacios S/N -> Callejón Los Palacios 777 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Callejón Los Palacios 777', updated_at = NOW() WHERE localizacion_id = 'loc_e2dea8cea7e6';

-- ORIG: Sector El Sauce S/N -> Pasaje Norma Quijada Casa la Primavera 10 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Norma Quijada Casa la Primavera 10', localidad = 'El Sauce', updated_at = NOW() WHERE localizacion_id = 'loc_42274be863a4';

-- ORIG: Calle Sargento Aldea S/N -> Calle Sargento Aldea 439 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Sargento Aldea 439', updated_at = NOW() WHERE localizacion_id = 'loc_856a284b7df3';

-- ORIG: (vacío) -> Calle Vicuña Mackenna 240 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 240', updated_at = NOW() WHERE localizacion_id = 'loc_1206925fc1e2';

-- ORIG: (vacío) -> Sector Lomas de Puyaral, Los Canelos 295 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Lomas de Puyaral, Los Canelos 295', localidad = 'Lomas de Puyaral', updated_at = NOW() WHERE localizacion_id = 'loc_9f79abfceb26';

-- ORIG: (vacío) -> Sector Agua Buena, Villa la Esperanza (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena, Villa la Esperanza', localidad = 'Agua Buena', updated_at = NOW() WHERE localizacion_id = 'loc_2ae59397d14c';

-- ORIG: (vacío) -> Sector Bucalemu S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Bucalemu S/N', localidad = 'Bucalemu', updated_at = NOW() WHERE localizacion_id = 'loc_deb2485af4d9';

-- ORIG: (vacío) -> Calle Bilbao 147 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao 147', updated_at = NOW() WHERE localizacion_id = 'loc_3cb04fb257bc';

-- ORIG: Calle O''Higgins S/N -> Calle O''Higgins 862 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle O''Higgins 862', updated_at = NOW() WHERE localizacion_id = 'loc_8dfc0cf241ba';

-- ORIG: (vacío) -> Avenida Los Tios S/n S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Avenida Los Tios S/n S/N', updated_at = NOW() WHERE localizacion_id = 'loc_da646ccea1bb';

-- ORIG: (vacío) -> VILLA PRAT CONDELL 346 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Prat Condell 346', updated_at = NOW() WHERE localizacion_id = 'loc_bbf97a60cc5e';

-- ORIG: (vacío) -> VILLA PRAT PSJE IQUIQUE SAN CARLOS 1322 1322 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Prat Pasaje Iquique San Carlos 1322', updated_at = NOW() WHERE localizacion_id = 'loc_d1e652dd98cd';

-- ORIG: (vacío) -> SECTOR MONTE BLANCO (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte Blanco', updated_at = NOW() WHERE localizacion_id = 'loc_0b0594aa8479';

-- ORIG: Pasaje Luna S/N -> Pasaje La Luna 617 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje La Luna 617', updated_at = NOW() WHERE localizacion_id = 'loc_90ea79c2aa2c';

-- ORIG: Sector Raulí S/N -> EL RAULI 877 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'EL RAULI 877', localidad = 'Raulí', updated_at = NOW() WHERE localizacion_id = 'loc_881e090845e5';

-- ORIG: Villa las Americas, los Andes -> Villa las Americas , los Andes 101 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Villa las Americas, los Andes 101', updated_at = NOW() WHERE localizacion_id = 'loc_1298164c189c';

-- ORIG: Calle Matta S/N -> Calle Matta 475 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta 475', updated_at = NOW() WHERE localizacion_id = 'loc_b8556ff86e50';

-- ORIG: (vacío) -> Puesta del Sol C, Uribe (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Puesta del Sol C, Uribe', updated_at = NOW() WHERE localizacion_id = 'loc_3eda96d35c76';

-- ORIG: (vacío) -> Sector Monte Blanco S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte Blanco S/N', localidad = 'Monte Blanco', updated_at = NOW() WHERE localizacion_id = 'loc_a7d96ba8a30e';

-- ORIG: (vacío) -> ESTACION ÑIQUEN (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'ESTACION ÑIQUEN', updated_at = NOW() WHERE localizacion_id = 'loc_d08a2c9c1286';

-- ORIG: (vacío) -> PICHOCO 0 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'PICHOCO 0', updated_at = NOW() WHERE localizacion_id = 'loc_8833f4547c99';

-- ORIG: Sector El Roble 104 -> Calle Roble S/N, Con Pedro Lagos 104 (type: more_detail)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble S/N, Con Pedro Lagos 104', localidad = 'El Roble', updated_at = NOW() WHERE localizacion_id = 'loc_a8c2fcdf3708';

-- ORIG: Calle Navotavo S/N -> Calle Navotavo 381 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Navotavo 381', updated_at = NOW() WHERE localizacion_id = 'loc_679d33a82b6a';

-- ORIG: Los Pidenes, Villa el Bosque -> Los Pidenes , Villa el Bosque 754 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Los Pidenes, Villa el Bosque 754', updated_at = NOW() WHERE localizacion_id = 'loc_845f18cd99dc';

-- ORIG: (vacío) -> SECTOR PRIMAVERA J FUENTEALBA 9049 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Primavera J Fuentealba 9049', updated_at = NOW() WHERE localizacion_id = 'loc_fb651dd5e0c6';

-- ORIG: (vacío) -> ALTO PUYARAL , LOS ALMENDROS SAN NICOLAS (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Alto Puyaral, Los Almendros San Nicolas', updated_at = NOW() WHERE localizacion_id = 'loc_75af36db29e8';

-- ORIG: (vacío) -> GENEREAL VENEGAS 520 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'GENEREAL VENEGAS 520', updated_at = NOW() WHERE localizacion_id = 'loc_92ea2d7e1e1a';

-- ORIG: Sector Los Magnolios S/N -> Los Magnolios 1143 Pb.11 Septiembre (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Los Magnolios 1143 Pb.11 Septiembre', localidad = 'Los Magnolios', updated_at = NOW() WHERE localizacion_id = 'loc_f490aa9c0a9a';

-- ORIG: (vacío) -> POBLACION 11 DE SEPT 0 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'POBLACION 11 DE SEPT 0', updated_at = NOW() WHERE localizacion_id = 'loc_db829b881120';

-- ORIG: Sector San Miguel de Ablemo S/N -> Sector San Miguel de Ablemo, Casa 10 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Miguel de Ablemo, Casa 10', localidad = 'San Miguel de Ablemo', updated_at = NOW() WHERE localizacion_id = 'loc_e32a8c842f91';

-- ORIG: (vacío) -> Sector Las Arboledas, Psje el Durazno Sn (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Arboledas, Psje el Durazno Sn', localidad = 'Las Arboledas', updated_at = NOW() WHERE localizacion_id = 'loc_77a07ff181fa';

-- ORIG: (vacío) -> La Mira KM 5 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'La Mira KM 5', updated_at = NOW() WHERE localizacion_id = 'loc_f6cd7f13f6a8';

-- ORIG: (vacío) -> Sector Agua Buena S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena S/N', localidad = 'Agua Buena', updated_at = NOW() WHERE localizacion_id = 'loc_ec4a7f8b495a';

-- ORIG: Calle Vicuña Mackenna S/N -> Calle Vicuña Mackenna 882 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 882', updated_at = NOW() WHERE localizacion_id = 'loc_76d7d4cf98db';

-- ORIG: Sector Los Aromos 13 -> Sector Los Aromos 13, Monteleon (type: more_detail)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Los Aromos 13, Monteleon', localidad = 'Los Aromos', updated_at = NOW() WHERE localizacion_id = 'loc_eac996403102';

-- ORIG: Calle Navotavo S/N -> Calle Navotavo 653 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Navotavo 653', updated_at = NOW() WHERE localizacion_id = 'loc_b85024f25631';

-- ORIG: Villa Puesta del Sol Pasaje Abdiel Sepulveda -> Villa Puesta del Sol Psje Abdiel Sepulveda 168 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Puesta del Sol Psje Abdiel Sepulveda 168', updated_at = NOW() WHERE localizacion_id = 'loc_b16250f15ecb';

-- ORIG: Calle Brasil S/N -> Calle Brasil S/N, San Carlos 1201 1201 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil S/N, San Carlos 1201', updated_at = NOW() WHERE localizacion_id = 'loc_229683bd44da';

-- ORIG: (vacío) -> Sector San Camilo S/N (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Camilo S/N', localidad = 'San Camilo', updated_at = NOW() WHERE localizacion_id = 'loc_8aebf35b2f84';

-- ORIG: (vacío) -> OTINHUE KILOMETRO 11 PASADO ESTACION DE TREN ÑIQUEN OESTE (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Otinhue Kilometro 11 Pasado Estacion De Tren Ñiquen Oeste', updated_at = NOW() WHERE localizacion_id = 'loc_bd96c77fe217';

-- ORIG: (vacío) -> Nueva Esperanza Villa Paraiso 566 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Nueva Esperanza Villa Paraiso 566', updated_at = NOW() WHERE localizacion_id = 'loc_af6d42adb096';

-- ORIG: (vacío) -> VILLA CARLOS PONIENTE 476 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Carlos Poniente 476', updated_at = NOW() WHERE localizacion_id = 'loc_19ed6ce51806';

-- ORIG: (vacío) -> VILLA PADRE HURTADO COLICO 820 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Villa Padre Hurtado Colico 820', updated_at = NOW() WHERE localizacion_id = 'loc_5a93771dfbbf';

-- ORIG: (vacío) -> Sector San Jorge, Parcela 4 (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Jorge, Parcela 4', localidad = 'San Jorge', updated_at = NOW() WHERE localizacion_id = 'loc_0604bdf6a454';

-- ORIG: (vacío) -> Sector Monte Leon (type: new_address)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte Leon', updated_at = NOW() WHERE localizacion_id = 'loc_6a308efaf230';

-- ORIG: Portal del Sur, Silvia Slier -> Portal del Sur , Silvia Slier 566 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Portal del Sur, Silvia Slier 566', updated_at = NOW() WHERE localizacion_id = 'loc_455f0e181fb8';

-- ORIG: Pasaje La Estrella Villa Nueva Vida S/N -> Psje, la Estrella 0698, Villa Nueva Vida (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Psje, la Estrella 0698, Villa Nueva Vida', updated_at = NOW() WHERE localizacion_id = 'loc_91f28d2a0b2f';

-- ORIG: Calle Pedro Lagos S/N -> Calle Pedro Lagos 649 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos 649', updated_at = NOW() WHERE localizacion_id = 'loc_fa15dccc39f8';

-- ORIG: Calle Sargento Aldea S/N -> Calle Sargento Aldea 444 (type: added_number)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Sargento Aldea 444', updated_at = NOW() WHERE localizacion_id = 'loc_6f1ef4b92dfd';

-- ── Proveniencia ────────────────────────────────────────────────────

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_209b38c1f49e', 'correction', 'patient_address.csv', 'loc_209b38c1f49e', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b3aca72037bb', 'correction', 'patient_address.csv', 'loc_b3aca72037bb', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7d912f298260', 'correction', 'patient_address.csv', 'loc_7d912f298260', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_11c27e55ad47', 'correction', 'patient_address.csv', 'loc_11c27e55ad47', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d83f45ea4c29', 'correction', 'patient_address.csv', 'loc_d83f45ea4c29', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9c05b69084b5', 'correction', 'patient_address.csv', 'loc_9c05b69084b5', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6839bfc2dd97', 'correction', 'patient_address.csv', 'loc_6839bfc2dd97', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6839bfc2dd97', 'correction', 'patient_address.csv', 'loc_6839bfc2dd97', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a7b3093f3d67', 'correction', 'patient_address.csv', 'loc_a7b3093f3d67', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e22e03ccfd18', 'correction', 'patient_address.csv', 'loc_e22e03ccfd18', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_cc0fbdea2f59', 'correction', 'patient_address.csv', 'loc_cc0fbdea2f59', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_844a448efdaf', 'correction', 'patient_address.csv', 'loc_844a448efdaf', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_844a448efdaf', 'correction', 'patient_address.csv', 'loc_844a448efdaf', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9cc97c4b8263', 'correction', 'patient_address.csv', 'loc_9cc97c4b8263', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b8b7cc6659fc', 'correction', 'patient_address.csv', 'loc_b8b7cc6659fc', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5a4cf03896d1', 'correction', 'patient_address.csv', 'loc_5a4cf03896d1', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_68f1681c4891', 'correction', 'patient_address.csv', 'loc_68f1681c4891', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9edae02716b0', 'correction', 'patient_address.csv', 'loc_9edae02716b0', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ef412e6f165a', 'correction', 'patient_address.csv', 'loc_ef412e6f165a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_323c949b6f0f', 'correction', 'patient_address.csv', 'loc_323c949b6f0f', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e0efd220dd93', 'correction', 'patient_address.csv', 'loc_e0efd220dd93', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_cce1c3c51269', 'correction', 'patient_address.csv', 'loc_cce1c3c51269', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fb808ea49b72', 'correction', 'patient_address.csv', 'loc_fb808ea49b72', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e7c4eb91a105', 'correction', 'patient_address.csv', 'loc_e7c4eb91a105', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7a2eda599082', 'correction', 'patient_address.csv', 'loc_7a2eda599082', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0a98c5c48ea7', 'correction', 'patient_address.csv', 'loc_0a98c5c48ea7', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_452a41d729c7', 'correction', 'patient_address.csv', 'loc_452a41d729c7', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e223946c1aae', 'correction', 'patient_address.csv', 'loc_e223946c1aae', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b368875353c5', 'correction', 'patient_address.csv', 'loc_b368875353c5', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c97f6a23720a', 'correction', 'patient_address.csv', 'loc_c97f6a23720a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c97f6a23720a', 'correction', 'patient_address.csv', 'loc_c97f6a23720a', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7c74ded6113c', 'correction', 'patient_address.csv', 'loc_7c74ded6113c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7c74ded6113c', 'correction', 'patient_address.csv', 'loc_7c74ded6113c', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_efa25fa022d9', 'correction', 'patient_address.csv', 'loc_efa25fa022d9', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5e5427553fc9', 'correction', 'patient_address.csv', 'loc_5e5427553fc9', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d7c620fe0654', 'correction', 'patient_address.csv', 'loc_d7c620fe0654', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_55daef1bfddf', 'correction', 'patient_address.csv', 'loc_55daef1bfddf', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_55daef1bfddf', 'correction', 'patient_address.csv', 'loc_55daef1bfddf', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_44a0750a6358', 'correction', 'patient_address.csv', 'loc_44a0750a6358', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_44a0750a6358', 'correction', 'patient_address.csv', 'loc_44a0750a6358', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1ffe6515fd08', 'correction', 'patient_address.csv', 'loc_1ffe6515fd08', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_25115418cbef', 'correction', 'patient_address.csv', 'loc_25115418cbef', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_01706ab816f4', 'correction', 'patient_address.csv', 'loc_01706ab816f4', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c321e82a429f', 'correction', 'patient_address.csv', 'loc_c321e82a429f', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_dc9d74522686', 'correction', 'patient_address.csv', 'loc_dc9d74522686', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a70ba2b2010b', 'correction', 'patient_address.csv', 'loc_a70ba2b2010b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7a6cf174ed4e', 'correction', 'patient_address.csv', 'loc_7a6cf174ed4e', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7a6cf174ed4e', 'correction', 'patient_address.csv', 'loc_7a6cf174ed4e', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_22eab95df4dc', 'correction', 'patient_address.csv', 'loc_22eab95df4dc', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c5461f4efdf8', 'correction', 'patient_address.csv', 'loc_c5461f4efdf8', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bc1f174eb363', 'correction', 'patient_address.csv', 'loc_bc1f174eb363', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f1441479f75b', 'correction', 'patient_address.csv', 'loc_f1441479f75b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c394f4107802', 'correction', 'patient_address.csv', 'loc_c394f4107802', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_af7e6a243a57', 'correction', 'patient_address.csv', 'loc_af7e6a243a57', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_abae8df7d209', 'correction', 'patient_address.csv', 'loc_abae8df7d209', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_659eacb0079a', 'correction', 'patient_address.csv', 'loc_659eacb0079a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_659eacb0079a', 'correction', 'patient_address.csv', 'loc_659eacb0079a', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b2c9aa1fdfa5', 'correction', 'patient_address.csv', 'loc_b2c9aa1fdfa5', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_09c1f6f88446', 'correction', 'patient_address.csv', 'loc_09c1f6f88446', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0674146cf6e3', 'correction', 'patient_address.csv', 'loc_0674146cf6e3', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0674146cf6e3', 'correction', 'patient_address.csv', 'loc_0674146cf6e3', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_af3dff331990', 'correction', 'patient_address.csv', 'loc_af3dff331990', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fee309029c19', 'correction', 'patient_address.csv', 'loc_fee309029c19', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fee309029c19', 'correction', 'patient_address.csv', 'loc_fee309029c19', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_97a4fd49a0e8', 'correction', 'patient_address.csv', 'loc_97a4fd49a0e8', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_97a4fd49a0e8', 'correction', 'patient_address.csv', 'loc_97a4fd49a0e8', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3df8f63b555a', 'correction', 'patient_address.csv', 'loc_3df8f63b555a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6c76127ecb86', 'correction', 'patient_address.csv', 'loc_6c76127ecb86', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5f8e253e630d', 'correction', 'patient_address.csv', 'loc_5f8e253e630d', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5f8e253e630d', 'correction', 'patient_address.csv', 'loc_5f8e253e630d', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4c5149ceeda6', 'correction', 'patient_address.csv', 'loc_4c5149ceeda6', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bd2581e4ec04', 'correction', 'patient_address.csv', 'loc_bd2581e4ec04', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9117499cc087', 'correction', 'patient_address.csv', 'loc_9117499cc087', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2bf598a19e8c', 'correction', 'patient_address.csv', 'loc_2bf598a19e8c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2bf598a19e8c', 'correction', 'patient_address.csv', 'loc_2bf598a19e8c', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_88c88d8c632c', 'correction', 'patient_address.csv', 'loc_88c88d8c632c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7bc77516af27', 'correction', 'patient_address.csv', 'loc_7bc77516af27', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1b1078f7bf57', 'correction', 'patient_address.csv', 'loc_1b1078f7bf57', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f2f2c0963f4a', 'correction', 'patient_address.csv', 'loc_f2f2c0963f4a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_33e1540e1c9a', 'correction', 'patient_address.csv', 'loc_33e1540e1c9a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6ec263b79ab1', 'correction', 'patient_address.csv', 'loc_6ec263b79ab1', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_30ccb13f5655', 'correction', 'patient_address.csv', 'loc_30ccb13f5655', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_30ccb13f5655', 'correction', 'patient_address.csv', 'loc_30ccb13f5655', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f70781f8bf50', 'correction', 'patient_address.csv', 'loc_f70781f8bf50', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f70781f8bf50', 'correction', 'patient_address.csv', 'loc_f70781f8bf50', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_78261f85d6a9', 'correction', 'patient_address.csv', 'loc_78261f85d6a9', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_78261f85d6a9', 'correction', 'patient_address.csv', 'loc_78261f85d6a9', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8dd945eb297c', 'correction', 'patient_address.csv', 'loc_8dd945eb297c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c7beeb30ece0', 'correction', 'patient_address.csv', 'loc_c7beeb30ece0', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4bfefa0fa0c5', 'correction', 'patient_address.csv', 'loc_4bfefa0fa0c5', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_954319091562', 'correction', 'patient_address.csv', 'loc_954319091562', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_56a319f50685', 'correction', 'patient_address.csv', 'loc_56a319f50685', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5af4bae8868a', 'correction', 'patient_address.csv', 'loc_5af4bae8868a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1e44e9903a65', 'correction', 'patient_address.csv', 'loc_1e44e9903a65', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_04328271ed84', 'correction', 'patient_address.csv', 'loc_04328271ed84', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_01b46a997e3a', 'correction', 'patient_address.csv', 'loc_01b46a997e3a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e73b126d75ae', 'correction', 'patient_address.csv', 'loc_e73b126d75ae', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_70ede1e9fbea', 'correction', 'patient_address.csv', 'loc_70ede1e9fbea', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_333ea9a21601', 'correction', 'patient_address.csv', 'loc_333ea9a21601', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8e56158110df', 'correction', 'patient_address.csv', 'loc_8e56158110df', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7df1bce4a095', 'correction', 'patient_address.csv', 'loc_7df1bce4a095', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7df1bce4a095', 'correction', 'patient_address.csv', 'loc_7df1bce4a095', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ec9628742f0e', 'correction', 'patient_address.csv', 'loc_ec9628742f0e', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0e0d3c171285', 'correction', 'patient_address.csv', 'loc_0e0d3c171285', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0e0d3c171285', 'correction', 'patient_address.csv', 'loc_0e0d3c171285', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9785188e119d', 'correction', 'patient_address.csv', 'loc_9785188e119d', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fbcd5d477bf1', 'correction', 'patient_address.csv', 'loc_fbcd5d477bf1', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fbcd5d477bf1', 'correction', 'patient_address.csv', 'loc_fbcd5d477bf1', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ab3c3a7a0072', 'correction', 'patient_address.csv', 'loc_ab3c3a7a0072', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1a9b5dcf8bba', 'correction', 'patient_address.csv', 'loc_1a9b5dcf8bba', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0c20a159b1c2', 'correction', 'patient_address.csv', 'loc_0c20a159b1c2', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0c20a159b1c2', 'correction', 'patient_address.csv', 'loc_0c20a159b1c2', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f8a305779fda', 'correction', 'patient_address.csv', 'loc_f8a305779fda', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_db384fe5cf22', 'correction', 'patient_address.csv', 'loc_db384fe5cf22', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_cadf73161468', 'correction', 'patient_address.csv', 'loc_cadf73161468', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c6e304f9d27a', 'correction', 'patient_address.csv', 'loc_c6e304f9d27a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c330364bf1f5', 'correction', 'patient_address.csv', 'loc_c330364bf1f5', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c330364bf1f5', 'correction', 'patient_address.csv', 'loc_c330364bf1f5', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_19b9c62fc470', 'correction', 'patient_address.csv', 'loc_19b9c62fc470', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_610a1c7d9b74', 'correction', 'patient_address.csv', 'loc_610a1c7d9b74', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_610a1c7d9b74', 'correction', 'patient_address.csv', 'loc_610a1c7d9b74', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1217c880193a', 'correction', 'patient_address.csv', 'loc_1217c880193a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1217c880193a', 'correction', 'patient_address.csv', 'loc_1217c880193a', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4cc0c6dd8ea1', 'correction', 'patient_address.csv', 'loc_4cc0c6dd8ea1', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6f4301b0bbd0', 'correction', 'patient_address.csv', 'loc_6f4301b0bbd0', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c3212bb5e9af', 'correction', 'patient_address.csv', 'loc_c3212bb5e9af', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_950ea85e1a8d', 'correction', 'patient_address.csv', 'loc_950ea85e1a8d', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_950ea85e1a8d', 'correction', 'patient_address.csv', 'loc_950ea85e1a8d', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b327dd71188d', 'correction', 'patient_address.csv', 'loc_b327dd71188d', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_04c9e7969c51', 'correction', 'patient_address.csv', 'loc_04c9e7969c51', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_94ed42232d55', 'correction', 'patient_address.csv', 'loc_94ed42232d55', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b007c213d2f7', 'correction', 'patient_address.csv', 'loc_b007c213d2f7', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d1f6076682a7', 'correction', 'patient_address.csv', 'loc_d1f6076682a7', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f8adf5657943', 'correction', 'patient_address.csv', 'loc_f8adf5657943', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ebd3a1c52a0d', 'correction', 'patient_address.csv', 'loc_ebd3a1c52a0d', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_63cb07e72972', 'correction', 'patient_address.csv', 'loc_63cb07e72972', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_63cb07e72972', 'correction', 'patient_address.csv', 'loc_63cb07e72972', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7b85bc2e8a4b', 'correction', 'patient_address.csv', 'loc_7b85bc2e8a4b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9929584f53bd', 'correction', 'patient_address.csv', 'loc_9929584f53bd', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ffa96fd1750e', 'correction', 'patient_address.csv', 'loc_ffa96fd1750e', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4a3ee7602da7', 'correction', 'patient_address.csv', 'loc_4a3ee7602da7', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4a3ee7602da7', 'correction', 'patient_address.csv', 'loc_4a3ee7602da7', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a90a7271d2bb', 'correction', 'patient_address.csv', 'loc_a90a7271d2bb', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2dfad16b66ce', 'correction', 'patient_address.csv', 'loc_2dfad16b66ce', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4a00c2e9ef92', 'correction', 'patient_address.csv', 'loc_4a00c2e9ef92', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6d52773d5dd5', 'correction', 'patient_address.csv', 'loc_6d52773d5dd5', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4de834934748', 'correction', 'patient_address.csv', 'loc_4de834934748', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_529013984536', 'correction', 'patient_address.csv', 'loc_529013984536', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8bab0e86807c', 'correction', 'patient_address.csv', 'loc_8bab0e86807c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d00068a90499', 'correction', 'patient_address.csv', 'loc_d00068a90499', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f0d4bd6bf568', 'correction', 'patient_address.csv', 'loc_f0d4bd6bf568', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f0d4bd6bf568', 'correction', 'patient_address.csv', 'loc_f0d4bd6bf568', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_cc7b87d3d87a', 'correction', 'patient_address.csv', 'loc_cc7b87d3d87a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_21af363cb87b', 'correction', 'patient_address.csv', 'loc_21af363cb87b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1c7f21a29767', 'correction', 'patient_address.csv', 'loc_1c7f21a29767', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f7564797f223', 'correction', 'patient_address.csv', 'loc_f7564797f223', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0062bb4c3a43', 'correction', 'patient_address.csv', 'loc_0062bb4c3a43', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0062bb4c3a43', 'correction', 'patient_address.csv', 'loc_0062bb4c3a43', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_607c664d3512', 'correction', 'patient_address.csv', 'loc_607c664d3512', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_607c664d3512', 'correction', 'patient_address.csv', 'loc_607c664d3512', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_271e76615f11', 'correction', 'patient_address.csv', 'loc_271e76615f11', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_575c43e05ed2', 'correction', 'patient_address.csv', 'loc_575c43e05ed2', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d6ea084d4dc9', 'correction', 'patient_address.csv', 'loc_d6ea084d4dc9', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_15c0463a8063', 'correction', 'patient_address.csv', 'loc_15c0463a8063', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_15c0463a8063', 'correction', 'patient_address.csv', 'loc_15c0463a8063', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bdd3b0f74009', 'correction', 'patient_address.csv', 'loc_bdd3b0f74009', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_20996ee5919a', 'correction', 'patient_address.csv', 'loc_20996ee5919a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_20996ee5919a', 'correction', 'patient_address.csv', 'loc_20996ee5919a', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7f2cf0730832', 'correction', 'patient_address.csv', 'loc_7f2cf0730832', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0dd83c742263', 'correction', 'patient_address.csv', 'loc_0dd83c742263', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_849f20da22fa', 'correction', 'patient_address.csv', 'loc_849f20da22fa', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_37aae9b329c6', 'correction', 'patient_address.csv', 'loc_37aae9b329c6', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9c6974c1fbc5', 'correction', 'patient_address.csv', 'loc_9c6974c1fbc5', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9c6974c1fbc5', 'correction', 'patient_address.csv', 'loc_9c6974c1fbc5', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a1eb4850f5c2', 'correction', 'patient_address.csv', 'loc_a1eb4850f5c2', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ab928cb5c0fb', 'correction', 'patient_address.csv', 'loc_ab928cb5c0fb', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a6e65c5490b6', 'correction', 'patient_address.csv', 'loc_a6e65c5490b6', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_caa7f6671e2d', 'correction', 'patient_address.csv', 'loc_caa7f6671e2d', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_267326f5991b', 'correction', 'patient_address.csv', 'loc_267326f5991b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_267326f5991b', 'correction', 'patient_address.csv', 'loc_267326f5991b', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_84c57a846d37', 'correction', 'patient_address.csv', 'loc_84c57a846d37', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f2c750d3fcdd', 'correction', 'patient_address.csv', 'loc_f2c750d3fcdd', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4c62a0a7c146', 'correction', 'patient_address.csv', 'loc_4c62a0a7c146', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3e493614e2da', 'correction', 'patient_address.csv', 'loc_3e493614e2da', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9e4d6f67e105', 'correction', 'patient_address.csv', 'loc_9e4d6f67e105', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_efa464617213', 'correction', 'patient_address.csv', 'loc_efa464617213', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_80cb6c97ed4d', 'correction', 'patient_address.csv', 'loc_80cb6c97ed4d', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_43c94cbdb0d0', 'correction', 'patient_address.csv', 'loc_43c94cbdb0d0', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8473edcd73f5', 'correction', 'patient_address.csv', 'loc_8473edcd73f5', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8473edcd73f5', 'correction', 'patient_address.csv', 'loc_8473edcd73f5', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7df136e984a1', 'correction', 'patient_address.csv', 'loc_7df136e984a1', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c76c053c9aae', 'correction', 'patient_address.csv', 'loc_c76c053c9aae', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d460e79d307b', 'correction', 'patient_address.csv', 'loc_d460e79d307b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_79100519d152', 'correction', 'patient_address.csv', 'loc_79100519d152', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2098a8c7bb45', 'correction', 'patient_address.csv', 'loc_2098a8c7bb45', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ac279e97882c', 'correction', 'patient_address.csv', 'loc_ac279e97882c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ac279e97882c', 'correction', 'patient_address.csv', 'loc_ac279e97882c', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_729dc7a7b269', 'correction', 'patient_address.csv', 'loc_729dc7a7b269', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2e90bdfec7db', 'correction', 'patient_address.csv', 'loc_2e90bdfec7db', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0cb3c2c70c0b', 'correction', 'patient_address.csv', 'loc_0cb3c2c70c0b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bc69c45fda3c', 'correction', 'patient_address.csv', 'loc_bc69c45fda3c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_36f9a428e84d', 'correction', 'patient_address.csv', 'loc_36f9a428e84d', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a75bbfdbf307', 'correction', 'patient_address.csv', 'loc_a75bbfdbf307', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fe51e90903ca', 'correction', 'patient_address.csv', 'loc_fe51e90903ca', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7c7ede1e2fb6', 'correction', 'patient_address.csv', 'loc_7c7ede1e2fb6', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b590f6e285a9', 'correction', 'patient_address.csv', 'loc_b590f6e285a9', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b2c026f14991', 'correction', 'patient_address.csv', 'loc_b2c026f14991', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4cdda427b7bc', 'correction', 'patient_address.csv', 'loc_4cdda427b7bc', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0064a30f91fe', 'correction', 'patient_address.csv', 'loc_0064a30f91fe', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0064a30f91fe', 'correction', 'patient_address.csv', 'loc_0064a30f91fe', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b3b6379409a2', 'correction', 'patient_address.csv', 'loc_b3b6379409a2', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f9923c364faf', 'correction', 'patient_address.csv', 'loc_f9923c364faf', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_efe2212c1cb2', 'correction', 'patient_address.csv', 'loc_efe2212c1cb2', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_62231d9c2de4', 'correction', 'patient_address.csv', 'loc_62231d9c2de4', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f218a66c039b', 'correction', 'patient_address.csv', 'loc_f218a66c039b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a9d33ef762fc', 'correction', 'patient_address.csv', 'loc_a9d33ef762fc', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f58268c96898', 'correction', 'patient_address.csv', 'loc_f58268c96898', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_41b43307b6fd', 'correction', 'patient_address.csv', 'loc_41b43307b6fd', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7762c7481bff', 'correction', 'patient_address.csv', 'loc_7762c7481bff', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_46b9235d41b9', 'correction', 'patient_address.csv', 'loc_46b9235d41b9', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bd2918c99bef', 'correction', 'patient_address.csv', 'loc_bd2918c99bef', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bd2918c99bef', 'correction', 'patient_address.csv', 'loc_bd2918c99bef', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5b23764614c9', 'correction', 'patient_address.csv', 'loc_5b23764614c9', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_edfdc742c02b', 'correction', 'patient_address.csv', 'loc_edfdc742c02b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_38d5f331dcbf', 'correction', 'patient_address.csv', 'loc_38d5f331dcbf', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d3104d6ad9b2', 'correction', 'patient_address.csv', 'loc_d3104d6ad9b2', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_638947ff7d03', 'correction', 'patient_address.csv', 'loc_638947ff7d03', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e4cbec7c48ef', 'correction', 'patient_address.csv', 'loc_e4cbec7c48ef', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e1be519a51dc', 'correction', 'patient_address.csv', 'loc_e1be519a51dc', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_834fc86f2722', 'correction', 'patient_address.csv', 'loc_834fc86f2722', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_834fc86f2722', 'correction', 'patient_address.csv', 'loc_834fc86f2722', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e41e90bd48be', 'correction', 'patient_address.csv', 'loc_e41e90bd48be', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9223e52761df', 'correction', 'patient_address.csv', 'loc_9223e52761df', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_03d6d7f996fc', 'correction', 'patient_address.csv', 'loc_03d6d7f996fc', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7de6bcc6e7a9', 'correction', 'patient_address.csv', 'loc_7de6bcc6e7a9', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e4de90659c27', 'correction', 'patient_address.csv', 'loc_e4de90659c27', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bc71cb1e9209', 'correction', 'patient_address.csv', 'loc_bc71cb1e9209', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b70cdc3995c4', 'correction', 'patient_address.csv', 'loc_b70cdc3995c4', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c353b9d8949f', 'correction', 'patient_address.csv', 'loc_c353b9d8949f', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7357025e0774', 'correction', 'patient_address.csv', 'loc_7357025e0774', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6f9db068e094', 'correction', 'patient_address.csv', 'loc_6f9db068e094', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bb7c58bea77b', 'correction', 'patient_address.csv', 'loc_bb7c58bea77b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4204198cc320', 'correction', 'patient_address.csv', 'loc_4204198cc320', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4204198cc320', 'correction', 'patient_address.csv', 'loc_4204198cc320', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c2ac4e37154b', 'correction', 'patient_address.csv', 'loc_c2ac4e37154b', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c3469fe021c6', 'correction', 'patient_address.csv', 'loc_c3469fe021c6', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ea0ea6f91afb', 'correction', 'patient_address.csv', 'loc_ea0ea6f91afb', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_88e5147fd1dd', 'correction', 'patient_address.csv', 'loc_88e5147fd1dd', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_701ae2a903ed', 'correction', 'patient_address.csv', 'loc_701ae2a903ed', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fc4249da0bd4', 'correction', 'patient_address.csv', 'loc_fc4249da0bd4', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e2dea8cea7e6', 'correction', 'patient_address.csv', 'loc_e2dea8cea7e6', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_42274be863a4', 'correction', 'patient_address.csv', 'loc_42274be863a4', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_42274be863a4', 'correction', 'patient_address.csv', 'loc_42274be863a4', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_856a284b7df3', 'correction', 'patient_address.csv', 'loc_856a284b7df3', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1206925fc1e2', 'correction', 'patient_address.csv', 'loc_1206925fc1e2', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9f79abfceb26', 'correction', 'patient_address.csv', 'loc_9f79abfceb26', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9f79abfceb26', 'correction', 'patient_address.csv', 'loc_9f79abfceb26', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2ae59397d14c', 'correction', 'patient_address.csv', 'loc_2ae59397d14c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2ae59397d14c', 'correction', 'patient_address.csv', 'loc_2ae59397d14c', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_deb2485af4d9', 'correction', 'patient_address.csv', 'loc_deb2485af4d9', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_deb2485af4d9', 'correction', 'patient_address.csv', 'loc_deb2485af4d9', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3cb04fb257bc', 'correction', 'patient_address.csv', 'loc_3cb04fb257bc', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8dfc0cf241ba', 'correction', 'patient_address.csv', 'loc_8dfc0cf241ba', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_da646ccea1bb', 'correction', 'patient_address.csv', 'loc_da646ccea1bb', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bbf97a60cc5e', 'correction', 'patient_address.csv', 'loc_bbf97a60cc5e', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d1e652dd98cd', 'correction', 'patient_address.csv', 'loc_d1e652dd98cd', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0b0594aa8479', 'correction', 'patient_address.csv', 'loc_0b0594aa8479', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_90ea79c2aa2c', 'correction', 'patient_address.csv', 'loc_90ea79c2aa2c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_881e090845e5', 'correction', 'patient_address.csv', 'loc_881e090845e5', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_881e090845e5', 'correction', 'patient_address.csv', 'loc_881e090845e5', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1298164c189c', 'correction', 'patient_address.csv', 'loc_1298164c189c', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b8556ff86e50', 'correction', 'patient_address.csv', 'loc_b8556ff86e50', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3eda96d35c76', 'correction', 'patient_address.csv', 'loc_3eda96d35c76', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a7d96ba8a30e', 'correction', 'patient_address.csv', 'loc_a7d96ba8a30e', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a7d96ba8a30e', 'correction', 'patient_address.csv', 'loc_a7d96ba8a30e', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d08a2c9c1286', 'correction', 'patient_address.csv', 'loc_d08a2c9c1286', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8833f4547c99', 'correction', 'patient_address.csv', 'loc_8833f4547c99', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a8c2fcdf3708', 'correction', 'patient_address.csv', 'loc_a8c2fcdf3708', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a8c2fcdf3708', 'correction', 'patient_address.csv', 'loc_a8c2fcdf3708', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_679d33a82b6a', 'correction', 'patient_address.csv', 'loc_679d33a82b6a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_845f18cd99dc', 'correction', 'patient_address.csv', 'loc_845f18cd99dc', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fb651dd5e0c6', 'correction', 'patient_address.csv', 'loc_fb651dd5e0c6', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_75af36db29e8', 'correction', 'patient_address.csv', 'loc_75af36db29e8', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_92ea2d7e1e1a', 'correction', 'patient_address.csv', 'loc_92ea2d7e1e1a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f490aa9c0a9a', 'correction', 'patient_address.csv', 'loc_f490aa9c0a9a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f490aa9c0a9a', 'correction', 'patient_address.csv', 'loc_f490aa9c0a9a', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_db829b881120', 'correction', 'patient_address.csv', 'loc_db829b881120', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e32a8c842f91', 'correction', 'patient_address.csv', 'loc_e32a8c842f91', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e32a8c842f91', 'correction', 'patient_address.csv', 'loc_e32a8c842f91', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_77a07ff181fa', 'correction', 'patient_address.csv', 'loc_77a07ff181fa', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_77a07ff181fa', 'correction', 'patient_address.csv', 'loc_77a07ff181fa', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f6cd7f13f6a8', 'correction', 'patient_address.csv', 'loc_f6cd7f13f6a8', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ec4a7f8b495a', 'correction', 'patient_address.csv', 'loc_ec4a7f8b495a', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ec4a7f8b495a', 'correction', 'patient_address.csv', 'loc_ec4a7f8b495a', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_76d7d4cf98db', 'correction', 'patient_address.csv', 'loc_76d7d4cf98db', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eac996403102', 'correction', 'patient_address.csv', 'loc_eac996403102', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eac996403102', 'correction', 'patient_address.csv', 'loc_eac996403102', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b85024f25631', 'correction', 'patient_address.csv', 'loc_b85024f25631', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b16250f15ecb', 'correction', 'patient_address.csv', 'loc_b16250f15ecb', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_229683bd44da', 'correction', 'patient_address.csv', 'loc_229683bd44da', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8aebf35b2f84', 'correction', 'patient_address.csv', 'loc_8aebf35b2f84', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8aebf35b2f84', 'correction', 'patient_address.csv', 'loc_8aebf35b2f84', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bd96c77fe217', 'correction', 'patient_address.csv', 'loc_bd96c77fe217', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_af6d42adb096', 'correction', 'patient_address.csv', 'loc_af6d42adb096', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_19ed6ce51806', 'correction', 'patient_address.csv', 'loc_19ed6ce51806', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5a93771dfbbf', 'correction', 'patient_address.csv', 'loc_5a93771dfbbf', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0604bdf6a454', 'correction', 'patient_address.csv', 'loc_0604bdf6a454', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0604bdf6a454', 'correction', 'patient_address.csv', 'loc_0604bdf6a454', 'CORR-10', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6a308efaf230', 'correction', 'patient_address.csv', 'loc_6a308efaf230', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_455f0e181fb8', 'correction', 'patient_address.csv', 'loc_455f0e181fb8', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_91f28d2a0b2f', 'correction', 'patient_address.csv', 'loc_91f28d2a0b2f', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fa15dccc39f8', 'correction', 'patient_address.csv', 'loc_fa15dccc39f8', 'CORR-10', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6f1ef4b92dfd', 'correction', 'patient_address.csv', 'loc_6f1ef4b92dfd', 'CORR-10', 'direccion_texto', NOW());

COMMIT;