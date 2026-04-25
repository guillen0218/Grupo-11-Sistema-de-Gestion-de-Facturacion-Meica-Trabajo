===========================================================================
  SGFM - SISTEMA DE GESTIÓN DE FACTURACIÓN MÉDICA
  Grupo 11 - Universidad Fidélitas - Lenguaje de Base de Datos
  Proyecto Final
===========================================================================

INSTRUCCIONES DE INSTALACIÓN Y EJECUCIÓN
-----------------------------------------

PRE-REQUISITOS
--------------
1. Oracle Database XE 21c (o versión compatible) instalado y en ejecución.
   Descarga: https://www.oracle.com/database/technologies/xe-downloads.html

2. Python 3.10 o superior instalado.
   Descarga: https://www.python.org/downloads/

3. Librería python-oracledb instalada:
   Abrir una terminal y ejecutar:

       pip install oracledb

PASO 1 — CREAR USUARIO EN ORACLE
----------------------------------
Abrir SQL*Plus o SQL Developer y conectarse como SYSDBA:

   CONNECT sys AS sysdba;

Ejecutar los siguientes comandos:

   CREATE USER sgfm_user IDENTIFIED BY sgfm_pass_2024
       DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;

   GRANT CONNECT, RESOURCE, CREATE VIEW,
         CREATE PROCEDURE, CREATE SEQUENCE,
         CREATE TRIGGER, CREATE TABLE TO sgfm_user;

PASO 2 — EJECUTAR LOS SCRIPTS SQL EN ORDEN
--------------------------------------------
Conectarse con el usuario creado:

   CONNECT sgfm_user/sgfm_pass_2024@localhost/XEPDB1;

Ejecutar los scripts en el siguiente orden EXACTO:

   @01_DDL_tablas.sql
   @02_procedimientos_almacenados.sql
   @03_funciones.sql
   @04_vistas.sql
   @05_paquetes.sql
   @06_triggers_y_cursores.sql
   @08_datos_prueba.sql
   @09_diccionario_datos.sql

Nota: El archivo 09_diccionario_datos.sql genera consultas de
      verificación. No contiene DML; es solo informativo.

PASO 3 — EJECUTAR LA INTERFAZ GRÁFICA
---------------------------------------
Abrir una terminal en la carpeta del proyecto y ejecutar:

   python 10_gui_principal.py

Nota: Si el comando anterior no funciona, intentar:

   python3 10_gui_principal.py

CREDENCIALES POR DEFECTO (pre-cargadas en el login)
------------------------------------------------------
   Usuario Oracle : sgfm_user
   Contraseña     : sgfm_pass_2024
   DSN            : localhost/XEPDB1

VERIFICACIÓN DE CONEXIÓN DESDE PYTHON
---------------------------------------
Para verificar únicamente la conexión sin abrir la GUI:

   python 07_conexion_oracle.py

ESTRUCTURA DE ARCHIVOS
-----------------------
   01_DDL_tablas.sql             → Estructura de tablas, datos iniciales
   02_procedimientos_almacenados.sql → 25 Stored Procedures (CRUD)
   03_funciones.sql              → 15 Funciones PL/SQL
   04_vistas.sql                 → 10 Vistas
   05_paquetes.sql               → 10 Paquetes (spec + body)
   06_triggers_y_cursores.sql    → 5 Triggers + 15 Cursores
   07_conexion_oracle.py         → Módulo de conexión (Python)
   08_datos_prueba.sql           → Datos de prueba adicionales
   09_diccionario_datos.sql      → Consultas de documentación
   10_gui_principal.py           → Interfaz Gráfica (GUI) principal
   LEAME.txt                     → Este archivo

SOLUCIÓN DE PROBLEMAS FRECUENTES
----------------------------------
Problema: "DPI-1047: Cannot locate a 64-bit Oracle Client library"
Solución:  python-oracledb en modo "Thin" no requiere cliente Oracle.
           El script ya usa thin mode por defecto con oracledb.connect().
           Si el error persiste, verificar que Oracle XE esté corriendo:
           En Windows: Services → "OracleServiceXEPDB1" debe estar en Running.

Problema: "ORA-12541: TNS:no listener"
Solución:  El listener de Oracle no está activo.
           Ejecutar en cmd (Windows):   lsnrctl start
           Ejecutar en terminal (Linux): sudo systemctl start oracle-xe-21c

Problema: "ORA-01017: invalid username/password"
Solución:  Verificar que el usuario fue creado correctamente (Paso 1).
           Las credenciales son sensibles a mayúsculas en algunos sistemas.

Problema: "ModuleNotFoundError: No module named 'oracledb'"
Solución:  Ejecutar: pip install oracledb --upgrade

NOTAS ACADÉMICAS
-----------------
- El sistema implementa CRUD completo para todas las tablas.
- La GUI conecta a Oracle usando python-oracledb (modo Thin).
- Los procedimientos almacenados son invocables desde la GUI y
  también directamente desde SQL*Plus/SQL Developer.
- Los cursores en 06_triggers_y_cursores.sql son bloques PL/SQL
  listos para ejecutar con SET SERVEROUTPUT ON en SQL*Plus.

===========================================================================
  Grupo 11 | Universidad Fidélitas | Lenguaje de Base de Datos | 2024
===========================================================================