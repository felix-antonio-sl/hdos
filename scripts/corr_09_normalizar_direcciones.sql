-- CORR-09: Normalización de direcciones de pacientes HODOM
-- Generado: 2026-04-07 17:10
-- Total: 480  |  Modificadas: 480  |  Sin cambio: 0

BEGIN;

-- ── Actualizaciones territorial.localizacion ────────────────────────

-- ORIG: TOMAS YAVAR PASAJE BULNES
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Bulnes S/N, Tomás Yavar' WHERE localizacion_id = 'loc_f1441479f75b';

-- ORIG: TRES ESQUINA DE CATO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tres Esquinas de Cato S/N', localidad = 'Tres Esquinas' WHERE localizacion_id = 'loc_99ce0d3a1050';

-- ORIG: AGUA BUENA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena S/N', localidad = 'Agua Buena' WHERE localizacion_id = 'loc_1754b26d8ea3';

-- ORIG: AGUA BUENA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena S/N', localidad = 'Agua Buena' WHERE localizacion_id = 'loc_8313778b0a73';

-- ORIG: AGUA BUENA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena S/N', localidad = 'Agua Buena' WHERE localizacion_id = 'loc_e0cbf82a59ed';

-- ORIG: BULI CASERIO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Buli, Caserio', localidad = 'Buli' WHERE localizacion_id = 'loc_91f5be444e33';

-- ORIG: BULI ESTACION
UPDATE territorial.localizacion SET direccion_texto = 'Sector Buli, Estacion', localidad = 'Buli' WHERE localizacion_id = 'loc_8c8ff430ef76';

-- ORIG: BULI ESTACION S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Buli, Estacion', localidad = 'Buli' WHERE localizacion_id = 'loc_eb6a6fb689e0';

-- ORIG: CHACAY
UPDATE territorial.localizacion SET direccion_texto = 'Sector Chacay S/N', localidad = 'Chacay' WHERE localizacion_id = 'loc_c84a4fc4e344';

-- ORIG: CHORRILLO IANSA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Chorrillo Iansa S/N', localidad = 'Chorrillo Iansa' WHERE localizacion_id = 'loc_46fe0d933123';

-- ORIG: Camino viejo virguin s/n (Tiuquilemu hacia el sur)
UPDATE territorial.localizacion SET direccion_texto = 'Camino Viejo Virguin S/n', referencia = 'Tiuquilemu hacia el sur' WHERE localizacion_id = 'loc_a0bb1260f658';

-- ORIG: EL ESPINAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Espinal S/N', localidad = 'El Espinal' WHERE localizacion_id = 'loc_b6b1edaa9b79';

-- ORIG: EL ESPINAL ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Espinal S/N', localidad = 'El Espinal' WHERE localizacion_id = 'loc_719b3a978b53';

-- ORIG: Estacion Ñiquen S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Estación Ñiquén S/N', localidad = 'Ñiquén' WHERE localizacion_id = 'loc_fb788d9f727b';

-- ORIG: HUENUTIL CENTRO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Huenutil, Centro', localidad = 'Huenutil' WHERE localizacion_id = 'loc_3f8f46395ab8';

-- ORIG: HUENUTIL LA CABRERIA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Huenutil, La Cabreria', localidad = 'Huenutil' WHERE localizacion_id = 'loc_ca3fddc63767';

-- ORIG: JP SUBERCASEUX 072 ÑIQUEN ESTACION
UPDATE territorial.localizacion SET direccion_texto = 'José Pedro Subercaseaux 072 Ñiquen Estacion' WHERE localizacion_id = 'loc_5746c6f7ace3';

-- ORIG: LA GLORIA ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Gloria S/N', localidad = 'La Gloria' WHERE localizacion_id = 'loc_d569361afc6f';

-- ORIG: LA GLORIA, ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Gloria S/N', localidad = 'La Gloria' WHERE localizacion_id = 'loc_4ac646a9c026';

-- ORIG: LAS ROSAS CHACAY
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Rosas, Chacay', localidad = 'Las Rosas' WHERE localizacion_id = 'loc_0fc42444301f';

-- ORIG: LAS ROSAS ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Rosas S/N', localidad = 'Las Rosas' WHERE localizacion_id = 'loc_e5e6499d6304';

-- ORIG: LO MELLADO S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Lo Mellado S/N', localidad = 'Lo Mellado' WHERE localizacion_id = 'loc_aa7470d1372d';

-- ORIG: LOS MAITENES, ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Los Maitenes' WHERE localizacion_id = 'loc_053092aef7eb';

-- ORIG: LOS MAITENES, ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Los Maitenes' WHERE localizacion_id = 'loc_db6feb1b879a';

-- ORIG: La Pitrilla, Chacay ( Casa esquina color azul)
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Pitrilla, Chacay', localidad = 'La Pitrilla', referencia = 'Casa esquina color azul' WHERE localizacion_id = 'loc_a8e8418865b0';

-- ORIG: PAQUE NORTE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Paque, Norte', localidad = 'Paque' WHERE localizacion_id = 'loc_8c01f411c473';

-- ORIG: PAQUE NORTE, ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Paque, Norte', localidad = 'Paque' WHERE localizacion_id = 'loc_c4dce71ee43f';

-- ORIG: PUERTAS DE VIRGUIN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Virhuín, Puertas de Virhuín S/N', localidad = 'Virhuín' WHERE localizacion_id = 'loc_b7705fbeeaa7';

-- ORIG: RANCHILLO TORRECILLAS KM 9
UPDATE territorial.localizacion SET direccion_texto = 'Sector Ranchillo, Torrecillas Km 9', localidad = 'Ranchillo' WHERE localizacion_id = 'loc_3df4e5f1f60f';

-- ORIG: SAN FERNANDO DE ZEMITE
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Fernando, De Zemite', localidad = 'San Fernando' WHERE localizacion_id = 'loc_8b7b173bb88e';

-- ORIG: SAN JORGE SECTOR EL RINCON
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Jorge, Sector el Rincon', localidad = 'San Jorge' WHERE localizacion_id = 'loc_daffa7e7ac1b';

-- ORIG: SAN JOSE, ZEMITA
UPDATE territorial.localizacion SET direccion_texto = 'Sector San José, Zemita', localidad = 'San José' WHERE localizacion_id = 'loc_737cdbe14fbc';

-- ORIG: SAN PEDRO DE ÑIQUEN S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Pedro de Ñiquén S/N', localidad = 'San Pedro de Ñiquén' WHERE localizacion_id = 'loc_bdddbbd7ae83';

-- ORIG: SECTOR LAS ROSAS, ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Rosas' WHERE localizacion_id = 'loc_5274e2669b06';

-- ORIG: TIUQUILEMU
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tiuquilemu S/N', localidad = 'Tiuquilemu' WHERE localizacion_id = 'loc_fba22de5ff1b';

-- ORIG: TIUQUILEMU
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tiuquilemu S/N', localidad = 'Tiuquilemu' WHERE localizacion_id = 'loc_e7b6e8f6d4db';

-- ORIG: TIUQUILEMU KM 1
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tiuquilemu, Km 1', localidad = 'Tiuquilemu' WHERE localizacion_id = 'loc_4143c120d1ed';

-- ORIG: TIUQUILEMU S/N (SAUCE HACIA ADENTRO 4 KM)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tiuquilemu S/N', localidad = 'Tiuquilemu', referencia = 'SAUCE HACIA ADENTRO 4 KM' WHERE localizacion_id = 'loc_0700353dabdf';

-- ORIG: VILLA CHACAY, CALLE LOS OLIVO CASA 30 , ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Calle Los Olivo Casa 30' WHERE localizacion_id = 'loc_b23900d05087';

-- ORIG: VIRGUIN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Virhuín S/N', localidad = 'Virhuín' WHERE localizacion_id = 'loc_6e7980d701c6';

-- ORIG: VIRGUIN CAMINO VIEJO
UPDATE territorial.localizacion SET direccion_texto = 'Virguin Camino Viejo' WHERE localizacion_id = 'loc_0015b41c6cfa';

-- ORIG: VIRGUIN KM
UPDATE territorial.localizacion SET direccion_texto = 'Sector Virhuín S/N', localidad = 'Virhuín' WHERE localizacion_id = 'loc_3df1a4156ac3';

-- ORIG: ZEMITA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Zemita S/N', localidad = 'Zemita' WHERE localizacion_id = 'loc_dc4cb1d8b4cb';

-- ORIG: ZEMITA EL PALO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Zemita, El Palo', localidad = 'Zemita' WHERE localizacion_id = 'loc_5ff2967431b4';

-- ORIG: ZEMITA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Zemita S/N', localidad = 'Zemita' WHERE localizacion_id = 'loc_60c59f71a76d';

-- ORIG: ZEMITA S/N, SAN FERNANDO
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Fernando, San Fernando', localidad = 'San Fernando' WHERE localizacion_id = 'loc_9c6746588769';

-- ORIG: ZEMITA, ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Zemita S/N', localidad = 'Zemita' WHERE localizacion_id = 'loc_3caebe001049';

-- ORIG: ÑIQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Ñiquén S/N', localidad = 'Ñiquén' WHERE localizacion_id = 'loc_ae07a314e4ca';

-- ORIG: ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble S/N' WHERE localizacion_id = 'loc_fe51e90903ca';

-- ORIG: 11 DE SEPTIEMBRE, LA LENGA
UPDATE territorial.localizacion SET direccion_texto = '11 de Septiembre, la Lenga' WHERE localizacion_id = 'loc_c41cc76fe4cd';

-- ORIG: 11 SEPT CIPRES 1132
UPDATE territorial.localizacion SET direccion_texto = '11 Sept Cipres 1132' WHERE localizacion_id = 'loc_79100519d152';

-- ORIG: 11 SEPT.LAS ENCINAS 0104
UPDATE territorial.localizacion SET direccion_texto = '11 Sept.las Encinas 0104' WHERE localizacion_id = 'loc_d1da335c4f68';

-- ORIG: 27 DE ABRIL H MONROY 0358
UPDATE territorial.localizacion SET direccion_texto = 'Calle 27 de Abril S/N, H Monroy 0358' WHERE localizacion_id = 'loc_183e1630c7e1';

-- ORIG: 27 DE ABRIL. PJE ROBERTO BUSTAMANTE 713
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Roberto Bustamante 713' WHERE localizacion_id = 'loc_460a714d621a';

-- ORIG: 5 DE ABRIL, VALLE HONDO
UPDATE territorial.localizacion SET direccion_texto = '5 de Abril, Valle Hondo' WHERE localizacion_id = 'loc_e1be519a51dc';

-- ORIG: ACACIAS 0166, POBLA. 11 DE SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'Acacias 0166, Pobla. 11 de Septiembre' WHERE localizacion_id = 'loc_49232f6828a5';

-- ORIG: AGUA BUENA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena S/N', localidad = 'Agua Buena' WHERE localizacion_id = 'loc_6c7ef5f83650';

-- ORIG: AGUA BUENA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena S/N', localidad = 'Agua Buena' WHERE localizacion_id = 'loc_72728c06941c';

-- ORIG: AGUA BUENA KM 10 S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena, Km 10', localidad = 'Agua Buena' WHERE localizacion_id = 'loc_adb39232003e';

-- ORIG: AGUA BUENA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena S/N', localidad = 'Agua Buena' WHERE localizacion_id = 'loc_b08bc31dda61';

-- ORIG: AGUA BUENA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena S/N', localidad = 'Agua Buena' WHERE localizacion_id = 'loc_f4a0c34592a8';

-- ORIG: AGUA BUENA S/N SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Agua Buena S/N', localidad = 'Agua Buena' WHERE localizacion_id = 'loc_d441bb241e32';

-- ORIG: ARTURO PRAT 130
UPDATE territorial.localizacion SET direccion_texto = 'Calle Arturo Prat 130' WHERE localizacion_id = 'loc_fa7996bdfd4e';

-- ORIG: Arturo Prat
UPDATE territorial.localizacion SET direccion_texto = 'Calle Arturo Prat S/N' WHERE localizacion_id = 'loc_e0efd220dd93';

-- ORIG: BALDOMERO SILVA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Baldomero Silva S/N' WHERE localizacion_id = 'loc_af7e6a243a57';

-- ORIG: BALDOMERO SILVA PSJE. LAS ROSAS 36
UPDATE territorial.localizacion SET direccion_texto = 'Calle Baldomero Silva S/N, Psje, las Rosas 36' WHERE localizacion_id = 'loc_b8e389f8152e';

-- ORIG: BALMACEDA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Balmaceda S/N' WHERE localizacion_id = 'loc_36f9a428e84d';

-- ORIG: BALMACEDA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Balmaceda S/N' WHERE localizacion_id = 'loc_84d0e1eae9e2';

-- ORIG: BALMACEDA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Balmaceda S/N' WHERE localizacion_id = 'loc_7b85bc2e8a4b';

-- ORIG: BALMACEDA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Balmaceda S/N' WHERE localizacion_id = 'loc_b85898aad317';

-- ORIG: BILBAO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao S/N' WHERE localizacion_id = 'loc_d23dc3f10ddc';

-- ORIG: BILBAO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao S/N' WHERE localizacion_id = 'loc_ab928cb5c0fb';

-- ORIG: BILBAO 0138
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao 0138' WHERE localizacion_id = 'loc_18cb59af5393';

-- ORIG: BILBAO 849
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao 849' WHERE localizacion_id = 'loc_3b3f7a4fa77c';

-- ORIG: BILBAO, VILLA PUESTA DEL SOL
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao S/N, Villa Puesta del Sol' WHERE localizacion_id = 'loc_c321e82a429f';

-- ORIG: BRASIL
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil S/N' WHERE localizacion_id = 'loc_229683bd44da';

-- ORIG: BRASIL 450, BLOCK 3 DEPTO 8
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil 450, Block 3 Depto 8' WHERE localizacion_id = 'loc_a50a446cbd40';

-- ORIG: BRASIL 48
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil 48' WHERE localizacion_id = 'loc_6ae831e7caf8';

-- ORIG: BRASIL ESQINA PRATT
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil S/N, Esqina Pratt' WHERE localizacion_id = 'loc_e3eff4fb6474';

-- ORIG: Balmaceda
UPDATE territorial.localizacion SET direccion_texto = 'Calle Balmaceda S/N' WHERE localizacion_id = 'loc_4cdda427b7bc';

-- ORIG: C. ORTIZ 0285, VILLA 27 DE ABRIL
UPDATE territorial.localizacion SET direccion_texto = 'C, Ortiz 0285, Villa 27 de Abril' WHERE localizacion_id = 'loc_095c64d1c765';

-- ORIG: CACHAPOAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cachapoal S/N', localidad = 'Cachapoal' WHERE localizacion_id = 'loc_5d35fc62dcef';

-- ORIG: CACHAPOAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cachapoal S/N', localidad = 'Cachapoal' WHERE localizacion_id = 'loc_e05eb90a7aef';

-- ORIG: CACHAPOAL ALTO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cachapoal, Alto', localidad = 'Cachapoal' WHERE localizacion_id = 'loc_5b86366c4e32';

-- ORIG: CALLE BRASIL
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil S/N' WHERE localizacion_id = 'loc_2098a8c7bb45';

-- ORIG: CALLE BRASIL
UPDATE territorial.localizacion SET direccion_texto = 'Calle Brasil S/N' WHERE localizacion_id = 'loc_a90a7271d2bb';

-- ORIG: CALLE MATTA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta S/N' WHERE localizacion_id = 'loc_8dd945eb297c';

-- ORIG: CALLE PUELMA 657 HOGAR PADRE PIO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma Hogar Padre Pio 657' WHERE localizacion_id = 'loc_f28c0e2b273a';

-- ORIG: CALLEJON LOS PALACIOS
UPDATE territorial.localizacion SET direccion_texto = 'Callejón Los Palacios S/N' WHERE localizacion_id = 'loc_e2dea8cea7e6';

-- ORIG: CAM SAN AGUSTIN KM 2
UPDATE territorial.localizacion SET direccion_texto = 'Camino a San Agustín KM 2' WHERE localizacion_id = 'loc_a1c46835fb6d';

-- ORIG: CAMINO A MONTE BLANCO PARCELA 5
UPDATE territorial.localizacion SET direccion_texto = 'Camino a Monte Blanco Parcela 5' WHERE localizacion_id = 'loc_81ae12a307fb';

-- ORIG: CAMINO A SAN AGUSTIN KM 1.5 LOS CIPRECES
UPDATE territorial.localizacion SET direccion_texto = 'Camino a San Agustin KM 1.5, Los Cipreces' WHERE localizacion_id = 'loc_3d575edacaed';

-- ORIG: CAMINO A SAN CAMILO KM 3.3
UPDATE territorial.localizacion SET direccion_texto = 'Camino a San Camilo KM 3.3' WHERE localizacion_id = 'loc_8df72b80a3ef';

-- ORIG: CAMINO A SAN CAMILO KM2
UPDATE territorial.localizacion SET direccion_texto = 'Camino a San Camilo KM 2' WHERE localizacion_id = 'loc_4286a73f8125';

-- ORIG: CAMINO A TORRECILLAS KM 5, FUNDO SANTA ELENA
UPDATE territorial.localizacion SET direccion_texto = 'Camino a Torrecillas KM 5 , Fundo Santa Elena' WHERE localizacion_id = 'loc_1d1dfccbe4cf';

-- ORIG: CAMINO LAS TOMAS DE CACHAPOAL 1,5 KM
UPDATE territorial.localizacion SET direccion_texto = 'Camino las Tomas de Cachapoal 1,5 Km' WHERE localizacion_id = 'loc_d3190ee7d528';

-- ORIG: CAMINO RIVERA ÑUBLE, NUEVA ESPERANZA PSJE LAS PALMERAS
UPDATE territorial.localizacion SET direccion_texto = 'Camino Rivera Ñuble, Nueva Esperanza Psje las Palmeras' WHERE localizacion_id = 'loc_0643ee8098ab';

-- ORIG: CAMINO SAN AGUSTIN
UPDATE territorial.localizacion SET direccion_texto = 'Camino San Agustin' WHERE localizacion_id = 'loc_facebe420f7f';

-- ORIG: CAMINO SAN CAMILO KM 4 HOGAR JUAN BAUTISTA
UPDATE territorial.localizacion SET direccion_texto = 'Camino San Camilo KM 4, Hogar Juan Bautista' WHERE localizacion_id = 'loc_daa4f363dae9';

-- ORIG: CAMINO SAN FABIAN
UPDATE territorial.localizacion SET direccion_texto = 'Camino San Fabian' WHERE localizacion_id = 'loc_dead370bfca3';

-- ORIG: CARLOS URIBE 390 Puesta del Sol
UPDATE territorial.localizacion SET direccion_texto = 'Carlos Uribe 390 Puesta del Sol' WHERE localizacion_id = 'loc_ffa86f7fa28f';

-- ORIG: CARRERA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera S/N' WHERE localizacion_id = 'loc_9e4d6f67e105';

-- ORIG: CARRERA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera S/N' WHERE localizacion_id = 'loc_271e76615f11';

-- ORIG: CARRERA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera S/N' WHERE localizacion_id = 'loc_849f20da22fa';

-- ORIG: CARRERA 2021
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera 2021' WHERE localizacion_id = 'loc_46fc4c218e95';

-- ORIG: CARRERA 342
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera 342' WHERE localizacion_id = 'loc_2d75b50e77cd';

-- ORIG: CARRERA 422
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera 422' WHERE localizacion_id = 'loc_8b91c2491b01';

-- ORIG: CARRERA 781
UPDATE territorial.localizacion SET direccion_texto = 'Calle Carrera 781' WHERE localizacion_id = 'loc_0a558f81eab6';

-- ORIG: CASARES 2 BLOCK C DEPTO 33
UPDATE territorial.localizacion SET direccion_texto = 'Calle Casares 2, Block C Depto. 33' WHERE localizacion_id = 'loc_c0f957a26e37';

-- ORIG: CASARES, BLOCK D DEPARTAMENTO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Casares S/N, Block D Departamento' WHERE localizacion_id = 'loc_9aa659b3e3b3';

-- ORIG: CHACABUCO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Chacabuco S/N' WHERE localizacion_id = 'loc_fba42bcffa8a';

-- ORIG: CHACABUCO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Chacabuco S/N' WHERE localizacion_id = 'loc_bd2581e4ec04';

-- ORIG: COLOMBIA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Colombia S/N' WHERE localizacion_id = 'loc_b590f6e285a9';

-- ORIG: CONDOMINIO LA MANTAÑA CASA 25
UPDATE territorial.localizacion SET direccion_texto = 'Condominio La Montaña, Casa 25' WHERE localizacion_id = 'loc_37b3b657d73d';

-- ORIG: CUADRANPANGUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cuadrapangue S/N', localidad = 'Cuadrapangue' WHERE localizacion_id = 'loc_5672c6ba9483';

-- ORIG: CUADRAPANGUE CHICO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cuadrapangue Chico S/N', localidad = 'Cuadrapangue' WHERE localizacion_id = 'loc_08f2a9a4979d';

-- ORIG: CUADRAPANGUE CHICO S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cuadrapangue Chico S/N', localidad = 'Cuadrapangue' WHERE localizacion_id = 'loc_7fcad06a588d';

-- ORIG: CUADRAPANGUE S/N KM 7.5
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cuadrapangue, KM 7.5', localidad = 'Cuadrapangue' WHERE localizacion_id = 'loc_b5e3868c5dc2';

-- ORIG: Calle padre Eloy Parra
UPDATE territorial.localizacion SET direccion_texto = 'Calle Padre Eloy Parra S/N' WHERE localizacion_id = 'loc_3787ea089a21';

-- ORIG: Camino Trapiche millauquen Km 10, San Carlos.
UPDATE territorial.localizacion SET direccion_texto = 'Camino Trapiche Millauquen KM 10' WHERE localizacion_id = 'loc_20734391170f';

-- ORIG: DIEGO PORTALES
UPDATE territorial.localizacion SET direccion_texto = 'Calle Diego Portales S/N' WHERE localizacion_id = 'loc_38d037338a69';

-- ORIG: DIEGO PORTALES  ELEAM SAN PABLO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Diego Portales S/N, Eleam San Pablo' WHERE localizacion_id = 'loc_c3d01fcaebd0';

-- ORIG: DIEGO PORTALES 973
UPDATE territorial.localizacion SET direccion_texto = 'Calle Diego Portales 973' WHERE localizacion_id = 'loc_4ae522f750fd';

-- ORIG: DIEGO PORTALES 973
UPDATE territorial.localizacion SET direccion_texto = 'Calle Diego Portales 973' WHERE localizacion_id = 'loc_ad380250a7a4';

-- ORIG: DIEGO PORTALES HOGAR SAN PABLO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Diego Portales S/N, Hogar San Pablo' WHERE localizacion_id = 'loc_8620b9544b6a';

-- ORIG: EL ALAMO 1131, POBLACION 11 SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'El Alamo 1131, Poblacion 11 Septiembre' WHERE localizacion_id = 'loc_f65f414c9cf5';

-- ORIG: EL ALAMO, PASJE 1 CASA 0125 POBLACION 11 DE SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Casa 0125 Poblacion 11 de Septiembre 1' WHERE localizacion_id = 'loc_aa671d0ac639';

-- ORIG: EL ALBA, LAS ARBOLEDAS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Arboledas, Arboledas', localidad = 'Las Arboledas' WHERE localizacion_id = 'loc_0ec980a98634';

-- ORIG: EL AROMO
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Aromo S/N', localidad = 'El Aromo' WHERE localizacion_id = 'loc_3b92690ace14';

-- ORIG: EL AVELLANO 1011, POBL. 11 DE SEPT
UPDATE territorial.localizacion SET direccion_texto = 'El Avellano 1011, Población 11 de Sept' WHERE localizacion_id = 'loc_bb87d0f91a2a';

-- ORIG: EL AVELLANO 983 11 SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'El Avellano 983 11 Septiembre' WHERE localizacion_id = 'loc_ed6ee97c760d';

-- ORIG: EL CAPE
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Capé S/N', localidad = 'El Capé' WHERE localizacion_id = 'loc_f9d5f3f5457b';

-- ORIG: EL CAPE SN
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Capé S/N', localidad = 'El Capé' WHERE localizacion_id = 'loc_80f8124b946a';

-- ORIG: EL CARBON S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Carbón S/N', localidad = 'El Carbón' WHERE localizacion_id = 'loc_aad8af7b0fa2';

-- ORIG: EL CEREZO, POBL. 11 DE SEPT
UPDATE territorial.localizacion SET direccion_texto = 'El Cerezo, Población 11 de Sept' WHERE localizacion_id = 'loc_66caea271d20';

-- ORIG: EL CIPRES POB 11 DE SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'El Cipres Pob 11 de Septiembre' WHERE localizacion_id = 'loc_426d128a6e5d';

-- ORIG: EL LAUREL
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Laurel S/N', localidad = 'El Laurel' WHERE localizacion_id = 'loc_67ba994e394e';

-- ORIG: EL ORATORIO CASA 15
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Oratorio, Casa 15', localidad = 'El Oratorio' WHERE localizacion_id = 'loc_f6d155b27be0';

-- ORIG: EL PERAL DE NINQUIHUE S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Peral, De Ninquihue', localidad = 'El Peral' WHERE localizacion_id = 'loc_b0f796585050';

-- ORIG: EL PERAL, 11 DE SEPT
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Peral 11, De Sept', localidad = 'El Peral' WHERE localizacion_id = 'loc_65b7845636ad';

-- ORIG: EL PEUMO
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Peumo S/N', localidad = 'El Peumo' WHERE localizacion_id = 'loc_30ccb13f5655';

-- ORIG: EL PEUMO 11 DE SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Peumo 11, De Septiembre', localidad = 'El Peumo' WHERE localizacion_id = 'loc_03c8e30acbfa';

-- ORIG: EL ROBLE
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Roble S/N', localidad = 'El Roble' WHERE localizacion_id = 'loc_2d1083755a1e';

-- ORIG: EL ROBLE 104
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Roble 104', localidad = 'El Roble' WHERE localizacion_id = 'loc_a8c2fcdf3708';

-- ORIG: EL SAUCE
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Sauce S/N', localidad = 'El Sauce' WHERE localizacion_id = 'loc_3473bc14bd9f';

-- ORIG: EL SAUCE KM 12.5
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Sauce, Km 12.5', localidad = 'El Sauce' WHERE localizacion_id = 'loc_bd2918c99bef';

-- ORIG: EL SAUCE S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Sauce S/N', localidad = 'El Sauce' WHERE localizacion_id = 'loc_42274be863a4';

-- ORIG: EL SAUCE S/N KM 11.5
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Sauce S/N', localidad = 'El Sauce' WHERE localizacion_id = 'loc_e949fb969335';

-- ORIG: EL SAUCE S/N SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Sauce S/N', localidad = 'El Sauce' WHERE localizacion_id = 'loc_7677f937ac23';

-- ORIG: EL SOL, 11 DE SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'El Sol, 11 de Septiembre' WHERE localizacion_id = 'loc_83b9025df4d4';

-- ORIG: EL TORREON
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Torreón S/N', localidad = 'El Torreón' WHERE localizacion_id = 'loc_3af058537bc0';

-- ORIG: EL TORREON KM 12 PSJE. MARIA ENRIQUEZ 2
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Torreón, Km 12 Psje, Maria Enriquez 2', localidad = 'El Torreón' WHERE localizacion_id = 'loc_197d01cd750d';

-- ORIG: EL TORREON KM 15
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Torreón, Km 15', localidad = 'El Torreón' WHERE localizacion_id = 'loc_86629abfd6ed';

-- ORIG: EL TORREON NINQUIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Torreón, Ninquihue', localidad = 'El Torreón' WHERE localizacion_id = 'loc_3107818e1fed';

-- ORIG: ELEAM AMOR DE FAMILIA
UPDATE territorial.localizacion SET direccion_texto = 'Eleam Amor de Familia' WHERE localizacion_id = 'loc_343e2a128e4f';

-- ORIG: ELEAM NUEVA VIDA CAMINO A SAN CAMILO
UPDATE territorial.localizacion SET direccion_texto = 'Eleam Nueva Vida Camino a San Camilo' WHERE localizacion_id = 'loc_f0a4f5025ecf';

-- ORIG: ELEAM NUEVO AMANECER
UPDATE territorial.localizacion SET direccion_texto = 'Eleam Nuevo Amanecer' WHERE localizacion_id = 'loc_c48e7004bf5c';

-- ORIG: ELEAM SAN AGUSTIN CAMINO A CAPE
UPDATE territorial.localizacion SET direccion_texto = 'Eleam San Agustin Camino a Cape' WHERE localizacion_id = 'loc_4226297b1497';

-- ORIG: ELEAM SAN AGUSTIN CAPE
UPDATE territorial.localizacion SET direccion_texto = 'Eleam San Agustin Cape' WHERE localizacion_id = 'loc_6f1d561cd0dc';

-- ORIG: FRANCISCO PEREIRA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Francisco Pereira S/N' WHERE localizacion_id = 'loc_fc5a17f0b021';

-- ORIG: FRANCISCO PUELMA 179 CASA 4
UPDATE territorial.localizacion SET direccion_texto = 'Calle Francisco Puelma 179, Casa 4' WHERE localizacion_id = 'loc_e65d1c34b484';

-- ORIG: FRANCISCO PUELMA 237
UPDATE territorial.localizacion SET direccion_texto = 'Calle Francisco Puelma 237' WHERE localizacion_id = 'loc_bc1a601475ac';

-- ORIG: FREIRE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire S/N' WHERE localizacion_id = 'loc_37aae9b329c6';

-- ORIG: FREIRE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire S/N' WHERE localizacion_id = 'loc_4c5149ceeda6';

-- ORIG: FREIRE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire S/N' WHERE localizacion_id = 'loc_88c88d8c632c';

-- ORIG: FREIRE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire S/N' WHERE localizacion_id = 'loc_04328271ed84';

-- ORIG: FREIRE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire S/N' WHERE localizacion_id = 'loc_19439d9409da';

-- ORIG: FREIRE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire S/N' WHERE localizacion_id = 'loc_4cc0c6dd8ea1';

-- ORIG: FREIRE 533
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire 533' WHERE localizacion_id = 'loc_a065df141777';

-- ORIG: GAONA KM 372
UPDATE territorial.localizacion SET direccion_texto = 'Sector Gaona, Km 372', localidad = 'Gaona' WHERE localizacion_id = 'loc_b905ee6de64c';

-- ORIG: GAONA, SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Gaona S/N', localidad = 'Gaona' WHERE localizacion_id = 'loc_ae2d53374121';

-- ORIG: GAZMURI
UPDATE territorial.localizacion SET direccion_texto = 'Calle Gazmuri S/N' WHERE localizacion_id = 'loc_575c43e05ed2';

-- ORIG: GAZMURI 866
UPDATE territorial.localizacion SET direccion_texto = 'Calle Gazmuri 866' WHERE localizacion_id = 'loc_d041706bab5f';

-- ORIG: GENERAL TENIENTE MERINO
UPDATE territorial.localizacion SET direccion_texto = 'Calle General Teniente Merino S/N' WHERE localizacion_id = 'loc_29a114dfa6a5';

-- ORIG: GENERAL VENEGAS 402
UPDATE territorial.localizacion SET direccion_texto = 'Calle General Venegas 402' WHERE localizacion_id = 'loc_e9cea29f9a1c';

-- ORIG: GENERAL VENEGAS 520
UPDATE territorial.localizacion SET direccion_texto = 'Calle General Venegas 520' WHERE localizacion_id = 'loc_e7bd19919dfc';

-- ORIG: GENERAL VENEGAS ESQUINA ITIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Calle General Venegas S/N, Esquina Itihue' WHERE localizacion_id = 'loc_69aef50699e2';

-- ORIG: GOLONDRINAS 0902 EL BOSQUE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Golondrinas 0902, Villa El Bosque' WHERE localizacion_id = 'loc_44d3294170b6';

-- ORIG: GRAL VENEGAS 520 GERIATRICO SCHALCHI
UPDATE territorial.localizacion SET direccion_texto = 'Calle General Venegas 520, Geriatrico Schalchi' WHERE localizacion_id = 'loc_62fe36b29185';

-- ORIG: HERNAN CORTES CONTRERAS
UPDATE territorial.localizacion SET direccion_texto = 'Calle Hernan Cortes Contreras S/N' WHERE localizacion_id = 'loc_bf16243e2b3e';

-- ORIG: HIOGAR BUEN PASTOR ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Hogar Buen Pastor, Ñuble S/N' WHERE localizacion_id = 'loc_41913fada705';

-- ORIG: HOGAR DE FAMILIA, SANTA ROSA NINQUIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Hogar de Familia, Santa Rosa Ninquihue' WHERE localizacion_id = 'loc_f6ec56bcd3b8';

-- ORIG: HOGAR NUEVA VIDA KM 2 SAN CAMILO
UPDATE territorial.localizacion SET direccion_texto = 'Hogar Nueva Vida Km 2 San Camilo' WHERE localizacion_id = 'loc_fae406188228';

-- ORIG: HOGAR PADRE PIO
UPDATE territorial.localizacion SET direccion_texto = 'Hogar Padre Pio' WHERE localizacion_id = 'loc_e475c5da297a';

-- ORIG: HOGAR PADRE PIO - PUELMA 657
UPDATE territorial.localizacion SET direccion_texto = 'Hogar Padre Pio - Puelma 657' WHERE localizacion_id = 'loc_5c4b1a196da2';

-- ORIG: HOGAR SAN CAMILO
UPDATE territorial.localizacion SET direccion_texto = 'Hogar San Camilo' WHERE localizacion_id = 'loc_d9f58f702451';

-- ORIG: Hogar amor de familia
UPDATE territorial.localizacion SET direccion_texto = 'Hogar Amor de Familia S/N' WHERE localizacion_id = 'loc_dd3faa726d59';

-- ORIG: INDEPENDENCIA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Independencia S/N' WHERE localizacion_id = 'loc_8ede28b01193';

-- ORIG: INDEPENDENCIA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Independencia S/N' WHERE localizacion_id = 'loc_4c62a0a7c146';

-- ORIG: INDEPENDENCIA 1215
UPDATE territorial.localizacion SET direccion_texto = 'Calle Independencia 1215' WHERE localizacion_id = 'loc_8895301d2cca';

-- ORIG: INDEPENDENCIA 1553
UPDATE territorial.localizacion SET direccion_texto = 'Calle Independencia 1553' WHERE localizacion_id = 'loc_664677318f01';

-- ORIG: ITIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Itihue S/N', localidad = 'Itihue' WHERE localizacion_id = 'loc_5d136106ebff';

-- ORIG: ITIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Itihue S/N', localidad = 'Itihue' WHERE localizacion_id = 'loc_918f58764bd8';

-- ORIG: ITIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Itihue S/N', localidad = 'Itihue' WHERE localizacion_id = 'loc_22d4fa774d41';

-- ORIG: ITIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Itihue S/N', localidad = 'Itihue' WHERE localizacion_id = 'loc_dbae81ad3907';

-- ORIG: J MONTES LOS POETAS
UPDATE territorial.localizacion SET direccion_texto = 'José Montes los Poetas' WHERE localizacion_id = 'loc_b2c026f14991';

-- ORIG: JOAQUIN DEL PINO 763
UPDATE territorial.localizacion SET direccion_texto = 'Calle Joaquin del Pino 763' WHERE localizacion_id = 'loc_7b4c2a791ed9';

-- ORIG: JUNQUILLO ( 6 CUADRAS ANTES DEL COLEGIO)
UPDATE territorial.localizacion SET direccion_texto = 'Sector Junquillo S/N', localidad = 'Junquillo', referencia = '6 CUADRAS ANTES DEL COLEGIO' WHERE localizacion_id = 'loc_738263382135';

-- ORIG: JUNQUILLO S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Junquillo S/N', localidad = 'Junquillo' WHERE localizacion_id = 'loc_b9f52c9ab0dc';

-- ORIG: Joaquin del Pino 368
UPDATE territorial.localizacion SET direccion_texto = 'Calle Joaquin del Pino 368' WHERE localizacion_id = 'loc_23e072a1866b';

-- ORIG: L C MARTINEZ 051
UPDATE territorial.localizacion SET direccion_texto = 'Calle Luis Cruz Martinez 051' WHERE localizacion_id = 'loc_4a3cefa1212a';

-- ORIG: LA HIGUERA 874
UPDATE territorial.localizacion SET direccion_texto = 'Calle La Higuera 874' WHERE localizacion_id = 'loc_d83cd50a7f8a';

-- ORIG: LA LUNA, VILLA NUEVA VIDA
UPDATE territorial.localizacion SET direccion_texto = 'La Luna, Villa Nueva Vida' WHERE localizacion_id = 'loc_2d6b77c40e42';

-- ORIG: LA PITRILLA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Pitrilla S/N', localidad = 'La Pitrilla' WHERE localizacion_id = 'loc_55c9b6dd322b';

-- ORIG: LA RIBERA
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Ribera S/N', localidad = 'La Ribera' WHERE localizacion_id = 'loc_b2a5c4a5d326';

-- ORIG: LA RIBERA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Ribera S/N', localidad = 'La Ribera' WHERE localizacion_id = 'loc_1de28784f720';

-- ORIG: LA RIVERA
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Ribera S/N', localidad = 'La Ribera' WHERE localizacion_id = 'loc_2c37e07215ac';

-- ORIG: LAGOS DE CHILE, RIÑIHUE 549
UPDATE territorial.localizacion SET direccion_texto = 'Lagos de Chile, Riñihue 549' WHERE localizacion_id = 'loc_7cdf285a906f';

-- ORIG: LAGOS DE CHILE, T. LOS S.
UPDATE territorial.localizacion SET direccion_texto = 'Lagos de Chile, T, los S' WHERE localizacion_id = 'loc_b007c213d2f7';

-- ORIG: LAR ARBOLEDAS
UPDATE territorial.localizacion SET direccion_texto = 'Villa Las Arboledas S/N' WHERE localizacion_id = 'loc_3e0e4622dac9';

-- ORIG: LAS ARBOLEDAS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Arboledas S/N', localidad = 'Las Arboledas' WHERE localizacion_id = 'loc_5f8e253e630d';

-- ORIG: LAS ARBOLEDAS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Arboledas S/N', localidad = 'Las Arboledas' WHERE localizacion_id = 'loc_90e9ab701a4e';

-- ORIG: LAS ARBOLEDAS CALLE LIBERTAD SN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Arboledas, Calle Libertad Sn', localidad = 'Las Arboledas' WHERE localizacion_id = 'loc_bdccd1987e86';

-- ORIG: LAS ARBOLEDAS PASAJE EL DURAZNO, CAMINO EL SAUCE
UPDATE territorial.localizacion SET direccion_texto = 'Las Arboledas Pasaje el Durazno, Camino el Sauce' WHERE localizacion_id = 'loc_4fa84b6e23a7';

-- ORIG: LAS ARBOLEDAS S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Arboledas S/N', localidad = 'Las Arboledas' WHERE localizacion_id = 'loc_fdf659e8c4bc';

-- ORIG: LAS ARBOLEDAS, PJE EL DURAZNO
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje El Durazno S/N, Villa Las Arboledas' WHERE localizacion_id = 'loc_6eae986b5b41';

-- ORIG: LAS MIRAS s/n
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Miras S/N', localidad = 'Las Miras' WHERE localizacion_id = 'loc_974e24f5305e';

-- ORIG: LAS NUBES  653, NUEVA VIDA
UPDATE territorial.localizacion SET direccion_texto = 'Las Nubes 653, Nueva Vida' WHERE localizacion_id = 'loc_d8c2451c193a';

-- ORIG: LAS ROSAS, CACHAPOAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Rosas, Cachapoal', localidad = 'Las Rosas' WHERE localizacion_id = 'loc_5d969c53d4e9';

-- ORIG: LAS TOMAS DE CACHAPOAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cachapoal, Las Tomas S/N', localidad = 'Cachapoal' WHERE localizacion_id = 'loc_ea3b12b5a32d';

-- ORIG: LAUREL 940 11 SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Laurel 940, Población 11 de Septiembre' WHERE localizacion_id = 'loc_239b4ba8745f';

-- ORIG: LAUTARO 1024
UPDATE territorial.localizacion SET direccion_texto = 'Calle Lautaro 1024' WHERE localizacion_id = 'loc_2c1ade76072e';

-- ORIG: LENGA
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Lenga S/N', localidad = 'La Lenga' WHERE localizacion_id = 'loc_8bd8041e30aa';

-- ORIG: LLAHUIMAVIDA KM 3.4
UPDATE territorial.localizacion SET direccion_texto = 'Sector Llahuimávida, Km 3.4', localidad = 'Llahuimávida' WHERE localizacion_id = 'loc_a1a02ab0f6ef';

-- ORIG: LLAHUIMAVIDA ORIENTE KM 2.6
UPDATE territorial.localizacion SET direccion_texto = 'Sector Llahuimávida, Oriente Km 2.6', localidad = 'Llahuimávida' WHERE localizacion_id = 'loc_91f4f1d30330';

-- ORIG: LLAHUIMAVIDA ORIENTE KM 3.2
UPDATE territorial.localizacion SET direccion_texto = 'Sector Llahuimávida, Oriente Km 3.2', localidad = 'Llahuimávida' WHERE localizacion_id = 'loc_73f83275b266';

-- ORIG: LLAHUIMAVIDA, SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Llahuimávida S/N', localidad = 'Llahuimávida' WHERE localizacion_id = 'loc_0064a30f91fe';

-- ORIG: LLANQUIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Llanquihue S/N' WHERE localizacion_id = 'loc_7df136e984a1';

-- ORIG: LLANQUIHUE 506, LAGOS DE CHILE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Llanquihue 506, Lagos de Chile, Villa Lagos de Chile' WHERE localizacion_id = 'loc_3d2b641661e2';

-- ORIG: LOS AROMOS 13
UPDATE territorial.localizacion SET direccion_texto = 'Sector Los Aromos 13', localidad = 'Los Aromos' WHERE localizacion_id = 'loc_eac996403102';

-- ORIG: LOS CARACOLITOS, VILLA SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Los Caracolitos, Villa San Carlos' WHERE localizacion_id = 'loc_72e5e92872a8';

-- ORIG: LOS CASTAÑOS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Los Castaños S/N', localidad = 'Los Castaños' WHERE localizacion_id = 'loc_e6c656351152';

-- ORIG: LOS CIPRES, POBL. 11 DE SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'Los Cipres, Población 11 de Septiembre' WHERE localizacion_id = 'loc_a769ca40de0b';

-- ORIG: LOS LIBERTADORES, SAN MARTIN
UPDATE territorial.localizacion SET direccion_texto = 'Calle Los Libertadores S/N, San Martín' WHERE localizacion_id = 'loc_c2bf5f84c8ee';

-- ORIG: LOS MAGNOLIOS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Los Magnolios S/N', localidad = 'Los Magnolios' WHERE localizacion_id = 'loc_f490aa9c0a9a';

-- ORIG: LOS MELLIZOS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Los Mellizos S/N', localidad = 'Los Mellizos' WHERE localizacion_id = 'loc_2da1db0e01e0';

-- ORIG: LOS NARANJOS LA RIVERA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Los Naranjos, La Rivera', localidad = 'Los Naranjos' WHERE localizacion_id = 'loc_17b2759d1a39';

-- ORIG: LOS PIDENES, VILLA EL BOSQUE
UPDATE territorial.localizacion SET direccion_texto = 'Los Pidenes, Villa el Bosque' WHERE localizacion_id = 'loc_845f18cd99dc';

-- ORIG: LOS QUELTEHUES, VILLA EL BOSQUE
UPDATE territorial.localizacion SET direccion_texto = 'Los Queltehues, Villa el Bosque' WHERE localizacion_id = 'loc_b327dd71188d';

-- ORIG: LOS REGIDORES
UPDATE territorial.localizacion SET direccion_texto = 'Sector Los Regidores S/N', localidad = 'Los Regidores' WHERE localizacion_id = 'loc_563873c8ad8e';

-- ORIG: LUIS ACEVEDO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Luis Acevedo S/N' WHERE localizacion_id = 'loc_7bc77516af27';

-- ORIG: LUIS ACEVEDO 07//
UPDATE territorial.localizacion SET direccion_texto = 'Calle Luis Acevedo 07' WHERE localizacion_id = 'loc_8689f6b713fe';

-- ORIG: LUIS CRUZ MARTINEZ
UPDATE territorial.localizacion SET direccion_texto = 'Calle Luis Cruz Martinez S/N' WHERE localizacion_id = 'loc_b70cdc3995c4';

-- ORIG: LUIS CRUZ MARTINEZ
UPDATE territorial.localizacion SET direccion_texto = 'Calle Luis Cruz Martinez S/N' WHERE localizacion_id = 'loc_29c73973d855';

-- ORIG: LURIN
UPDATE territorial.localizacion SET direccion_texto = 'Calle Lurin S/N' WHERE localizacion_id = 'loc_9edae02716b0';

-- ORIG: La unión, Ninquihue
UPDATE territorial.localizacion SET direccion_texto = 'Sector Ninquihue, Ninquihue', localidad = 'Ninquihue' WHERE localizacion_id = 'loc_1f5bfa3b579c';

-- ORIG: Las Garzas 1146, Población 11 de Septiembre, Villa el bosque
UPDATE territorial.localizacion SET direccion_texto = 'Las Garzas 1146, Población 11 de Septiembre, Villa El Bosque', localidad = 'Las Garzas' WHERE localizacion_id = 'loc_cc4040b649a7';

-- ORIG: Las arboledas, a 50 metros frente al colegio.
UPDATE territorial.localizacion SET direccion_texto = 'Villa Las Arboledas S/N' WHERE localizacion_id = 'loc_508175b0a050';

-- ORIG: Las dumas (12 kms aprox )
UPDATE territorial.localizacion SET direccion_texto = 'Sector Las Dumas S/N', localidad = 'Las Dumas', referencia = '12 kms aprox' WHERE localizacion_id = 'loc_76f8013f0f18';

-- ORIG: Los Magnolios, 11 Sept San Carlos.
UPDATE territorial.localizacion SET direccion_texto = 'Los Magnolios, 11 Sept San Carlos' WHERE localizacion_id = 'loc_4d0cc7f1dfa8';

-- ORIG: MAIPU
UPDATE territorial.localizacion SET direccion_texto = 'Calle Maipú S/N' WHERE localizacion_id = 'loc_efe2212c1cb2';

-- ORIG: MATTA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta S/N' WHERE localizacion_id = 'loc_1e44e9903a65';

-- ORIG: MATTA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta S/N' WHERE localizacion_id = 'loc_b8556ff86e50';

-- ORIG: MATTA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta S/N' WHERE localizacion_id = 'loc_2dfad16b66ce';

-- ORIG: MATTA 0696 LAGOS DE CHILE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta 0696, Villa Lagos de Chile' WHERE localizacion_id = 'loc_dedb98edd39c';

-- ORIG: MATTA 210
UPDATE territorial.localizacion SET direccion_texto = 'Calle Matta 210' WHERE localizacion_id = 'loc_c914cd356353';

-- ORIG: MEDARDO VENEGAS
UPDATE territorial.localizacion SET direccion_texto = 'Calle Medardo Venegas S/N' WHERE localizacion_id = 'loc_6d52773d5dd5';

-- ORIG: MILLAUQUEN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Millauquén S/N', localidad = 'Millauquén' WHERE localizacion_id = 'loc_a9a3ef7b6fad';

-- ORIG: MILLAUQUEN S/N  KM 17
UPDATE territorial.localizacion SET direccion_texto = 'Sector Millauquén S/N', localidad = 'Millauquén' WHERE localizacion_id = 'loc_a1245ae6206a';

-- ORIG: MONTE BLANCO KM 2,6 FRENTE HUERTO DE ARANDANOS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte Blanco, Km 2,6 Frente Huerto de Arandanos', localidad = 'Monte Blanco' WHERE localizacion_id = 'loc_477cf7e5f37b';

-- ORIG: MONTEBLANCO S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte Blanco S/N', localidad = 'Monte Blanco' WHERE localizacion_id = 'loc_2a7cb5e9ba7a';

-- ORIG: MONTEBLANCO, PARCELA 7
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte Blanco, Parcela 7', localidad = 'Monte Blanco' WHERE localizacion_id = 'loc_bc405f8f605d';

-- ORIG: MONTECILLO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Montecillo S/N', localidad = 'Montecillo' WHERE localizacion_id = 'loc_bda16c5d6831';

-- ORIG: MONTECILLO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Montecillo S/N', localidad = 'Montecillo' WHERE localizacion_id = 'loc_22a15c9b0cbd';

-- ORIG: MONTECILLO AGUA BUENAKM 1.6
UPDATE territorial.localizacion SET direccion_texto = 'Sector Montecillo, Agua Buena KM 1.6', localidad = 'Montecillo' WHERE localizacion_id = 'loc_7b3c7ac61c06';

-- ORIG: MONTECILLO KM 12
UPDATE territorial.localizacion SET direccion_texto = 'Sector Montecillo, KM 12', localidad = 'Montecillo' WHERE localizacion_id = 'loc_01293607e891';

-- ORIG: MUTICURA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Muticura S/N', localidad = 'Muticura' WHERE localizacion_id = 'loc_8971c622e758';

-- ORIG: MUTICURA   km 18 mano derecha antes de copa de agua los ibañez
UPDATE territorial.localizacion SET direccion_texto = 'Sector Muticura, Km 18', localidad = 'Muticura', referencia = 'mano derecha antes de copa de agua los ibañez' WHERE localizacion_id = 'loc_d59c632ced55';

-- ORIG: MUTICURA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Muticura S/N', localidad = 'Muticura' WHERE localizacion_id = 'loc_230f531855d4';

-- ORIG: MUTIPIN KM 8.5
UPDATE territorial.localizacion SET direccion_texto = 'Sector Mutupín, KM 8.5', localidad = 'Mutupín' WHERE localizacion_id = 'loc_1009f0cbb737';

-- ORIG: Monteleon El Sauce
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte León, El Sauce S/N', localidad = 'Monte León' WHERE localizacion_id = 'loc_7306460fbaaf';

-- ORIG: NAVOTAVO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Navotavo S/N' WHERE localizacion_id = 'loc_679d33a82b6a';

-- ORIG: NAVOTAVO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Navotavo S/N' WHERE localizacion_id = 'loc_13cbc02211cb';

-- ORIG: NAVOTAVO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Navotavo S/N' WHERE localizacion_id = 'loc_b85024f25631';

-- ORIG: NAVOTAVO 624
UPDATE territorial.localizacion SET direccion_texto = 'Calle Navotavo 624' WHERE localizacion_id = 'loc_1567b9d91e65';

-- ORIG: NAVOTAVO 672
UPDATE territorial.localizacion SET direccion_texto = 'Calle Navotavo 672' WHERE localizacion_id = 'loc_349177f4e83c';

-- ORIG: NINQUIHUE 0131 BOSQUES DE ALGARROBAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector Ninquihue 0131, Bosques de Algarrobal', localidad = 'Ninquihue' WHERE localizacion_id = 'loc_9c80e1cfb76b';

-- ORIG: NINQUIHUE KM 385 RESIDENCIA AMOR DE FAMILIA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Ninquihue, Km 385 Residencia Amor de Familia', localidad = 'Ninquihue' WHERE localizacion_id = 'loc_271928f7fb04';

-- ORIG: NUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble S/N' WHERE localizacion_id = 'loc_33f7a448429c';

-- ORIG: NVA ATARDECER BENICIO ARZOLA 127
UPDATE territorial.localizacion SET direccion_texto = 'Nueva Atardecer Benicio Arzola 127' WHERE localizacion_id = 'loc_5660df9e5418';

-- ORIG: O''HIGGINS
UPDATE territorial.localizacion SET direccion_texto = 'Calle O''Higgins S/N' WHERE localizacion_id = 'loc_20bdb5187b63';

-- ORIG: OHIGGINS
UPDATE territorial.localizacion SET direccion_texto = 'Calle O''Higgins S/N' WHERE localizacion_id = 'loc_fbd428701410';

-- ORIG: OHIGGINS
UPDATE territorial.localizacion SET direccion_texto = 'Calle O''Higgins S/N' WHERE localizacion_id = 'loc_3d861afbb17f';

-- ORIG: OHIGGINS
UPDATE territorial.localizacion SET direccion_texto = 'Calle O''Higgins S/N' WHERE localizacion_id = 'loc_8dfc0cf241ba';

-- ORIG: OHIGGINS
UPDATE territorial.localizacion SET direccion_texto = 'Calle O''Higgins S/N' WHERE localizacion_id = 'loc_8a9d09638815';

-- ORIG: OHIGGINS PASAJE COLO COLO
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Colo Colo S/N, Calle O''Higgins' WHERE localizacion_id = 'loc_31a1f1cdec65';

-- ORIG: OSSA 490
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ossa 490' WHERE localizacion_id = 'loc_734184c6712a';

-- ORIG: OSSA 53
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ossa 53' WHERE localizacion_id = 'loc_111b56b91cb9';

-- ORIG: OSSA 822
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ossa 822' WHERE localizacion_id = 'loc_27a05424932d';

-- ORIG: OSSA 833
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ossa 833' WHERE localizacion_id = 'loc_29baa15d2717';

-- ORIG: OSSA 859
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ossa 859' WHERE localizacion_id = 'loc_9a9b6e129962';

-- ORIG: P DEL SOL E ABUKALIL
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje E. Abukalil S/N, Villa Puesta del Sol' WHERE localizacion_id = 'loc_f42ce675ae48';

-- ORIG: P DEL SUR FREIRE 655
UPDATE territorial.localizacion SET direccion_texto = 'Villa Portal del Sur Freire 655' WHERE localizacion_id = 'loc_bdd00f78adcb';

-- ORIG: PADRE ELOY
UPDATE territorial.localizacion SET direccion_texto = 'Calle Padre Eloy S/N' WHERE localizacion_id = 'loc_fb808ea49b72';

-- ORIG: PASAJE BUIN
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Buin S/N' WHERE localizacion_id = 'loc_dc9d74522686';

-- ORIG: PASAJE GERMAN NORAMBUENA 602 VILLA SANTA MARIA
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje German Norambuena Villa Santa Maria 602' WHERE localizacion_id = 'loc_c872f3a0dbbd';

-- ORIG: PASAJE LOS CASTAÑOS POBLACION 11 DE SEPTIEMBRE
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Los Castaños Poblacion de Septiembre 11, Población 11 de Septiembre' WHERE localizacion_id = 'loc_acf12ef7a373';

-- ORIG: PASAJE SAN ANDRES, VILLA LA VIRGEN
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Andres S/N, Villa La Virgen' WHERE localizacion_id = 'loc_e55461f4ddd8';

-- ORIG: PEDRO LAGOS
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos S/N' WHERE localizacion_id = 'loc_f2f2c0963f4a';

-- ORIG: PEDRO LAGOS
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos S/N' WHERE localizacion_id = 'loc_fa15dccc39f8';

-- ORIG: PEDRO LAGOS 121
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos 121' WHERE localizacion_id = 'loc_526b97180bcd';

-- ORIG: PEDRO LAGOS 473
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos 473' WHERE localizacion_id = 'loc_91b5723fc01e';

-- ORIG: PEDRO LAGOS 717
UPDATE territorial.localizacion SET direccion_texto = 'Calle Pedro Lagos 717' WHERE localizacion_id = 'loc_ba14909278a6';

-- ORIG: PERDICES  VILLA EL BOSQUE
UPDATE territorial.localizacion SET direccion_texto = 'Perdices Villa el Bosque' WHERE localizacion_id = 'loc_94ed42232d55';

-- ORIG: PEUMO CHINO CAMINO TORECILLAS
UPDATE territorial.localizacion SET direccion_texto = 'Peumo Chino Camino Torecillas' WHERE localizacion_id = 'loc_a7e566f3b48b';

-- ORIG: PIEDRA REDONDA KIM 5 SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Piedra Redonda KM 5 San Carlos' WHERE localizacion_id = 'loc_981ac5bb1681';

-- ORIG: PJE. LAS HIGUERAS 888, 11 DE SEPT
UPDATE territorial.localizacion SET direccion_texto = 'Pje, las Higueras 888, 11 de Sept' WHERE localizacion_id = 'loc_a90db607ab81';

-- ORIG: PJE. MICHIMALONGO 184 / POBLACION ARAUCANIA
UPDATE territorial.localizacion SET direccion_texto = 'Pje, Michimalongo 184 / Poblacion Araucania' WHERE localizacion_id = 'loc_a37eb7512e1a';

-- ORIG: POB GRAL PARRA PSJE MATTA
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Matta S/N, Población General Parra' WHERE localizacion_id = 'loc_54610338be52';

-- ORIG: POBL. 11 DE SEPT.PJE. EL DURAZNO
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Durazno 11, De Sept.pje, el Durazno', localidad = 'El Durazno' WHERE localizacion_id = 'loc_215ca19a0739';

-- ORIG: POBL. 11 DE SEPTIEMBRE, PJE EL MAÑIO
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje El Mañio S/N, Población 11 de Septiembre' WHERE localizacion_id = 'loc_576bd6ef0bcf';

-- ORIG: POBL. EL ROBLE, EUGENIO AMPUERO
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Roble, Roble, Eugenio Ampuero', localidad = 'El Roble' WHERE localizacion_id = 'loc_e7c743124a83';

-- ORIG: POBL. ESMERALDA QUECHEREGUA 26
UPDATE territorial.localizacion SET direccion_texto = 'Pobl, Esmeralda Quecheregua 26' WHERE localizacion_id = 'loc_34605f281853';

-- ORIG: POBL. VALLE HONDO, PSJE EJERCITO DE CHILE
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Ejercito de Chile S/N, Población Valle Hondo' WHERE localizacion_id = 'loc_bbbb58b4f707';

-- ORIG: POBLACION 11 SEPTIEMBRE PSJ. EL BOLDO 955
UPDATE territorial.localizacion SET direccion_texto = 'Poblacion 11 Septiembre Psj, el Boldo 955' WHERE localizacion_id = 'loc_a11b5146d654';

-- ORIG: POBLACION TENIENTE MERINO VIA CENTRAL 035
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Vía Central 035, Población Teniente Merino' WHERE localizacion_id = 'loc_c2c5aae168bf';

-- ORIG: POBLACIÓN NUEVA ESPERANZA CALLE VIOLETA PARRA
UPDATE territorial.localizacion SET direccion_texto = 'Población Nueva Esperanza Calle Violeta Parra' WHERE localizacion_id = 'loc_7762c7481bff';

-- ORIG: POMUYETO, PARCELA 12
UPDATE territorial.localizacion SET direccion_texto = 'Sector Pomuyeto, Parcela 12', localidad = 'Pomuyeto' WHERE localizacion_id = 'loc_4a027b3e7af1';

-- ORIG: PORTAL DE LA LUNA, PTE ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Puente Ñuble S/N, Villa Portal de la Luna' WHERE localizacion_id = 'loc_63e2bcaa262b';

-- ORIG: PORTAL DEL SUR 2, FELIPE CUBILLOS 114
UPDATE territorial.localizacion SET direccion_texto = 'Portal del Sur 2, Felipe Cubillos 114' WHERE localizacion_id = 'loc_1b5749d4df9c';

-- ORIG: PORTAL DEL SUR PJE. GALIAS DIAZ RIFFO
UPDATE territorial.localizacion SET direccion_texto = 'Portal del Sur Pje, Galias Diaz Riffo' WHERE localizacion_id = 'loc_32877a116e02';

-- ORIG: PORTAL DEL SUR, MINA FRITZ
UPDATE territorial.localizacion SET direccion_texto = 'Portal del Sur, Mina Fritz' WHERE localizacion_id = 'loc_452a41d729c7';

-- ORIG: PORTAL DEL SUR, SILVIA SLIER
UPDATE territorial.localizacion SET direccion_texto = 'Portal del Sur, Silvia Slier' WHERE localizacion_id = 'loc_455f0e181fb8';

-- ORIG: PSJE. EL PROGRESO LAS ARBOLEDAS
UPDATE territorial.localizacion SET direccion_texto = 'Psje, el Progreso las Arboledas' WHERE localizacion_id = 'loc_333d96b5ff26';

-- ORIG: PSJE. RANCO 533 LAGOS DE CHILE
UPDATE territorial.localizacion SET direccion_texto = 'Psje, Ranco 533 Lagos de Chile' WHERE localizacion_id = 'loc_6a1bb208c0fe';

-- ORIG: PSJE. SIMON BOLIVAR 1069, VALLE HONDO
UPDATE territorial.localizacion SET direccion_texto = 'Psje, Simon Bolivar 1069, Valle Hondo' WHERE localizacion_id = 'loc_3728ec603b25';

-- ORIG: PUELMA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma S/N' WHERE localizacion_id = 'loc_ef412e6f165a';

-- ORIG: PUELMA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma S/N' WHERE localizacion_id = 'loc_1c7f21a29767';

-- ORIG: PUELMA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma S/N' WHERE localizacion_id = 'loc_b2c9aa1fdfa5';

-- ORIG: PUELMA 020 VILLA BAENA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Puelma 020, Villa Baena' WHERE localizacion_id = 'loc_a6ecbd184e22';

-- ORIG: PUESTA DEL SOL DEMETRIO ZUÑIGA
UPDATE territorial.localizacion SET direccion_texto = 'Puesta del Sol Demetrio Zuñiga' WHERE localizacion_id = 'loc_b97fdf7dae0b';

-- ORIG: PUYARAL 2.5 KM NORTE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Puyaral 2.5, Km Norte', localidad = 'Puyaral' WHERE localizacion_id = 'loc_3c939c42f4d5';

-- ORIG: PUYEHUE, LAGOS DE CHILE
UPDATE territorial.localizacion SET direccion_texto = 'Puyehue, Lagos de Chile' WHERE localizacion_id = 'loc_638947ff7d03';

-- ORIG: Pasaje Yungay, SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Yungay S/N' WHERE localizacion_id = 'loc_ea0ea6f91afb';

-- ORIG: Poblacion Valle Hondo, Psje 5 de Abril 941 ( calle Puelma )
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje De Abril 941 5, Población Valle Hondo', referencia = 'calle Puelma' WHERE localizacion_id = 'loc_d6592e4491fa';

-- ORIG: Portal del sur 1 - Psje Romina Irarrazaval 562
UPDATE territorial.localizacion SET direccion_texto = 'Portal del Sur 1 - Psje Romina Irarrazaval 562' WHERE localizacion_id = 'loc_a876a5afbf13';

-- ORIG: Psje La Estrella Villa Nueva Vida
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje La Estrella Villa Nueva Vida S/N' WHERE localizacion_id = 'loc_91f28d2a0b2f';

-- ORIG: Puesta del Sol, José Gómez
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje José Gómez S/N, Villa Puesta del Sol' WHERE localizacion_id = 'loc_450357608736';

-- ORIG: QUILELTO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Quilelto S/N', localidad = 'Quilelto' WHERE localizacion_id = 'loc_0dadca597d6e';

-- ORIG: QUILELTO, KM 5 CAMINO STA TERESA
UPDATE territorial.localizacion SET direccion_texto = 'Quilelto, KM 5, Camino Sta Teresa' WHERE localizacion_id = 'loc_61f5784e0a84';

-- ORIG: QUILELTO, LA ESTRELLA
UPDATE territorial.localizacion SET direccion_texto = 'Sector Quilelto, La Estrella', localidad = 'Quilelto' WHERE localizacion_id = 'loc_0fc707ec7f2d';

-- ORIG: QUILELTO, MANZANAL
UPDATE territorial.localizacion SET direccion_texto = 'Sector Quilelto, Manzanal', localidad = 'Quilelto' WHERE localizacion_id = 'loc_eaba32ec4f5d';

-- ORIG: QUINQUEHUA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Quinquegua S/N', localidad = 'Quinquegua' WHERE localizacion_id = 'loc_6ff3978ef720';

-- ORIG: RAMON DIAZ 0756 AIRES DE LAURIN
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ramon Diaz 0756, Villa Aires de Lurín' WHERE localizacion_id = 'loc_79fdf9c5135d';

-- ORIG: REYMAN 754
UPDATE territorial.localizacion SET direccion_texto = 'Calle Reyman 754' WHERE localizacion_id = 'loc_ffa96fd1750e';

-- ORIG: RIQUELME
UPDATE territorial.localizacion SET direccion_texto = 'Calle Riquelme S/N' WHERE localizacion_id = 'loc_f2c750d3fcdd';

-- ORIG: RIQUELME INTERIOR
UPDATE territorial.localizacion SET direccion_texto = 'Calle Riquelme S/N, Interior' WHERE localizacion_id = 'loc_57f338bf7ed0';

-- ORIG: RIVERA DE ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Ribera de Ñuble S/N', localidad = 'Ribera de Ñuble' WHERE localizacion_id = 'loc_971011892df1';

-- ORIG: ROBLE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble S/N' WHERE localizacion_id = 'loc_ec3c82664453';

-- ORIG: ROBLE 1075
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble 1075' WHERE localizacion_id = 'loc_e30cff3ae0bf';

-- ORIG: ROBLE 126 INTERIOR
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble 126, Interior' WHERE localizacion_id = 'loc_1b591e9fabaf';

-- ORIG: ROBLE 146 INTERIOR
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble 146, Interior' WHERE localizacion_id = 'loc_4553b9529783';

-- ORIG: ROBLE 224
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble 224' WHERE localizacion_id = 'loc_66ee50e03cb7';

-- ORIG: ROBLE, SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Calle Roble S/N' WHERE localizacion_id = 'loc_25115418cbef';

-- ORIG: Rauli
UPDATE territorial.localizacion SET direccion_texto = 'Sector Raulí S/N', localidad = 'Raulí' WHERE localizacion_id = 'loc_881e090845e5';

-- ORIG: Ribera de Ñuble S/N.
UPDATE territorial.localizacion SET direccion_texto = 'Sector Ribera de Ñuble S/N', localidad = 'Ribera de Ñuble' WHERE localizacion_id = 'loc_a7a55ba202b3';

-- ORIG: SAGENTO ALDEA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Sargento Aldea S/N' WHERE localizacion_id = 'loc_856a284b7df3';

-- ORIG: SAN AGUSTIN KM 2 ( POR RUTA 5 SUR, PASAR PUENTE)
UPDATE territorial.localizacion SET direccion_texto = 'Camino a San Agustín KM 2' WHERE localizacion_id = 'loc_fb3bdde5e92e';

-- ORIG: SAN CAMILO KM 2
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Camilo, Km 2', localidad = 'San Camilo' WHERE localizacion_id = 'loc_4cd5fad23730';

-- ORIG: SAN CAMILO PARCELA 2 KM 41
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Camilo, Parcela 2 Km 41', localidad = 'San Camilo' WHERE localizacion_id = 'loc_86f7b7975d7f';

-- ORIG: SAN CAMILO PARCELA 6
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Camilo, Parcela 6', localidad = 'San Camilo' WHERE localizacion_id = 'loc_59f5ebbe7439';

-- ORIG: SAN CAMILO, KM 1
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Camilo, Km 1', localidad = 'San Camilo' WHERE localizacion_id = 'loc_9d51dccce004';

-- ORIG: SAN JORGE ZEMITA
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Jorge, Zemita', localidad = 'San Jorge' WHERE localizacion_id = 'loc_badf048ad5f2';

-- ORIG: SAN JORGE,
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Jorge S/N', localidad = 'San Jorge' WHERE localizacion_id = 'loc_7af4e2735ebe';

-- ORIG: SAN JORGE, SECTOR EL TRANQUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Jorge, Sector el Tranque', localidad = 'San Jorge' WHERE localizacion_id = 'loc_8a5c0839aac9';

-- ORIG: SAN JOSE DE ZEMITA
UPDATE territorial.localizacion SET direccion_texto = 'Sector San José, De Zemita', localidad = 'San José' WHERE localizacion_id = 'loc_3f54d08a5558';

-- ORIG: SAN LUIS S/N  MILLAHUEQUEN
UPDATE territorial.localizacion SET direccion_texto = 'San Luis S/N Millahuequen' WHERE localizacion_id = 'loc_6ed0b61bce33';

-- ORIG: SAN MANUEL DE VERQUICO
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Manuel de Verquico S/N', localidad = 'Verquico' WHERE localizacion_id = 'loc_7c74ded6113c';

-- ORIG: SAN MIGUEL DE ABLEMO
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Miguel de Ablemo S/N', localidad = 'San Miguel de Ablemo' WHERE localizacion_id = 'loc_e32a8c842f91';

-- ORIG: SAN MOISES 1688 , VILA VIRGEN DEL CAMINO
UPDATE territorial.localizacion SET direccion_texto = 'San Moises 1688 , Vila Virgen del Camino' WHERE localizacion_id = 'loc_24dd33b872cc';

-- ORIG: SAN PEDRO DE LILAHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Pedro de Lilahue S/N', localidad = 'San Pedro de Lilahue' WHERE localizacion_id = 'loc_35c4b50b572a';

-- ORIG: SAN PEDRO LILAHUA C/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Pedro, Lilahua C/n', localidad = 'San Pedro' WHERE localizacion_id = 'loc_fab9ae2795e0';

-- ORIG: SAN PEDRO LILAHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Pedro Lilahue S/N', localidad = 'San Pedro Lilahue' WHERE localizacion_id = 'loc_eca63007fb86';

-- ORIG: SAN ROQUE, ÑIQUÉN
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Roque S/N', localidad = 'San Roque' WHERE localizacion_id = 'loc_073d53b73e84';

-- ORIG: SANTA FILOMENA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Santa Filomena S/N', localidad = 'Santa Filomena' WHERE localizacion_id = 'loc_488ce77dda5b';

-- ORIG: SANTA ISABEL DE NINQUIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Santa Isabel, De Ninquihue', localidad = 'Santa Isabel' WHERE localizacion_id = 'loc_e008cd057d21';

-- ORIG: SANTA ISABEL, SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Santa Isabel S/N', localidad = 'Santa Isabel' WHERE localizacion_id = 'loc_d9701f5c79b7';

-- ORIG: SANTA ROSA DE NINQUIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Santa Rosa, De Ninquihue', localidad = 'Santa Rosa' WHERE localizacion_id = 'loc_d208b7e32cbe';

-- ORIG: SANTA ROSA NINQUIHUE
UPDATE territorial.localizacion SET direccion_texto = 'Sector Santa Rosa, Ninquihue', localidad = 'Santa Rosa' WHERE localizacion_id = 'loc_1df4b40c9752';

-- ORIG: SARGENTO ALDEA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Sargento Aldea S/N' WHERE localizacion_id = 'loc_6f1ef4b92dfd';

-- ORIG: SARGENTO ALDEA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Sargento Aldea S/N' WHERE localizacion_id = 'loc_245d82ffef6d';

-- ORIG: SECTOR EL TRANQUE DE POMUYETO
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Tranque de Pomuyeto S/N', localidad = 'El Tranque de Pomuyeto' WHERE localizacion_id = 'loc_2452f3af87af';

-- ORIG: SECTOR IANSA, CHORILLO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Iansa, Chorrillo S/N', localidad = 'Iansa' WHERE localizacion_id = 'loc_a625f9710b86';

-- ORIG: SERRANO 19
UPDATE territorial.localizacion SET direccion_texto = 'Calle Serrano 19' WHERE localizacion_id = 'loc_26bf86c5a15e';

-- ORIG: TAMAS YAVAR
UPDATE territorial.localizacion SET direccion_texto = 'Calle Tomás Yavar S/N' WHERE localizacion_id = 'loc_a7b3093f3d67';

-- ORIG: TENIENTE MERINO V.CENTRAL 081
UPDATE territorial.localizacion SET direccion_texto = 'Calle Teniente Merino S/N, V.central 081' WHERE localizacion_id = 'loc_8363b3e1c5de';

-- ORIG: TIUQUILEMU
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tiuquilemu S/N', localidad = 'Tiuquilemu' WHERE localizacion_id = 'loc_df506cd3a61e';

-- ORIG: TIUQUILEMU, SIN NUMERO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tiuquilemu, Sin Numero', localidad = 'Tiuquilemu' WHERE localizacion_id = 'loc_0ec38c0bf7b2';

-- ORIG: TOMAS YAVAR
UPDATE territorial.localizacion SET direccion_texto = 'Calle Tomás Yavar S/N' WHERE localizacion_id = 'loc_caa7f6671e2d';

-- ORIG: TOMAS YAVAR
UPDATE territorial.localizacion SET direccion_texto = 'Calle Tomás Yavar S/N' WHERE localizacion_id = 'loc_175270023e60';

-- ORIG: TOMAS YAVAR
UPDATE territorial.localizacion SET direccion_texto = 'Calle Tomás Yavar S/N' WHERE localizacion_id = 'loc_d3104d6ad9b2';

-- ORIG: TOMAS YAVAR 111 ESQUINA FREIRE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Tomás Yavar 111, Esquina Freire' WHERE localizacion_id = 'loc_41c8b23415a7';

-- ORIG: TRES ESQUINA PASAJE LAS CAMELIAS
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Las Camelias S/N, Sector Tres Esquinas', localidad = 'Tres Esquinas' WHERE localizacion_id = 'loc_db669a12866d';

-- ORIG: TRES ESQUINAS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Tres Esquinas S/N', localidad = 'Tres Esquinas' WHERE localizacion_id = 'loc_359aacb855cc';

-- ORIG: TTE MERINO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Teniente Merino S/N' WHERE localizacion_id = 'loc_56a319f50685';

-- ORIG: TULIPANES 1343 VILLA LOS JARDINES
UPDATE territorial.localizacion SET direccion_texto = 'Tulipanes 1343 Villa los Jardines' WHERE localizacion_id = 'loc_5a9007b91fdf';

-- ORIG: Tehualda 997 pobl. Araucanía san Carlos
UPDATE territorial.localizacion SET direccion_texto = 'Tehualda 997 Pobl, Araucanía San Carlos' WHERE localizacion_id = 'loc_25fb6bc77cea';

-- ORIG: V NVA. VIDA, PSJE LUNA
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Luna S/N' WHERE localizacion_id = 'loc_90ea79c2aa2c';

-- ORIG: VALENTINA TERESHKOVA 0207 - AIRES DE LURIN
UPDATE territorial.localizacion SET direccion_texto = 'Calle Valentina Tereshkova 0207, - Aires de Lurin, Villa Aires de Lurín' WHERE localizacion_id = 'loc_ed3020cdad14';

-- ORIG: VARIANTE SAN AGUSTIN 523
UPDATE territorial.localizacion SET direccion_texto = 'Calle Variante San Agustin 523' WHERE localizacion_id = 'loc_fd979ab891ef';

-- ORIG: VERQICO S/N KM 6
UPDATE territorial.localizacion SET direccion_texto = 'Sector Verquico, KM 6', localidad = 'Verquico' WHERE localizacion_id = 'loc_0eb98b3b5a79';

-- ORIG: VERQUICO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Verquico S/N', localidad = 'Verquico' WHERE localizacion_id = 'loc_a852fa3f2cdb';

-- ORIG: VERQUICO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Verquico S/N', localidad = 'Verquico' WHERE localizacion_id = 'loc_f0d4bd6bf568';

-- ORIG: VERQUICO CAMINO A TRAPICHE KM 7
UPDATE territorial.localizacion SET direccion_texto = 'Verquico Camino a Trapiche KM 7' WHERE localizacion_id = 'loc_577645e6a983';

-- ORIG: VERQUICO S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Verquico S/N', localidad = 'Verquico' WHERE localizacion_id = 'loc_0bcae7140060';

-- ORIG: VERQUICO S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Verquico S/N', localidad = 'Verquico' WHERE localizacion_id = 'loc_3613f05c4169';

-- ORIG: VICUÑA MACKENA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna S/N' WHERE localizacion_id = 'loc_62231d9c2de4';

-- ORIG: VICUÑA MACKENNA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna S/N' WHERE localizacion_id = 'loc_efa464617213';

-- ORIG: VICUÑA MACKENNA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna S/N' WHERE localizacion_id = 'loc_c76c053c9aae';

-- ORIG: VICUÑA MACKENNA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna S/N' WHERE localizacion_id = 'loc_9929584f53bd';

-- ORIG: VICUÑA MACKENNA
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna S/N' WHERE localizacion_id = 'loc_76d7d4cf98db';

-- ORIG: VICUÑA MACKENNA 1315 ( CAMINO SAN FABIAN)
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 1315', referencia = 'CAMINO SAN FABIAN' WHERE localizacion_id = 'loc_b56727a2a140';

-- ORIG: VICUÑA MACKENNA 1334
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 1334' WHERE localizacion_id = 'loc_f414497840d5';

-- ORIG: VICUÑA MACKENNA 2660
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna 2660' WHERE localizacion_id = 'loc_b67675c0f76e';

-- ORIG: VILLA 27 DE ABRIL, PASAJE HUGO MONROY
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Hugo Monroy S/N' WHERE localizacion_id = 'loc_e22e03ccfd18';

-- ORIG: VILLA AIRES DE LURIN. CALLE MANUEL CONTRERAS
UPDATE territorial.localizacion SET direccion_texto = 'Calle Manuel Contreras S/N, Villa Aires de Lurín' WHERE localizacion_id = 'loc_4de834934748';

-- ORIG: VILLA EL BOSQUE PASAJE LAS PERDICES
UPDATE territorial.localizacion SET direccion_texto = 'Villa el Bosque Pasaje las Perdices' WHERE localizacion_id = 'loc_32c56bf91e3a';

-- ORIG: VILLA LA VIRGEN, PJE SAN MATEO
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Mateo S/N, Villa La Virgen' WHERE localizacion_id = 'loc_0dd83c742263';

-- ORIG: VILLA LAS AMERICAS, LOS ANDES
UPDATE territorial.localizacion SET direccion_texto = 'Villa las Americas, los Andes' WHERE localizacion_id = 'loc_1298164c189c';

-- ORIG: VILLA LAS AMERICAS, PASAJE LOS ANDES
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Los Andes S/N, Villa Las Américas' WHERE localizacion_id = 'loc_4bfefa0fa0c5';

-- ORIG: VILLA LAS AMERICAS, PJE BUIN
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Buin S/N, Villa Las Américas' WHERE localizacion_id = 'loc_73ff427c33a2';

-- ORIG: VILLA LOS ANDES, PSJE LONQUIMAY 178
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Lonquimay 178, Villa Los Andes' WHERE localizacion_id = 'loc_408873411022';

-- ORIG: VILLA LOS POETAS CALLE JORGE MONTES MORAGA
UPDATE territorial.localizacion SET direccion_texto = 'Villa los Poetas Calle Jorge Montes Moraga' WHERE localizacion_id = 'loc_e5f14c1cce0a';

-- ORIG: VILLA LOS POETAS MANUEL CONTRERAS PINCHEIRA
UPDATE territorial.localizacion SET direccion_texto = 'Villa los Poetas Manuel Contreras Pincheira' WHERE localizacion_id = 'loc_c6e304f9d27a';

-- ORIG: VILLA LOS POETAS, MARIO MOLINA CARO
UPDATE territorial.localizacion SET direccion_texto = 'Villa los Poetas, Mario Molina Caro' WHERE localizacion_id = 'loc_a1da6ccd1600';

-- ORIG: VILLA LOS POETAS, PJE MARIO MOLINA CARO
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Mario Molina Caro S/N, Villa Los Poetas' WHERE localizacion_id = 'loc_197be1570c20';

-- ORIG: VILLA NUEVA VIDA, EL SOL 693, SAN CARLOS
UPDATE territorial.localizacion SET direccion_texto = 'Villa Nueva Vida, el Sol 693' WHERE localizacion_id = 'loc_1cc88555a485';

-- ORIG: VILLA PORTAL DEL SUR, FELIPE CUBILLOS
UPDATE territorial.localizacion SET direccion_texto = 'Villa Portal del Sur, Felipe Cubillos' WHERE localizacion_id = 'loc_5379264473b8';

-- ORIG: VILLA PUESTA DEL SOL CALLE ELOY PARRA
UPDATE territorial.localizacion SET direccion_texto = 'Villa Puesta del Sol Calle Eloy Parra' WHERE localizacion_id = 'loc_01e314ad4c04';

-- ORIG: VILLA PUESTA DEL SOL PASAJE ABDIEL SEPULVEDA
UPDATE territorial.localizacion SET direccion_texto = 'Villa Puesta del Sol Pasaje Abdiel Sepulveda' WHERE localizacion_id = 'loc_b16250f15ecb';

-- ORIG: VILLA PUETA DEL SOL, CALLE BILBAO
UPDATE territorial.localizacion SET direccion_texto = 'Calle Bilbao S/N' WHERE localizacion_id = 'loc_1b1078f7bf57';

-- ORIG: VILLA VISIÓN MUNDIAL PASAJE AMIGO SIN FRONTERA
UPDATE territorial.localizacion SET direccion_texto = 'Villa Visión Mundial Pasaje Amigo sin Frontera' WHERE localizacion_id = 'loc_9c05b69084b5';

-- ORIG: VISTA CORDILLERA, LA PRIMAVERA S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Primavera S/N, Vista Cordillera', localidad = 'La Primavera' WHERE localizacion_id = 'loc_2a7b0dd0fb34';

-- ORIG: Vicuña Mackenna
UPDATE territorial.localizacion SET direccion_texto = 'Calle Vicuña Mackenna S/N' WHERE localizacion_id = 'loc_bdd3b0f74009';

-- ORIG: Villa Balmaceda
UPDATE territorial.localizacion SET direccion_texto = 'Villa Balmaceda S/N' WHERE localizacion_id = 'loc_6ec263b79ab1';

-- ORIG: Villa vision mundial psje Nuevo horizonte 0672
UPDATE territorial.localizacion SET direccion_texto = 'Villa Vision Mundial Psje Nuevo Horizonte 0672' WHERE localizacion_id = 'loc_58bb7547cd33';

-- ORIG: Visión mundial amigos sin frontera
UPDATE territorial.localizacion SET direccion_texto = 'Visión Mundial Amigos sin Frontera' WHERE localizacion_id = 'loc_f3d741c388c1';

-- ORIG: camino a trapiche km 10
UPDATE territorial.localizacion SET direccion_texto = 'Camino a Trapiche KM 10' WHERE localizacion_id = 'loc_c193be4f81a8';

-- ORIG: freire 1052
UPDATE territorial.localizacion SET direccion_texto = 'Calle Freire 1052' WHERE localizacion_id = 'loc_c031b6e6261a';

-- ORIG: independencia 1181
UPDATE territorial.localizacion SET direccion_texto = 'Calle Independencia 1181' WHERE localizacion_id = 'loc_31f0a3156cc5';

-- ORIG: independencia 982, san Carlos
UPDATE territorial.localizacion SET direccion_texto = 'Calle Independencia 982' WHERE localizacion_id = 'loc_d55e6d34f076';

-- ORIG: villa el bosque las perdices
UPDATE territorial.localizacion SET direccion_texto = 'Villa el Bosque las Perdices' WHERE localizacion_id = 'loc_2788ea6c035d';

-- ORIG: ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble S/N' WHERE localizacion_id = 'loc_f218a66c039b';

-- ORIG: ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble S/N' WHERE localizacion_id = 'loc_68f1681c4891';

-- ORIG: ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble S/N' WHERE localizacion_id = 'loc_b3b6379409a2';

-- ORIG: ÑUBLE ENTRE CARRERA Y ROBLE
UPDATE territorial.localizacion SET direccion_texto = 'Calle Ñuble S/N, Entre Carrera y Roble' WHERE localizacion_id = 'loc_a2e3adb987da';

-- ORIG: CAMINO A SAN FABIAN KM3 SECTOR EL CASTAÑO
UPDATE territorial.localizacion SET direccion_texto = 'Camino a San Fabian KM 3, Sector el Castaño' WHERE localizacion_id = 'loc_3f5408ad59e4';

-- ORIG: AV. PUENTE ÑUBLE 558 , SECTOR PUENTE ÑUBLE , SAN NICOLAS
UPDATE territorial.localizacion SET direccion_texto = 'Puente Ñuble 558' WHERE localizacion_id = 'loc_7f83f1085022';

-- ORIG: AVDA PTE ÑUBLE, VILLA LAS CAMELIAS, SAN NICOLAS
UPDATE territorial.localizacion SET direccion_texto = 'Avenida Pte Ñuble S/N' WHERE localizacion_id = 'loc_01706ab816f4';

-- ORIG: Avenida Pte Ñuble casa 28
UPDATE territorial.localizacion SET direccion_texto = 'Avenida Pte Ñuble Casa 28' WHERE localizacion_id = 'loc_6529546b258c';

-- ORIG: BAJO EL MEMBRILLO SN
UPDATE territorial.localizacion SET direccion_texto = 'Sector Bajo el Membrillo S/N', localidad = 'Bajo el Membrillo' WHERE localizacion_id = 'loc_37ca9fa4353d';

-- ORIG: C. SAN NICOLAS
UPDATE territorial.localizacion SET direccion_texto = 'C' WHERE localizacion_id = 'loc_1070a297845b';

-- ORIG: CAMINO A SANTA LAURA SN PUENTE ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Camino a Santa Laura S/N Puente Ñuble' WHERE localizacion_id = 'loc_a5ff7471d4f5';

-- ORIG: DADINCO
UPDATE territorial.localizacion SET direccion_texto = 'Sector Dadinco S/N', localidad = 'Dadinco' WHERE localizacion_id = 'loc_5614701cca5c';

-- ORIG: EL MANZANO S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Manzano S/N', localidad = 'El Manzano' WHERE localizacion_id = 'loc_2a7fe086e371';

-- ORIG: EL ORATORIO S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector El Oratorio S/N', localidad = 'El Oratorio' WHERE localizacion_id = 'loc_df17013b31a2';

-- ORIG: EL ORATORIO, COCHARCAS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Cocharcas, Io, Cocharcas', localidad = 'Cocharcas' WHERE localizacion_id = 'loc_26ddfee1472f';

-- ORIG: HUAMPANGUE KM 1
UPDATE territorial.localizacion SET direccion_texto = 'Sector Huampangue, KM 1', localidad = 'Huampangue' WHERE localizacion_id = 'loc_58471c0bf8a2';

-- ORIG: HUERTO BONITO 1CAMINO A SAN NICOLAS KM 1,5
UPDATE territorial.localizacion SET direccion_texto = 'Sector Huerto Bonito 1CAMINO, A San Nicolas Km 1,5', localidad = 'Huerto Bonito' WHERE localizacion_id = 'loc_406c1df3090b';

-- ORIG: LA PRIMAVERA
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Primavera S/N', localidad = 'La Primavera' WHERE localizacion_id = 'loc_ee538125cdf5';

-- ORIG: LA PRIMAVERA
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Primavera S/N', localidad = 'La Primavera' WHERE localizacion_id = 'loc_2517820aab3e';

-- ORIG: LA QUINTRALA
UPDATE territorial.localizacion SET direccion_texto = 'Sector La Quintrala S/N', localidad = 'La Quintrala' WHERE localizacion_id = 'loc_7758c7b1d31c';

-- ORIG: MONTE LEON S/N
UPDATE territorial.localizacion SET direccion_texto = 'Sector Monte León S/N', localidad = 'Monte León' WHERE localizacion_id = 'loc_7d815b57be26';

-- ORIG: NUEVA ESPERANZA, SAN NICOLAS
UPDATE territorial.localizacion SET direccion_texto = 'Nueva Esperanza' WHERE localizacion_id = 'loc_29d321e3b787';

-- ORIG: PJE OMEGA E 21 PORTAL DE LA LUNA
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Omega E Portal de la Luna 21, Villa Portal de la Luna' WHERE localizacion_id = 'loc_42605f696da8';

-- ORIG: POB ISMAEL MARTIN 36, SAN NICOLAS
UPDATE territorial.localizacion SET direccion_texto = 'Pob Ismael Martin 36' WHERE localizacion_id = 'loc_9b4c843c0fe7';

-- ORIG: POB. I. MARTINEZ CASA 13 B
UPDATE territorial.localizacion SET direccion_texto = 'Pob, I. Martinez Casa 13 B' WHERE localizacion_id = 'loc_a26b7338459d';

-- ORIG: POBALCIÓN MARTINEZ PASAJE PUENTE ÑUBLE, MARTA BRUNET
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Marta Brunet S/N, Población Ismael Martínez' WHERE localizacion_id = 'loc_49fe17ece465';

-- ORIG: PORTAL DE LA LUNA, PSJE LA ESTRELLA CASA 5
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje La Estrella Casa 5, Villa Portal de la Luna' WHERE localizacion_id = 'loc_d03cf0e44081';

-- ORIG: PTE ÑUBLE, VISTA BELLA
UPDATE territorial.localizacion SET direccion_texto = 'Puente Ñuble S/N' WHERE localizacion_id = 'loc_84c57a846d37';

-- ORIG: PUENTE ÑUBLE , ISMAEL MARTINEZ
UPDATE territorial.localizacion SET direccion_texto = 'Puente Ñuble S/N' WHERE localizacion_id = 'loc_4265bf465b7d';

-- ORIG: PUENTE ÑUBLE A 1 CUADRA DE LA POSTA
UPDATE territorial.localizacion SET direccion_texto = 'Puente Ñuble a Cuadra de la Posta 1' WHERE localizacion_id = 'loc_ff87f792c860';

-- ORIG: PUENTE ÑUBLE CAMINO VIEJO CASA 18
UPDATE territorial.localizacion SET direccion_texto = 'Puente Ñuble Camino Viejo Casa 18' WHERE localizacion_id = 'loc_c1dfc2e319ce';

-- ORIG: PUENTE ÑUBLE POBL ISMAEL MARTINEZ
UPDATE territorial.localizacion SET direccion_texto = 'Puente Ñuble Pobl Ismael Martinez S/N' WHERE localizacion_id = 'loc_ffdacb995f37';

-- ORIG: PUYARAL SAN NICOLAS
UPDATE territorial.localizacion SET direccion_texto = 'Sector Puyaral S/N', localidad = 'Puyaral' WHERE localizacion_id = 'loc_abb8e13d225e';

-- ORIG: Población Nuevo Amanecer, San Nicolas
UPDATE territorial.localizacion SET direccion_texto = 'Población Nuevo Amanecer' WHERE localizacion_id = 'loc_ab21b7cd739e';

-- ORIG: RUTA 5 SUR  PUENTE ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Ruta 5 Sur Puente Ñuble' WHERE localizacion_id = 'loc_6437cb4ced0f';

-- ORIG: SAN JORGE ZEMITA
UPDATE territorial.localizacion SET direccion_texto = 'Sector San Jorge, Zemita', localidad = 'San Jorge' WHERE localizacion_id = 'loc_2689b2782f71';

-- ORIG: VILLA ILLINOIS, PSJE ÑUBLE # 19, PUENTE ÑUBLE
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje Ñuble # 19' WHERE localizacion_id = 'loc_f437a69df36a';

-- ORIG: VILLA LOS CARACOLES, PASAJE LA UNION
UPDATE territorial.localizacion SET direccion_texto = 'Pasaje La Union S/N, Villa Los Caracoles' WHERE localizacion_id = 'loc_7357025e0774';

-- ── Proveniencia ────────────────────────────────────────────────────

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f1441479f75b', 'correction', 'corr_09_normalizar_direcciones', 'loc_f1441479f75b', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_99ce0d3a1050', 'correction', 'corr_09_normalizar_direcciones', 'loc_99ce0d3a1050', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_99ce0d3a1050', 'correction', 'corr_09_normalizar_direcciones', 'loc_99ce0d3a1050', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1754b26d8ea3', 'correction', 'corr_09_normalizar_direcciones', 'loc_1754b26d8ea3', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1754b26d8ea3', 'correction', 'corr_09_normalizar_direcciones', 'loc_1754b26d8ea3', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8313778b0a73', 'correction', 'corr_09_normalizar_direcciones', 'loc_8313778b0a73', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8313778b0a73', 'correction', 'corr_09_normalizar_direcciones', 'loc_8313778b0a73', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e0cbf82a59ed', 'correction', 'corr_09_normalizar_direcciones', 'loc_e0cbf82a59ed', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e0cbf82a59ed', 'correction', 'corr_09_normalizar_direcciones', 'loc_e0cbf82a59ed', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_91f5be444e33', 'correction', 'corr_09_normalizar_direcciones', 'loc_91f5be444e33', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_91f5be444e33', 'correction', 'corr_09_normalizar_direcciones', 'loc_91f5be444e33', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8c8ff430ef76', 'correction', 'corr_09_normalizar_direcciones', 'loc_8c8ff430ef76', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8c8ff430ef76', 'correction', 'corr_09_normalizar_direcciones', 'loc_8c8ff430ef76', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eb6a6fb689e0', 'correction', 'corr_09_normalizar_direcciones', 'loc_eb6a6fb689e0', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eb6a6fb689e0', 'correction', 'corr_09_normalizar_direcciones', 'loc_eb6a6fb689e0', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c84a4fc4e344', 'correction', 'corr_09_normalizar_direcciones', 'loc_c84a4fc4e344', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c84a4fc4e344', 'correction', 'corr_09_normalizar_direcciones', 'loc_c84a4fc4e344', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_46fe0d933123', 'correction', 'corr_09_normalizar_direcciones', 'loc_46fe0d933123', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_46fe0d933123', 'correction', 'corr_09_normalizar_direcciones', 'loc_46fe0d933123', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a0bb1260f658', 'correction', 'corr_09_normalizar_direcciones', 'loc_a0bb1260f658', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a0bb1260f658', 'correction', 'corr_09_normalizar_direcciones', 'loc_a0bb1260f658', 'CORR-09', 'referencia', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b6b1edaa9b79', 'correction', 'corr_09_normalizar_direcciones', 'loc_b6b1edaa9b79', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b6b1edaa9b79', 'correction', 'corr_09_normalizar_direcciones', 'loc_b6b1edaa9b79', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_719b3a978b53', 'correction', 'corr_09_normalizar_direcciones', 'loc_719b3a978b53', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_719b3a978b53', 'correction', 'corr_09_normalizar_direcciones', 'loc_719b3a978b53', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fb788d9f727b', 'correction', 'corr_09_normalizar_direcciones', 'loc_fb788d9f727b', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fb788d9f727b', 'correction', 'corr_09_normalizar_direcciones', 'loc_fb788d9f727b', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3f8f46395ab8', 'correction', 'corr_09_normalizar_direcciones', 'loc_3f8f46395ab8', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3f8f46395ab8', 'correction', 'corr_09_normalizar_direcciones', 'loc_3f8f46395ab8', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ca3fddc63767', 'correction', 'corr_09_normalizar_direcciones', 'loc_ca3fddc63767', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ca3fddc63767', 'correction', 'corr_09_normalizar_direcciones', 'loc_ca3fddc63767', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5746c6f7ace3', 'correction', 'corr_09_normalizar_direcciones', 'loc_5746c6f7ace3', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d569361afc6f', 'correction', 'corr_09_normalizar_direcciones', 'loc_d569361afc6f', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d569361afc6f', 'correction', 'corr_09_normalizar_direcciones', 'loc_d569361afc6f', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4ac646a9c026', 'correction', 'corr_09_normalizar_direcciones', 'loc_4ac646a9c026', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4ac646a9c026', 'correction', 'corr_09_normalizar_direcciones', 'loc_4ac646a9c026', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0fc42444301f', 'correction', 'corr_09_normalizar_direcciones', 'loc_0fc42444301f', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0fc42444301f', 'correction', 'corr_09_normalizar_direcciones', 'loc_0fc42444301f', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e5e6499d6304', 'correction', 'corr_09_normalizar_direcciones', 'loc_e5e6499d6304', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e5e6499d6304', 'correction', 'corr_09_normalizar_direcciones', 'loc_e5e6499d6304', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_aa7470d1372d', 'correction', 'corr_09_normalizar_direcciones', 'loc_aa7470d1372d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_aa7470d1372d', 'correction', 'corr_09_normalizar_direcciones', 'loc_aa7470d1372d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_053092aef7eb', 'correction', 'corr_09_normalizar_direcciones', 'loc_053092aef7eb', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_db6feb1b879a', 'correction', 'corr_09_normalizar_direcciones', 'loc_db6feb1b879a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a8e8418865b0', 'correction', 'corr_09_normalizar_direcciones', 'loc_a8e8418865b0', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a8e8418865b0', 'correction', 'corr_09_normalizar_direcciones', 'loc_a8e8418865b0', 'CORR-09', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a8e8418865b0', 'correction', 'corr_09_normalizar_direcciones', 'loc_a8e8418865b0', 'CORR-09', 'referencia', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8c01f411c473', 'correction', 'corr_09_normalizar_direcciones', 'loc_8c01f411c473', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8c01f411c473', 'correction', 'corr_09_normalizar_direcciones', 'loc_8c01f411c473', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c4dce71ee43f', 'correction', 'corr_09_normalizar_direcciones', 'loc_c4dce71ee43f', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c4dce71ee43f', 'correction', 'corr_09_normalizar_direcciones', 'loc_c4dce71ee43f', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b7705fbeeaa7', 'correction', 'corr_09_normalizar_direcciones', 'loc_b7705fbeeaa7', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b7705fbeeaa7', 'correction', 'corr_09_normalizar_direcciones', 'loc_b7705fbeeaa7', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3df4e5f1f60f', 'correction', 'corr_09_normalizar_direcciones', 'loc_3df4e5f1f60f', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3df4e5f1f60f', 'correction', 'corr_09_normalizar_direcciones', 'loc_3df4e5f1f60f', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8b7b173bb88e', 'correction', 'corr_09_normalizar_direcciones', 'loc_8b7b173bb88e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8b7b173bb88e', 'correction', 'corr_09_normalizar_direcciones', 'loc_8b7b173bb88e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_daffa7e7ac1b', 'correction', 'corr_09_normalizar_direcciones', 'loc_daffa7e7ac1b', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_daffa7e7ac1b', 'correction', 'corr_09_normalizar_direcciones', 'loc_daffa7e7ac1b', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_737cdbe14fbc', 'correction', 'corr_09_normalizar_direcciones', 'loc_737cdbe14fbc', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_737cdbe14fbc', 'correction', 'corr_09_normalizar_direcciones', 'loc_737cdbe14fbc', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bdddbbd7ae83', 'correction', 'corr_09_normalizar_direcciones', 'loc_bdddbbd7ae83', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bdddbbd7ae83', 'correction', 'corr_09_normalizar_direcciones', 'loc_bdddbbd7ae83', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5274e2669b06', 'correction', 'corr_09_normalizar_direcciones', 'loc_5274e2669b06', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fba22de5ff1b', 'correction', 'corr_09_normalizar_direcciones', 'loc_fba22de5ff1b', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fba22de5ff1b', 'correction', 'corr_09_normalizar_direcciones', 'loc_fba22de5ff1b', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e7b6e8f6d4db', 'correction', 'corr_09_normalizar_direcciones', 'loc_e7b6e8f6d4db', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e7b6e8f6d4db', 'correction', 'corr_09_normalizar_direcciones', 'loc_e7b6e8f6d4db', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4143c120d1ed', 'correction', 'corr_09_normalizar_direcciones', 'loc_4143c120d1ed', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4143c120d1ed', 'correction', 'corr_09_normalizar_direcciones', 'loc_4143c120d1ed', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0700353dabdf', 'correction', 'corr_09_normalizar_direcciones', 'loc_0700353dabdf', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0700353dabdf', 'correction', 'corr_09_normalizar_direcciones', 'loc_0700353dabdf', 'CORR-09', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0700353dabdf', 'correction', 'corr_09_normalizar_direcciones', 'loc_0700353dabdf', 'CORR-09', 'referencia', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b23900d05087', 'correction', 'corr_09_normalizar_direcciones', 'loc_b23900d05087', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6e7980d701c6', 'correction', 'corr_09_normalizar_direcciones', 'loc_6e7980d701c6', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6e7980d701c6', 'correction', 'corr_09_normalizar_direcciones', 'loc_6e7980d701c6', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0015b41c6cfa', 'correction', 'corr_09_normalizar_direcciones', 'loc_0015b41c6cfa', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3df1a4156ac3', 'correction', 'corr_09_normalizar_direcciones', 'loc_3df1a4156ac3', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3df1a4156ac3', 'correction', 'corr_09_normalizar_direcciones', 'loc_3df1a4156ac3', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_dc4cb1d8b4cb', 'correction', 'corr_09_normalizar_direcciones', 'loc_dc4cb1d8b4cb', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_dc4cb1d8b4cb', 'correction', 'corr_09_normalizar_direcciones', 'loc_dc4cb1d8b4cb', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5ff2967431b4', 'correction', 'corr_09_normalizar_direcciones', 'loc_5ff2967431b4', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5ff2967431b4', 'correction', 'corr_09_normalizar_direcciones', 'loc_5ff2967431b4', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_60c59f71a76d', 'correction', 'corr_09_normalizar_direcciones', 'loc_60c59f71a76d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_60c59f71a76d', 'correction', 'corr_09_normalizar_direcciones', 'loc_60c59f71a76d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9c6746588769', 'correction', 'corr_09_normalizar_direcciones', 'loc_9c6746588769', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9c6746588769', 'correction', 'corr_09_normalizar_direcciones', 'loc_9c6746588769', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3caebe001049', 'correction', 'corr_09_normalizar_direcciones', 'loc_3caebe001049', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3caebe001049', 'correction', 'corr_09_normalizar_direcciones', 'loc_3caebe001049', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ae07a314e4ca', 'correction', 'corr_09_normalizar_direcciones', 'loc_ae07a314e4ca', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ae07a314e4ca', 'correction', 'corr_09_normalizar_direcciones', 'loc_ae07a314e4ca', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fe51e90903ca', 'correction', 'corr_09_normalizar_direcciones', 'loc_fe51e90903ca', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c41cc76fe4cd', 'correction', 'corr_09_normalizar_direcciones', 'loc_c41cc76fe4cd', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_79100519d152', 'correction', 'corr_09_normalizar_direcciones', 'loc_79100519d152', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d1da335c4f68', 'correction', 'corr_09_normalizar_direcciones', 'loc_d1da335c4f68', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_183e1630c7e1', 'correction', 'corr_09_normalizar_direcciones', 'loc_183e1630c7e1', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_460a714d621a', 'correction', 'corr_09_normalizar_direcciones', 'loc_460a714d621a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e1be519a51dc', 'correction', 'corr_09_normalizar_direcciones', 'loc_e1be519a51dc', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_49232f6828a5', 'correction', 'corr_09_normalizar_direcciones', 'loc_49232f6828a5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6c7ef5f83650', 'correction', 'corr_09_normalizar_direcciones', 'loc_6c7ef5f83650', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6c7ef5f83650', 'correction', 'corr_09_normalizar_direcciones', 'loc_6c7ef5f83650', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_72728c06941c', 'correction', 'corr_09_normalizar_direcciones', 'loc_72728c06941c', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_72728c06941c', 'correction', 'corr_09_normalizar_direcciones', 'loc_72728c06941c', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_adb39232003e', 'correction', 'corr_09_normalizar_direcciones', 'loc_adb39232003e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_adb39232003e', 'correction', 'corr_09_normalizar_direcciones', 'loc_adb39232003e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b08bc31dda61', 'correction', 'corr_09_normalizar_direcciones', 'loc_b08bc31dda61', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b08bc31dda61', 'correction', 'corr_09_normalizar_direcciones', 'loc_b08bc31dda61', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f4a0c34592a8', 'correction', 'corr_09_normalizar_direcciones', 'loc_f4a0c34592a8', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f4a0c34592a8', 'correction', 'corr_09_normalizar_direcciones', 'loc_f4a0c34592a8', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d441bb241e32', 'correction', 'corr_09_normalizar_direcciones', 'loc_d441bb241e32', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d441bb241e32', 'correction', 'corr_09_normalizar_direcciones', 'loc_d441bb241e32', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fa7996bdfd4e', 'correction', 'corr_09_normalizar_direcciones', 'loc_fa7996bdfd4e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e0efd220dd93', 'correction', 'corr_09_normalizar_direcciones', 'loc_e0efd220dd93', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_af7e6a243a57', 'correction', 'corr_09_normalizar_direcciones', 'loc_af7e6a243a57', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b8e389f8152e', 'correction', 'corr_09_normalizar_direcciones', 'loc_b8e389f8152e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_36f9a428e84d', 'correction', 'corr_09_normalizar_direcciones', 'loc_36f9a428e84d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_84d0e1eae9e2', 'correction', 'corr_09_normalizar_direcciones', 'loc_84d0e1eae9e2', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7b85bc2e8a4b', 'correction', 'corr_09_normalizar_direcciones', 'loc_7b85bc2e8a4b', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b85898aad317', 'correction', 'corr_09_normalizar_direcciones', 'loc_b85898aad317', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d23dc3f10ddc', 'correction', 'corr_09_normalizar_direcciones', 'loc_d23dc3f10ddc', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ab928cb5c0fb', 'correction', 'corr_09_normalizar_direcciones', 'loc_ab928cb5c0fb', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_18cb59af5393', 'correction', 'corr_09_normalizar_direcciones', 'loc_18cb59af5393', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3b3f7a4fa77c', 'correction', 'corr_09_normalizar_direcciones', 'loc_3b3f7a4fa77c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c321e82a429f', 'correction', 'corr_09_normalizar_direcciones', 'loc_c321e82a429f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_229683bd44da', 'correction', 'corr_09_normalizar_direcciones', 'loc_229683bd44da', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a50a446cbd40', 'correction', 'corr_09_normalizar_direcciones', 'loc_a50a446cbd40', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6ae831e7caf8', 'correction', 'corr_09_normalizar_direcciones', 'loc_6ae831e7caf8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e3eff4fb6474', 'correction', 'corr_09_normalizar_direcciones', 'loc_e3eff4fb6474', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4cdda427b7bc', 'correction', 'corr_09_normalizar_direcciones', 'loc_4cdda427b7bc', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_095c64d1c765', 'correction', 'corr_09_normalizar_direcciones', 'loc_095c64d1c765', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5d35fc62dcef', 'correction', 'corr_09_normalizar_direcciones', 'loc_5d35fc62dcef', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5d35fc62dcef', 'correction', 'corr_09_normalizar_direcciones', 'loc_5d35fc62dcef', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e05eb90a7aef', 'correction', 'corr_09_normalizar_direcciones', 'loc_e05eb90a7aef', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e05eb90a7aef', 'correction', 'corr_09_normalizar_direcciones', 'loc_e05eb90a7aef', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5b86366c4e32', 'correction', 'corr_09_normalizar_direcciones', 'loc_5b86366c4e32', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5b86366c4e32', 'correction', 'corr_09_normalizar_direcciones', 'loc_5b86366c4e32', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2098a8c7bb45', 'correction', 'corr_09_normalizar_direcciones', 'loc_2098a8c7bb45', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a90a7271d2bb', 'correction', 'corr_09_normalizar_direcciones', 'loc_a90a7271d2bb', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8dd945eb297c', 'correction', 'corr_09_normalizar_direcciones', 'loc_8dd945eb297c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f28c0e2b273a', 'correction', 'corr_09_normalizar_direcciones', 'loc_f28c0e2b273a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e2dea8cea7e6', 'correction', 'corr_09_normalizar_direcciones', 'loc_e2dea8cea7e6', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a1c46835fb6d', 'correction', 'corr_09_normalizar_direcciones', 'loc_a1c46835fb6d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_81ae12a307fb', 'correction', 'corr_09_normalizar_direcciones', 'loc_81ae12a307fb', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3d575edacaed', 'correction', 'corr_09_normalizar_direcciones', 'loc_3d575edacaed', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8df72b80a3ef', 'correction', 'corr_09_normalizar_direcciones', 'loc_8df72b80a3ef', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4286a73f8125', 'correction', 'corr_09_normalizar_direcciones', 'loc_4286a73f8125', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1d1dfccbe4cf', 'correction', 'corr_09_normalizar_direcciones', 'loc_1d1dfccbe4cf', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d3190ee7d528', 'correction', 'corr_09_normalizar_direcciones', 'loc_d3190ee7d528', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0643ee8098ab', 'correction', 'corr_09_normalizar_direcciones', 'loc_0643ee8098ab', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_facebe420f7f', 'correction', 'corr_09_normalizar_direcciones', 'loc_facebe420f7f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_daa4f363dae9', 'correction', 'corr_09_normalizar_direcciones', 'loc_daa4f363dae9', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_dead370bfca3', 'correction', 'corr_09_normalizar_direcciones', 'loc_dead370bfca3', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ffa86f7fa28f', 'correction', 'corr_09_normalizar_direcciones', 'loc_ffa86f7fa28f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9e4d6f67e105', 'correction', 'corr_09_normalizar_direcciones', 'loc_9e4d6f67e105', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_271e76615f11', 'correction', 'corr_09_normalizar_direcciones', 'loc_271e76615f11', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_849f20da22fa', 'correction', 'corr_09_normalizar_direcciones', 'loc_849f20da22fa', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_46fc4c218e95', 'correction', 'corr_09_normalizar_direcciones', 'loc_46fc4c218e95', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2d75b50e77cd', 'correction', 'corr_09_normalizar_direcciones', 'loc_2d75b50e77cd', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8b91c2491b01', 'correction', 'corr_09_normalizar_direcciones', 'loc_8b91c2491b01', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0a558f81eab6', 'correction', 'corr_09_normalizar_direcciones', 'loc_0a558f81eab6', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c0f957a26e37', 'correction', 'corr_09_normalizar_direcciones', 'loc_c0f957a26e37', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9aa659b3e3b3', 'correction', 'corr_09_normalizar_direcciones', 'loc_9aa659b3e3b3', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fba42bcffa8a', 'correction', 'corr_09_normalizar_direcciones', 'loc_fba42bcffa8a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bd2581e4ec04', 'correction', 'corr_09_normalizar_direcciones', 'loc_bd2581e4ec04', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b590f6e285a9', 'correction', 'corr_09_normalizar_direcciones', 'loc_b590f6e285a9', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_37b3b657d73d', 'correction', 'corr_09_normalizar_direcciones', 'loc_37b3b657d73d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5672c6ba9483', 'correction', 'corr_09_normalizar_direcciones', 'loc_5672c6ba9483', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5672c6ba9483', 'correction', 'corr_09_normalizar_direcciones', 'loc_5672c6ba9483', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_08f2a9a4979d', 'correction', 'corr_09_normalizar_direcciones', 'loc_08f2a9a4979d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_08f2a9a4979d', 'correction', 'corr_09_normalizar_direcciones', 'loc_08f2a9a4979d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7fcad06a588d', 'correction', 'corr_09_normalizar_direcciones', 'loc_7fcad06a588d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7fcad06a588d', 'correction', 'corr_09_normalizar_direcciones', 'loc_7fcad06a588d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b5e3868c5dc2', 'correction', 'corr_09_normalizar_direcciones', 'loc_b5e3868c5dc2', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b5e3868c5dc2', 'correction', 'corr_09_normalizar_direcciones', 'loc_b5e3868c5dc2', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3787ea089a21', 'correction', 'corr_09_normalizar_direcciones', 'loc_3787ea089a21', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_20734391170f', 'correction', 'corr_09_normalizar_direcciones', 'loc_20734391170f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_38d037338a69', 'correction', 'corr_09_normalizar_direcciones', 'loc_38d037338a69', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c3d01fcaebd0', 'correction', 'corr_09_normalizar_direcciones', 'loc_c3d01fcaebd0', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4ae522f750fd', 'correction', 'corr_09_normalizar_direcciones', 'loc_4ae522f750fd', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ad380250a7a4', 'correction', 'corr_09_normalizar_direcciones', 'loc_ad380250a7a4', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8620b9544b6a', 'correction', 'corr_09_normalizar_direcciones', 'loc_8620b9544b6a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f65f414c9cf5', 'correction', 'corr_09_normalizar_direcciones', 'loc_f65f414c9cf5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_aa671d0ac639', 'correction', 'corr_09_normalizar_direcciones', 'loc_aa671d0ac639', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0ec980a98634', 'correction', 'corr_09_normalizar_direcciones', 'loc_0ec980a98634', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0ec980a98634', 'correction', 'corr_09_normalizar_direcciones', 'loc_0ec980a98634', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3b92690ace14', 'correction', 'corr_09_normalizar_direcciones', 'loc_3b92690ace14', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3b92690ace14', 'correction', 'corr_09_normalizar_direcciones', 'loc_3b92690ace14', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bb87d0f91a2a', 'correction', 'corr_09_normalizar_direcciones', 'loc_bb87d0f91a2a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ed6ee97c760d', 'correction', 'corr_09_normalizar_direcciones', 'loc_ed6ee97c760d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f9d5f3f5457b', 'correction', 'corr_09_normalizar_direcciones', 'loc_f9d5f3f5457b', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f9d5f3f5457b', 'correction', 'corr_09_normalizar_direcciones', 'loc_f9d5f3f5457b', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_80f8124b946a', 'correction', 'corr_09_normalizar_direcciones', 'loc_80f8124b946a', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_80f8124b946a', 'correction', 'corr_09_normalizar_direcciones', 'loc_80f8124b946a', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_aad8af7b0fa2', 'correction', 'corr_09_normalizar_direcciones', 'loc_aad8af7b0fa2', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_aad8af7b0fa2', 'correction', 'corr_09_normalizar_direcciones', 'loc_aad8af7b0fa2', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_66caea271d20', 'correction', 'corr_09_normalizar_direcciones', 'loc_66caea271d20', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_426d128a6e5d', 'correction', 'corr_09_normalizar_direcciones', 'loc_426d128a6e5d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_67ba994e394e', 'correction', 'corr_09_normalizar_direcciones', 'loc_67ba994e394e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_67ba994e394e', 'correction', 'corr_09_normalizar_direcciones', 'loc_67ba994e394e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f6d155b27be0', 'correction', 'corr_09_normalizar_direcciones', 'loc_f6d155b27be0', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f6d155b27be0', 'correction', 'corr_09_normalizar_direcciones', 'loc_f6d155b27be0', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b0f796585050', 'correction', 'corr_09_normalizar_direcciones', 'loc_b0f796585050', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b0f796585050', 'correction', 'corr_09_normalizar_direcciones', 'loc_b0f796585050', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_65b7845636ad', 'correction', 'corr_09_normalizar_direcciones', 'loc_65b7845636ad', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_65b7845636ad', 'correction', 'corr_09_normalizar_direcciones', 'loc_65b7845636ad', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_30ccb13f5655', 'correction', 'corr_09_normalizar_direcciones', 'loc_30ccb13f5655', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_30ccb13f5655', 'correction', 'corr_09_normalizar_direcciones', 'loc_30ccb13f5655', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_03c8e30acbfa', 'correction', 'corr_09_normalizar_direcciones', 'loc_03c8e30acbfa', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_03c8e30acbfa', 'correction', 'corr_09_normalizar_direcciones', 'loc_03c8e30acbfa', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2d1083755a1e', 'correction', 'corr_09_normalizar_direcciones', 'loc_2d1083755a1e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2d1083755a1e', 'correction', 'corr_09_normalizar_direcciones', 'loc_2d1083755a1e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a8c2fcdf3708', 'correction', 'corr_09_normalizar_direcciones', 'loc_a8c2fcdf3708', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a8c2fcdf3708', 'correction', 'corr_09_normalizar_direcciones', 'loc_a8c2fcdf3708', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3473bc14bd9f', 'correction', 'corr_09_normalizar_direcciones', 'loc_3473bc14bd9f', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3473bc14bd9f', 'correction', 'corr_09_normalizar_direcciones', 'loc_3473bc14bd9f', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bd2918c99bef', 'correction', 'corr_09_normalizar_direcciones', 'loc_bd2918c99bef', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bd2918c99bef', 'correction', 'corr_09_normalizar_direcciones', 'loc_bd2918c99bef', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_42274be863a4', 'correction', 'corr_09_normalizar_direcciones', 'loc_42274be863a4', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_42274be863a4', 'correction', 'corr_09_normalizar_direcciones', 'loc_42274be863a4', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e949fb969335', 'correction', 'corr_09_normalizar_direcciones', 'loc_e949fb969335', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e949fb969335', 'correction', 'corr_09_normalizar_direcciones', 'loc_e949fb969335', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7677f937ac23', 'correction', 'corr_09_normalizar_direcciones', 'loc_7677f937ac23', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7677f937ac23', 'correction', 'corr_09_normalizar_direcciones', 'loc_7677f937ac23', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_83b9025df4d4', 'correction', 'corr_09_normalizar_direcciones', 'loc_83b9025df4d4', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3af058537bc0', 'correction', 'corr_09_normalizar_direcciones', 'loc_3af058537bc0', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3af058537bc0', 'correction', 'corr_09_normalizar_direcciones', 'loc_3af058537bc0', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_197d01cd750d', 'correction', 'corr_09_normalizar_direcciones', 'loc_197d01cd750d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_197d01cd750d', 'correction', 'corr_09_normalizar_direcciones', 'loc_197d01cd750d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_86629abfd6ed', 'correction', 'corr_09_normalizar_direcciones', 'loc_86629abfd6ed', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_86629abfd6ed', 'correction', 'corr_09_normalizar_direcciones', 'loc_86629abfd6ed', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3107818e1fed', 'correction', 'corr_09_normalizar_direcciones', 'loc_3107818e1fed', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3107818e1fed', 'correction', 'corr_09_normalizar_direcciones', 'loc_3107818e1fed', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_343e2a128e4f', 'correction', 'corr_09_normalizar_direcciones', 'loc_343e2a128e4f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f0a4f5025ecf', 'correction', 'corr_09_normalizar_direcciones', 'loc_f0a4f5025ecf', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c48e7004bf5c', 'correction', 'corr_09_normalizar_direcciones', 'loc_c48e7004bf5c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4226297b1497', 'correction', 'corr_09_normalizar_direcciones', 'loc_4226297b1497', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6f1d561cd0dc', 'correction', 'corr_09_normalizar_direcciones', 'loc_6f1d561cd0dc', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fc5a17f0b021', 'correction', 'corr_09_normalizar_direcciones', 'loc_fc5a17f0b021', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e65d1c34b484', 'correction', 'corr_09_normalizar_direcciones', 'loc_e65d1c34b484', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bc1a601475ac', 'correction', 'corr_09_normalizar_direcciones', 'loc_bc1a601475ac', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_37aae9b329c6', 'correction', 'corr_09_normalizar_direcciones', 'loc_37aae9b329c6', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4c5149ceeda6', 'correction', 'corr_09_normalizar_direcciones', 'loc_4c5149ceeda6', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_88c88d8c632c', 'correction', 'corr_09_normalizar_direcciones', 'loc_88c88d8c632c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_04328271ed84', 'correction', 'corr_09_normalizar_direcciones', 'loc_04328271ed84', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_19439d9409da', 'correction', 'corr_09_normalizar_direcciones', 'loc_19439d9409da', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4cc0c6dd8ea1', 'correction', 'corr_09_normalizar_direcciones', 'loc_4cc0c6dd8ea1', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a065df141777', 'correction', 'corr_09_normalizar_direcciones', 'loc_a065df141777', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b905ee6de64c', 'correction', 'corr_09_normalizar_direcciones', 'loc_b905ee6de64c', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b905ee6de64c', 'correction', 'corr_09_normalizar_direcciones', 'loc_b905ee6de64c', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ae2d53374121', 'correction', 'corr_09_normalizar_direcciones', 'loc_ae2d53374121', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ae2d53374121', 'correction', 'corr_09_normalizar_direcciones', 'loc_ae2d53374121', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_575c43e05ed2', 'correction', 'corr_09_normalizar_direcciones', 'loc_575c43e05ed2', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d041706bab5f', 'correction', 'corr_09_normalizar_direcciones', 'loc_d041706bab5f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_29a114dfa6a5', 'correction', 'corr_09_normalizar_direcciones', 'loc_29a114dfa6a5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e9cea29f9a1c', 'correction', 'corr_09_normalizar_direcciones', 'loc_e9cea29f9a1c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e7bd19919dfc', 'correction', 'corr_09_normalizar_direcciones', 'loc_e7bd19919dfc', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_69aef50699e2', 'correction', 'corr_09_normalizar_direcciones', 'loc_69aef50699e2', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_44d3294170b6', 'correction', 'corr_09_normalizar_direcciones', 'loc_44d3294170b6', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_62fe36b29185', 'correction', 'corr_09_normalizar_direcciones', 'loc_62fe36b29185', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bf16243e2b3e', 'correction', 'corr_09_normalizar_direcciones', 'loc_bf16243e2b3e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_41913fada705', 'correction', 'corr_09_normalizar_direcciones', 'loc_41913fada705', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f6ec56bcd3b8', 'correction', 'corr_09_normalizar_direcciones', 'loc_f6ec56bcd3b8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fae406188228', 'correction', 'corr_09_normalizar_direcciones', 'loc_fae406188228', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e475c5da297a', 'correction', 'corr_09_normalizar_direcciones', 'loc_e475c5da297a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5c4b1a196da2', 'correction', 'corr_09_normalizar_direcciones', 'loc_5c4b1a196da2', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d9f58f702451', 'correction', 'corr_09_normalizar_direcciones', 'loc_d9f58f702451', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_dd3faa726d59', 'correction', 'corr_09_normalizar_direcciones', 'loc_dd3faa726d59', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8ede28b01193', 'correction', 'corr_09_normalizar_direcciones', 'loc_8ede28b01193', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4c62a0a7c146', 'correction', 'corr_09_normalizar_direcciones', 'loc_4c62a0a7c146', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8895301d2cca', 'correction', 'corr_09_normalizar_direcciones', 'loc_8895301d2cca', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_664677318f01', 'correction', 'corr_09_normalizar_direcciones', 'loc_664677318f01', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5d136106ebff', 'correction', 'corr_09_normalizar_direcciones', 'loc_5d136106ebff', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5d136106ebff', 'correction', 'corr_09_normalizar_direcciones', 'loc_5d136106ebff', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_918f58764bd8', 'correction', 'corr_09_normalizar_direcciones', 'loc_918f58764bd8', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_918f58764bd8', 'correction', 'corr_09_normalizar_direcciones', 'loc_918f58764bd8', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_22d4fa774d41', 'correction', 'corr_09_normalizar_direcciones', 'loc_22d4fa774d41', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_22d4fa774d41', 'correction', 'corr_09_normalizar_direcciones', 'loc_22d4fa774d41', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_dbae81ad3907', 'correction', 'corr_09_normalizar_direcciones', 'loc_dbae81ad3907', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_dbae81ad3907', 'correction', 'corr_09_normalizar_direcciones', 'loc_dbae81ad3907', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b2c026f14991', 'correction', 'corr_09_normalizar_direcciones', 'loc_b2c026f14991', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7b4c2a791ed9', 'correction', 'corr_09_normalizar_direcciones', 'loc_7b4c2a791ed9', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_738263382135', 'correction', 'corr_09_normalizar_direcciones', 'loc_738263382135', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_738263382135', 'correction', 'corr_09_normalizar_direcciones', 'loc_738263382135', 'CORR-09', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_738263382135', 'correction', 'corr_09_normalizar_direcciones', 'loc_738263382135', 'CORR-09', 'referencia', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b9f52c9ab0dc', 'correction', 'corr_09_normalizar_direcciones', 'loc_b9f52c9ab0dc', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b9f52c9ab0dc', 'correction', 'corr_09_normalizar_direcciones', 'loc_b9f52c9ab0dc', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_23e072a1866b', 'correction', 'corr_09_normalizar_direcciones', 'loc_23e072a1866b', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4a3cefa1212a', 'correction', 'corr_09_normalizar_direcciones', 'loc_4a3cefa1212a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d83cd50a7f8a', 'correction', 'corr_09_normalizar_direcciones', 'loc_d83cd50a7f8a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2d6b77c40e42', 'correction', 'corr_09_normalizar_direcciones', 'loc_2d6b77c40e42', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_55c9b6dd322b', 'correction', 'corr_09_normalizar_direcciones', 'loc_55c9b6dd322b', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_55c9b6dd322b', 'correction', 'corr_09_normalizar_direcciones', 'loc_55c9b6dd322b', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b2a5c4a5d326', 'correction', 'corr_09_normalizar_direcciones', 'loc_b2a5c4a5d326', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b2a5c4a5d326', 'correction', 'corr_09_normalizar_direcciones', 'loc_b2a5c4a5d326', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1de28784f720', 'correction', 'corr_09_normalizar_direcciones', 'loc_1de28784f720', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1de28784f720', 'correction', 'corr_09_normalizar_direcciones', 'loc_1de28784f720', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2c37e07215ac', 'correction', 'corr_09_normalizar_direcciones', 'loc_2c37e07215ac', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2c37e07215ac', 'correction', 'corr_09_normalizar_direcciones', 'loc_2c37e07215ac', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7cdf285a906f', 'correction', 'corr_09_normalizar_direcciones', 'loc_7cdf285a906f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b007c213d2f7', 'correction', 'corr_09_normalizar_direcciones', 'loc_b007c213d2f7', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3e0e4622dac9', 'correction', 'corr_09_normalizar_direcciones', 'loc_3e0e4622dac9', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5f8e253e630d', 'correction', 'corr_09_normalizar_direcciones', 'loc_5f8e253e630d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5f8e253e630d', 'correction', 'corr_09_normalizar_direcciones', 'loc_5f8e253e630d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_90e9ab701a4e', 'correction', 'corr_09_normalizar_direcciones', 'loc_90e9ab701a4e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_90e9ab701a4e', 'correction', 'corr_09_normalizar_direcciones', 'loc_90e9ab701a4e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bdccd1987e86', 'correction', 'corr_09_normalizar_direcciones', 'loc_bdccd1987e86', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bdccd1987e86', 'correction', 'corr_09_normalizar_direcciones', 'loc_bdccd1987e86', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4fa84b6e23a7', 'correction', 'corr_09_normalizar_direcciones', 'loc_4fa84b6e23a7', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fdf659e8c4bc', 'correction', 'corr_09_normalizar_direcciones', 'loc_fdf659e8c4bc', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fdf659e8c4bc', 'correction', 'corr_09_normalizar_direcciones', 'loc_fdf659e8c4bc', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6eae986b5b41', 'correction', 'corr_09_normalizar_direcciones', 'loc_6eae986b5b41', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_974e24f5305e', 'correction', 'corr_09_normalizar_direcciones', 'loc_974e24f5305e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_974e24f5305e', 'correction', 'corr_09_normalizar_direcciones', 'loc_974e24f5305e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d8c2451c193a', 'correction', 'corr_09_normalizar_direcciones', 'loc_d8c2451c193a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5d969c53d4e9', 'correction', 'corr_09_normalizar_direcciones', 'loc_5d969c53d4e9', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5d969c53d4e9', 'correction', 'corr_09_normalizar_direcciones', 'loc_5d969c53d4e9', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ea3b12b5a32d', 'correction', 'corr_09_normalizar_direcciones', 'loc_ea3b12b5a32d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ea3b12b5a32d', 'correction', 'corr_09_normalizar_direcciones', 'loc_ea3b12b5a32d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_239b4ba8745f', 'correction', 'corr_09_normalizar_direcciones', 'loc_239b4ba8745f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2c1ade76072e', 'correction', 'corr_09_normalizar_direcciones', 'loc_2c1ade76072e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8bd8041e30aa', 'correction', 'corr_09_normalizar_direcciones', 'loc_8bd8041e30aa', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8bd8041e30aa', 'correction', 'corr_09_normalizar_direcciones', 'loc_8bd8041e30aa', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a1a02ab0f6ef', 'correction', 'corr_09_normalizar_direcciones', 'loc_a1a02ab0f6ef', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a1a02ab0f6ef', 'correction', 'corr_09_normalizar_direcciones', 'loc_a1a02ab0f6ef', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_91f4f1d30330', 'correction', 'corr_09_normalizar_direcciones', 'loc_91f4f1d30330', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_91f4f1d30330', 'correction', 'corr_09_normalizar_direcciones', 'loc_91f4f1d30330', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_73f83275b266', 'correction', 'corr_09_normalizar_direcciones', 'loc_73f83275b266', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_73f83275b266', 'correction', 'corr_09_normalizar_direcciones', 'loc_73f83275b266', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0064a30f91fe', 'correction', 'corr_09_normalizar_direcciones', 'loc_0064a30f91fe', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0064a30f91fe', 'correction', 'corr_09_normalizar_direcciones', 'loc_0064a30f91fe', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7df136e984a1', 'correction', 'corr_09_normalizar_direcciones', 'loc_7df136e984a1', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3d2b641661e2', 'correction', 'corr_09_normalizar_direcciones', 'loc_3d2b641661e2', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eac996403102', 'correction', 'corr_09_normalizar_direcciones', 'loc_eac996403102', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eac996403102', 'correction', 'corr_09_normalizar_direcciones', 'loc_eac996403102', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_72e5e92872a8', 'correction', 'corr_09_normalizar_direcciones', 'loc_72e5e92872a8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e6c656351152', 'correction', 'corr_09_normalizar_direcciones', 'loc_e6c656351152', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e6c656351152', 'correction', 'corr_09_normalizar_direcciones', 'loc_e6c656351152', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a769ca40de0b', 'correction', 'corr_09_normalizar_direcciones', 'loc_a769ca40de0b', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c2bf5f84c8ee', 'correction', 'corr_09_normalizar_direcciones', 'loc_c2bf5f84c8ee', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f490aa9c0a9a', 'correction', 'corr_09_normalizar_direcciones', 'loc_f490aa9c0a9a', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f490aa9c0a9a', 'correction', 'corr_09_normalizar_direcciones', 'loc_f490aa9c0a9a', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2da1db0e01e0', 'correction', 'corr_09_normalizar_direcciones', 'loc_2da1db0e01e0', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2da1db0e01e0', 'correction', 'corr_09_normalizar_direcciones', 'loc_2da1db0e01e0', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_17b2759d1a39', 'correction', 'corr_09_normalizar_direcciones', 'loc_17b2759d1a39', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_17b2759d1a39', 'correction', 'corr_09_normalizar_direcciones', 'loc_17b2759d1a39', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_845f18cd99dc', 'correction', 'corr_09_normalizar_direcciones', 'loc_845f18cd99dc', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b327dd71188d', 'correction', 'corr_09_normalizar_direcciones', 'loc_b327dd71188d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_563873c8ad8e', 'correction', 'corr_09_normalizar_direcciones', 'loc_563873c8ad8e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_563873c8ad8e', 'correction', 'corr_09_normalizar_direcciones', 'loc_563873c8ad8e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7bc77516af27', 'correction', 'corr_09_normalizar_direcciones', 'loc_7bc77516af27', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8689f6b713fe', 'correction', 'corr_09_normalizar_direcciones', 'loc_8689f6b713fe', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b70cdc3995c4', 'correction', 'corr_09_normalizar_direcciones', 'loc_b70cdc3995c4', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_29c73973d855', 'correction', 'corr_09_normalizar_direcciones', 'loc_29c73973d855', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9edae02716b0', 'correction', 'corr_09_normalizar_direcciones', 'loc_9edae02716b0', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1f5bfa3b579c', 'correction', 'corr_09_normalizar_direcciones', 'loc_1f5bfa3b579c', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1f5bfa3b579c', 'correction', 'corr_09_normalizar_direcciones', 'loc_1f5bfa3b579c', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_cc4040b649a7', 'correction', 'corr_09_normalizar_direcciones', 'loc_cc4040b649a7', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_cc4040b649a7', 'correction', 'corr_09_normalizar_direcciones', 'loc_cc4040b649a7', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_508175b0a050', 'correction', 'corr_09_normalizar_direcciones', 'loc_508175b0a050', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_76f8013f0f18', 'correction', 'corr_09_normalizar_direcciones', 'loc_76f8013f0f18', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_76f8013f0f18', 'correction', 'corr_09_normalizar_direcciones', 'loc_76f8013f0f18', 'CORR-09', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_76f8013f0f18', 'correction', 'corr_09_normalizar_direcciones', 'loc_76f8013f0f18', 'CORR-09', 'referencia', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4d0cc7f1dfa8', 'correction', 'corr_09_normalizar_direcciones', 'loc_4d0cc7f1dfa8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_efe2212c1cb2', 'correction', 'corr_09_normalizar_direcciones', 'loc_efe2212c1cb2', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1e44e9903a65', 'correction', 'corr_09_normalizar_direcciones', 'loc_1e44e9903a65', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b8556ff86e50', 'correction', 'corr_09_normalizar_direcciones', 'loc_b8556ff86e50', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2dfad16b66ce', 'correction', 'corr_09_normalizar_direcciones', 'loc_2dfad16b66ce', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_dedb98edd39c', 'correction', 'corr_09_normalizar_direcciones', 'loc_dedb98edd39c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c914cd356353', 'correction', 'corr_09_normalizar_direcciones', 'loc_c914cd356353', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6d52773d5dd5', 'correction', 'corr_09_normalizar_direcciones', 'loc_6d52773d5dd5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a9a3ef7b6fad', 'correction', 'corr_09_normalizar_direcciones', 'loc_a9a3ef7b6fad', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a9a3ef7b6fad', 'correction', 'corr_09_normalizar_direcciones', 'loc_a9a3ef7b6fad', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a1245ae6206a', 'correction', 'corr_09_normalizar_direcciones', 'loc_a1245ae6206a', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a1245ae6206a', 'correction', 'corr_09_normalizar_direcciones', 'loc_a1245ae6206a', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_477cf7e5f37b', 'correction', 'corr_09_normalizar_direcciones', 'loc_477cf7e5f37b', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_477cf7e5f37b', 'correction', 'corr_09_normalizar_direcciones', 'loc_477cf7e5f37b', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2a7cb5e9ba7a', 'correction', 'corr_09_normalizar_direcciones', 'loc_2a7cb5e9ba7a', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2a7cb5e9ba7a', 'correction', 'corr_09_normalizar_direcciones', 'loc_2a7cb5e9ba7a', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bc405f8f605d', 'correction', 'corr_09_normalizar_direcciones', 'loc_bc405f8f605d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bc405f8f605d', 'correction', 'corr_09_normalizar_direcciones', 'loc_bc405f8f605d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bda16c5d6831', 'correction', 'corr_09_normalizar_direcciones', 'loc_bda16c5d6831', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bda16c5d6831', 'correction', 'corr_09_normalizar_direcciones', 'loc_bda16c5d6831', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_22a15c9b0cbd', 'correction', 'corr_09_normalizar_direcciones', 'loc_22a15c9b0cbd', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_22a15c9b0cbd', 'correction', 'corr_09_normalizar_direcciones', 'loc_22a15c9b0cbd', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7b3c7ac61c06', 'correction', 'corr_09_normalizar_direcciones', 'loc_7b3c7ac61c06', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7b3c7ac61c06', 'correction', 'corr_09_normalizar_direcciones', 'loc_7b3c7ac61c06', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_01293607e891', 'correction', 'corr_09_normalizar_direcciones', 'loc_01293607e891', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_01293607e891', 'correction', 'corr_09_normalizar_direcciones', 'loc_01293607e891', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8971c622e758', 'correction', 'corr_09_normalizar_direcciones', 'loc_8971c622e758', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8971c622e758', 'correction', 'corr_09_normalizar_direcciones', 'loc_8971c622e758', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d59c632ced55', 'correction', 'corr_09_normalizar_direcciones', 'loc_d59c632ced55', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d59c632ced55', 'correction', 'corr_09_normalizar_direcciones', 'loc_d59c632ced55', 'CORR-09', 'localidad', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d59c632ced55', 'correction', 'corr_09_normalizar_direcciones', 'loc_d59c632ced55', 'CORR-09', 'referencia', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_230f531855d4', 'correction', 'corr_09_normalizar_direcciones', 'loc_230f531855d4', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_230f531855d4', 'correction', 'corr_09_normalizar_direcciones', 'loc_230f531855d4', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1009f0cbb737', 'correction', 'corr_09_normalizar_direcciones', 'loc_1009f0cbb737', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1009f0cbb737', 'correction', 'corr_09_normalizar_direcciones', 'loc_1009f0cbb737', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7306460fbaaf', 'correction', 'corr_09_normalizar_direcciones', 'loc_7306460fbaaf', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7306460fbaaf', 'correction', 'corr_09_normalizar_direcciones', 'loc_7306460fbaaf', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_679d33a82b6a', 'correction', 'corr_09_normalizar_direcciones', 'loc_679d33a82b6a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_13cbc02211cb', 'correction', 'corr_09_normalizar_direcciones', 'loc_13cbc02211cb', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b85024f25631', 'correction', 'corr_09_normalizar_direcciones', 'loc_b85024f25631', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1567b9d91e65', 'correction', 'corr_09_normalizar_direcciones', 'loc_1567b9d91e65', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_349177f4e83c', 'correction', 'corr_09_normalizar_direcciones', 'loc_349177f4e83c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9c80e1cfb76b', 'correction', 'corr_09_normalizar_direcciones', 'loc_9c80e1cfb76b', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9c80e1cfb76b', 'correction', 'corr_09_normalizar_direcciones', 'loc_9c80e1cfb76b', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_271928f7fb04', 'correction', 'corr_09_normalizar_direcciones', 'loc_271928f7fb04', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_271928f7fb04', 'correction', 'corr_09_normalizar_direcciones', 'loc_271928f7fb04', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_33f7a448429c', 'correction', 'corr_09_normalizar_direcciones', 'loc_33f7a448429c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5660df9e5418', 'correction', 'corr_09_normalizar_direcciones', 'loc_5660df9e5418', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_20bdb5187b63', 'correction', 'corr_09_normalizar_direcciones', 'loc_20bdb5187b63', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fbd428701410', 'correction', 'corr_09_normalizar_direcciones', 'loc_fbd428701410', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3d861afbb17f', 'correction', 'corr_09_normalizar_direcciones', 'loc_3d861afbb17f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8dfc0cf241ba', 'correction', 'corr_09_normalizar_direcciones', 'loc_8dfc0cf241ba', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8a9d09638815', 'correction', 'corr_09_normalizar_direcciones', 'loc_8a9d09638815', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_31a1f1cdec65', 'correction', 'corr_09_normalizar_direcciones', 'loc_31a1f1cdec65', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_734184c6712a', 'correction', 'corr_09_normalizar_direcciones', 'loc_734184c6712a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_111b56b91cb9', 'correction', 'corr_09_normalizar_direcciones', 'loc_111b56b91cb9', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_27a05424932d', 'correction', 'corr_09_normalizar_direcciones', 'loc_27a05424932d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_29baa15d2717', 'correction', 'corr_09_normalizar_direcciones', 'loc_29baa15d2717', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9a9b6e129962', 'correction', 'corr_09_normalizar_direcciones', 'loc_9a9b6e129962', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f42ce675ae48', 'correction', 'corr_09_normalizar_direcciones', 'loc_f42ce675ae48', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bdd00f78adcb', 'correction', 'corr_09_normalizar_direcciones', 'loc_bdd00f78adcb', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fb808ea49b72', 'correction', 'corr_09_normalizar_direcciones', 'loc_fb808ea49b72', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_dc9d74522686', 'correction', 'corr_09_normalizar_direcciones', 'loc_dc9d74522686', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c872f3a0dbbd', 'correction', 'corr_09_normalizar_direcciones', 'loc_c872f3a0dbbd', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_acf12ef7a373', 'correction', 'corr_09_normalizar_direcciones', 'loc_acf12ef7a373', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e55461f4ddd8', 'correction', 'corr_09_normalizar_direcciones', 'loc_e55461f4ddd8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f2f2c0963f4a', 'correction', 'corr_09_normalizar_direcciones', 'loc_f2f2c0963f4a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fa15dccc39f8', 'correction', 'corr_09_normalizar_direcciones', 'loc_fa15dccc39f8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_526b97180bcd', 'correction', 'corr_09_normalizar_direcciones', 'loc_526b97180bcd', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_91b5723fc01e', 'correction', 'corr_09_normalizar_direcciones', 'loc_91b5723fc01e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ba14909278a6', 'correction', 'corr_09_normalizar_direcciones', 'loc_ba14909278a6', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_94ed42232d55', 'correction', 'corr_09_normalizar_direcciones', 'loc_94ed42232d55', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a7e566f3b48b', 'correction', 'corr_09_normalizar_direcciones', 'loc_a7e566f3b48b', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_981ac5bb1681', 'correction', 'corr_09_normalizar_direcciones', 'loc_981ac5bb1681', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a90db607ab81', 'correction', 'corr_09_normalizar_direcciones', 'loc_a90db607ab81', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a37eb7512e1a', 'correction', 'corr_09_normalizar_direcciones', 'loc_a37eb7512e1a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_54610338be52', 'correction', 'corr_09_normalizar_direcciones', 'loc_54610338be52', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_215ca19a0739', 'correction', 'corr_09_normalizar_direcciones', 'loc_215ca19a0739', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_215ca19a0739', 'correction', 'corr_09_normalizar_direcciones', 'loc_215ca19a0739', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_576bd6ef0bcf', 'correction', 'corr_09_normalizar_direcciones', 'loc_576bd6ef0bcf', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e7c743124a83', 'correction', 'corr_09_normalizar_direcciones', 'loc_e7c743124a83', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e7c743124a83', 'correction', 'corr_09_normalizar_direcciones', 'loc_e7c743124a83', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_34605f281853', 'correction', 'corr_09_normalizar_direcciones', 'loc_34605f281853', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bbbb58b4f707', 'correction', 'corr_09_normalizar_direcciones', 'loc_bbbb58b4f707', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a11b5146d654', 'correction', 'corr_09_normalizar_direcciones', 'loc_a11b5146d654', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c2c5aae168bf', 'correction', 'corr_09_normalizar_direcciones', 'loc_c2c5aae168bf', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7762c7481bff', 'correction', 'corr_09_normalizar_direcciones', 'loc_7762c7481bff', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4a027b3e7af1', 'correction', 'corr_09_normalizar_direcciones', 'loc_4a027b3e7af1', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4a027b3e7af1', 'correction', 'corr_09_normalizar_direcciones', 'loc_4a027b3e7af1', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_63e2bcaa262b', 'correction', 'corr_09_normalizar_direcciones', 'loc_63e2bcaa262b', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1b5749d4df9c', 'correction', 'corr_09_normalizar_direcciones', 'loc_1b5749d4df9c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_32877a116e02', 'correction', 'corr_09_normalizar_direcciones', 'loc_32877a116e02', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_452a41d729c7', 'correction', 'corr_09_normalizar_direcciones', 'loc_452a41d729c7', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_455f0e181fb8', 'correction', 'corr_09_normalizar_direcciones', 'loc_455f0e181fb8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_333d96b5ff26', 'correction', 'corr_09_normalizar_direcciones', 'loc_333d96b5ff26', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6a1bb208c0fe', 'correction', 'corr_09_normalizar_direcciones', 'loc_6a1bb208c0fe', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3728ec603b25', 'correction', 'corr_09_normalizar_direcciones', 'loc_3728ec603b25', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ef412e6f165a', 'correction', 'corr_09_normalizar_direcciones', 'loc_ef412e6f165a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1c7f21a29767', 'correction', 'corr_09_normalizar_direcciones', 'loc_1c7f21a29767', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b2c9aa1fdfa5', 'correction', 'corr_09_normalizar_direcciones', 'loc_b2c9aa1fdfa5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a6ecbd184e22', 'correction', 'corr_09_normalizar_direcciones', 'loc_a6ecbd184e22', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b97fdf7dae0b', 'correction', 'corr_09_normalizar_direcciones', 'loc_b97fdf7dae0b', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3c939c42f4d5', 'correction', 'corr_09_normalizar_direcciones', 'loc_3c939c42f4d5', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3c939c42f4d5', 'correction', 'corr_09_normalizar_direcciones', 'loc_3c939c42f4d5', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_638947ff7d03', 'correction', 'corr_09_normalizar_direcciones', 'loc_638947ff7d03', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ea0ea6f91afb', 'correction', 'corr_09_normalizar_direcciones', 'loc_ea0ea6f91afb', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d6592e4491fa', 'correction', 'corr_09_normalizar_direcciones', 'loc_d6592e4491fa', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d6592e4491fa', 'correction', 'corr_09_normalizar_direcciones', 'loc_d6592e4491fa', 'CORR-09', 'referencia', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a876a5afbf13', 'correction', 'corr_09_normalizar_direcciones', 'loc_a876a5afbf13', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_91f28d2a0b2f', 'correction', 'corr_09_normalizar_direcciones', 'loc_91f28d2a0b2f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_450357608736', 'correction', 'corr_09_normalizar_direcciones', 'loc_450357608736', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0dadca597d6e', 'correction', 'corr_09_normalizar_direcciones', 'loc_0dadca597d6e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0dadca597d6e', 'correction', 'corr_09_normalizar_direcciones', 'loc_0dadca597d6e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_61f5784e0a84', 'correction', 'corr_09_normalizar_direcciones', 'loc_61f5784e0a84', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0fc707ec7f2d', 'correction', 'corr_09_normalizar_direcciones', 'loc_0fc707ec7f2d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0fc707ec7f2d', 'correction', 'corr_09_normalizar_direcciones', 'loc_0fc707ec7f2d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eaba32ec4f5d', 'correction', 'corr_09_normalizar_direcciones', 'loc_eaba32ec4f5d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eaba32ec4f5d', 'correction', 'corr_09_normalizar_direcciones', 'loc_eaba32ec4f5d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6ff3978ef720', 'correction', 'corr_09_normalizar_direcciones', 'loc_6ff3978ef720', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6ff3978ef720', 'correction', 'corr_09_normalizar_direcciones', 'loc_6ff3978ef720', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_79fdf9c5135d', 'correction', 'corr_09_normalizar_direcciones', 'loc_79fdf9c5135d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ffa96fd1750e', 'correction', 'corr_09_normalizar_direcciones', 'loc_ffa96fd1750e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f2c750d3fcdd', 'correction', 'corr_09_normalizar_direcciones', 'loc_f2c750d3fcdd', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_57f338bf7ed0', 'correction', 'corr_09_normalizar_direcciones', 'loc_57f338bf7ed0', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_971011892df1', 'correction', 'corr_09_normalizar_direcciones', 'loc_971011892df1', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_971011892df1', 'correction', 'corr_09_normalizar_direcciones', 'loc_971011892df1', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ec3c82664453', 'correction', 'corr_09_normalizar_direcciones', 'loc_ec3c82664453', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e30cff3ae0bf', 'correction', 'corr_09_normalizar_direcciones', 'loc_e30cff3ae0bf', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1b591e9fabaf', 'correction', 'corr_09_normalizar_direcciones', 'loc_1b591e9fabaf', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4553b9529783', 'correction', 'corr_09_normalizar_direcciones', 'loc_4553b9529783', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_66ee50e03cb7', 'correction', 'corr_09_normalizar_direcciones', 'loc_66ee50e03cb7', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_25115418cbef', 'correction', 'corr_09_normalizar_direcciones', 'loc_25115418cbef', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_881e090845e5', 'correction', 'corr_09_normalizar_direcciones', 'loc_881e090845e5', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_881e090845e5', 'correction', 'corr_09_normalizar_direcciones', 'loc_881e090845e5', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a7a55ba202b3', 'correction', 'corr_09_normalizar_direcciones', 'loc_a7a55ba202b3', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a7a55ba202b3', 'correction', 'corr_09_normalizar_direcciones', 'loc_a7a55ba202b3', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_856a284b7df3', 'correction', 'corr_09_normalizar_direcciones', 'loc_856a284b7df3', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fb3bdde5e92e', 'correction', 'corr_09_normalizar_direcciones', 'loc_fb3bdde5e92e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4cd5fad23730', 'correction', 'corr_09_normalizar_direcciones', 'loc_4cd5fad23730', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4cd5fad23730', 'correction', 'corr_09_normalizar_direcciones', 'loc_4cd5fad23730', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_86f7b7975d7f', 'correction', 'corr_09_normalizar_direcciones', 'loc_86f7b7975d7f', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_86f7b7975d7f', 'correction', 'corr_09_normalizar_direcciones', 'loc_86f7b7975d7f', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_59f5ebbe7439', 'correction', 'corr_09_normalizar_direcciones', 'loc_59f5ebbe7439', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_59f5ebbe7439', 'correction', 'corr_09_normalizar_direcciones', 'loc_59f5ebbe7439', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9d51dccce004', 'correction', 'corr_09_normalizar_direcciones', 'loc_9d51dccce004', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9d51dccce004', 'correction', 'corr_09_normalizar_direcciones', 'loc_9d51dccce004', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_badf048ad5f2', 'correction', 'corr_09_normalizar_direcciones', 'loc_badf048ad5f2', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_badf048ad5f2', 'correction', 'corr_09_normalizar_direcciones', 'loc_badf048ad5f2', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7af4e2735ebe', 'correction', 'corr_09_normalizar_direcciones', 'loc_7af4e2735ebe', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7af4e2735ebe', 'correction', 'corr_09_normalizar_direcciones', 'loc_7af4e2735ebe', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8a5c0839aac9', 'correction', 'corr_09_normalizar_direcciones', 'loc_8a5c0839aac9', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8a5c0839aac9', 'correction', 'corr_09_normalizar_direcciones', 'loc_8a5c0839aac9', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3f54d08a5558', 'correction', 'corr_09_normalizar_direcciones', 'loc_3f54d08a5558', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3f54d08a5558', 'correction', 'corr_09_normalizar_direcciones', 'loc_3f54d08a5558', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6ed0b61bce33', 'correction', 'corr_09_normalizar_direcciones', 'loc_6ed0b61bce33', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7c74ded6113c', 'correction', 'corr_09_normalizar_direcciones', 'loc_7c74ded6113c', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7c74ded6113c', 'correction', 'corr_09_normalizar_direcciones', 'loc_7c74ded6113c', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e32a8c842f91', 'correction', 'corr_09_normalizar_direcciones', 'loc_e32a8c842f91', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e32a8c842f91', 'correction', 'corr_09_normalizar_direcciones', 'loc_e32a8c842f91', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_24dd33b872cc', 'correction', 'corr_09_normalizar_direcciones', 'loc_24dd33b872cc', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_35c4b50b572a', 'correction', 'corr_09_normalizar_direcciones', 'loc_35c4b50b572a', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_35c4b50b572a', 'correction', 'corr_09_normalizar_direcciones', 'loc_35c4b50b572a', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fab9ae2795e0', 'correction', 'corr_09_normalizar_direcciones', 'loc_fab9ae2795e0', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fab9ae2795e0', 'correction', 'corr_09_normalizar_direcciones', 'loc_fab9ae2795e0', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eca63007fb86', 'correction', 'corr_09_normalizar_direcciones', 'loc_eca63007fb86', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_eca63007fb86', 'correction', 'corr_09_normalizar_direcciones', 'loc_eca63007fb86', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_073d53b73e84', 'correction', 'corr_09_normalizar_direcciones', 'loc_073d53b73e84', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_073d53b73e84', 'correction', 'corr_09_normalizar_direcciones', 'loc_073d53b73e84', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_488ce77dda5b', 'correction', 'corr_09_normalizar_direcciones', 'loc_488ce77dda5b', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_488ce77dda5b', 'correction', 'corr_09_normalizar_direcciones', 'loc_488ce77dda5b', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e008cd057d21', 'correction', 'corr_09_normalizar_direcciones', 'loc_e008cd057d21', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e008cd057d21', 'correction', 'corr_09_normalizar_direcciones', 'loc_e008cd057d21', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d9701f5c79b7', 'correction', 'corr_09_normalizar_direcciones', 'loc_d9701f5c79b7', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d9701f5c79b7', 'correction', 'corr_09_normalizar_direcciones', 'loc_d9701f5c79b7', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d208b7e32cbe', 'correction', 'corr_09_normalizar_direcciones', 'loc_d208b7e32cbe', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d208b7e32cbe', 'correction', 'corr_09_normalizar_direcciones', 'loc_d208b7e32cbe', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1df4b40c9752', 'correction', 'corr_09_normalizar_direcciones', 'loc_1df4b40c9752', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1df4b40c9752', 'correction', 'corr_09_normalizar_direcciones', 'loc_1df4b40c9752', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6f1ef4b92dfd', 'correction', 'corr_09_normalizar_direcciones', 'loc_6f1ef4b92dfd', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_245d82ffef6d', 'correction', 'corr_09_normalizar_direcciones', 'loc_245d82ffef6d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2452f3af87af', 'correction', 'corr_09_normalizar_direcciones', 'loc_2452f3af87af', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2452f3af87af', 'correction', 'corr_09_normalizar_direcciones', 'loc_2452f3af87af', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a625f9710b86', 'correction', 'corr_09_normalizar_direcciones', 'loc_a625f9710b86', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a625f9710b86', 'correction', 'corr_09_normalizar_direcciones', 'loc_a625f9710b86', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_26bf86c5a15e', 'correction', 'corr_09_normalizar_direcciones', 'loc_26bf86c5a15e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a7b3093f3d67', 'correction', 'corr_09_normalizar_direcciones', 'loc_a7b3093f3d67', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_8363b3e1c5de', 'correction', 'corr_09_normalizar_direcciones', 'loc_8363b3e1c5de', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_df506cd3a61e', 'correction', 'corr_09_normalizar_direcciones', 'loc_df506cd3a61e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_df506cd3a61e', 'correction', 'corr_09_normalizar_direcciones', 'loc_df506cd3a61e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0ec38c0bf7b2', 'correction', 'corr_09_normalizar_direcciones', 'loc_0ec38c0bf7b2', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0ec38c0bf7b2', 'correction', 'corr_09_normalizar_direcciones', 'loc_0ec38c0bf7b2', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_caa7f6671e2d', 'correction', 'corr_09_normalizar_direcciones', 'loc_caa7f6671e2d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_175270023e60', 'correction', 'corr_09_normalizar_direcciones', 'loc_175270023e60', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d3104d6ad9b2', 'correction', 'corr_09_normalizar_direcciones', 'loc_d3104d6ad9b2', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_41c8b23415a7', 'correction', 'corr_09_normalizar_direcciones', 'loc_41c8b23415a7', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_db669a12866d', 'correction', 'corr_09_normalizar_direcciones', 'loc_db669a12866d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_db669a12866d', 'correction', 'corr_09_normalizar_direcciones', 'loc_db669a12866d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_359aacb855cc', 'correction', 'corr_09_normalizar_direcciones', 'loc_359aacb855cc', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_359aacb855cc', 'correction', 'corr_09_normalizar_direcciones', 'loc_359aacb855cc', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_56a319f50685', 'correction', 'corr_09_normalizar_direcciones', 'loc_56a319f50685', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5a9007b91fdf', 'correction', 'corr_09_normalizar_direcciones', 'loc_5a9007b91fdf', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_25fb6bc77cea', 'correction', 'corr_09_normalizar_direcciones', 'loc_25fb6bc77cea', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_90ea79c2aa2c', 'correction', 'corr_09_normalizar_direcciones', 'loc_90ea79c2aa2c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ed3020cdad14', 'correction', 'corr_09_normalizar_direcciones', 'loc_ed3020cdad14', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_fd979ab891ef', 'correction', 'corr_09_normalizar_direcciones', 'loc_fd979ab891ef', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0eb98b3b5a79', 'correction', 'corr_09_normalizar_direcciones', 'loc_0eb98b3b5a79', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0eb98b3b5a79', 'correction', 'corr_09_normalizar_direcciones', 'loc_0eb98b3b5a79', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a852fa3f2cdb', 'correction', 'corr_09_normalizar_direcciones', 'loc_a852fa3f2cdb', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a852fa3f2cdb', 'correction', 'corr_09_normalizar_direcciones', 'loc_a852fa3f2cdb', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f0d4bd6bf568', 'correction', 'corr_09_normalizar_direcciones', 'loc_f0d4bd6bf568', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f0d4bd6bf568', 'correction', 'corr_09_normalizar_direcciones', 'loc_f0d4bd6bf568', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_577645e6a983', 'correction', 'corr_09_normalizar_direcciones', 'loc_577645e6a983', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0bcae7140060', 'correction', 'corr_09_normalizar_direcciones', 'loc_0bcae7140060', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0bcae7140060', 'correction', 'corr_09_normalizar_direcciones', 'loc_0bcae7140060', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3613f05c4169', 'correction', 'corr_09_normalizar_direcciones', 'loc_3613f05c4169', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3613f05c4169', 'correction', 'corr_09_normalizar_direcciones', 'loc_3613f05c4169', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_62231d9c2de4', 'correction', 'corr_09_normalizar_direcciones', 'loc_62231d9c2de4', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_efa464617213', 'correction', 'corr_09_normalizar_direcciones', 'loc_efa464617213', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c76c053c9aae', 'correction', 'corr_09_normalizar_direcciones', 'loc_c76c053c9aae', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9929584f53bd', 'correction', 'corr_09_normalizar_direcciones', 'loc_9929584f53bd', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_76d7d4cf98db', 'correction', 'corr_09_normalizar_direcciones', 'loc_76d7d4cf98db', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b56727a2a140', 'correction', 'corr_09_normalizar_direcciones', 'loc_b56727a2a140', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b56727a2a140', 'correction', 'corr_09_normalizar_direcciones', 'loc_b56727a2a140', 'CORR-09', 'referencia', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f414497840d5', 'correction', 'corr_09_normalizar_direcciones', 'loc_f414497840d5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b67675c0f76e', 'correction', 'corr_09_normalizar_direcciones', 'loc_b67675c0f76e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e22e03ccfd18', 'correction', 'corr_09_normalizar_direcciones', 'loc_e22e03ccfd18', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4de834934748', 'correction', 'corr_09_normalizar_direcciones', 'loc_4de834934748', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_32c56bf91e3a', 'correction', 'corr_09_normalizar_direcciones', 'loc_32c56bf91e3a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_0dd83c742263', 'correction', 'corr_09_normalizar_direcciones', 'loc_0dd83c742263', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1298164c189c', 'correction', 'corr_09_normalizar_direcciones', 'loc_1298164c189c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4bfefa0fa0c5', 'correction', 'corr_09_normalizar_direcciones', 'loc_4bfefa0fa0c5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_73ff427c33a2', 'correction', 'corr_09_normalizar_direcciones', 'loc_73ff427c33a2', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_408873411022', 'correction', 'corr_09_normalizar_direcciones', 'loc_408873411022', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_e5f14c1cce0a', 'correction', 'corr_09_normalizar_direcciones', 'loc_e5f14c1cce0a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c6e304f9d27a', 'correction', 'corr_09_normalizar_direcciones', 'loc_c6e304f9d27a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a1da6ccd1600', 'correction', 'corr_09_normalizar_direcciones', 'loc_a1da6ccd1600', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_197be1570c20', 'correction', 'corr_09_normalizar_direcciones', 'loc_197be1570c20', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1cc88555a485', 'correction', 'corr_09_normalizar_direcciones', 'loc_1cc88555a485', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5379264473b8', 'correction', 'corr_09_normalizar_direcciones', 'loc_5379264473b8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_01e314ad4c04', 'correction', 'corr_09_normalizar_direcciones', 'loc_01e314ad4c04', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b16250f15ecb', 'correction', 'corr_09_normalizar_direcciones', 'loc_b16250f15ecb', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1b1078f7bf57', 'correction', 'corr_09_normalizar_direcciones', 'loc_1b1078f7bf57', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9c05b69084b5', 'correction', 'corr_09_normalizar_direcciones', 'loc_9c05b69084b5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2a7b0dd0fb34', 'correction', 'corr_09_normalizar_direcciones', 'loc_2a7b0dd0fb34', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2a7b0dd0fb34', 'correction', 'corr_09_normalizar_direcciones', 'loc_2a7b0dd0fb34', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_bdd3b0f74009', 'correction', 'corr_09_normalizar_direcciones', 'loc_bdd3b0f74009', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6ec263b79ab1', 'correction', 'corr_09_normalizar_direcciones', 'loc_6ec263b79ab1', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_58bb7547cd33', 'correction', 'corr_09_normalizar_direcciones', 'loc_58bb7547cd33', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f3d741c388c1', 'correction', 'corr_09_normalizar_direcciones', 'loc_f3d741c388c1', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c193be4f81a8', 'correction', 'corr_09_normalizar_direcciones', 'loc_c193be4f81a8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c031b6e6261a', 'correction', 'corr_09_normalizar_direcciones', 'loc_c031b6e6261a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_31f0a3156cc5', 'correction', 'corr_09_normalizar_direcciones', 'loc_31f0a3156cc5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d55e6d34f076', 'correction', 'corr_09_normalizar_direcciones', 'loc_d55e6d34f076', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2788ea6c035d', 'correction', 'corr_09_normalizar_direcciones', 'loc_2788ea6c035d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f218a66c039b', 'correction', 'corr_09_normalizar_direcciones', 'loc_f218a66c039b', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_68f1681c4891', 'correction', 'corr_09_normalizar_direcciones', 'loc_68f1681c4891', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_b3b6379409a2', 'correction', 'corr_09_normalizar_direcciones', 'loc_b3b6379409a2', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a2e3adb987da', 'correction', 'corr_09_normalizar_direcciones', 'loc_a2e3adb987da', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_3f5408ad59e4', 'correction', 'corr_09_normalizar_direcciones', 'loc_3f5408ad59e4', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7f83f1085022', 'correction', 'corr_09_normalizar_direcciones', 'loc_7f83f1085022', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_01706ab816f4', 'correction', 'corr_09_normalizar_direcciones', 'loc_01706ab816f4', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6529546b258c', 'correction', 'corr_09_normalizar_direcciones', 'loc_6529546b258c', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_37ca9fa4353d', 'correction', 'corr_09_normalizar_direcciones', 'loc_37ca9fa4353d', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_37ca9fa4353d', 'correction', 'corr_09_normalizar_direcciones', 'loc_37ca9fa4353d', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_1070a297845b', 'correction', 'corr_09_normalizar_direcciones', 'loc_1070a297845b', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a5ff7471d4f5', 'correction', 'corr_09_normalizar_direcciones', 'loc_a5ff7471d4f5', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5614701cca5c', 'correction', 'corr_09_normalizar_direcciones', 'loc_5614701cca5c', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_5614701cca5c', 'correction', 'corr_09_normalizar_direcciones', 'loc_5614701cca5c', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2a7fe086e371', 'correction', 'corr_09_normalizar_direcciones', 'loc_2a7fe086e371', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2a7fe086e371', 'correction', 'corr_09_normalizar_direcciones', 'loc_2a7fe086e371', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_df17013b31a2', 'correction', 'corr_09_normalizar_direcciones', 'loc_df17013b31a2', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_df17013b31a2', 'correction', 'corr_09_normalizar_direcciones', 'loc_df17013b31a2', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_26ddfee1472f', 'correction', 'corr_09_normalizar_direcciones', 'loc_26ddfee1472f', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_26ddfee1472f', 'correction', 'corr_09_normalizar_direcciones', 'loc_26ddfee1472f', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_58471c0bf8a2', 'correction', 'corr_09_normalizar_direcciones', 'loc_58471c0bf8a2', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_58471c0bf8a2', 'correction', 'corr_09_normalizar_direcciones', 'loc_58471c0bf8a2', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_406c1df3090b', 'correction', 'corr_09_normalizar_direcciones', 'loc_406c1df3090b', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_406c1df3090b', 'correction', 'corr_09_normalizar_direcciones', 'loc_406c1df3090b', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ee538125cdf5', 'correction', 'corr_09_normalizar_direcciones', 'loc_ee538125cdf5', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ee538125cdf5', 'correction', 'corr_09_normalizar_direcciones', 'loc_ee538125cdf5', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2517820aab3e', 'correction', 'corr_09_normalizar_direcciones', 'loc_2517820aab3e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2517820aab3e', 'correction', 'corr_09_normalizar_direcciones', 'loc_2517820aab3e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7758c7b1d31c', 'correction', 'corr_09_normalizar_direcciones', 'loc_7758c7b1d31c', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7758c7b1d31c', 'correction', 'corr_09_normalizar_direcciones', 'loc_7758c7b1d31c', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7d815b57be26', 'correction', 'corr_09_normalizar_direcciones', 'loc_7d815b57be26', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7d815b57be26', 'correction', 'corr_09_normalizar_direcciones', 'loc_7d815b57be26', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_29d321e3b787', 'correction', 'corr_09_normalizar_direcciones', 'loc_29d321e3b787', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_42605f696da8', 'correction', 'corr_09_normalizar_direcciones', 'loc_42605f696da8', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_9b4c843c0fe7', 'correction', 'corr_09_normalizar_direcciones', 'loc_9b4c843c0fe7', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_a26b7338459d', 'correction', 'corr_09_normalizar_direcciones', 'loc_a26b7338459d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_49fe17ece465', 'correction', 'corr_09_normalizar_direcciones', 'loc_49fe17ece465', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_d03cf0e44081', 'correction', 'corr_09_normalizar_direcciones', 'loc_d03cf0e44081', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_84c57a846d37', 'correction', 'corr_09_normalizar_direcciones', 'loc_84c57a846d37', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_4265bf465b7d', 'correction', 'corr_09_normalizar_direcciones', 'loc_4265bf465b7d', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ff87f792c860', 'correction', 'corr_09_normalizar_direcciones', 'loc_ff87f792c860', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_c1dfc2e319ce', 'correction', 'corr_09_normalizar_direcciones', 'loc_c1dfc2e319ce', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ffdacb995f37', 'correction', 'corr_09_normalizar_direcciones', 'loc_ffdacb995f37', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_abb8e13d225e', 'correction', 'corr_09_normalizar_direcciones', 'loc_abb8e13d225e', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_abb8e13d225e', 'correction', 'corr_09_normalizar_direcciones', 'loc_abb8e13d225e', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_ab21b7cd739e', 'correction', 'corr_09_normalizar_direcciones', 'loc_ab21b7cd739e', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_6437cb4ced0f', 'correction', 'corr_09_normalizar_direcciones', 'loc_6437cb4ced0f', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2689b2782f71', 'correction', 'corr_09_normalizar_direcciones', 'loc_2689b2782f71', 'CORR-09', 'direccion_texto', NOW());
INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_2689b2782f71', 'correction', 'corr_09_normalizar_direcciones', 'loc_2689b2782f71', 'CORR-09', 'localidad', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_f437a69df36a', 'correction', 'corr_09_normalizar_direcciones', 'loc_f437a69df36a', 'CORR-09', 'direccion_texto', NOW());

INSERT INTO migration.provenance (target_table, target_pk, source_type, source_file, source_key, phase, field_name, created_at) VALUES ('territorial.localizacion', 'loc_7357025e0774', 'correction', 'corr_09_normalizar_direcciones', 'loc_7357025e0774', 'CORR-09', 'direccion_texto', NOW());

COMMIT;