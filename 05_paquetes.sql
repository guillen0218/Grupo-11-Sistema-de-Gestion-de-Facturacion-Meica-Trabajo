-- ============================================================
-- SISTEMA DE GESTIÓN DE FACTURACIÓN MÉDICA
-- Archivo: 05_paquetes.sql
-- Total: 10 paquetes (spec + body)
-- ============================================================

-- ================================================================
-- PKG01: Gestión de Pacientes
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_paciente AS
    PROCEDURE insertar(
        p_id_seguro IN NUMBER, p_cedula IN VARCHAR2, p_nombre IN VARCHAR2,
        p_apellidos IN VARCHAR2, p_fecha_nacimiento IN DATE, p_telefono IN VARCHAR2,
        p_correo IN VARCHAR2, p_direccion IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE actualizar(
        p_id_paciente IN NUMBER, p_id_seguro IN NUMBER, p_nombre IN VARCHAR2,
        p_apellidos IN VARCHAR2, p_telefono IN VARCHAR2, p_correo IN VARCHAR2,
        p_direccion IN VARCHAR2, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE eliminar(p_id_paciente IN NUMBER, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE buscar_por_cedula(p_cedula IN VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE listar(p_cursor OUT SYS_REFCURSOR);
    FUNCTION  existe(p_cedula IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION  total_registrados RETURN NUMBER;
END pkg_paciente;
/
CREATE OR REPLACE PACKAGE BODY pkg_paciente AS
    PROCEDURE insertar(
        p_id_seguro IN NUMBER, p_cedula IN VARCHAR2, p_nombre IN VARCHAR2,
        p_apellidos IN VARCHAR2, p_fecha_nacimiento IN DATE, p_telefono IN VARCHAR2,
        p_correo IN VARCHAR2, p_direccion IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_insertar_paciente(p_id_seguro, p_cedula, p_nombre, p_apellidos,
            p_fecha_nacimiento, p_telefono, p_correo, p_direccion, p_resultado, p_mensaje);
    END insertar;
    PROCEDURE actualizar(
        p_id_paciente IN NUMBER, p_id_seguro IN NUMBER, p_nombre IN VARCHAR2,
        p_apellidos IN VARCHAR2, p_telefono IN VARCHAR2, p_correo IN VARCHAR2,
        p_direccion IN VARCHAR2, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_actualizar_paciente(p_id_paciente, p_id_seguro, p_nombre, p_apellidos,
            p_telefono, p_correo, p_direccion, p_resultado, p_mensaje);
    END actualizar;
    PROCEDURE eliminar(p_id_paciente IN NUMBER, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_eliminar_paciente(p_id_paciente, p_resultado, p_mensaje);
    END eliminar;
    PROCEDURE buscar_por_cedula(p_cedula IN VARCHAR2, p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT P.ID_PACIENTE, P.CEDULA,
                   P.NOMBRE || ' ' || P.APELLIDOS          AS NOMBRE_COMPLETO,
                   fn_calcular_edad(P.FECHA_NACIMIENTO)    AS EDAD,
                   P.TELEFONO, P.CORREO, P.DIRECCION,
                   NVL(S.NOMBRE_ASEGURADORA, 'Sin seguro') AS ASEGURADORA
            FROM PACIENTE P LEFT JOIN SEGURO_MEDICO S ON P.ID_SEGURO = S.ID_SEGURO
            WHERE P.CEDULA = p_cedula;
    END buscar_por_cedula;
    PROCEDURE listar(p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        sp_listar_pacientes(p_cursor);
    END listar;
    FUNCTION existe(p_cedula IN VARCHAR2) RETURN BOOLEAN AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PACIENTE WHERE CEDULA = p_cedula;
        RETURN v_count > 0;
    END existe;
    FUNCTION total_registrados RETURN NUMBER AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PACIENTE;
        RETURN v_count;
    END total_registrados;
END pkg_paciente;
/

-- ================================================================
-- PKG02: Gestión de Médicos
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_medico AS
    PROCEDURE insertar(
        p_cedula IN VARCHAR2, p_nombre IN VARCHAR2, p_apellidos IN VARCHAR2,
        p_especialidad IN VARCHAR2, p_codigo_medico IN VARCHAR2,
        p_telefono IN VARCHAR2, p_correo IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE actualizar(
        p_id_medico IN NUMBER, p_nombre IN VARCHAR2, p_apellidos IN VARCHAR2,
        p_especialidad IN VARCHAR2, p_telefono IN VARCHAR2, p_correo IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE listar_por_especialidad(p_especialidad IN VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    FUNCTION  citas_hoy(p_id_medico IN NUMBER) RETURN NUMBER;
    FUNCTION  total_especialidades RETURN NUMBER;
END pkg_medico;
/
CREATE OR REPLACE PACKAGE BODY pkg_medico AS
    PROCEDURE insertar(
        p_cedula IN VARCHAR2, p_nombre IN VARCHAR2, p_apellidos IN VARCHAR2,
        p_especialidad IN VARCHAR2, p_codigo_medico IN VARCHAR2,
        p_telefono IN VARCHAR2, p_correo IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_insertar_medico(p_cedula, p_nombre, p_apellidos, p_especialidad,
            p_codigo_medico, p_telefono, p_correo, p_resultado, p_mensaje);
    END insertar;
    PROCEDURE actualizar(
        p_id_medico IN NUMBER, p_nombre IN VARCHAR2, p_apellidos IN VARCHAR2,
        p_especialidad IN VARCHAR2, p_telefono IN VARCHAR2, p_correo IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_actualizar_medico(p_id_medico, p_nombre, p_apellidos, p_especialidad,
            p_telefono, p_correo, p_resultado, p_mensaje);
    END actualizar;
    PROCEDURE listar_por_especialidad(p_especialidad IN VARCHAR2, p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT ID_MEDICO, CEDULA, NOMBRE || ' ' || APELLIDOS AS NOMBRE_COMPLETO,
                   ESPECIALIDAD, CODIGO_MEDICO, TELEFONO, CORREO
            FROM MEDICO
            WHERE UPPER(ESPECIALIDAD) LIKE '%' || UPPER(p_especialidad) || '%'
            ORDER BY APELLIDOS;
    END listar_por_especialidad;
    FUNCTION citas_hoy(p_id_medico IN NUMBER) RETURN NUMBER AS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total FROM CITA
        WHERE ID_MEDICO = p_id_medico AND TRUNC(FECHA) = TRUNC(SYSDATE)
          AND ESTADO = 'PROGRAMADA';
        RETURN v_total;
    END citas_hoy;
    FUNCTION total_especialidades RETURN NUMBER AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(DISTINCT ESPECIALIDAD) INTO v_count FROM MEDICO;
        RETURN v_count;
    END total_especialidades;
END pkg_medico;
/

-- ================================================================
-- PKG03: Gestión de Citas
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_cita AS
    PROCEDURE programar(
        p_id_paciente IN NUMBER, p_id_medico IN NUMBER, p_fecha IN DATE,
        p_hora IN VARCHAR2, p_motivo IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE cancelar(p_id_cita IN NUMBER, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE marcar_atendida(p_id_cita IN NUMBER, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE agenda_medico(p_id_medico IN NUMBER, p_fecha IN DATE, p_cursor OUT SYS_REFCURSOR);
    FUNCTION  disponible(p_id_medico IN NUMBER, p_fecha IN DATE, p_hora IN VARCHAR2) RETURN BOOLEAN;
END pkg_cita;
/
CREATE OR REPLACE PACKAGE BODY pkg_cita AS
    PROCEDURE programar(
        p_id_paciente IN NUMBER, p_id_medico IN NUMBER, p_fecha IN DATE,
        p_hora IN VARCHAR2, p_motivo IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_insertar_cita(p_id_paciente, p_id_medico, p_fecha, p_hora, p_motivo, p_resultado, p_mensaje);
    END programar;
    PROCEDURE cancelar(p_id_cita IN NUMBER, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_actualizar_estado_cita(p_id_cita, 'CANCELADA', p_resultado, p_mensaje);
    END cancelar;
    PROCEDURE marcar_atendida(p_id_cita IN NUMBER, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_actualizar_estado_cita(p_id_cita, 'ATENDIDA', p_resultado, p_mensaje);
    END marcar_atendida;
    PROCEDURE agenda_medico(p_id_medico IN NUMBER, p_fecha IN DATE, p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT C.ID_CITA, C.HORA,
                   P.NOMBRE || ' ' || P.APELLIDOS AS PACIENTE,
                   P.CEDULA, P.TELEFONO,
                   C.MOTIVO_CONSULTA, C.ESTADO
            FROM CITA C JOIN PACIENTE P ON C.ID_PACIENTE = P.ID_PACIENTE
            WHERE C.ID_MEDICO = p_id_medico AND TRUNC(C.FECHA) = TRUNC(p_fecha)
            ORDER BY C.HORA;
    END agenda_medico;
    FUNCTION disponible(p_id_medico IN NUMBER, p_fecha IN DATE, p_hora IN VARCHAR2) RETURN BOOLEAN AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM CITA
        WHERE ID_MEDICO = p_id_medico AND TRUNC(FECHA) = TRUNC(p_fecha)
          AND HORA = p_hora AND ESTADO NOT IN ('CANCELADA','NO_ASISTIO');
        RETURN v_count = 0;
    END disponible;
END pkg_cita;
/

-- ================================================================
-- PKG04: Facturación
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_factura AS
    PROCEDURE generar(
        p_id_cita IN NUMBER, p_descuento IN NUMBER DEFAULT 0,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2, p_id_factura OUT NUMBER);
    PROCEDURE agregar_servicio(
        p_id_factura IN NUMBER, p_id_servicio IN NUMBER, p_cantidad IN NUMBER,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE anular(p_id_factura IN NUMBER, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE listar_pendientes(p_cursor OUT SYS_REFCURSOR);
    FUNCTION  cobrado_hoy RETURN NUMBER;
    FUNCTION  saldo_pendiente(p_id_factura IN NUMBER) RETURN NUMBER;
END pkg_factura;
/
CREATE OR REPLACE PACKAGE BODY pkg_factura AS
    PROCEDURE generar(
        p_id_cita IN NUMBER, p_descuento IN NUMBER DEFAULT 0,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2, p_id_factura OUT NUMBER) AS
    BEGIN
        sp_generar_factura(p_id_cita, p_descuento, p_resultado, p_mensaje, p_id_factura);
    END generar;
    PROCEDURE agregar_servicio(
        p_id_factura IN NUMBER, p_id_servicio IN NUMBER, p_cantidad IN NUMBER,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_insertar_detalle_factura(p_id_factura, p_id_servicio, p_cantidad, p_resultado, p_mensaje);
    END agregar_servicio;
    PROCEDURE anular(p_id_factura IN NUMBER, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_anular_factura(p_id_factura, p_resultado, p_mensaje);
    END anular;
    PROCEDURE listar_pendientes(p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR SELECT * FROM vw_facturas_pendientes;
    END listar_pendientes;
    FUNCTION cobrado_hoy RETURN NUMBER AS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(MONTO_PAGADO), 0) INTO v_total
        FROM PAGO WHERE TRUNC(FECHA_PAGO) = TRUNC(SYSDATE) AND ESTADO = 'APROBADO';
        RETURN v_total;
    END cobrado_hoy;
    FUNCTION saldo_pendiente(p_id_factura IN NUMBER) RETURN NUMBER AS
        v_total  NUMBER; v_pagado NUMBER;
    BEGIN
        SELECT TOTAL INTO v_total FROM FACTURA WHERE ID_FACTURA = p_id_factura;
        SELECT NVL(SUM(MONTO_PAGADO), 0) INTO v_pagado
        FROM PAGO WHERE ID_FACTURA = p_id_factura AND ESTADO = 'APROBADO';
        RETURN GREATEST(v_total - v_pagado, 0);
    END saldo_pendiente;
END pkg_factura;
/

-- ================================================================
-- PKG05: Pagos
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_pago AS
    PROCEDURE registrar(
        p_id_factura IN NUMBER, p_monto IN NUMBER, p_metodo IN VARCHAR2,
        p_referencia IN VARCHAR2, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE historial_paciente(p_id_paciente IN NUMBER, p_cursor OUT SYS_REFCURSOR);
    FUNCTION  total_cobrado_mes(p_anio IN NUMBER, p_mes IN NUMBER) RETURN NUMBER;
END pkg_pago;
/
CREATE OR REPLACE PACKAGE BODY pkg_pago AS
    PROCEDURE registrar(
        p_id_factura IN NUMBER, p_monto IN NUMBER, p_metodo IN VARCHAR2,
        p_referencia IN VARCHAR2, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_registrar_pago(p_id_factura, p_monto, p_metodo, p_referencia, p_resultado, p_mensaje);
    END registrar;
    PROCEDURE historial_paciente(p_id_paciente IN NUMBER, p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT PA.ID_PAGO, TO_CHAR(PA.FECHA_PAGO,'DD/MM/YYYY') AS FECHA,
                   PA.MONTO_PAGADO, PA.METODO_PAGO,
                   F.NUMERO_FACTURA_ELECTRONICA, F.TOTAL AS TOTAL_FACTURA
            FROM PAGO PA JOIN FACTURA F ON PA.ID_FACTURA = F.ID_FACTURA
                         JOIN CITA C    ON F.ID_CITA     = C.ID_CITA
            WHERE C.ID_PACIENTE = p_id_paciente AND PA.ESTADO = 'APROBADO'
            ORDER BY PA.FECHA_PAGO DESC;
    END historial_paciente;
    FUNCTION total_cobrado_mes(p_anio IN NUMBER, p_mes IN NUMBER) RETURN NUMBER AS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(MONTO_PAGADO),0) INTO v_total FROM PAGO
        WHERE EXTRACT(YEAR FROM FECHA_PAGO)=p_anio AND EXTRACT(MONTH FROM FECHA_PAGO)=p_mes
          AND ESTADO='APROBADO';
        RETURN v_total;
    END total_cobrado_mes;
END pkg_pago;
/

-- ================================================================
-- PKG06: Catálogo de Servicios
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_servicio AS
    PROCEDURE insertar(
        p_nombre IN VARCHAR2, p_descripcion IN VARCHAR2,
        p_precio IN NUMBER, p_categoria IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE actualizar_precio(p_id_servicio IN NUMBER, p_nuevo_precio IN NUMBER,
                                p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE buscar(p_criterio IN VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    FUNCTION  precio_con_iva(p_id_servicio IN NUMBER) RETURN NUMBER;
    FUNCTION  mas_solicitado RETURN VARCHAR2;
END pkg_servicio;
/
CREATE OR REPLACE PACKAGE BODY pkg_servicio AS
    PROCEDURE insertar(
        p_nombre IN VARCHAR2, p_descripcion IN VARCHAR2,
        p_precio IN NUMBER, p_categoria IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_insertar_servicio(p_nombre, p_descripcion, p_precio, p_categoria, p_resultado, p_mensaje);
    END insertar;
    PROCEDURE actualizar_precio(p_id_servicio IN NUMBER, p_nuevo_precio IN NUMBER,
                                p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_actualizar_servicio(p_id_servicio, p_nuevo_precio, NULL, p_resultado, p_mensaje);
    END actualizar_precio;
    PROCEDURE buscar(p_criterio IN VARCHAR2, p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT ID_SERVICIO, NOMBRE_SERVICIO, DESCRIPCION, PRECIO_BASE, CATEGORIA
            FROM SERVICIO
            WHERE UPPER(NOMBRE_SERVICIO) LIKE '%'||UPPER(p_criterio)||'%'
               OR UPPER(CATEGORIA)       LIKE '%'||UPPER(p_criterio)||'%'
            ORDER BY CATEGORIA, NOMBRE_SERVICIO;
    END buscar;
    FUNCTION precio_con_iva(p_id_servicio IN NUMBER) RETURN NUMBER AS
        v_precio NUMBER;
    BEGIN
        SELECT PRECIO_BASE INTO v_precio FROM SERVICIO WHERE ID_SERVICIO = p_id_servicio;
        RETURN ROUND(v_precio * 1.13, 2);
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 0;
    END precio_con_iva;
    FUNCTION mas_solicitado RETURN VARCHAR2 AS
        v_nombre VARCHAR2(200);
    BEGIN
        SELECT S.NOMBRE_SERVICIO INTO v_nombre
        FROM (SELECT ID_SERVICIO, SUM(CANTIDAD) AS TOTAL FROM DETALLE_FACTURA
              GROUP BY ID_SERVICIO ORDER BY TOTAL DESC)
        JOIN SERVICIO S ON S.ID_SERVICIO = ID_SERVICIO
        WHERE ROWNUM = 1;
        RETURN v_nombre;
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 'Sin datos';
    END mas_solicitado;
END pkg_servicio;
/

-- ================================================================
-- PKG07: Seguridad y Usuarios
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_usuario AS
    PROCEDURE crear(
        p_nombre_usuario IN VARCHAR2, p_contrasena_hash IN VARCHAR2,
        p_rol IN VARCHAR2, p_correo IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE autenticar(
        p_nombre_usuario IN VARCHAR2, p_contrasena_hash IN VARCHAR2,
        p_autenticado OUT NUMBER, p_rol OUT VARCHAR2);
    PROCEDURE desactivar(p_nombre_usuario IN VARCHAR2, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    FUNCTION  obtener_rol(p_nombre_usuario IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION  esta_activo(p_nombre_usuario IN VARCHAR2) RETURN BOOLEAN;
END pkg_usuario;
/
CREATE OR REPLACE PACKAGE BODY pkg_usuario AS
    PROCEDURE crear(
        p_nombre_usuario IN VARCHAR2, p_contrasena_hash IN VARCHAR2,
        p_rol IN VARCHAR2, p_correo IN VARCHAR2,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_insertar_usuario(p_nombre_usuario, p_contrasena_hash, p_rol, p_correo, p_resultado, p_mensaje);
    END crear;
    PROCEDURE autenticar(
        p_nombre_usuario IN VARCHAR2, p_contrasena_hash IN VARCHAR2,
        p_autenticado OUT NUMBER, p_rol OUT VARCHAR2) AS
        v_hash   VARCHAR2(200); v_activo NUMBER;
    BEGIN
        SELECT CONTRASENA_HASH, ROL, ACTIVO INTO v_hash, p_rol, v_activo
        FROM USUARIO_SISTEMA WHERE NOMBRE_USUARIO = p_nombre_usuario;
        IF v_activo = 0 THEN p_autenticado := 0; p_rol := NULL;
        ELSIF v_hash = p_contrasena_hash THEN p_autenticado := 1;
        ELSE p_autenticado := 0; p_rol := NULL; END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN p_autenticado := 0; p_rol := NULL;
    END autenticar;
    PROCEDURE desactivar(p_nombre_usuario IN VARCHAR2, p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        UPDATE USUARIO_SISTEMA SET ACTIVO = 0 WHERE NOMBRE_USUARIO = p_nombre_usuario;
        IF SQL%ROWCOUNT = 0 THEN p_resultado := 0; p_mensaje := 'Usuario no encontrado.';
        ELSE COMMIT; p_resultado := 1; p_mensaje := 'Usuario desactivado.'; END IF;
    END desactivar;
    FUNCTION obtener_rol(p_nombre_usuario IN VARCHAR2) RETURN VARCHAR2 AS
        v_rol VARCHAR2(50);
    BEGIN
        SELECT ROL INTO v_rol FROM USUARIO_SISTEMA WHERE NOMBRE_USUARIO = p_nombre_usuario;
        RETURN v_rol;
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
    END obtener_rol;
    FUNCTION esta_activo(p_nombre_usuario IN VARCHAR2) RETURN BOOLEAN AS
        v_activo NUMBER;
    BEGIN
        SELECT ACTIVO INTO v_activo FROM USUARIO_SISTEMA WHERE NOMBRE_USUARIO = p_nombre_usuario;
        RETURN v_activo = 1;
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN FALSE;
    END esta_activo;
END pkg_usuario;
/

-- ================================================================
-- PKG08: Reportes y Estadísticas
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_reportes AS
    PROCEDURE ingresos_por_dia(p_anio IN NUMBER, p_mes IN NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE citas_por_especialidad(p_fecha_ini IN DATE, p_fecha_fin IN DATE, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE servicios_mas_demandados(p_top IN NUMBER, p_cursor OUT SYS_REFCURSOR);
    FUNCTION  promedio_citas_diarias(p_id_medico IN NUMBER) RETURN NUMBER;
    FUNCTION  porcentaje_cancelacion RETURN NUMBER;
END pkg_reportes;
/
CREATE OR REPLACE PACKAGE BODY pkg_reportes AS
    PROCEDURE ingresos_por_dia(p_anio IN NUMBER, p_mes IN NUMBER, p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT EXTRACT(DAY FROM FECHA_PAGO) AS DIA,
                   COUNT(ID_PAGO)              AS TRANSACCIONES,
                   SUM(MONTO_PAGADO)           AS TOTAL_DIA
            FROM PAGO
            WHERE EXTRACT(YEAR FROM FECHA_PAGO)=p_anio
              AND EXTRACT(MONTH FROM FECHA_PAGO)=p_mes
              AND ESTADO='APROBADO'
            GROUP BY EXTRACT(DAY FROM FECHA_PAGO) ORDER BY DIA;
    END ingresos_por_dia;
    PROCEDURE citas_por_especialidad(p_fecha_ini IN DATE, p_fecha_fin IN DATE, p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT M.ESPECIALIDAD,
                   COUNT(C.ID_CITA)                                     AS TOTAL,
                   COUNT(CASE WHEN C.ESTADO='ATENDIDA'   THEN 1 END)   AS ATENDIDAS,
                   COUNT(CASE WHEN C.ESTADO='CANCELADA'  THEN 1 END)   AS CANCELADAS,
                   COUNT(CASE WHEN C.ESTADO='NO_ASISTIO' THEN 1 END)   AS NO_ASISTIO
            FROM CITA C JOIN MEDICO M ON C.ID_MEDICO = M.ID_MEDICO
            WHERE C.FECHA BETWEEN p_fecha_ini AND p_fecha_fin
            GROUP BY M.ESPECIALIDAD ORDER BY TOTAL DESC;
    END citas_por_especialidad;
    PROCEDURE servicios_mas_demandados(p_top IN NUMBER, p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT * FROM (
                SELECT S.NOMBRE_SERVICIO, S.CATEGORIA,
                       SUM(DF.CANTIDAD)       AS VECES_SOLICITADO,
                       SUM(DF.SUBTOTAL_LINEA) AS INGRESO_GENERADO
                FROM DETALLE_FACTURA DF JOIN SERVICIO S ON DF.ID_SERVICIO=S.ID_SERVICIO
                GROUP BY S.NOMBRE_SERVICIO, S.CATEGORIA ORDER BY VECES_SOLICITADO DESC
            ) WHERE ROWNUM <= p_top;
    END servicios_mas_demandados;
    FUNCTION promedio_citas_diarias(p_id_medico IN NUMBER) RETURN NUMBER AS
        v_total NUMBER; v_dias NUMBER;
    BEGIN
        SELECT COUNT(*), COUNT(DISTINCT TRUNC(FECHA)) INTO v_total, v_dias
        FROM CITA WHERE ID_MEDICO=p_id_medico AND ESTADO='ATENDIDA';
        IF v_dias=0 THEN RETURN 0; END IF;
        RETURN ROUND(v_total/v_dias,2);
    END promedio_citas_diarias;
    FUNCTION porcentaje_cancelacion RETURN NUMBER AS
        v_total NUMBER; v_canc NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total FROM CITA;
        SELECT COUNT(*) INTO v_canc  FROM CITA WHERE ESTADO='CANCELADA';
        IF v_total=0 THEN RETURN 0; END IF;
        RETURN ROUND((v_canc/v_total)*100,2);
    END porcentaje_cancelacion;
END pkg_reportes;
/

-- ================================================================
-- PKG09: Seguros Médicos
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_seguro AS
    PROCEDURE insertar(
        p_nombre_aseguradora IN VARCHAR2, p_numero_poliza IN VARCHAR2,
        p_cobertura IN NUMBER, p_fecha_vencimiento IN DATE,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE por_vencer(p_dias IN NUMBER, p_cursor OUT SYS_REFCURSOR);
    FUNCTION  cobertura_promedio RETURN NUMBER;
    FUNCTION  pacientes_con_seguro RETURN NUMBER;
END pkg_seguro;
/
CREATE OR REPLACE PACKAGE BODY pkg_seguro AS
    PROCEDURE insertar(
        p_nombre_aseguradora IN VARCHAR2, p_numero_poliza IN VARCHAR2,
        p_cobertura IN NUMBER, p_fecha_vencimiento IN DATE,
        p_resultado OUT NUMBER, p_mensaje OUT VARCHAR2) AS
    BEGIN
        sp_insertar_seguro(p_nombre_aseguradora,p_numero_poliza,p_cobertura,p_fecha_vencimiento,p_resultado,p_mensaje);
    END insertar;
    PROCEDURE por_vencer(p_dias IN NUMBER, p_cursor OUT SYS_REFCURSOR) AS
    BEGIN
        OPEN p_cursor FOR
            SELECT S.ID_SEGURO, S.NOMBRE_ASEGURADORA, S.NUMERO_POLIZA, S.FECHA_VENCIMIENTO,
                   TRUNC(S.FECHA_VENCIMIENTO-SYSDATE) AS DIAS_RESTANTES,
                   COUNT(P.ID_PACIENTE) AS PACIENTES
            FROM SEGURO_MEDICO S LEFT JOIN PACIENTE P ON S.ID_SEGURO=P.ID_SEGURO
            WHERE S.FECHA_VENCIMIENTO BETWEEN SYSDATE AND SYSDATE+p_dias
            GROUP BY S.ID_SEGURO,S.NOMBRE_ASEGURADORA,S.NUMERO_POLIZA,S.FECHA_VENCIMIENTO
            ORDER BY S.FECHA_VENCIMIENTO;
    END por_vencer;
    FUNCTION cobertura_promedio RETURN NUMBER AS
        v_prom NUMBER;
    BEGIN
        SELECT ROUND(AVG(COBERTURA_PORCENTAJE),2) INTO v_prom FROM SEGURO_MEDICO;
        RETURN NVL(v_prom,0);
    END cobertura_promedio;
    FUNCTION pacientes_con_seguro RETURN NUMBER AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PACIENTE WHERE ID_SEGURO IS NOT NULL;
        RETURN v_count;
    END pacientes_con_seguro;
END pkg_seguro;
/

-- ================================================================
-- PKG10: Utilidades del Sistema
-- ================================================================
CREATE OR REPLACE PACKAGE pkg_utilidades AS
    FUNCTION  formatear_colones(p_monto IN NUMBER) RETURN VARCHAR2;
    FUNCTION  validar_cedula_cr(p_cedula IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION  dias_habiles(p_fecha_ini IN DATE, p_fecha_fin IN DATE) RETURN NUMBER;
    PROCEDURE limpiar_citas_obsoletas(p_dias IN NUMBER, p_eliminadas OUT NUMBER);
    FUNCTION  version_sistema RETURN VARCHAR2;
END pkg_utilidades;
/
CREATE OR REPLACE PACKAGE BODY pkg_utilidades AS
    FUNCTION formatear_colones(p_monto IN NUMBER) RETURN VARCHAR2 AS
    BEGIN
        RETURN '₡' || TO_CHAR(NVL(p_monto,0), 'FM999,999,999.00');
    END formatear_colones;
    FUNCTION validar_cedula_cr(p_cedula IN VARCHAR2) RETURN BOOLEAN AS
    BEGIN
        RETURN LENGTH(REGEXP_REPLACE(TRIM(p_cedula),'[^0-9]','')) = 9;
    END validar_cedula_cr;
    FUNCTION dias_habiles(p_fecha_ini IN DATE, p_fecha_fin IN DATE) RETURN NUMBER AS
        v_fecha DATE := p_fecha_ini; v_dias NUMBER := 0;
    BEGIN
        WHILE v_fecha <= p_fecha_fin LOOP
            IF TO_CHAR(v_fecha,'DY','NLS_DATE_LANGUAGE=ENGLISH') NOT IN ('SAT','SUN') THEN
                v_dias := v_dias + 1;
            END IF;
            v_fecha := v_fecha + 1;
        END LOOP;
        RETURN v_dias;
    END dias_habiles;
    PROCEDURE limpiar_citas_obsoletas(p_dias IN NUMBER, p_eliminadas OUT NUMBER) AS
    BEGIN
        DELETE FROM CITA
        WHERE ESTADO IN ('CANCELADA','NO_ASISTIO') AND FECHA < SYSDATE - p_dias;
        p_eliminadas := SQL%ROWCOUNT;
        COMMIT;
    END limpiar_citas_obsoletas;
    FUNCTION version_sistema RETURN VARCHAR2 AS
    BEGIN
        RETURN 'SGFM v1.0 - Grupo 11 - Universidad Fidélitas - ' || TO_CHAR(SYSDATE,'YYYY');
    END version_sistema;
END pkg_utilidades;
/

PROMPT ✓ 10 paquetes creados exitosamente.
