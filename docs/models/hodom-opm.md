=== SD ===
Infraestructura Administrativa es un objeto, físico.
Condición Clínica de Grupo de Pacientes es un objeto, informático.
Condición Clínica de Grupo de Pacientes puede estar agudo/reagudizado o recuperado.
Estado agudo/reagudizado de Condición Clínica de Grupo de Pacientes es inicial.
Estado recuperado de Condición Clínica de Grupo de Pacientes es final.
Sistema de Comunicación es un objeto, físico.
Normativa Vigente es un objeto, informático, ambiental.
Equipo de Salud es un objeto, físico.
Sistema de Hospitalización Domiciliaria es un objeto, físico.
Establecimiento de Atención Cerrada es un objeto, físico, ambiental.
Equipamiento Médico es un objeto, físico.
Grupo de Pacientes es un objeto, físico.
Domicilio del Paciente es un objeto, físico, ambiental.
Vehículo de Transporte es un objeto, físico.
Hospitalizar en Domicilio de Sistema de Hospitalización Domiciliaria es un proceso, físico.
Ocupar Cama Hospitalaria es un proceso, físico, ambiental.
Sistema de Hospitalización Domiciliaria exhibe Hospitalizar en Domicilio.
Grupo de Pacientes exhibe Condición Clínica.
Normativa Vigente governs Sistema de Hospitalización Domiciliaria.
Establecimiento de Atención Cerrada refers Hospitalizar en Domicilio.
Ocupar Cama Hospitalaria cambia Condición Clínica a agudo/reagudizado.
Establecimiento de Atención Cerrada refers Grupo de Pacientes.
Domicilio del Paciente hosts Grupo de Pacientes.
Hospitalizar en Domicilio cambia Condición Clínica de agudo/reagudizado a recuperado.
Equipo de Salud maneja Hospitalizar en Domicilio.
Equipamiento Médico requiere Hospitalizar en Domicilio.
Sistema de Comunicación requiere Hospitalizar en Domicilio.
Vehículo de Transporte requiere Hospitalizar en Domicilio.
Infraestructura Administrativa requiere Hospitalizar en Domicilio.
Domicilio del Paciente hosts Hospitalizar en Domicilio.

=== SD1 ===
SD se refina por descomposición de Hospitalizar en Domicilio en SD1.
Formulario de Ingreso es un objeto, informático.
Cuidador es un objeto, físico.
Cuidador puede estar disponible o no disponible.
Condición Clínica es un objeto, informático.
Condición Clínica puede estar agudo/reagudizado o recuperado.
Estado agudo/reagudizado de Condición Clínica es inicial.
Estado recuperado de Condición Clínica es final.
Decisión de Continuidad es un objeto, informático.
Decisión de Continuidad puede estar continuar tratamiento o proceder egreso.
Resumen Clínico Domiciliario es un objeto, informático.
Estado de Elegibilidad es un objeto, informático.
Estado de Elegibilidad puede estar elegible, no elegible o pendiente.
Estado elegible de Estado de Elegibilidad es final.
Estado pendiente de Estado de Elegibilidad es inicial.
Epicrisis es un objeto, informático.
Equipo de Salud es un objeto, físico.
Estado de Hospitalización es un objeto, informático.
Estado de Hospitalización puede estar activo o egresado.
Estado activo de Estado de Hospitalización es inicial.
Estado egresado de Estado de Hospitalización es final.
Consentimiento Informado es un objeto, informático.
Consentimiento Informado puede estar firmado o sin firmar.
Estado firmado de Consentimiento Informado es final.
Estado sin firmar de Consentimiento Informado es inicial.
Establecimiento de Atención Cerrada es un objeto, físico, ambiental.
Equipamiento Médico es un objeto, físico.
Plan de Cuidados de Enfermería es un objeto, informático.
Plan de Cuidados de Enfermería puede estar activo, completado o borrador.
Estado completado de Plan de Cuidados de Enfermería es final.
Estado borrador de Plan de Cuidados de Enfermería es inicial.
Encuesta de Satisfacción es un objeto, informático.
Informe Social es un objeto, informático.
Red de Apoyo es un objeto, físico.
Red de Apoyo puede estar insuficiente o verificada.
Plan Terapéutico es un objeto, informático.
Plan Terapéutico puede estar activo, completado o borrador.
Estado activo de Plan Terapéutico es por defecto.
Estado completado de Plan Terapéutico es final.
Estado borrador de Plan Terapéutico es inicial.
Vehículo de Transporte es un objeto, físico.
Planificar Atención es un proceso, informático.
Monitorear Evolución Clínica es un proceso, informático.
Hospitalizar en Domicilio es un proceso, físico.
Evaluar Elegibilidad es un proceso, informático.
Ingresar Paciente es un proceso, informático.
Egresar de Hospitalización Domiciliaria es un proceso, informático.
Ejecutar Plan Terapéutico es un proceso, físico.
Hospitalizar en Domicilio se descompone en paralelo Evaluar Elegibilidad and Ingresar Paciente, paralelo Planificar Atención and Ejecutar Plan Terapéutico, y paralelo Monitorear Evolución Clínica and Egresar de Hospitalización Domiciliaria, así como Consentimiento Informado, Cuidador, Decisión de Continuidad, Encuesta de Satisfacción, Epicrisis, Estado de Elegibilidad, Estado de Hospitalización, Formulario de Ingreso, Informe Social, Plan de Cuidados de Enfermería, Plan Terapéutico, Red de Apoyo, y Resumen Clínico Domiciliario, en esa secuencia.
Evaluar Elegibilidad cambia Estado de Elegibilidad de pendiente a elegible.
Establecimiento de Atención Cerrada requiere Evaluar Elegibilidad.
Cuidador requiere Evaluar Elegibilidad en disponible.
Evaluar Elegibilidad cambia Red de Apoyo de insuficiente a verificada.
Ingresar Paciente cambia Consentimiento Informado de sin firmar a firmado.
Planificar Atención cambia Plan Terapéutico a borrador.
Plan Terapéutico requiere Ejecutar Plan Terapéutico en activo.
Plan de Cuidados de Enfermería requiere Ejecutar Plan Terapéutico en activo.
Equipamiento Médico requiere Ejecutar Plan Terapéutico.
Vehículo de Transporte requiere Ejecutar Plan Terapéutico.
Monitorear Evolución Clínica cambia Condición Clínica de agudo/reagudizado a recuperado.
Egresar de Hospitalización Domiciliaria cambia Estado de Hospitalización de activo a egresado.
Egresar de Hospitalización Domiciliaria cambia Plan Terapéutico de activo a completado.
Egresar de Hospitalización Domiciliaria cambia Plan de Cuidados de Enfermería de activo a completado.
Egresar de Hospitalización Domiciliaria genera Encuesta de Satisfacción.
Equipo de Salud maneja Evaluar Elegibilidad.
Equipo de Salud maneja Ingresar Paciente.
Equipo de Salud maneja Planificar Atención.
Equipo de Salud maneja Ejecutar Plan Terapéutico.
Equipo de Salud maneja Monitorear Evolución Clínica.
Equipo de Salud maneja Egresar de Hospitalización Domiciliaria.
Ingresar Paciente requiere Consentimiento Informado en firmado.
Egresar de Hospitalización Domiciliaria requiere Estado de Hospitalización en egresado.
Evaluar Elegibilidad requiere Estado de Elegibilidad en elegible.

=== SD1.1 ===
SD1 se refina por descomposición de Evaluar Elegibilidad en SD1.1.
Médico de Atención Directa es un objeto, físico.
Cuidador es un objeto, físico.
Cuidador puede estar disponible o no disponible.
Condición Clínica de Grupo de Pacientes es un objeto, informático.
Condición Clínica de Grupo de Pacientes puede estar agudo/reagudizado o recuperado.
Estado agudo/reagudizado de Condición Clínica de Grupo de Pacientes es inicial.
Estado recuperado de Condición Clínica de Grupo de Pacientes es final.
Enfermero Clínico es un objeto, físico.
Condición del Domicilio de Domicilio del Paciente es un objeto, informático.
Condición del Domicilio de Domicilio del Paciente puede estar adecuada o inadecuada.
Estado adecuada de Condición del Domicilio de Domicilio del Paciente es final.
Consentimiento Informado es un objeto, informático.
Consentimiento Informado puede estar firmado o sin firmar.
Estado firmado de Consentimiento Informado es final.
Estado sin firmar de Consentimiento Informado es inicial.
Establecimiento de Atención Cerrada es un objeto, físico, ambiental.
Grupo de Pacientes es un objeto, físico.
Domicilio del Paciente es un objeto, físico, ambiental.
Carta de Derechos y Deberes es un objeto, informático.
Informe Social es un objeto, informático.
Trabajador Social es un objeto, físico.
Red de Apoyo es un objeto, físico.
Red de Apoyo puede estar insuficiente o verificada.
Evaluar Condición Clínica es un proceso, informático.
Evaluar Elegibilidad es un proceso, informático.
Evaluar Condiciones del Domicilio es un proceso, informático.
Obtener Consentimiento Informado es un proceso, informático.
Verificar Red de Apoyo es un proceso, informático.
Evaluar Elegibilidad se descompone en paralelo Evaluar Condición Clínica and Evaluar Condiciones del Domicilio and paralelo Obtener Consentimiento Informado and Verificar Red de Apoyo, en esa secuencia.
Grupo de Pacientes exhibe Condición Clínica.
Domicilio del Paciente exhibe Condición del Domicilio and Condición del Domicilio.
Evaluar Condición Clínica afecta Grupo de Pacientes.
Evaluar Condición Clínica cambia Condición Clínica de agudo/reagudizado.
Establecimiento de Atención Cerrada requiere Evaluar Condición Clínica.
Médico de Atención Directa maneja Evaluar Condición Clínica.
Evaluar Condiciones del Domicilio genera Informe Social.
Evaluar Condiciones del Domicilio afecta Domicilio del Paciente.
Trabajador Social maneja Evaluar Condiciones del Domicilio.
Evaluar Condiciones del Domicilio cambia Condición del Domicilio de inadecuada a adecuada.
Verificar Red de Apoyo cambia Red de Apoyo de insuficiente a verificada.
Cuidador requiere Verificar Red de Apoyo en disponible.
Trabajador Social maneja Verificar Red de Apoyo.
Obtener Consentimiento Informado cambia Consentimiento Informado de sin firmar a firmado.
Grupo de Pacientes requiere Obtener Consentimiento Informado.
Enfermero Clínico maneja Obtener Consentimiento Informado.
Obtener Consentimiento Informado genera Carta de Derechos y Deberes.

=== SD8 ===
SD1.1 se refina por descomposición de despliegue de Condición de Exclusión en SD8.
Exclusión por Inestabilidad Clínica es un objeto, informático.
Exclusión por Salud Mental Descompensada es un objeto, informático.
Condición de Exclusión es un objeto, informático.
Condición de Exclusión puede estar ausente o presente.
Estado ausente de Condición de Exclusión es inicial.
Exclusión por Alta Disciplinaria Previa es un objeto, informático.
Exclusión por Diagnóstico no Establecido es un objeto, informático.
Exclusión por Prestación no Listada es un objeto, informático.
Exclusión por Inestabilidad Clínica, Exclusión por Diagnóstico no Establecido, Exclusión por Salud Mental Descompensada, Exclusión por Prestación no Listada, y Exclusión por Alta Disciplinaria Previa son un Condición de Exclusión.

=== SD1.2 ===
SD1 se refina por descomposición de Ingresar Paciente en SD1.2.
Personal Administrativo es un objeto, físico.
Formulario de Ingreso es un objeto, informático.
Documento de Indicaciones de Cuidado es un objeto, informático.
Enfermero Clínico es un objeto, físico.
Sistema de Comunicación es un objeto, físico.
Profesional Coordinador es un objeto, físico.
Consentimiento Informado es un objeto, informático.
Consentimiento Informado puede estar firmado o sin firmar.
Estado firmado de Consentimiento Informado es final.
Estado sin firmar de Consentimiento Informado es inicial.
Establecimiento de Atención Cerrada es un objeto, físico, ambiental.
Grupo de Pacientes es un objeto, físico.
Domicilio del Paciente es un objeto, físico, ambiental.
Informe Social es un objeto, informático.
Trabajador Social es un objeto, físico.
Situación Socioeconómica es un objeto, informático.
Registrar Ingreso es un proceso, informático.
Ingresar Paciente es un proceso, informático.
Entregar Documentación al Paciente es un proceso, informático.
Coordinar con Establecimiento Derivador es un proceso, informático.
Elaborar Diagnóstico Social es un proceso, informático.
Ingresar Paciente se descompone en paralelo Registrar Ingreso and Elaborar Diagnóstico Social and paralelo Entregar Documentación al Paciente and Coordinar con Establecimiento Derivador, en esa secuencia.
Registrar Ingreso genera Formulario de Ingreso.
Sistema de Comunicación requiere Registrar Ingreso.
Personal Administrativo maneja Registrar Ingreso.
Elaborar Diagnóstico Social genera Informe Social.
Elaborar Diagnóstico Social afecta Domicilio del Paciente.
Trabajador Social maneja Elaborar Diagnóstico Social.
Elaborar Diagnóstico Social genera Situación Socioeconómica.
Entregar Documentación al Paciente afecta Grupo de Pacientes.
Consentimiento Informado requiere Entregar Documentación al Paciente en firmado.
Entregar Documentación al Paciente genera Documento de Indicaciones de Cuidado.
Enfermero Clínico maneja Entregar Documentación al Paciente.
Coordinar con Establecimiento Derivador afecta Grupo de Pacientes.
Establecimiento de Atención Cerrada requiere Coordinar con Establecimiento Derivador.
Sistema de Comunicación requiere Coordinar con Establecimiento Derivador.
Profesional Coordinador maneja Coordinar con Establecimiento Derivador.
Ingresar Paciente requiere Consentimiento Informado en firmado.

=== SD1.3 ===
SD1 se refina por descomposición de Planificar Atención en SD1.3.
Personal Administrativo es un objeto, físico.
Médico de Atención Directa es un objeto, físico.
Condición Clínica es un objeto, informático.
Condición Clínica puede estar agudo/reagudizado o recuperado.
Estado agudo/reagudizado de Condición Clínica es inicial.
Estado recuperado de Condición Clínica es final.
Enfermero Clínico es un objeto, físico.
Profesional Coordinador es un objeto, físico.
Plan de Cuidados de Enfermería es un objeto, informático.
Plan de Cuidados de Enfermería puede estar activo, completado o borrador.
Estado completado de Plan de Cuidados de Enfermería es final.
Estado borrador de Plan de Cuidados de Enfermería es inicial.
Domicilio del Paciente es un objeto, físico, ambiental.
Plan Terapéutico es un objeto, informático.
Plan Terapéutico puede estar activo, completado o borrador.
Estado activo de Plan Terapéutico es por defecto.
Estado completado de Plan Terapéutico es final.
Estado borrador de Plan Terapéutico es inicial.
Ruta de Transporte es un objeto, informático.
Programa de Visitas es un objeto, informático.
Planificar Atención es un proceso, informático.
Programar Visitas Domiciliarias es un proceso, informático.
Elaborar Plan de Cuidados de Enfermería es un proceso, informático.
Elaborar Plan Terapéutico es un proceso, informático.
Programar Rutas de Transporte es un proceso, informático.
Planificar Atención se descompone en paralelo Elaborar Plan de Cuidados de Enfermería and Elaborar Plan Terapéutico and paralelo Programar Visitas Domiciliarias and Programar Rutas de Transporte, en esa secuencia.
Elaborar Plan Terapéutico genera Plan Terapéutico en borrador.
Condición Clínica requiere Elaborar Plan Terapéutico.
Médico de Atención Directa maneja Elaborar Plan Terapéutico.
Elaborar Plan de Cuidados de Enfermería genera Plan de Cuidados de Enfermería en borrador.
Plan Terapéutico requiere Elaborar Plan de Cuidados de Enfermería en borrador.
Enfermero Clínico maneja Elaborar Plan de Cuidados de Enfermería.
Programar Visitas Domiciliarias genera Programa de Visitas.
Plan Terapéutico requiere Programar Visitas Domiciliarias en borrador.
Profesional Coordinador maneja Programar Visitas Domiciliarias.
Programar Rutas de Transporte genera Ruta de Transporte.
Programa de Visitas requiere Programar Rutas de Transporte.
Domicilio del Paciente requiere Programar Rutas de Transporte.
Personal Administrativo maneja Programar Rutas de Transporte.

=== SD1.4 ===
SD1 se refina por descomposición de Ejecutar Plan Terapéutico en SD1.4.
Médico de Atención Directa es un objeto, físico.
Cuidador es un objeto, físico.
Cuidador puede estar disponible o no disponible.
Enfermero Clínico es un objeto, físico.
Insumo Clínico es un objeto, físico.
Sistema de Comunicación es un objeto, físico.
Resumen Clínico Domiciliario es un objeto, informático.
Kinesiólogo es un objeto, físico.
Equipamiento Médico es un objeto, físico.
Medicamento es un objeto, físico.
Terapia Motora es un objeto, informático.
Plan de Cuidados de Enfermería es un objeto, informático.
Plan de Cuidados de Enfermería puede estar activo, completado o borrador.
Estado completado de Plan de Cuidados de Enfermería es final.
Estado borrador de Plan de Cuidados de Enfermería es inicial.
Técnico de Enfermería es un objeto, físico.
Grupo de Pacientes es un objeto, físico.
Receta Médica es un objeto, informático.
Médico Regulador es un objeto, físico.
Terapia Respiratoria es un objeto, informático.
Conocimiento de Autocuidado de Grupo de Pacientes es un objeto, informático.
Conocimiento de Autocuidado de Grupo de Pacientes puede estar insuficiente o suficiente.
Estado insuficiente de Conocimiento de Autocuidado de Grupo de Pacientes es inicial.
Registro de Telesalud es un objeto, informático.
Plan Terapéutico es un objeto, informático.
Plan Terapéutico puede estar activo, completado o borrador.
Estado activo de Plan Terapéutico es por defecto.
Estado completado de Plan Terapéutico es final.
Estado borrador de Plan Terapéutico es inicial.
Vehículo de Transporte es un objeto, físico.
Ejecutar Terapia Kinesiológica es un proceso, físico.
Realizar Visita Médica es un proceso, físico.
Administrar Medicamentos es un proceso, físico.
Ejecutar Cuidados de Enfermería es un proceso, físico.
Educar a Paciente y Cuidador es un proceso, informático.
Regular Atención a Distancia es un proceso, informático.
Ejecutar Plan Terapéutico es un proceso, físico.
Ejecutar Plan Terapéutico se descompone en paralelo Ejecutar Terapia Kinesiológica, Realizar Visita Médica, y Ejecutar Cuidados de Enfermería and paralelo Administrar Medicamentos, Educar a Paciente y Cuidador, y Regular Atención a Distancia, en esa secuencia.
Grupo de Pacientes exhibe Conocimiento de Autocuidado.
Enfermero Clínico maneja Administrar Medicamentos.
Técnico de Enfermería maneja Administrar Medicamentos.
Receta Médica requiere Administrar Medicamentos.
Regular Atención a Distancia afecta Grupo de Pacientes.
Sistema de Comunicación requiere Regular Atención a Distancia.
Médico Regulador maneja Regular Atención a Distancia.
Regular Atención a Distancia genera Registro de Telesalud.
Educar a Paciente y Cuidador afecta Grupo de Pacientes.
Educar a Paciente y Cuidador afecta Cuidador.
Plan Terapéutico requiere Educar a Paciente y Cuidador en activo.
Enfermero Clínico maneja Educar a Paciente y Cuidador.
Educar a Paciente y Cuidador cambia Conocimiento de Autocuidado de insuficiente a suficiente.
Realizar Visita Médica afecta Grupo de Pacientes.
Plan Terapéutico requiere Realizar Visita Médica en activo.
Equipamiento Médico requiere Realizar Visita Médica.
Vehículo de Transporte requiere Realizar Visita Médica.
Realizar Visita Médica genera Resumen Clínico Domiciliario.
Médico de Atención Directa maneja Realizar Visita Médica.
Ejecutar Cuidados de Enfermería afecta Grupo de Pacientes.
Plan de Cuidados de Enfermería requiere Ejecutar Cuidados de Enfermería en activo.
Equipamiento Médico requiere Ejecutar Cuidados de Enfermería.
Ejecutar Cuidados de Enfermería consume Insumo Clínico.
Enfermero Clínico maneja Ejecutar Cuidados de Enfermería.
Técnico de Enfermería maneja Ejecutar Cuidados de Enfermería.
Ejecutar Terapia Kinesiológica afecta Grupo de Pacientes.
Plan Terapéutico requiere Ejecutar Terapia Kinesiológica en activo.
Equipamiento Médico requiere Ejecutar Terapia Kinesiológica.
Kinesiólogo maneja Ejecutar Terapia Kinesiológica.
Ejecutar Terapia Kinesiológica genera Terapia Motora.
Ejecutar Terapia Kinesiológica genera Terapia Respiratoria.
Administrar Medicamentos consume Medicamento.
Administrar Medicamentos afecta Grupo de Pacientes.
Plan Terapéutico requiere Administrar Medicamentos en activo.

=== SD1.5 ===
SD1 se refina por descomposición de Monitorear Evolución Clínica en SD1.5.
Médico de Atención Directa es un objeto, físico.
Presión Arterial es un objeto, informático.
Enfermero Clínico es un objeto, físico.
Ficha Clínica es un objeto, informático.
Sistema de Comunicación es un objeto, físico.
Decisión de Continuidad es un objeto, informático.
Decisión de Continuidad puede estar continuar tratamiento o proceder egreso.
Frecuencia Cardíaca es un objeto, informático.
Equipamiento Médico es un objeto, físico.
Saturación de Oxígeno es un objeto, informático.
Categoría del Paciente es un objeto, informático.
Categoría del Paciente puede estar deteriorándose, mejorando o estable.
Estado estable de Categoría del Paciente es por defecto.
Grupo de Pacientes es un objeto, físico.
Frecuencia Respiratoria es un objeto, informático.
Datos de Signos Vitales es un objeto, informático.
Monitorear Evolución Clínica es un proceso, informático.
Actualizar Registro Clínico es un proceso, informático.
Decidir Continuidad es un proceso, informático.
Categorizar Paciente es un proceso, informático.
Evaluar Signos Vitales es un proceso, informático.
Monitorear Evolución Clínica se descompone en paralelo Actualizar Registro Clínico and Evaluar Signos Vitales and paralelo Decidir Continuidad and Categorizar Paciente, en esa secuencia.
Datos de Signos Vitales consta de Presión Arterial, Frecuencia Cardíaca, Frecuencia Respiratoria, y Saturación de Oxígeno.
Evaluar Signos Vitales afecta Grupo de Pacientes.
Equipamiento Médico requiere Evaluar Signos Vitales.
Enfermero Clínico maneja Evaluar Signos Vitales.
Evaluar Signos Vitales genera Datos de Signos Vitales.
Actualizar Registro Clínico consume Datos de Signos Vitales.
Actualizar Registro Clínico afecta Ficha Clínica.
Sistema de Comunicación requiere Actualizar Registro Clínico.
Enfermero Clínico maneja Actualizar Registro Clínico.
Categorizar Paciente genera Categoría del Paciente.
Datos de Signos Vitales requiere Categorizar Paciente.
Médico de Atención Directa maneja Categorizar Paciente.
Decidir Continuidad genera Decisión de Continuidad.
Categoría del Paciente requiere Decidir Continuidad.
Médico de Atención Directa maneja Decidir Continuidad.

=== SD1.6 ===
SD1 se refina por descomposición de despliegue de Egresar de Hospitalización Domiciliaria en SD1.6.
Médico de Atención Directa es un objeto, físico.
Condición Clínica es un objeto, informático.
Condición Clínica puede estar agudo/reagudizado o recuperado.
Estado agudo/reagudizado de Condición Clínica es inicial.
Estado recuperado de Condición Clínica es final.
Inestabilidad Clínica es un objeto, informático.
Inestabilidad Clínica puede estar ausente o presente.
Protocolo de Fallecimiento es un objeto, informático.
Epicrisis es un objeto, informático.
Estado de Hospitalización es un objeto, informático.
Estado de Hospitalización puede estar activo o egresado.
Estado activo de Estado de Hospitalización es inicial.
Estado egresado de Estado de Hospitalización es final.
Consentimiento Informado es un objeto, informático.
Consentimiento Informado puede estar firmado o sin firmar.
Estado firmado de Consentimiento Informado es final.
Estado sin firmar de Consentimiento Informado es inicial.
Establecimiento de Atención Cerrada es un objeto, físico, ambiental.
Director Técnico es un objeto, físico.
Vehículo de Transporte es un objeto, físico.
Adherencia al Tratamiento es un objeto, informático.
Adherencia al Tratamiento puede estar adherente o no adherente.
Declaración de Retiro es un objeto, informático.
Egresar por Fallecimiento es un proceso, informático.
Egresar por Alta Disciplinaria es un proceso, informático.
Egresar por Reingreso Hospitalario es un proceso, informático.
Egresar por Alta Médica es un proceso, informático.
Egresar de Hospitalización Domiciliaria es un proceso, informático.
Egresar por Renuncia Voluntaria es un proceso, informático.
Egresar de Hospitalización Domiciliaria se descompone en paralelo Egresar por Fallecimiento, Egresar por Alta Disciplinaria, Egresar por Reingreso Hospitalario, Egresar por Alta Médica, y Egresar por Renuncia Voluntaria.
Egresar por Alta Médica, Egresar por Reingreso Hospitalario, Egresar por Fallecimiento, Egresar por Renuncia Voluntaria, y Egresar por Alta Disciplinaria son un Egresar de Hospitalización Domiciliaria.
Egresar por Alta Médica cambia Condición Clínica a recuperado.
Egresar por Alta Médica cambia Estado de Hospitalización de activo a egresado.
Egresar por Alta Médica genera Epicrisis.
Médico de Atención Directa maneja Egresar por Alta Médica.
Egresar por Reingreso Hospitalario cambia Estado de Hospitalización de activo a egresado.
Establecimiento de Atención Cerrada requiere Egresar por Reingreso Hospitalario.
Vehículo de Transporte requiere Egresar por Reingreso Hospitalario.
Egresar por Reingreso Hospitalario genera Epicrisis.
Médico de Atención Directa maneja Egresar por Reingreso Hospitalario.
Egresar por Fallecimiento cambia Estado de Hospitalización de activo a egresado.
Egresar por Fallecimiento genera Epicrisis.
Médico de Atención Directa maneja Egresar por Fallecimiento.
Egresar por Fallecimiento genera Protocolo de Fallecimiento.
Egresar por Renuncia Voluntaria cambia Estado de Hospitalización de activo a egresado.
Consentimiento Informado requiere Egresar por Renuncia Voluntaria.
Egresar por Renuncia Voluntaria genera Epicrisis.
Egresar por Renuncia Voluntaria genera Declaración de Retiro.
Egresar por Alta Disciplinaria cambia Estado de Hospitalización de activo a egresado.
Director Técnico maneja Egresar por Alta Disciplinaria.
Egresar por Alta Disciplinaria genera Epicrisis.
Inestabilidad Clínica requiere Egresar por Reingreso Hospitalario en presente.
Adherencia al Tratamiento requiere Egresar por Alta Disciplinaria en no adherente.
Egresar de Hospitalización Domiciliaria requiere Estado de Hospitalización en egresado.
Egresar por Reingreso Hospitalario requiere Estado de Hospitalización en egresado.
Egresar por Alta Disciplinaria requiere Estado de Hospitalización en egresado.

=== SD2 ===
SD se refina por descomposición de despliegue de Equipo de Salud en SD2.
Personal Administrativo es un objeto, físico.
Médico de Atención Directa es un objeto, físico.
Certificación SVB de Médico de Atención Directa es un objeto, informático.
Experiencia Clínica de Director Técnico es un objeto, informático.
Enfermero Clínico es un objeto, físico.
Profesional Coordinador es un objeto, físico.
Equipo de Salud es un objeto, físico.
Curso IAAS de Profesional Coordinador es un objeto, informático.
Curso de Prevención de IAAS de Director Técnico es un objeto, informático.
Kinesiólogo es un objeto, físico.
Formación en Gestión de Profesional Coordinador es un objeto, informático.
Técnico de Enfermería es un objeto, físico.
Formación de Postgrado en Gestión de Director Técnico es un objeto, informático.
Médico Regulador es un objeto, físico.
Experiencia en Regulación de Médico Regulador es un objeto, informático.
Trabajador Social es un objeto, físico.
Director Técnico es un objeto, físico.
Dedicación Semanal de Director Técnico es un objeto, informático.
Equipo de Salud consta de Director Técnico, Profesional Coordinador, Médico de Atención Directa, Médico Regulador, Enfermero Clínico, Kinesiólogo, Técnico de Enfermería, Trabajador Social, y Personal Administrativo.
Director Técnico exhibe Experiencia Clínica, Formación de Postgrado en Gestión, Curso de Prevención de IAAS, y Dedicación Semanal.
Profesional Coordinador exhibe Experiencia Clínica, Formación en Gestión, y Curso IAAS.
Médico de Atención Directa exhibe Experiencia Clínica, Curso IAAS, y Certificación SVB.
Médico Regulador exhibe Experiencia en Regulación and Certificación SVB.
Enfermero Clínico exhibe Experiencia Clínica and Certificación SVB.
Kinesiólogo exhibe Experiencia Clínica and Certificación SVB.
Técnico de Enfermería exhibe Experiencia Clínica and Certificación SVB.
Médico Regulador supports Médico de Atención Directa.

=== SD3 ===
SD se refina por descomposición de despliegue de Infraestructura Administrativa en SD3.
Infraestructura Administrativa es un objeto, físico.
Disponibilidad de Sistema Telefónico es un objeto, informático.
Disponibilidad de Sistema Telefónico puede estar 24/7 o parcial.
Estado 24/7 de Disponibilidad de Sistema Telefónico es inicial.
Sala de Estar es un objeto, físico.
Recinto de Aseo es un objeto, físico.
Área de Archivo Clínico es un objeto, físico.
Cumplimiento de Cadena de Frío de Farmacia o Botiquín Autorizado es un objeto, informático.
Cumplimiento de Cadena de Frío de Farmacia o Botiquín Autorizado puede estar cumple o no cumple.
Estado cumple de Cumplimiento de Cadena de Frío de Farmacia o Botiquín Autorizado es inicial.
Acceso a Alimentación es un objeto, físico.
Respaldo Eléctrico es un objeto, físico.
Sistema de Señalización y Evacuación es un objeto, físico.
Servicios Higiénicos es un objeto, físico.
Conectividad Internet de Sistema Informático es un objeto, informático.
Sistema Informático es un objeto, informático.
Casilleros es un objeto, físico.
Farmacia o Botiquín Autorizado es un objeto, físico.
Cumplimiento REAS de Área de Disposición de Residuos es un objeto, informático.
Cumplimiento REAS de Área de Disposición de Residuos puede estar cumple o no cumple.
Autorización SEC de Respaldo Eléctrico es un objeto, informático.
Nivel de Seguridad de Área de Archivo Clínico es un objeto, informático.
Nivel de Seguridad de Área de Archivo Clínico puede estar seguro o no seguro.
Área de Bienestar del Personal es un objeto, físico.
Bodega de Insumos es un objeto, físico.
Sistema Telefónico es un objeto, físico.
Control de Temperatura de Bodega de Insumos es un objeto, informático.
Estacionamiento de Vehículos es un objeto, físico.
Área de Disposición de Residuos es un objeto, físico.
Infraestructura Administrativa consta de Sistema Telefónico, Sistema Informático, Respaldo Eléctrico, Área de Archivo Clínico, Farmacia o Botiquín Autorizado, Bodega de Insumos, Área de Disposición de Residuos, Recinto de Aseo, Área de Bienestar del Personal, Estacionamiento de Vehículos, y Sistema de Señalización y Evacuación.
Área de Bienestar del Personal consta de Acceso a Alimentación, Servicios Higiénicos, Casilleros, y Sala de Estar.
Sistema Telefónico exhibe Disponibilidad.
Sistema Informático exhibe Conectividad Internet.
Respaldo Eléctrico exhibe Autorización SEC.
Área de Archivo Clínico exhibe Nivel de Seguridad.
Farmacia o Botiquín Autorizado exhibe Cumplimiento de Cadena de Frío.
Bodega de Insumos exhibe Control de Temperatura.
Área de Disposición de Residuos exhibe Cumplimiento REAS.

=== SD4 ===
SD se refina por descomposición de despliegue de Equipamiento Médico en SD4.
Monitor de Presión Arterial es un objeto, físico.
Monitor Cardíaco es un objeto, físico.
Desfibrilador es un objeto, físico.
Estado de Mantención de Equipamiento Médico es un objeto, informático.
Estado de Mantención de Equipamiento Médico puede estar vigente o vencido.
Estado vigente de Estado de Mantención de Equipamiento Médico es inicial.
Equipamiento Médico es un objeto, físico.
Oxímetro de Pulso es un objeto, físico.
Autorización Sanitaria de Equipamiento Médico es un objeto, informático.
Autorización Sanitaria de Equipamiento Médico puede estar autorizado o no autorizado.
Estado autorizado de Autorización Sanitaria de Equipamiento Médico es inicial.
Conjunto de Instrumentos Especializados es un objeto, físico.
Termómetro es un objeto, físico.
Equipamiento Médico consta de Monitor de Presión Arterial, Oxímetro de Pulso, Monitor Cardíaco, Termómetro, Desfibrilador, y Conjunto de Instrumentos Especializados.
Equipamiento Médico exhibe Estado de Mantención and Autorización Sanitaria.

=== SD5 ===
SD se refina por descomposición de despliegue de Sistema de Hospitalización Domiciliaria en SD5.
Protocolo de Evaluación e Ingreso es un objeto, informático.
Plan Anual de Capacitación es un objeto, informático.
Capacitación SVB es un objeto, informático.
Protocolo de Categorización y Egreso es un objeto, informático.
Procedimiento de Vía Venosa Central es un objeto, informático.
Conjunto de Protocolos Clínicos es un objeto, informático.
Sistema Documental de Sistema de Hospitalización Domiciliaria es un objeto, informático.
Protocolo de Actuación ante Emergencias es un objeto, informático.
Sistema de Hospitalización Domiciliaria es un objeto, físico.
Capacitación en Humanización del Cuidado es un objeto, informático.
Reglamento de Higiene es un objeto, informático.
Capacitación IAAS es un objeto, informático.
Manual de Organización Interna es un objeto, informático.
Procedimiento de Precauciones de Aislamiento es un objeto, informático.
Duración Mínima de Programa de Inducción es un objeto, informático.
Organigrama es un objeto, informático.
Procedimiento de Vía Venosa Periférica es un objeto, informático.
Protocolo de Gestión de Recetas e Interconsultas es un objeto, informático.
Manual de Procedimientos es un objeto, informático.
Cumplimiento Decreto REAS de Protocolo de Manejo de Residuos es un objeto, informático.
Conjunto de Definiciones de Rol es un objeto, informático.
Procedimiento de Toma de Muestras es un objeto, informático.
Definición de Horarios es un objeto, informático.
Protocolo ante Agresiones al Personal es un objeto, informático.
Programa de Inducción es un objeto, informático.
Procedimiento de Traqueostomía es un objeto, informático.
Procedimiento de Catéter Urinario es un objeto, informático.
Protocolo de Programación de Visitas y Rutas es un objeto, informático.
Protocolo de Manejo de Residuos es un objeto, informático.
Sistema Documental consta de Manual de Organización Interna, Conjunto de Protocolos Clínicos, Manual de Procedimientos, Protocolo de Manejo de Residuos, y Plan Anual de Capacitación.
Manual de Organización Interna consta de Organigrama, Conjunto de Definiciones de Rol, Definición de Horarios, y Reglamento de Higiene.
Conjunto de Protocolos Clínicos consta de Protocolo de Evaluación e Ingreso, Protocolo de Programación de Visitas y Rutas, Protocolo de Categorización y Egreso, Protocolo de Gestión de Recetas e Interconsultas, Protocolo de Actuación ante Emergencias, y Protocolo ante Agresiones al Personal.
Manual de Procedimientos consta de Procedimiento de Vía Venosa Periférica, Procedimiento de Vía Venosa Central, Procedimiento de Catéter Urinario, Procedimiento de Traqueostomía, Procedimiento de Toma de Muestras, y Procedimiento de Precauciones de Aislamiento.
Plan Anual de Capacitación consta de Capacitación IAAS, Capacitación SVB, Programa de Inducción, y Capacitación en Humanización del Cuidado.
Sistema de Hospitalización Domiciliaria exhibe Sistema Documental.
Protocolo de Manejo de Residuos exhibe Cumplimiento Decreto REAS.
Programa de Inducción exhibe Duración Mínima.

=== SD6 ===
SD se refina por descomposición de despliegue de Sistema de Hospitalización Domiciliaria en SD6.
Auditoría de Reacciones Adversas es un objeto, informático.
Plan Anual de Capacitación es un objeto, informático.
Vigencia de Autorización de Estado de Autorización Sanitaria es un objeto, informático.
Residuo Biomédico es un objeto, físico.
Insumo Clínico es un objeto, físico.
Profesional Coordinador es un objeto, físico.
Normativa Vigente es un objeto, informático, ambiental.
Sistema Documental de Sistema de Hospitalización Domiciliaria es un objeto, informático.
Equipo de Salud es un objeto, físico.
Sistema de Hospitalización Domiciliaria es un objeto, físico.
Estado de Mantención de Equipamiento Médico es un objeto, informático.
Estado de Mantención de Equipamiento Médico puede estar vigente o vencido.
Estado vigente de Estado de Mantención de Equipamiento Médico es inicial.
Equipamiento Médico es un objeto, físico.
Medicamento es un objeto, físico.
Auditoría de Mortalidad es un objeto, informático.
Farmacia o Botiquín Autorizado es un objeto, físico.
Programa de Mantención Preventiva es un objeto, informático.
Nivel de Calidad de Sistema de Hospitalización Domiciliaria es un objeto, informático.
Estado de Autorización Sanitaria de Sistema de Hospitalización Domiciliaria es un objeto, informático.
Estado de Autorización Sanitaria de Sistema de Hospitalización Domiciliaria puede estar autorizado, vencida o pendiente.
Estado pendiente de Estado de Autorización Sanitaria de Sistema de Hospitalización Domiciliaria es inicial.
SEREMI es un objeto, físico, ambiental.
Protocolo de Desecho de Cortopunzantes es un objeto, informático.
Director Técnico es un objeto, físico.
Cumplimiento de Capacitación de Equipo de Salud es un objeto, informático.
Cumplimiento de Capacitación de Equipo de Salud puede estar cumple o no cumple.
Área de Disposición de Residuos es un objeto, físico.
Protocolo de Manejo de Residuos es un objeto, informático.
Gestionar Mantención de Equipos de Sistema de Hospitalización Domiciliaria es un proceso, informático.
Gestionar Calidad y Seguridad de Sistema de Hospitalización Domiciliaria es un proceso, informático.
Gestionar Autorización Sanitaria de Sistema de Hospitalización Domiciliaria es un proceso, informático.
Gestionar Capacitación del Personal de Sistema de Hospitalización Domiciliaria es un proceso, informático.
Gestionar Cadena de Abastecimiento de Sistema de Hospitalización Domiciliaria es un proceso, informático.
Gestionar Residuos de Sistema de Hospitalización Domiciliaria es un proceso, informático.
Sistema de Hospitalización Domiciliaria se descompone en paralelo Gestionar Calidad y Seguridad, Gestionar Autorización Sanitaria, y Gestionar Capacitación del Personal and paralelo Gestionar Mantención de Equipos, Gestionar Cadena de Abastecimiento, y Gestionar Residuos, en esa secuencia.
Equipo de Salud consta de Director Técnico and Profesional Coordinador.
Sistema Documental consta de Protocolo de Manejo de Residuos and Plan Anual de Capacitación.
Equipamiento Médico exhibe Estado de Mantención.
Sistema de Hospitalización Domiciliaria exhibe Sistema Documental, Estado de Autorización Sanitaria, y Nivel de Calidad, así como Gestionar Autorización Sanitaria, Gestionar Calidad y Seguridad, Gestionar Capacitación del Personal, Gestionar Cadena de Abastecimiento, Gestionar Residuos, y Gestionar Mantención de Equipos.
Estado de Autorización Sanitaria exhibe Vigencia de Autorización.
Equipo de Salud exhibe Cumplimiento de Capacitación.
Normativa Vigente requiere Gestionar Autorización Sanitaria.
Director Técnico maneja Gestionar Autorización Sanitaria.
Gestionar Autorización Sanitaria cambia Estado de Autorización Sanitaria de pendiente a autorizado.
SEREMI requiere Gestionar Autorización Sanitaria.
Sistema Documental requiere Gestionar Calidad y Seguridad.
Profesional Coordinador maneja Gestionar Calidad y Seguridad.
Gestionar Calidad y Seguridad afecta Nivel de Calidad.
Gestionar Calidad y Seguridad genera Auditoría de Reacciones Adversas.
Gestionar Calidad y Seguridad genera Auditoría de Mortalidad.
Gestionar Capacitación del Personal afecta Equipo de Salud.
Plan Anual de Capacitación requiere Gestionar Capacitación del Personal.
Profesional Coordinador maneja Gestionar Capacitación del Personal.
Gestionar Capacitación del Personal cambia Cumplimiento de Capacitación de no cumple a cumple.
Gestionar Cadena de Abastecimiento afecta Insumo Clínico.
Gestionar Cadena de Abastecimiento afecta Medicamento.
Farmacia o Botiquín Autorizado requiere Gestionar Cadena de Abastecimiento.
Profesional Coordinador maneja Gestionar Cadena de Abastecimiento.
Gestionar Residuos consume Residuo Biomédico.
Área de Disposición de Residuos requiere Gestionar Residuos.
Protocolo de Manejo de Residuos requiere Gestionar Residuos.
Protocolo de Desecho de Cortopunzantes requiere Gestionar Residuos.
Gestionar Mantención de Equipos afecta Equipamiento Médico.
Gestionar Mantención de Equipos cambia Estado de Mantención de vencido a vigente.
Director Técnico maneja Gestionar Mantención de Equipos.
Programa de Mantención Preventiva requiere Gestionar Mantención de Equipos.

=== SD7 ===
SD se refina por descomposición de despliegue de Domicilio del Paciente en SD7.
Servicios Básicos de Domicilio del Paciente es un objeto, informático.
Servicios Básicos de Domicilio del Paciente puede estar disponible o no disponible.
Estado disponible de Servicios Básicos de Domicilio del Paciente es inicial.
Cumplimiento de Radio de Cobertura de Domicilio del Paciente es un objeto, informático.
Cumplimiento de Radio de Cobertura de Domicilio del Paciente puede estar cumple o no cumple.
Condición del Domicilio de Domicilio del Paciente es un objeto, informático.
Condición del Domicilio de Domicilio del Paciente puede estar adecuada o inadecuada.
Estado adecuada de Condición del Domicilio de Domicilio del Paciente es final.
Domicilio del Paciente es un objeto, físico, ambiental.
Acceso Vial de Domicilio del Paciente es un objeto, informático.
Acceso Vial de Domicilio del Paciente puede estar fuera del radio o dentro del radio.
Estado dentro del radio de Acceso Vial de Domicilio del Paciente es inicial.
Acceso a Telefonía de Domicilio del Paciente es un objeto, informático.
Acceso a Telefonía de Domicilio del Paciente puede estar disponible o no disponible.
Domicilio del Paciente exhibe Condición del Domicilio, Servicios Básicos, Acceso a Telefonía, Acceso Vial, Cumplimiento de Radio de Cobertura, y Condición del Domicilio.

=== SD9 ===
Médico de Atención Directa es un objeto, físico.
Cuidador es un objeto, físico.
Cuidador puede estar disponible o no disponible.
Continuidad de la Atención es un objeto, informático.
Normativa Vigente es un objeto, informático, ambiental.
Sistema de Hospitalización Domiciliaria es un objeto, físico.
Establecimiento de Atención Cerrada es un objeto, físico, ambiental.
Grupo de Pacientes es un objeto, físico.
Domicilio del Paciente es un objeto, físico, ambiental.
Médico Regulador es un objeto, físico.
Director Técnico es un objeto, físico.
Normativa Vigente governs Sistema de Hospitalización Domiciliaria.
Establecimiento de Atención Cerrada refers Grupo de Pacientes.
Domicilio del Paciente hosts Grupo de Pacientes.
Director Técnico represents Sistema de Hospitalización Domiciliaria.
Sistema de Hospitalización Domiciliaria guarantees Continuidad de la Atención.
Médico de Atención Directa coordinates Establecimiento de Atención Cerrada.
Médico Regulador supports Médico de Atención Directa.
Cuidador cares-for Grupo de Pacientes.