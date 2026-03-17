"""
=====================================================
SISTEMA DE GESTIÓN DE FACTURACIÓN MÉDICA
Archivo: conexion_oracle.py
Descripción: Módulo de conexión segura a Oracle DB
             usando python-oracledb (cx_Oracle moderno)
Grupo 11 - Universidad Fidélitas
=====================================================
"""

import oracledb
from contextlib import contextmanager

# ─────────────────────────────────────────────────
# CONFIGURACIÓN DE CONEXIÓN
# Ajustar según el entorno del grupo
# ─────────────────────────────────────────────────
DB_CONFIG = {
    "user":     "sgfm_user",        # Usuario de la BD
    "password": "sgfm_pass_2024",   # Contraseña
    "dsn":      "localhost/XEPDB1", # host/service_name de Oracle XE
}


def obtener_conexion() -> oracledb.Connection:
    """
    Establece y retorna una conexión activa a Oracle.
    Lanza una excepción si falla la conexión.
    """
    try:
        conn = oracledb.connect(**DB_CONFIG)
        print(f"[OK] Conexión establecida | BD: {conn.dsn} | Usuario: {conn.username}")
        return conn
    except oracledb.DatabaseError as e:
        error, = e.args
        raise RuntimeError(
            f"[ERROR] No se pudo conectar a Oracle.\n"
            f"Código: {error.code} | Mensaje: {error.message}"
        ) from e


@contextmanager
def conexion_bd():
    """
    Context manager para manejo seguro de conexiones.
    Garantiza cierre automático y rollback ante errores.

    Uso recomendado:
        with conexion_bd() as (conn, cur):
            cur.execute(...)
    """
    conn = None
    cur  = None
    try:
        conn = obtener_conexion()
        cur  = conn.cursor()
        yield conn, cur
        conn.commit()
    except oracledb.DatabaseError as e:
        if conn:
            conn.rollback()
        error, = e.args
        raise RuntimeError(f"Error de BD: {error.code} - {error.message}") from e
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


# ─────────────────────────────────────────────────
# HELPERS — Ejecutar procedimientos almacenados
# ─────────────────────────────────────────────────

def ejecutar_sp_simple(nombre_sp: str, params: dict) -> dict:
    """
    Ejecuta un stored procedure con parámetros de entrada/salida.

    Args:
        nombre_sp: Nombre del SP, ej: "sp_insertar_paciente"
        params: dict con clave = nombre parámetro, valor = (valor, tipo_oracledb)
                - Para OUT:    (oracledb.CURSOR, None) o (None, tipo)
                - Para IN:     (valor, None)

    Returns:
        dict con los valores OUT del SP
    """
    with conexion_bd() as (conn, cur):
        args  = {}
        salida = {}

        for nombre, (valor, tipo) in params.items():
            if tipo is not None:
                # Parámetro de salida
                var = cur.var(tipo)
                args[nombre] = var
                salida[nombre] = var
            else:
                args[nombre] = valor

        cur.callproc(nombre_sp, keywordParameters=args)

        return {k: v.getvalue() for k, v in salida.items()}


def ejecutar_sp_cursor(nombre_sp: str, params_in: dict) -> list[dict]:
    """
    Ejecuta un SP que retorna un REF CURSOR y convierte el resultado a lista de dicts.

    Args:
        nombre_sp:  Nombre del SP
        params_in:  Parámetros IN (dict simple)

    Returns:
        Lista de diccionarios con las filas retornadas
    """
    with conexion_bd() as (conn, cur):
        ref_cursor = cur.var(oracledb.CURSOR)
        args = {**params_in, "p_cursor": ref_cursor}
        cur.callproc(nombre_sp, keywordParameters=args)

        rc = ref_cursor.getvalue()
        columnas = [d[0].lower() for d in rc.description]
        filas    = rc.fetchall()
        return [dict(zip(columnas, fila)) for fila in filas]


# ─────────────────────────────────────────────────
# EJEMPLOS DE USO (modo __main__)
# ─────────────────────────────────────────────────

def demo_listar_pacientes():
    print("\n── Listado de Pacientes ──")
    pacientes = ejecutar_sp_cursor("sp_listar_pacientes", {})
    for p in pacientes:
        print(f"  [{p['id_paciente']}] {p['nombre_completo']} | {p['aseguradora']}")


def demo_insertar_paciente():
    import oracledb as odb
    from datetime import date

    print("\n── Insertando paciente de prueba ──")
    resultado = ejecutar_sp_simple("sp_insertar_paciente", {
        "p_id_seguro":        (1,                       None),
        "p_cedula":           ("304560099",             None),
        "p_nombre":           ("Juan",                  None),
        "p_apellidos":        ("Prueba Ejemplo",        None),
        "p_fecha_nacimiento": (date(1995, 6, 15),       None),
        "p_telefono":         ("8888-9999",             None),
        "p_correo":           ("juan.prueba@test.com",  None),
        "p_direccion":        ("San José, Curridabat",  None),
        "p_resultado":        (None,                    odb.NUMBER),
        "p_mensaje":          (None,                    odb.STRING),
    })
    print(f"  Resultado: {resultado['p_resultado']}")
    print(f"  Mensaje:   {resultado['p_mensaje']}")


def demo_listar_citas_hoy():
    print("\n── Citas de Hoy ──")
    from datetime import date
    citas = ejecutar_sp_cursor("sp_citas_del_dia", {"p_fecha": date.today()})
    if not citas:
        print("  No hay citas programadas para hoy.")
    for c in citas:
        print(f"  {c['hora']} | {c['paciente']} | Dr. {c['medico']} [{c['estado']}]")


if __name__ == "__main__":
    print("=" * 55)
    print("  SGFM - Demo de conexión Python ↔ Oracle")
    print("=" * 55)
    try:
        demo_listar_pacientes()
        demo_insertar_paciente()
        demo_listar_citas_hoy()
    except RuntimeError as e:
        print(f"\n[FALLO] {e}")
    print("\n[Fin de la demo]")
