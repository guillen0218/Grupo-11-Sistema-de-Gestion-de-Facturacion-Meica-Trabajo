-- ============================================================
-- SISTEMA DE GESTIÓN DE FACTURACIÓN MÉDICA
-- Archivo: 02_procedimientos_almacenados.sql
-- Total: 25 procedimientos almacenados
-- ============================================================

-- MÓDULO PACIENTE (SP01 - SP05)

-- SP01: Insertar paciente
CREATE OR REPLACE PROCEDURE sp_insertar_paciente(
    p_id_seguro        IN NUMBER,
    p_cedula           IN VARCHAR2,
    p_nombre           IN VARCHAR2,
    p_apellidos        IN VARCHAR2,
    p_fecha_nacimiento IN DATE,
    p_telefono         IN VARCHAR2,
    p_correo           IN VARCHAR2,
    p_direccion        IN VARCHAR2,
    p_resultado        OUT NUMBER,
    p_mensaje          OUT VARCHAR2
) AS
BEGIN
    INSERT INTO PACIENTE(ID_SEGURO, CEDULA, NOMBRE, APELLIDOS,
                         FECHA_NACIMIENTO, TELEFONO, CORREO, DIRECCION)
    VALUES (p_id_seguro, p_cedula, p_nombre, p_apellidos,
            p_fecha_nacimiento, p_telefono, p_correo, p_direccion);
    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Paciente registrado exitosamente.';
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error: ya existe un paciente con esa cédula.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_insertar_paciente;
/

-- SP02: Actualizar paciente
CREATE OR REPLACE PROCEDURE sp_actualizar_paciente(
    p_id_paciente IN NUMBER,
    p_id_seguro   IN NUMBER,
    p_nombre      IN VARCHAR2,
    p_apellidos   IN VARCHAR2,
    p_telefono    IN VARCHAR2,
    p_correo      IN VARCHAR2,
    p_direccion   IN VARCHAR2,
    p_resultado   OUT NUMBER,
    p_mensaje     OUT VARCHAR2
) AS
BEGIN
    UPDATE PACIENTE
    SET ID_SEGURO = p_id_seguro,
        NOMBRE    = p_nombre,
        APELLIDOS = p_apellidos,
        TELEFONO  = p_telefono,
        CORREO    = p_correo,
        DIRECCION = p_direccion
    WHERE ID_PACIENTE = p_id_paciente;

    IF SQL%ROWCOUNT = 0 THEN
        p_resultado := 0;
        p_mensaje   := 'Error: paciente no encontrado.';
    ELSE
        COMMIT;
        p_resultado := 1;
        p_mensaje   := 'Paciente actualizado exitosamente.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_actualizar_paciente;
/

-- SP03: Eliminar paciente (con validación de dependencias)
CREATE OR REPLACE PROCEDURE sp_eliminar_paciente(
    p_id_paciente IN NUMBER,
    p_resultado   OUT NUMBER,
    p_mensaje     OUT VARCHAR2
) AS
    v_citas NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_citas FROM CITA WHERE ID_PACIENTE = p_id_paciente;
    IF v_citas > 0 THEN
        p_resultado := 0;
        p_mensaje   := 'No se puede eliminar: el paciente tiene ' || v_citas || ' cita(s) asociada(s).';
        RETURN;
    END IF;

    DELETE FROM PACIENTE WHERE ID_PACIENTE = p_id_paciente;

    IF SQL%ROWCOUNT = 0 THEN
        p_resultado := 0;
        p_mensaje   := 'Error: paciente no encontrado.';
    ELSE
        COMMIT;
        p_resultado := 1;
        p_mensaje   := 'Paciente eliminado exitosamente.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_eliminar_paciente;
/

-- SP04: Obtener paciente por ID (REF CURSOR)
CREATE OR REPLACE PROCEDURE sp_obtener_paciente(
    p_id_paciente IN NUMBER,
    p_cursor      OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT P.ID_PACIENTE,
               P.CEDULA,
               P.NOMBRE || ' ' || P.APELLIDOS          AS NOMBRE_COMPLETO,
               P.FECHA_NACIMIENTO,
               TRUNC(MONTHS_BETWEEN(SYSDATE, P.FECHA_NACIMIENTO) / 12) AS EDAD,
               P.TELEFONO,
               P.CORREO,
               P.DIRECCION,
               NVL(S.NOMBRE_ASEGURADORA, 'Sin seguro') AS ASEGURADORA,
               S.NUMERO_POLIZA,
               S.COBERTURA_PORCENTAJE,
               CASE WHEN S.FECHA_VENCIMIENTO >= SYSDATE THEN 'VIGENTE' ELSE 'VENCIDA' END AS ESTADO_POLIZA
        FROM PACIENTE P
        LEFT JOIN SEGURO_MEDICO S ON P.ID_SEGURO = S.ID_SEGURO
        WHERE P.ID_PACIENTE = p_id_paciente;
END sp_obtener_paciente;
/

-- SP05: Listar todos los pacientes
CREATE OR REPLACE PROCEDURE sp_listar_pacientes(
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT P.ID_PACIENTE,
               P.CEDULA,
               P.NOMBRE || ' ' || P.APELLIDOS          AS NOMBRE_COMPLETO,
               P.TELEFONO,
               P.CORREO,
               NVL(S.NOMBRE_ASEGURADORA, 'Sin seguro') AS ASEGURADORA
        FROM PACIENTE P
        LEFT JOIN SEGURO_MEDICO S ON P.ID_SEGURO = S.ID_SEGURO
        ORDER BY P.APELLIDOS, P.NOMBRE;
END sp_listar_pacientes;
/

-- MÓDULO MÉDICO (SP06 - SP08)


-- SP06: Insertar médico
CREATE OR REPLACE PROCEDURE sp_insertar_medico(
    p_cedula        IN VARCHAR2,
    p_nombre        IN VARCHAR2,
    p_apellidos     IN VARCHAR2,
    p_especialidad  IN VARCHAR2,
    p_codigo_medico IN VARCHAR2,
    p_telefono      IN VARCHAR2,
    p_correo        IN VARCHAR2,
    p_resultado     OUT NUMBER,
    p_mensaje       OUT VARCHAR2
) AS
BEGIN
    INSERT INTO MEDICO(CEDULA, NOMBRE, APELLIDOS, ESPECIALIDAD, CODIGO_MEDICO, TELEFONO, CORREO)
    VALUES (p_cedula, p_nombre, p_apellidos, p_especialidad, p_codigo_medico, p_telefono, p_correo);
    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Médico registrado exitosamente.';
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error: ya existe un médico con esa cédula o código médico.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_insertar_medico;
/

-- SP07: Actualizar médico
CREATE OR REPLACE PROCEDURE sp_actualizar_medico(
    p_id_medico    IN NUMBER,
    p_nombre       IN VARCHAR2,
    p_apellidos    IN VARCHAR2,
    p_especialidad IN VARCHAR2,
    p_telefono     IN VARCHAR2,
    p_correo       IN VARCHAR2,
    p_resultado    OUT NUMBER,
    p_mensaje      OUT VARCHAR2
) AS
BEGIN
    UPDATE MEDICO
    SET NOMBRE       = p_nombre,
        APELLIDOS    = p_apellidos,
        ESPECIALIDAD = p_especialidad,
        TELEFONO     = p_telefono,
        CORREO       = p_correo
    WHERE ID_MEDICO = p_id_medico;

    IF SQL%ROWCOUNT = 0 THEN
        p_resultado := 0;
        p_mensaje   := 'Error: médico no encontrado.';
    ELSE
        COMMIT;
        p_resultado := 1;
        p_mensaje   := 'Médico actualizado exitosamente.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_actualizar_medico;
/

-- SP08: Listar médicos
CREATE OR REPLACE PROCEDURE sp_listar_medicos(
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT ID_MEDICO,
               CEDULA,
               NOMBRE || ' ' || APELLIDOS AS NOMBRE_COMPLETO,
               ESPECIALIDAD,
               CODIGO_MEDICO,
               TELEFONO,
               CORREO
        FROM MEDICO
        ORDER BY ESPECIALIDAD, APELLIDOS;
END sp_listar_medicos;
/


-- MÓDULO SEGURO MÉDICO (SP09 - SP11)


-- SP09: Insertar seguro
CREATE OR REPLACE PROCEDURE sp_insertar_seguro(
    p_nombre_aseguradora   IN VARCHAR2,
    p_numero_poliza        IN VARCHAR2,
    p_cobertura_porcentaje IN NUMBER,
    p_fecha_vencimiento    IN DATE,
    p_resultado            OUT NUMBER,
    p_mensaje              OUT VARCHAR2
) AS
BEGIN
    INSERT INTO SEGURO_MEDICO(NOMBRE_ASEGURADORA, NUMERO_POLIZA, COBERTURA_PORCENTAJE, FECHA_VENCIMIENTO)
    VALUES (p_nombre_aseguradora, p_numero_poliza, p_cobertura_porcentaje, p_fecha_vencimiento);
    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Seguro médico registrado exitosamente.';
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error: ya existe una póliza con ese número.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_insertar_seguro;
/

-- SP10: Actualizar seguro
CREATE OR REPLACE PROCEDURE sp_actualizar_seguro(
    p_id_seguro            IN NUMBER,
    p_cobertura_porcentaje IN NUMBER,
    p_fecha_vencimiento    IN DATE,
    p_resultado            OUT NUMBER,
    p_mensaje              OUT VARCHAR2
) AS
BEGIN
    UPDATE SEGURO_MEDICO
    SET COBERTURA_PORCENTAJE = p_cobertura_porcentaje,
        FECHA_VENCIMIENTO    = p_fecha_vencimiento
    WHERE ID_SEGURO = p_id_seguro;

    IF SQL%ROWCOUNT = 0 THEN
        p_resultado := 0;
        p_mensaje   := 'Error: seguro no encontrado.';
    ELSE
        COMMIT;
        p_resultado := 1;
        p_mensaje   := 'Seguro actualizado exitosamente.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_actualizar_seguro;
/

-- SP11: Listar seguros
CREATE OR REPLACE PROCEDURE sp_listar_seguros(
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT ID_SEGURO,
               NOMBRE_ASEGURADORA,
               NUMERO_POLIZA,
               COBERTURA_PORCENTAJE,
               FECHA_VENCIMIENTO,
               CASE WHEN FECHA_VENCIMIENTO >= SYSDATE THEN 'VIGENTE' ELSE 'VENCIDO' END AS ESTADO
        FROM SEGURO_MEDICO
        ORDER BY NOMBRE_ASEGURADORA;
END sp_listar_seguros;
/


-- MÓDULO CITA (SP12 - SP15)


-- SP12: Insertar cita (con validación de conflicto de horario)
CREATE OR REPLACE PROCEDURE sp_insertar_cita(
    p_id_paciente     IN NUMBER,
    p_id_medico       IN NUMBER,
    p_fecha           IN DATE,
    p_hora            IN VARCHAR2,
    p_motivo_consulta IN VARCHAR2,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) AS
    v_conflicto NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_conflicto
    FROM CITA
    WHERE ID_MEDICO = p_id_medico
      AND TRUNC(FECHA) = TRUNC(p_fecha)
      AND HORA  = p_hora
      AND ESTADO NOT IN ('CANCELADA', 'NO_ASISTIO');

    IF v_conflicto > 0 THEN
        p_resultado := 0;
        p_mensaje   := 'El médico ya tiene una cita en ese horario.';
        RETURN;
    END IF;

    INSERT INTO CITA(ID_PACIENTE, ID_MEDICO, FECHA, HORA, MOTIVO_CONSULTA, ESTADO)
    VALUES (p_id_paciente, p_id_medico, p_fecha, p_hora, p_motivo_consulta, 'PROGRAMADA');

    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Cita registrada exitosamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_insertar_cita;
/

-- SP13: Actualizar estado de cita
CREATE OR REPLACE PROCEDURE sp_actualizar_estado_cita(
    p_id_cita   IN NUMBER,
    p_estado    IN VARCHAR2,
    p_resultado OUT NUMBER,
    p_mensaje   OUT VARCHAR2
) AS
BEGIN
    UPDATE CITA
    SET ESTADO = p_estado
    WHERE ID_CITA = p_id_cita;

    IF SQL%ROWCOUNT = 0 THEN
        p_resultado := 0;
        p_mensaje   := 'Error: cita no encontrada.';
    ELSE
        COMMIT;
        p_resultado := 1;
        p_mensaje   := 'Estado actualizado a: ' || p_estado;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_actualizar_estado_cita;
/

-- SP14: Listar citas por paciente
CREATE OR REPLACE PROCEDURE sp_citas_por_paciente(
    p_id_paciente IN NUMBER,
    p_cursor      OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT C.ID_CITA,
               TO_CHAR(C.FECHA, 'DD/MM/YYYY') AS FECHA,
               C.HORA,
               C.MOTIVO_CONSULTA,
               C.ESTADO,
               M.NOMBRE || ' ' || M.APELLIDOS AS MEDICO,
               M.ESPECIALIDAD
        FROM CITA C
        JOIN MEDICO M ON C.ID_MEDICO = M.ID_MEDICO
        WHERE C.ID_PACIENTE = p_id_paciente
        ORDER BY C.FECHA DESC, C.HORA DESC;
END sp_citas_por_paciente;
/

-- SP15: Citas del día
CREATE OR REPLACE PROCEDURE sp_citas_del_dia(
    p_fecha  IN DATE,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT C.ID_CITA,
               C.HORA,
               P.NOMBRE || ' ' || P.APELLIDOS AS PACIENTE,
               P.CEDULA,
               M.NOMBRE || ' ' || M.APELLIDOS AS MEDICO,
               M.ESPECIALIDAD,
               C.MOTIVO_CONSULTA,
               C.ESTADO
        FROM CITA C
        JOIN PACIENTE P ON C.ID_PACIENTE = P.ID_PACIENTE
        JOIN MEDICO   M ON C.ID_MEDICO   = M.ID_MEDICO
        WHERE TRUNC(C.FECHA) = TRUNC(p_fecha)
        ORDER BY C.HORA;
END sp_citas_del_dia;
/

-- ================================================================
-- MÓDULO SERVICIO (SP16 - SP18)
-- ================================================================

-- SP16: Insertar servicio
CREATE OR REPLACE PROCEDURE sp_insertar_servicio(
    p_nombre_servicio IN VARCHAR2,
    p_descripcion     IN VARCHAR2,
    p_precio_base     IN NUMBER,
    p_categoria       IN VARCHAR2,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) AS
BEGIN
    INSERT INTO SERVICIO(NOMBRE_SERVICIO, DESCRIPCION, PRECIO_BASE, CATEGORIA)
    VALUES (p_nombre_servicio, p_descripcion, p_precio_base, p_categoria);
    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Servicio registrado exitosamente.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_insertar_servicio;
/

-- SP17: Actualizar precio de servicio
CREATE OR REPLACE PROCEDURE sp_actualizar_servicio(
    p_id_servicio IN NUMBER,
    p_precio_base IN NUMBER,
    p_descripcion IN VARCHAR2,
    p_resultado   OUT NUMBER,
    p_mensaje     OUT VARCHAR2
) AS
BEGIN
    UPDATE SERVICIO
    SET PRECIO_BASE = p_precio_base,
        DESCRIPCION = NVL(p_descripcion, DESCRIPCION)
    WHERE ID_SERVICIO = p_id_servicio;

    IF SQL%ROWCOUNT = 0 THEN
        p_resultado := 0;
        p_mensaje   := 'Error: servicio no encontrado.';
    ELSE
        COMMIT;
        p_resultado := 1;
        p_mensaje   := 'Servicio actualizado exitosamente.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_actualizar_servicio;
/

-- SP18: Listar servicios (con filtro opcional por categoría)
CREATE OR REPLACE PROCEDURE sp_listar_servicios(
    p_categoria IN VARCHAR2 DEFAULT NULL,
    p_cursor    OUT SYS_REFCURSOR
) AS
BEGIN
    IF p_categoria IS NULL THEN
        OPEN p_cursor FOR
            SELECT ID_SERVICIO, NOMBRE_SERVICIO, DESCRIPCION,
                   PRECIO_BASE, ROUND(PRECIO_BASE * 1.13, 2) AS PRECIO_CON_IVA, CATEGORIA
            FROM SERVICIO
            ORDER BY CATEGORIA, NOMBRE_SERVICIO;
    ELSE
        OPEN p_cursor FOR
            SELECT ID_SERVICIO, NOMBRE_SERVICIO, DESCRIPCION,
                   PRECIO_BASE, ROUND(PRECIO_BASE * 1.13, 2) AS PRECIO_CON_IVA, CATEGORIA
            FROM SERVICIO
            WHERE CATEGORIA = UPPER(p_categoria)
            ORDER BY NOMBRE_SERVICIO;
    END IF;
END sp_listar_servicios;
/

-- ================================================================
-- MÓDULO FACTURA (SP19 - SP22)
-- ================================================================

-- SP19: Generar factura
CREATE OR REPLACE PROCEDURE sp_generar_factura(
    p_id_cita    IN NUMBER,
    p_descuento  IN NUMBER DEFAULT 0,
    p_resultado  OUT NUMBER,
    p_mensaje    OUT VARCHAR2,
    p_id_factura OUT NUMBER
) AS
    v_existe      NUMBER;
    v_ya_facturada NUMBER;
    v_subtotal    NUMBER(10,2) := 0;
    v_descuento   NUMBER(10,2) := NVL(p_descuento, 0);
    v_iva         NUMBER(10,2);
    v_total       NUMBER(10,2);
    v_num_factura VARCHAR2(50);
BEGIN
    -- Verificar que la cita esté ATENDIDA
    SELECT COUNT(*) INTO v_existe FROM CITA WHERE ID_CITA = p_id_cita AND ESTADO = 'ATENDIDA';
    IF v_existe = 0 THEN
        p_resultado := 0; p_id_factura := 0;
        p_mensaje   := 'La cita debe estar en estado ATENDIDA para facturar.';
        RETURN;
    END IF;

    -- Verificar que no esté ya facturada
    SELECT COUNT(*) INTO v_ya_facturada FROM FACTURA WHERE ID_CITA = p_id_cita AND ESTADO_PAGO != 'ANULADA';
    IF v_ya_facturada > 0 THEN
        p_resultado := 0; p_id_factura := 0;
        p_mensaje   := 'Esta cita ya tiene una factura activa.';
        RETURN;
    END IF;

    v_num_factura := 'FE-' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '-' || LPAD(SEQ_FACTURA.NEXTVAL, 6, '0');
    v_iva         := ROUND((v_subtotal - v_descuento) * 0.13, 2);
    v_total       := (v_subtotal - v_descuento) + v_iva;

    INSERT INTO FACTURA(ID_CITA, NUMERO_FACTURA_ELECTRONICA, FECHA_EMISION,
                        SUBTOTAL, DESCUENTO, IVA, TOTAL, ESTADO_PAGO)
    VALUES (p_id_cita, v_num_factura, SYSDATE, v_subtotal, v_descuento, v_iva, v_total, 'PENDIENTE')
    RETURNING ID_FACTURA INTO p_id_factura;

    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Factura generada: ' || v_num_factura;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0; p_id_factura := 0;
        p_mensaje   := 'Error al generar factura: ' || SQLERRM;
END sp_generar_factura;
/

-- SP20: Insertar línea de detalle en factura
CREATE OR REPLACE PROCEDURE sp_insertar_detalle_factura(
    p_id_factura  IN NUMBER,
    p_id_servicio IN NUMBER,
    p_cantidad    IN NUMBER,
    p_resultado   OUT NUMBER,
    p_mensaje     OUT VARCHAR2
) AS
    v_precio   NUMBER(10,2);
    v_subtotal NUMBER(10,2);
    v_estado   VARCHAR2(20);
BEGIN
    -- Verificar que la factura esté en estado PENDIENTE
    SELECT ESTADO_PAGO INTO v_estado FROM FACTURA WHERE ID_FACTURA = p_id_factura;
    IF v_estado != 'PENDIENTE' THEN
        p_resultado := 0;
        p_mensaje   := 'Solo se pueden agregar detalles a facturas en estado PENDIENTE.';
        RETURN;
    END IF;

    SELECT PRECIO_BASE INTO v_precio FROM SERVICIO WHERE ID_SERVICIO = p_id_servicio;
    v_subtotal := ROUND(v_precio * p_cantidad, 2);

    INSERT INTO DETALLE_FACTURA(ID_FACTURA, ID_SERVICIO, CANTIDAD, PRECIO_UNITARIO, SUBTOTAL_LINEA)
    VALUES (p_id_factura, p_id_servicio, p_cantidad, v_precio, v_subtotal);

    -- Recalcular totales de la factura
    UPDATE FACTURA
    SET SUBTOTAL = SUBTOTAL + v_subtotal,
        IVA      = ROUND((SUBTOTAL + v_subtotal - DESCUENTO) * 0.13, 2),
        TOTAL    = ROUND((SUBTOTAL + v_subtotal - DESCUENTO) * 1.13, 2)
    WHERE ID_FACTURA = p_id_factura;

    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Servicio agregado a la factura exitosamente.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_resultado := 0;
        p_mensaje   := 'Error: factura o servicio no encontrado.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_insertar_detalle_factura;
/

-- SP21: Anular factura
CREATE OR REPLACE PROCEDURE sp_anular_factura(
    p_id_factura IN NUMBER,
    p_resultado  OUT NUMBER,
    p_mensaje    OUT VARCHAR2
) AS
    v_estado VARCHAR2(20);
BEGIN
    SELECT ESTADO_PAGO INTO v_estado FROM FACTURA WHERE ID_FACTURA = p_id_factura;
    IF v_estado = 'PAGADA' THEN
        p_resultado := 0;
        p_mensaje   := 'No se puede anular una factura ya pagada.';
        RETURN;
    END IF;
    UPDATE FACTURA SET ESTADO_PAGO = 'ANULADA' WHERE ID_FACTURA = p_id_factura;
    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Factura anulada exitosamente.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_resultado := 0;
        p_mensaje   := 'Error: factura no encontrada.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_anular_factura;
/

-- SP22: Obtener factura completa (encabezado + detalle)
CREATE OR REPLACE PROCEDURE sp_obtener_factura(
    p_id_factura IN NUMBER,
    p_cursor_hdr OUT SYS_REFCURSOR,
    p_cursor_det OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor_hdr FOR
        SELECT F.ID_FACTURA,
               F.NUMERO_FACTURA_ELECTRONICA,
               TO_CHAR(F.FECHA_EMISION, 'DD/MM/YYYY') AS FECHA_EMISION,
               F.SUBTOTAL, F.DESCUENTO, F.IVA, F.TOTAL,
               F.ESTADO_PAGO,
               P.NOMBRE || ' ' || P.APELLIDOS AS PACIENTE,
               P.CEDULA,
               M.NOMBRE || ' ' || M.APELLIDOS AS MEDICO
        FROM FACTURA F
        JOIN CITA     C ON F.ID_CITA      = C.ID_CITA
        JOIN PACIENTE P ON C.ID_PACIENTE  = P.ID_PACIENTE
        JOIN MEDICO   M ON C.ID_MEDICO    = M.ID_MEDICO
        WHERE F.ID_FACTURA = p_id_factura;

    OPEN p_cursor_det FOR
        SELECT DF.ID_DETALLE,
               S.NOMBRE_SERVICIO,
               S.CATEGORIA,
               DF.CANTIDAD,
               DF.PRECIO_UNITARIO,
               DF.SUBTOTAL_LINEA
        FROM DETALLE_FACTURA DF
        JOIN SERVICIO S ON DF.ID_SERVICIO = S.ID_SERVICIO
        WHERE DF.ID_FACTURA = p_id_factura;
END sp_obtener_factura;
/

-- ================================================================
-- MÓDULO PAGO (SP23 - SP24)
-- ================================================================

-- SP23: Registrar pago
CREATE OR REPLACE PROCEDURE sp_registrar_pago(
    p_id_factura             IN NUMBER,
    p_monto_pagado           IN NUMBER,
    p_metodo_pago            IN VARCHAR2,
    p_referencia_transaccion IN VARCHAR2,
    p_resultado              OUT NUMBER,
    p_mensaje                OUT VARCHAR2
) AS
    v_total        NUMBER(10,2);
    v_pagado_previo NUMBER(10,2);
    v_estado_nuevo VARCHAR2(20);
    v_estado_fact  VARCHAR2(20);
BEGIN
    SELECT TOTAL, ESTADO_PAGO INTO v_total, v_estado_fact
    FROM FACTURA WHERE ID_FACTURA = p_id_factura;

    IF v_estado_fact = 'ANULADA' THEN
        p_resultado := 0;
        p_mensaje   := 'No se puede pagar una factura anulada.';
        RETURN;
    END IF;
    IF v_estado_fact = 'PAGADA' THEN
        p_resultado := 0;
        p_mensaje   := 'La factura ya fue pagada en su totalidad.';
        RETURN;
    END IF;

    SELECT NVL(SUM(MONTO_PAGADO), 0) INTO v_pagado_previo
    FROM PAGO WHERE ID_FACTURA = p_id_factura AND ESTADO = 'APROBADO';

    INSERT INTO PAGO(ID_FACTURA, FECHA_PAGO, MONTO_PAGADO, METODO_PAGO,
                     REFERENCIA_TRANSACCION, ESTADO)
    VALUES (p_id_factura, SYSDATE, p_monto_pagado, p_metodo_pago,
            p_referencia_transaccion, 'APROBADO');

    v_estado_nuevo := CASE
        WHEN (v_pagado_previo + p_monto_pagado) >= v_total THEN 'PAGADA'
        ELSE 'PARCIAL'
    END;

    UPDATE FACTURA SET ESTADO_PAGO = v_estado_nuevo WHERE ID_FACTURA = p_id_factura;

    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Pago registrado. Estado de factura: ' || v_estado_nuevo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_resultado := 0;
        p_mensaje   := 'Error: factura no encontrada.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_registrar_pago;
/

-- SP24: Listar pagos por factura
CREATE OR REPLACE PROCEDURE sp_pagos_por_factura(
    p_id_factura IN NUMBER,
    p_cursor     OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT ID_PAGO,
               TO_CHAR(FECHA_PAGO, 'DD/MM/YYYY HH24:MI') AS FECHA_PAGO,
               MONTO_PAGADO,
               METODO_PAGO,
               REFERENCIA_TRANSACCION,
               ESTADO
        FROM PAGO
        WHERE ID_FACTURA = p_id_factura
        ORDER BY FECHA_PAGO;
END sp_pagos_por_factura;
/

-- ================================================================
-- MÓDULO USUARIO (SP25)
-- ================================================================

-- SP25: Insertar usuario del sistema
CREATE OR REPLACE PROCEDURE sp_insertar_usuario(
    p_nombre_usuario  IN VARCHAR2,
    p_contrasena_hash IN VARCHAR2,
    p_rol             IN VARCHAR2,
    p_correo          IN VARCHAR2,
    p_resultado       OUT NUMBER,
    p_mensaje         OUT VARCHAR2
) AS
BEGIN
    INSERT INTO USUARIO_SISTEMA(NOMBRE_USUARIO, CONTRASENA_HASH, ROL, CORREO)
    VALUES (p_nombre_usuario, p_contrasena_hash, p_rol, p_correo);
    COMMIT;
    p_resultado := 1;
    p_mensaje   := 'Usuario creado exitosamente.';
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error: nombre de usuario o correo ya en uso.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 0;
        p_mensaje   := 'Error inesperado: ' || SQLERRM;
END sp_insertar_usuario;
/

PROMPT ✓ 25 procedimientos almacenados creados exitosamente.
