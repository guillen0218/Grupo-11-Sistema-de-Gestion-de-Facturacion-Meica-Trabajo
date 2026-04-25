-- ============================================================
-- SISTEMA DE GESTIÓN DE FACTURACIÓN MÉDICA
-- Archivo: 09_diccionario_datos.sql
-- Descripción: Diccionario de datos del sistema
-- Grupo 11 - Universidad Fidélitas
-- ============================================================

-- ============================================================
-- SECCIÓN 1: RESUMEN DE TABLAS
-- ============================================================
SELECT
    T.TABLE_NAME                                          AS TABLA,
    OBJ.CREATED                                           AS FECHA_CREACION,
    (SELECT COUNT(*) FROM USER_COLUMNS C
     WHERE C.TABLE_NAME = T.TABLE_NAME)                  AS TOTAL_COLUMNAS,
    (SELECT COUNT(*) FROM USER_CONSTRAINTS K
     WHERE K.TABLE_NAME = T.TABLE_NAME
       AND K.CONSTRAINT_TYPE = 'P')                      AS TIENE_PK,
    (SELECT COUNT(*) FROM USER_CONSTRAINTS K
     WHERE K.TABLE_NAME = T.TABLE_NAME
       AND K.CONSTRAINT_TYPE = 'R')                      AS CANTIDAD_FK
FROM USER_TABLES T
JOIN USER_OBJECTS OBJ
    ON OBJ.OBJECT_NAME = T.TABLE_NAME
    AND OBJ.OBJECT_TYPE = 'TABLE'
WHERE T.TABLE_NAME IN (
    'SEGURO_MEDICO','PACIENTE','MEDICO','CITA',
    'SERVICIO','FACTURA','DETALLE_FACTURA','PAGO',
    'USUARIO_SISTEMA','AUDIT_FACTURA'
)
ORDER BY OBJ.CREATED;

-- ============================================================
-- SECCIÓN 2: COLUMNAS POR TABLA (DICCIONARIO COMPLETO)
-- ============================================================
SELECT
    C.TABLE_NAME                                          AS TABLA,
    C.COLUMN_ID                                           AS ORDEN,
    C.COLUMN_NAME                                         AS COLUMNA,
    C.DATA_TYPE
        || CASE
            WHEN C.DATA_TYPE IN ('VARCHAR2','CHAR')
                THEN '(' || C.CHAR_LENGTH || ')'
            WHEN C.DATA_TYPE = 'NUMBER' AND C.DATA_PRECISION IS NOT NULL
                THEN '(' || C.DATA_PRECISION || ',' || NVL(C.DATA_SCALE,0) || ')'
            ELSE ''
           END                                            AS TIPO_DATO,
    CASE C.NULLABLE WHEN 'N' THEN 'NO' ELSE 'SÍ' END    AS PERMITE_NULO,
    C.DATA_DEFAULT                                        AS VALOR_DEFAULT
FROM USER_TAB_COLUMNS C
WHERE C.TABLE_NAME IN (
    'SEGURO_MEDICO','PACIENTE','MEDICO','CITA',
    'SERVICIO','FACTURA','DETALLE_FACTURA','PAGO',
    'USUARIO_SISTEMA','AUDIT_FACTURA'
)
ORDER BY C.TABLE_NAME, C.COLUMN_ID;

-- ============================================================
-- SECCIÓN 3: LLAVES PRIMARIAS Y FORÁNEAS
-- ============================================================
SELECT
    K.TABLE_NAME                                          AS TABLA,
    K.CONSTRAINT_NAME                                     AS CONSTRAINT,
    CASE K.CONSTRAINT_TYPE
        WHEN 'P' THEN 'PRIMARY KEY'
        WHEN 'R' THEN 'FOREIGN KEY'
        WHEN 'U' THEN 'UNIQUE'
        WHEN 'C' THEN 'CHECK'
    END                                                   AS TIPO,
    CC.COLUMN_NAME                                        AS COLUMNA,
    RK.TABLE_NAME                                         AS TABLA_REFERENCIADA,
    RCC.COLUMN_NAME                                       AS COLUMNA_REFERENCIADA
FROM USER_CONSTRAINTS K
JOIN USER_CONS_COLUMNS CC
    ON K.CONSTRAINT_NAME = CC.CONSTRAINT_NAME
LEFT JOIN USER_CONSTRAINTS RK
    ON K.R_CONSTRAINT_NAME = RK.CONSTRAINT_NAME
LEFT JOIN USER_CONS_COLUMNS RCC
    ON RK.CONSTRAINT_NAME = RCC.CONSTRAINT_NAME
WHERE K.TABLE_NAME IN (
    'SEGURO_MEDICO','PACIENTE','MEDICO','CITA',
    'SERVICIO','FACTURA','DETALLE_FACTURA','PAGO',
    'USUARIO_SISTEMA','AUDIT_FACTURA'
)
AND K.CONSTRAINT_TYPE IN ('P','R','U')
ORDER BY K.TABLE_NAME, K.CONSTRAINT_TYPE, CC.COLUMN_NAME;

-- ============================================================
-- SECCIÓN 4: OBJETOS PL/SQL DEL SISTEMA
-- ============================================================
SELECT
    OBJECT_TYPE                                           AS TIPO,
    OBJECT_NAME                                           AS NOMBRE,
    STATUS                                                AS ESTADO,
    TO_CHAR(CREATED, 'DD/MM/YYYY HH24:MI')              AS CREADO,
    TO_CHAR(LAST_DDL_TIME, 'DD/MM/YYYY HH24:MI')        AS ULTIMA_MODIFICACION
FROM USER_OBJECTS
WHERE OBJECT_TYPE IN ('PROCEDURE','FUNCTION','PACKAGE','PACKAGE BODY','TRIGGER','VIEW','SEQUENCE')
ORDER BY OBJECT_TYPE, OBJECT_NAME;

PROMPT ✓ Diccionario de datos generado exitosamente.
