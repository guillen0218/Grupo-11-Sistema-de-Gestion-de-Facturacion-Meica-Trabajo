-- ============================================================
-- SISTEMA DE GESTIÓN DE FACTURACIÓN MÉDICA
-- Archivo: 06_triggers_y_cursores.sql
-- Total: 5 triggers + 15 cursores (en bloque anónimo de prueba)
-- ============================================================

-- ================================================================
-- SECCIÓN A: 5 TRIGGERS
-- ================================================================

-- TRG01: Auditoría de cambios de estado en FACTURA
CREATE OR REPLACE TRIGGER trg_audit_factura
AFTER UPDATE OF ESTADO_PAGO ON FACTURA
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_FACTURA (ID_FACTURA, ESTADO_ANTERIOR, ESTADO_NUEVO, FECHA_CAMBIO, USUARIO_BD)
    VALUES (:NEW.ID_FACTURA, :OLD.ESTADO_PAGO, :NEW.ESTADO_PAGO, SYSDATE, USER);
END trg_audit_factura;
/

-- TRG02: Validar que una cita no se programe en el pasado
CREATE OR REPLACE TRIGGER trg_validar_fecha_cita
BEFORE INSERT ON CITA
FOR EACH ROW
BEGIN
    IF TRUNC(:NEW.FECHA) < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20001, 'No se puede registrar una cita en una fecha pasada.');
    END IF;
END trg_validar_fecha_cita;
/

-- TRG03: Recalcular TOTAL de factura al insertar o actualizar detalle
CREATE OR REPLACE TRIGGER trg_recalcular_total_factura
AFTER INSERT OR UPDATE OR DELETE ON DETALLE_FACTURA
FOR EACH ROW
DECLARE
    v_id_factura NUMBER;
    v_subtotal   NUMBER;
    v_descuento  NUMBER;
BEGIN
    v_id_factura := CASE
        WHEN DELETING THEN :OLD.ID_FACTURA
        ELSE :NEW.ID_FACTURA
    END;
    SELECT SUM(DF.SUBTOTAL_LINEA), F.DESCUENTO
    INTO v_subtotal, v_descuento
    FROM DETALLE_FACTURA DF
    JOIN FACTURA F ON DF.ID_FACTURA = F.ID_FACTURA
    WHERE DF.ID_FACTURA = v_id_factura
    GROUP BY F.DESCUENTO;

    v_subtotal  := NVL(v_subtotal, 0);
    v_descuento := NVL(v_descuento, 0);

    UPDATE FACTURA
    SET SUBTOTAL = v_subtotal,
        IVA      = ROUND((v_subtotal - v_descuento) * 0.13, 2),
        TOTAL    = ROUND((v_subtotal - v_descuento) * 1.13, 2)
    WHERE ID_FACTURA = v_id_factura;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        UPDATE FACTURA SET SUBTOTAL=0, IVA=0, TOTAL=0 WHERE ID_FACTURA=v_id_factura;
END trg_recalcular_total_factura;
/

-- TRG04: Actualizar estado de CITA a ATENDIDA al crear su factura
CREATE OR REPLACE TRIGGER trg_actualizar_cita_al_facturar
AFTER INSERT ON FACTURA
FOR EACH ROW
BEGIN
    UPDATE CITA
    SET ESTADO = 'ATENDIDA'
    WHERE ID_CITA = :NEW.ID_CITA
      AND ESTADO  = 'PROGRAMADA';
END trg_actualizar_cita_al_facturar;
/

-- TRG05: Prevenir eliminación de servicios en uso activo en facturas
CREATE OR REPLACE TRIGGER trg_proteger_servicio_en_uso
BEFORE DELETE ON SERVICIO
FOR EACH ROW
DECLARE
    v_en_uso NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_en_uso
    FROM DETALLE_FACTURA DF
    JOIN FACTURA F ON DF.ID_FACTURA = F.ID_FACTURA
    WHERE DF.ID_SERVICIO = :OLD.ID_SERVICIO
      AND F.ESTADO_PAGO != 'ANULADA';

    IF v_en_uso > 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'No se puede eliminar el servicio "' || :OLD.NOMBRE_SERVICIO ||
            '" porque está en uso en ' || v_en_uso || ' factura(s) activa(s).');
    END IF;
END trg_proteger_servicio_en_uso;
/

PROMPT ✓ 5 triggers creados exitosamente.


-- ================================================================
-- SECCIÓN B: 15 CURSORES (implementados en bloques PL/SQL
--            listos para ejecutar o integrar en aplicación Python)
-- ================================================================

-- CURSOR 01: Pacientes con deuda pendiente de pago
DECLARE
    CURSOR cur_pacientes_deuda IS
        SELECT P.ID_PACIENTE,
               P.NOMBRE || ' ' || P.APELLIDOS AS PACIENTE,
               P.TELEFONO,
               fn_deuda_paciente(P.ID_PACIENTE) AS DEUDA
        FROM PACIENTE P
        WHERE fn_deuda_paciente(P.ID_PACIENTE) > 0
        ORDER BY DEUDA DESC;
    v_reg cur_pacientes_deuda%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== PACIENTES CON DEUDA PENDIENTE ===');
    OPEN cur_pacientes_deuda;
    LOOP
        FETCH cur_pacientes_deuda INTO v_reg;
        EXIT WHEN cur_pacientes_deuda%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_reg.PACIENTE || ' | Tel: ' || v_reg.TELEFONO ||
                             ' | Deuda: ' || pkg_utilidades.formatear_colones(v_reg.DEUDA));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Total registros: ' || cur_pacientes_deuda%ROWCOUNT);
    CLOSE cur_pacientes_deuda;
END;
/

-- CURSOR 02: Citas programadas para los próximos 7 días
DECLARE
    CURSOR cur_citas_semana IS
        SELECT C.ID_CITA,
               TO_CHAR(C.FECHA,'DD/MM/YYYY') AS FECHA,
               C.HORA,
               P.NOMBRE || ' ' || P.APELLIDOS AS PACIENTE,
               M.NOMBRE || ' ' || M.APELLIDOS AS MEDICO,
               M.ESPECIALIDAD
        FROM CITA C
        JOIN PACIENTE P ON C.ID_PACIENTE = P.ID_PACIENTE
        JOIN MEDICO   M ON C.ID_MEDICO   = M.ID_MEDICO
        WHERE TRUNC(C.FECHA) BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE)+7
          AND C.ESTADO = 'PROGRAMADA'
        ORDER BY C.FECHA, C.HORA;
    v_reg cur_citas_semana%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== CITAS PRÓXIMOS 7 DÍAS ===');
    FOR v_reg IN cur_citas_semana LOOP
        DBMS_OUTPUT.PUT_LINE(v_reg.FECHA || ' ' || v_reg.HORA ||
                             ' | ' || v_reg.PACIENTE || ' con ' || v_reg.MEDICO);
    END LOOP;
END;
/

-- CURSOR 03: Facturas emitidas en el mes actual
DECLARE
    CURSOR cur_facturas_mes IS
        SELECT F.NUMERO_FACTURA_ELECTRONICA,
               TO_CHAR(F.FECHA_EMISION,'DD/MM/YYYY') AS FECHA,
               F.TOTAL,
               F.ESTADO_PAGO,
               P.NOMBRE || ' ' || P.APELLIDOS AS PACIENTE
        FROM FACTURA F
        JOIN CITA     C ON F.ID_CITA     = C.ID_CITA
        JOIN PACIENTE P ON C.ID_PACIENTE = P.ID_PACIENTE
        WHERE EXTRACT(MONTH FROM F.FECHA_EMISION) = EXTRACT(MONTH FROM SYSDATE)
          AND EXTRACT(YEAR  FROM F.FECHA_EMISION) = EXTRACT(YEAR  FROM SYSDATE)
        ORDER BY F.FECHA_EMISION;
    v_reg   cur_facturas_mes%ROWTYPE;
    v_total NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== FACTURAS DEL MES ===');
    FOR v_reg IN cur_facturas_mes LOOP
        DBMS_OUTPUT.PUT_LINE(v_reg.NUMERO_FACTURA_ELECTRONICA || ' | ' || v_reg.PACIENTE ||
                             ' | ' || pkg_utilidades.formatear_colones(v_reg.TOTAL) ||
                             ' [' || v_reg.ESTADO_PAGO || ']');
        IF v_reg.ESTADO_PAGO != 'ANULADA' THEN v_total := v_total + v_reg.TOTAL; END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('TOTAL MES: ' || pkg_utilidades.formatear_colones(v_total));
END;
/

-- CURSOR 04: Seguros por vencer en los próximos 30 días
DECLARE
    CURSOR cur_polizas_vencer IS
        SELECT ID_SEGURO, NOMBRE_ASEGURADORA, NUMERO_POLIZA,
               FECHA_VENCIMIENTO,
               TRUNC(FECHA_VENCIMIENTO - SYSDATE) AS DIAS_RESTANTES
        FROM SEGURO_MEDICO
        WHERE FECHA_VENCIMIENTO BETWEEN SYSDATE AND SYSDATE + 30
        ORDER BY FECHA_VENCIMIENTO;
    v_reg cur_polizas_vencer%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== PÓLIZAS POR VENCER (30 días) ===');
    OPEN cur_polizas_vencer;
    LOOP
        FETCH cur_polizas_vencer INTO v_reg;
        EXIT WHEN cur_polizas_vencer%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_reg.NOMBRE_ASEGURADORA || ' | Póliza: ' || v_reg.NUMERO_POLIZA ||
                             ' | Vence en: ' || v_reg.DIAS_RESTANTES || ' días');
    END LOOP;
    CLOSE cur_polizas_vencer;
END;
/

-- CURSOR 05: Médicos con mayor cantidad de citas atendidas en el mes
DECLARE
    CURSOR cur_medicos_top IS
        SELECT M.NOMBRE || ' ' || M.APELLIDOS AS MEDICO,
               M.ESPECIALIDAD,
               COUNT(C.ID_CITA) AS CITAS_MES
        FROM MEDICO M
        LEFT JOIN CITA C ON M.ID_MEDICO = C.ID_MEDICO
                        AND EXTRACT(MONTH FROM C.FECHA) = EXTRACT(MONTH FROM SYSDATE)
                        AND C.ESTADO = 'ATENDIDA'
        GROUP BY M.ID_MEDICO, M.NOMBRE, M.APELLIDOS, M.ESPECIALIDAD
        ORDER BY CITAS_MES DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RANKING MÉDICOS POR CITAS ===');
    FOR v_reg IN cur_medicos_top LOOP
        DBMS_OUTPUT.PUT_LINE(v_reg.MEDICO || ' (' || v_reg.ESPECIALIDAD || ')' ||
                             ' - Citas: ' || v_reg.CITAS_MES);
    END LOOP;
END;
/

-- CURSOR 06: Detalle de servicios por categoría con subtotales acumulados
DECLARE
    CURSOR cur_servicios_cat IS
        SELECT CATEGORIA, NOMBRE_SERVICIO, PRECIO_BASE
        FROM SERVICIO ORDER BY CATEGORIA, NOMBRE_SERVICIO;
    v_cat_actual  VARCHAR2(100) := '---';
    v_subtotal    NUMBER := 0;
    v_gran_total  NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== CATÁLOGO POR CATEGORÍA ===');
    FOR v IN cur_servicios_cat LOOP
        IF v.CATEGORIA != v_cat_actual THEN
            IF v_cat_actual != '---' THEN
                DBMS_OUTPUT.PUT_LINE(' Subtotal ' || v_cat_actual || ': ' ||
                                     pkg_utilidades.formatear_colones(v_subtotal));
            END IF;
            v_cat_actual := v.CATEGORIA;
            v_subtotal   := 0;
            DBMS_OUTPUT.PUT_LINE('-- ' || v.CATEGORIA || ' --');
        END IF;
        DBMS_OUTPUT.PUT_LINE('  ' || v.NOMBRE_SERVICIO || ': ' ||
                             pkg_utilidades.formatear_colones(v.PRECIO_BASE));
        v_subtotal   := v_subtotal + v.PRECIO_BASE;
        v_gran_total := v_gran_total + v.PRECIO_BASE;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Gran total: ' || pkg_utilidades.formatear_colones(v_gran_total));
END;
/

-- CURSOR 07: Pagos recibidos hoy agrupados por método
DECLARE
    CURSOR cur_pagos_hoy IS
        SELECT METODO_PAGO,
               COUNT(*)           AS TRANSACCIONES,
               SUM(MONTO_PAGADO)  AS TOTAL
        FROM PAGO
        WHERE TRUNC(FECHA_PAGO) = TRUNC(SYSDATE) AND ESTADO = 'APROBADO'
        GROUP BY METODO_PAGO ORDER BY TOTAL DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== COBROS DE HOY ===');
    FOR v IN cur_pagos_hoy LOOP
        DBMS_OUTPUT.PUT_LINE(v.METODO_PAGO || ': ' || v.TRANSACCIONES ||
                             ' txn | ' || pkg_utilidades.formatear_colones(v.TOTAL));
    END LOOP;
END;
/

-- CURSOR 08: Historial de citas de un paciente específico
DECLARE
    v_id_paciente CONSTANT NUMBER := 1; -- Cambiar según contexto
    CURSOR cur_historial(p_id IN NUMBER) IS
        SELECT TO_CHAR(C.FECHA,'DD/MM/YYYY') AS FECHA,
               C.HORA, C.MOTIVO_CONSULTA, C.ESTADO,
               M.NOMBRE || ' ' || M.APELLIDOS AS MEDICO,
               M.ESPECIALIDAD,
               F.NUMERO_FACTURA_ELECTRONICA,
               F.TOTAL
        FROM CITA C
        JOIN MEDICO   M ON C.ID_MEDICO   = M.ID_MEDICO
        LEFT JOIN FACTURA F ON C.ID_CITA = F.ID_CITA AND F.ESTADO_PAGO != 'ANULADA'
        WHERE C.ID_PACIENTE = p_id
        ORDER BY C.FECHA DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== HISTORIAL PACIENTE #' || v_id_paciente || ' ===');
    FOR v IN cur_historial(v_id_paciente) LOOP
        DBMS_OUTPUT.PUT_LINE(v.FECHA || ' | ' || v.MEDICO || ' | ' ||
                             v.ESTADO || ' | Factura: ' ||
                             NVL(v.NUMERO_FACTURA_ELECTRONICA, 'Sin factura'));
    END LOOP;
END;
/

-- CURSOR 09: Facturas con saldo parcial pendiente
DECLARE
    CURSOR cur_saldo_parcial IS
        SELECT F.ID_FACTURA,
               F.NUMERO_FACTURA_ELECTRONICA,
               F.TOTAL,
               NVL((SELECT SUM(MONTO_PAGADO) FROM PAGO
                    WHERE ID_FACTURA=F.ID_FACTURA AND ESTADO='APROBADO'),0) AS COBRADO,
               F.TOTAL - NVL((SELECT SUM(MONTO_PAGADO) FROM PAGO
                              WHERE ID_FACTURA=F.ID_FACTURA AND ESTADO='APROBADO'),0) AS SALDO
        FROM FACTURA F WHERE F.ESTADO_PAGO = 'PARCIAL';
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== FACTURAS CON SALDO PARCIAL ===');
    FOR v IN cur_saldo_parcial LOOP
        DBMS_OUTPUT.PUT_LINE(v.NUMERO_FACTURA_ELECTRONICA ||
                             ' | Total: ' || pkg_utilidades.formatear_colones(v.TOTAL) ||
                             ' | Cobrado: ' || pkg_utilidades.formatear_colones(v.COBRADO) ||
                             ' | Saldo: ' || pkg_utilidades.formatear_colones(v.SALDO));
    END LOOP;
END;
/

-- CURSOR 10: Servicios más vendidos (top 5 por ingresos)
DECLARE
    CURSOR cur_top_servicios IS
        SELECT S.NOMBRE_SERVICIO, S.CATEGORIA,
               SUM(DF.CANTIDAD)       AS CANTIDAD_VENDIDA,
               SUM(DF.SUBTOTAL_LINEA) AS INGRESO_TOTAL
        FROM DETALLE_FACTURA DF
        JOIN SERVICIO S ON DF.ID_SERVICIO = S.ID_SERVICIO
        JOIN FACTURA  F ON DF.ID_FACTURA  = F.ID_FACTURA
        WHERE F.ESTADO_PAGO != 'ANULADA'
        GROUP BY S.NOMBRE_SERVICIO, S.CATEGORIA
        ORDER BY INGRESO_TOTAL DESC
        FETCH FIRST 5 ROWS ONLY;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TOP 5 SERVICIOS POR INGRESOS ===');
    FOR v IN cur_top_servicios LOOP
        DBMS_OUTPUT.PUT_LINE(v.NOMBRE_SERVICIO || ' | Qty: ' || v.CANTIDAD_VENDIDA ||
                             ' | Ingresos: ' || pkg_utilidades.formatear_colones(v.INGRESO_TOTAL));
    END LOOP;
END;
/

-- CURSOR 11: Usuarios del sistema por rol
DECLARE
    CURSOR cur_usuarios_rol IS
        SELECT ROL, COUNT(*) AS CANTIDAD,
               LISTAGG(NOMBRE_USUARIO, ', ') WITHIN GROUP (ORDER BY NOMBRE_USUARIO) AS USUARIOS
        FROM USUARIO_SISTEMA
        GROUP BY ROL ORDER BY ROL;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== USUARIOS POR ROL ===');
    FOR v IN cur_usuarios_rol LOOP
        DBMS_OUTPUT.PUT_LINE(v.ROL || ' (' || v.CANTIDAD || '): ' || v.USUARIOS);
    END LOOP;
END;
/

-- CURSOR 12: Citas canceladas o con inasistencia del último mes
DECLARE
    CURSOR cur_inasistencias IS
        SELECT P.NOMBRE || ' ' || P.APELLIDOS AS PACIENTE,
               P.TELEFONO,
               TO_CHAR(C.FECHA,'DD/MM/YYYY') AS FECHA,
               C.HORA, C.ESTADO,
               M.NOMBRE || ' ' || M.APELLIDOS AS MEDICO
        FROM CITA C
        JOIN PACIENTE P ON C.ID_PACIENTE = P.ID_PACIENTE
        JOIN MEDICO   M ON C.ID_MEDICO   = M.ID_MEDICO
        WHERE C.ESTADO IN ('CANCELADA','NO_ASISTIO')
          AND C.FECHA  >= SYSDATE - 30
        ORDER BY C.FECHA DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== CANCELACIONES / INASISTENCIAS (30 días) ===');
    FOR v IN cur_inasistencias LOOP
        DBMS_OUTPUT.PUT_LINE('[' || v.ESTADO || '] ' || v.FECHA || ' ' || v.HORA ||
                             ' | ' || v.PACIENTE || ' | ' || v.MEDICO);
    END LOOP;
END;
/

-- CURSOR 13: Ingresos mensuales del año actual
DECLARE
    CURSOR cur_ingresos_anuales IS
        SELECT EXTRACT(MONTH FROM FECHA_PAGO) AS MES,
               COUNT(ID_PAGO)                AS TRANSACCIONES,
               SUM(MONTO_PAGADO)             AS TOTAL_MES
        FROM PAGO
        WHERE EXTRACT(YEAR FROM FECHA_PAGO) = EXTRACT(YEAR FROM SYSDATE)
          AND ESTADO = 'APROBADO'
        GROUP BY EXTRACT(MONTH FROM FECHA_PAGO)
        ORDER BY MES;
    v_gran_total NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INGRESOS AÑO ' || EXTRACT(YEAR FROM SYSDATE) || ' ===');
    FOR v IN cur_ingresos_anuales LOOP
        DBMS_OUTPUT.PUT_LINE('Mes ' || LPAD(v.MES,2,'0') ||
                             ': ' || pkg_utilidades.formatear_colones(v.TOTAL_MES) ||
                             ' (' || v.TRANSACCIONES || ' txn)');
        v_gran_total := v_gran_total + v.TOTAL_MES;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('ACUMULADO: ' || pkg_utilidades.formatear_colones(v_gran_total));
END;
/

-- CURSOR 14: Auditoría de cambios en facturas
DECLARE
    CURSOR cur_auditoria IS
        SELECT A.ID_AUDIT,
               TO_CHAR(A.FECHA_CAMBIO,'DD/MM/YYYY HH24:MI:SS') AS FECHA,
               F.NUMERO_FACTURA_ELECTRONICA,
               A.ESTADO_ANTERIOR,
               A.ESTADO_NUEVO,
               A.USUARIO_BD
        FROM AUDIT_FACTURA A
        JOIN FACTURA F ON A.ID_FACTURA = F.ID_FACTURA
        ORDER BY A.FECHA_CAMBIO DESC
        FETCH FIRST 20 ROWS ONLY;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== LOG DE AUDITORÍA (últimos 20 cambios) ===');
    FOR v IN cur_auditoria LOOP
        DBMS_OUTPUT.PUT_LINE(v.FECHA || ' | ' || v.NUMERO_FACTURA_ELECTRONICA ||
                             ' | ' || NVL(v.ESTADO_ANTERIOR,'(nuevo)') ||
                             ' → ' || v.ESTADO_NUEVO ||
                             ' | Usuario: ' || v.USUARIO_BD);
    END LOOP;
END;
/

-- CURSOR 15: Resumen diario de la clínica (Dashboard)
DECLARE
    v_citas_hoy    NUMBER; v_atendidas NUMBER; v_programadas NUMBER;
    v_cobrado      NUMBER; v_pendientes NUMBER;
    CURSOR cur_dashboard IS
        SELECT 'Citas programadas hoy' AS INDICADOR,
               COUNT(*) AS VALOR
        FROM CITA WHERE TRUNC(FECHA)=TRUNC(SYSDATE) AND ESTADO='PROGRAMADA'
        UNION ALL
        SELECT 'Citas atendidas hoy',
               COUNT(*) FROM CITA WHERE TRUNC(FECHA)=TRUNC(SYSDATE) AND ESTADO='ATENDIDA'
        UNION ALL
        SELECT 'Nuevas facturas hoy',
               COUNT(*) FROM FACTURA WHERE TRUNC(FECHA_EMISION)=TRUNC(SYSDATE)
        UNION ALL
        SELECT 'Facturas pendientes',
               COUNT(*) FROM FACTURA WHERE ESTADO_PAGO IN ('PENDIENTE','PARCIAL')
        UNION ALL
        SELECT 'Pacientes registrados',
               COUNT(*) FROM PACIENTE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== DASHBOARD CLÍNICA - ' || TO_CHAR(SYSDATE,'DD/MM/YYYY') || ' ===');
    FOR v IN cur_dashboard LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(v.INDICADOR, 30) || ': ' || v.VALOR);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Cobrado hoy: ' ||
        pkg_utilidades.formatear_colones(pkg_factura.cobrado_hoy));
END;
/

PROMPT ✓ 5 triggers y 15 cursores creados exitosamente.
