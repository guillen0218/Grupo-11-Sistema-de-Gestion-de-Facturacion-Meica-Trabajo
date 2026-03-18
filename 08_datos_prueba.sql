-- ============================================================
-- SISTEMA DE GESTIÓN DE FACTURACIÓN MÉDICA
-- Archivo: 08_datos_prueba.sql
-- Descripción: Datos de prueba extendidos
-- Grupo 11 - Universidad Fidélitas
-- ============================================================

-- Seguros adicionales
INSERT INTO SEGURO_MEDICO (NOMBRE_ASEGURADORA, NUMERO_POLIZA, COBERTURA_PORCENTAJE, FECHA_VENCIMIENTO)
VALUES ('MAPFRE Costa Rica', 'MAP-2024-012', 75, DATE '2026-09-30');

INSERT INTO SEGURO_MEDICO (NOMBRE_ASEGURADORA, NUMERO_POLIZA, COBERTURA_PORCENTAJE, FECHA_VENCIMIENTO)
VALUES ('Pan-American Life', 'PAL-2024-088', 85, DATE '2027-01-15');

-- Médicos adicionales
INSERT INTO MEDICO (CEDULA, NOMBRE, APELLIDOS, ESPECIALIDAD, CODIGO_MEDICO, TELEFONO, CORREO)
VALUES ('102340004', 'María', 'Solís Herrera', 'Dermatología', 'DER-0004', '8888-0004', 'm.solis@clinica.cr');

INSERT INTO MEDICO (CEDULA, NOMBRE, APELLIDOS, ESPECIALIDAD, CODIGO_MEDICO, TELEFONO, CORREO)
VALUES ('102340005', 'Jorge', 'Méndez Quirós', 'Neurología', 'NEU-0005', '8888-0005', 'j.mendez@clinica.cr');

-- Pacientes adicionales
INSERT INTO PACIENTE (ID_SEGURO, CEDULA, NOMBRE, APELLIDOS, FECHA_NACIMIENTO, TELEFONO, CORREO, DIRECCION)
VALUES (4, '304560004', 'Carlos', 'Ramírez Torres', DATE '1980-03-10', '7070-1004', 'c.ramirez@mail.com', 'Cartago Centro');

INSERT INTO PACIENTE (ID_SEGURO, CEDULA, NOMBRE, APELLIDOS, FECHA_NACIMIENTO, TELEFONO, CORREO, DIRECCION)
VALUES (5, '304560005', 'Lucía', 'Vargas Mora', DATE '1995-08-25', '7070-1005', 'l.vargas@mail.com', 'Alajuela Centro');

INSERT INTO PACIENTE (ID_SEGURO, CEDULA, NOMBRE, APELLIDOS, FECHA_NACIMIENTO, TELEFONO, CORREO, DIRECCION)
VALUES (1, '304560006', 'Andrés', 'Chaves Brenes', DATE '2001-12-01', '7070-1006', 'a.chaves@mail.com', 'San José, La Sabana');

-- Servicios adicionales
INSERT INTO SERVICIO (NOMBRE_SERVICIO, DESCRIPCION, PRECIO_BASE, CATEGORIA)
VALUES ('Ultrasonido Abdominal', 'Ecosonografía de abdomen completo', 35000, 'IMAGENOLOGIA');

INSERT INTO SERVICIO (NOMBRE_SERVICIO, DESCRIPCION, PRECIO_BASE, CATEGORIA)
VALUES ('Glucosa en Ayunas', 'Medición de glucosa sérica en ayunas', 4500, 'LABORATORIO');

INSERT INTO SERVICIO (NOMBRE_SERVICIO, DESCRIPCION, PRECIO_BASE, CATEGORIA)
VALUES ('Consulta Dermatológica', 'Evaluación dermatológica especializada', 22000, 'CONSULTA');

INSERT INTO SERVICIO (NOMBRE_SERVICIO, DESCRIPCION, PRECIO_BASE, CATEGORIA)
VALUES ('Perfil Lipídico', 'Colesterol total HDL LDL triglicéridos', 12000, 'LABORATORIO');

-- Usuarios adicionales
INSERT INTO USUARIO_SISTEMA (NOMBRE_USUARIO, CONTRASENA_HASH, ROL, CORREO)
VALUES ('facturista01', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'FACTURISTA', 'facturista01@clinica.cr');

INSERT INTO USUARIO_SISTEMA (NOMBRE_USUARIO, CONTRASENA_HASH, ROL, CORREO)
VALUES ('recepcion01', 'b3a8e0e1f9ab1bfe3a36f231f676f78bb28a2028fd6e085a1ef092a8a3e33da0', 'RECEPCIONISTA', 'recepcion01@clinica.cr');

COMMIT;

PROMPT ✓ Datos de prueba extendidos insertados exitosamente.
