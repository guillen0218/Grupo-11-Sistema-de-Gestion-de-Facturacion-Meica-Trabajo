-- ============================================================
-- SISTEMA DE GESTIÓN DE FACTURACIÓN MÉDICA
-- Archivo: 03_funciones.sql
-- Total: 15 funciones
-- ============================================================

-- FN01: Calcular edad en años a partir de fecha de nacimiento
CREATE OR REPLACE FUNCTION fn_calcular_edad(p_fecha_nacimiento IN DATE)
RETURN NUMBER AS
BEGIN
    RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, p_fecha_nacimiento) / 12);
END fn_calcular_edad;
/

-- FN02: Calcular IVA del 13% sobre un subtotal con descuento
CREATE OR REPLACE FUNCTION fn_calcular_iva(
    p_subtotal  IN NUMBER,
    p_descuento IN NUMBER DEFAULT 0
) RETURN NUMBER AS
BEGIN
    RETURN ROUND((NVL(p_subtotal, 0) - NVL(p_descuento, 0)) * 0.13, 2);
END fn_calcular_iva;
/

-- FN03: Obtener nombre completo del paciente
CREATE OR REPLACE FUNCTION fn_nombre_paciente(p_id_paciente IN NUMBER)
RETURN VARCHAR2 AS
    v_nombre VARCHAR2(200);
BEGIN
    SELECT NOMBRE || ' ' || APELLIDOS
    INTO v_nombre
    FROM PACIENTE
    WHERE ID_PACIENTE = p_id_paciente;
    RETURN v_nombre;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'Paciente no encontrado';
END fn_nombre_paciente;
/

-- FN04: Obtener nombre completo del médico
CREATE OR REPLACE FUNCTION fn_nombre_medico(p_id_medico IN NUMBER)
RETURN VARCHAR2 AS
    v_nombre VARCHAR2(200);
BEGIN
    SELECT NOMBRE || ' ' || APELLIDOS
    INTO v_nombre
    FROM MEDICO
    WHERE ID_MEDICO = p_id_medico;
    RETURN v_nombre;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'Médico no encontrado';
END fn_nombre_medico;
/

-- FN05: Contar citas atendidas por médico en un rango de fechas
CREATE OR REPLACE FUNCTION fn_citas_medico(
    p_id_medico IN NUMBER,
    p_fecha_ini IN DATE,
    p_fecha_fin IN DATE
) RETURN NUMBER AS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM CITA
    WHERE ID_MEDICO = p_id_medico
      AND TRUNC(FECHA) BETWEEN TRUNC(p_fecha_ini) AND TRUNC(p_fecha_fin)
      AND ESTADO = 'ATENDIDA';
    RETURN NVL(v_total, 0);
END fn_citas_medico;
/

-- FN06: Verificar si una póliza de seguro está vigente
CREATE OR REPLACE FUNCTION fn_poliza_vigente(p_id_seguro IN NUMBER)
RETURN VARCHAR2 AS
    v_fecha DATE;
BEGIN
    SELECT FECHA_VENCIMIENTO INTO v_fecha
    FROM SEGURO_MEDICO WHERE ID_SEGURO = p_id_seguro;
    RETURN CASE WHEN v_fecha >= TRUNC(SYSDATE) THEN 'VIGENTE' ELSE 'VENCIDA' END;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'NO_EXISTE';
END fn_poliza_vigente;
/

-- FN07: Calcular monto de descuento según seguro del paciente
CREATE OR REPLACE FUNCTION fn_descuento_seguro(
    p_id_seguro IN NUMBER,
    p_subtotal  IN NUMBER
) RETURN NUMBER AS
    v_porcentaje NUMBER;
BEGIN
    IF fn_poliza_vigente(p_id_seguro) != 'VIGENTE' THEN
        RETURN 0;
    END IF;
    SELECT COBERTURA_PORCENTAJE INTO v_porcentaje
    FROM SEGURO_MEDICO WHERE ID_SEGURO = p_id_seguro;
    RETURN ROUND(p_subtotal * (v_porcentaje / 100), 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0;
END fn_descuento_seguro;
/

-- FN08: Calcular deuda total pendiente de un paciente
CREATE OR REPLACE FUNCTION fn_deuda_paciente(p_id_paciente IN NUMBER)
RETURN NUMBER AS
    v_deuda NUMBER;
BEGIN
    SELECT NVL(SUM(F.TOTAL - NVL(
        (SELECT SUM(P.MONTO_PAGADO) FROM PAGO P
         WHERE P.ID_FACTURA = F.ID_FACTURA AND P.ESTADO = 'APROBADO'), 0)), 0)
    INTO v_deuda
    FROM FACTURA F
    JOIN CITA C ON F.ID_CITA = C.ID_CITA
    WHERE C.ID_PACIENTE = p_id_paciente
      AND F.ESTADO_PAGO IN ('PENDIENTE', 'PARCIAL');
    RETURN v_deuda;
END fn_deuda_paciente;
/

-- FN09: Calcular total de ingresos cobrados en un mes
CREATE OR REPLACE FUNCTION fn_ingresos_mes(p_anio IN NUMBER, p_mes IN NUMBER)
RETURN NUMBER AS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(MONTO_PAGADO), 0) INTO v_total
    FROM PAGO
    WHERE EXTRACT(YEAR  FROM FECHA_PAGO) = p_anio
      AND EXTRACT(MONTH FROM FECHA_PAGO) = p_mes
      AND ESTADO = 'APROBADO';
    RETURN v_total;
END fn_ingresos_mes;
/

-- FN10: Contar facturas pendientes de cobro
CREATE OR REPLACE FUNCTION fn_facturas_pendientes
RETURN NUMBER AS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM FACTURA WHERE ESTADO_PAGO IN ('PENDIENTE', 'PARCIAL');
    RETURN v_total;
END fn_facturas_pendientes;
/

-- FN11: Obtener categoría de un servicio
CREATE OR REPLACE FUNCTION fn_categoria_servicio(p_id_servicio IN NUMBER)
RETURN VARCHAR2 AS
    v_cat VARCHAR2(100);
BEGIN
    SELECT CATEGORIA INTO v_cat FROM SERVICIO WHERE ID_SERVICIO = p_id_servicio;
    RETURN v_cat;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'N/A';
END fn_categoria_servicio;
/

-- FN12: Calcular días transcurridos desde una cita
CREATE OR REPLACE FUNCTION fn_dias_desde_cita(p_id_cita IN NUMBER)
RETURN NUMBER AS
    v_fecha DATE;
BEGIN
    SELECT FECHA INTO v_fecha FROM CITA WHERE ID_CITA = p_id_cita;
    RETURN TRUNC(SYSDATE - v_fecha);
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN -1;
END fn_dias_desde_cita;
/

-- FN13: Calcular total de ingresos generados por un médico en un año
CREATE OR REPLACE FUNCTION fn_ingresos_medico(
    p_id_medico IN NUMBER,
    p_anio      IN NUMBER
) RETURN NUMBER AS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(PA.MONTO_PAGADO), 0) INTO v_total
    FROM PAGO     PA
    JOIN FACTURA  F  ON PA.ID_FACTURA = F.ID_FACTURA
    JOIN CITA     C  ON F.ID_CITA     = C.ID_CITA
    WHERE C.ID_MEDICO = p_id_medico
      AND EXTRACT(YEAR FROM PA.FECHA_PAGO) = p_anio
      AND PA.ESTADO = 'APROBADO';
    RETURN v_total;
END fn_ingresos_medico;
/

-- FN14: Verificar si un usuario está activo (1=sí, 0=no)
CREATE OR REPLACE FUNCTION fn_usuario_activo(p_nombre_usuario IN VARCHAR2)
RETURN NUMBER AS
    v_activo NUMBER;
BEGIN
    SELECT ACTIVO INTO v_activo
    FROM USUARIO_SISTEMA WHERE NOMBRE_USUARIO = p_nombre_usuario;
    RETURN v_activo;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0;
END fn_usuario_activo;
/

-- FN15: Contar total de citas de un paciente
CREATE OR REPLACE FUNCTION fn_citas_paciente(p_id_paciente IN NUMBER)
RETURN NUMBER AS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total FROM CITA WHERE ID_PACIENTE = p_id_paciente;
    RETURN v_total;
END fn_citas_paciente;
/

PROMPT ✓ 15 funciones creadas exitosamente.
