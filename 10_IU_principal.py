"""
==========================================================================
SISTEMA DE GESTIÓN DE FACTURACIÓN MÉDICA
Archivo: 10_gui_principal.py
Descripción: Interfaz Gráfica de Usuario (GUI) — Tkinter
             CRUD completo para todas las tablas del sistema
Grupo 11 - Universidad Fidélitas
Requiere: python-oracledb, tkinter (incluido en Python estándar)
==========================================================================
"""

import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
from datetime import date, datetime
import oracledb

# ──────────────────────────────────────────────────────────────
# CONFIGURACIÓN DE CONEXIÓN (ajustar según entorno del grupo)
# ──────────────────────────────────────────────────────────────
DB_CONFIG = {
    "user":     "sgfm_user",
    "password": "sgfm_pass_2024",
    "dsn":      "localhost/XEPDB1",
}

# ──────────────────────────────────────────────────────────────
# PALETA DE COLORES
# ──────────────────────────────────────────────────────────────
COLORS = {
    "bg_dark":    "#0D1B2A",
    "bg_medium":  "#1B2A3B",
    "bg_light":   "#243447",
    "accent":     "#00A8E8",
    "accent2":    "#00D4AA",
    "danger":     "#E84855",
    "warning":    "#F4A261",
    "text_main":  "#E8F4FD",
    "text_sub":   "#8BA3BD",
    "border":     "#2D4A63",
    "success":    "#2DC653",
    "white":      "#FFFFFF",
}

FONT_TITLE  = ("Segoe UI", 22, "bold")
FONT_HEADER = ("Segoe UI", 13, "bold")
FONT_BODY   = ("Segoe UI", 10)
FONT_SMALL  = ("Segoe UI", 9)
FONT_BTN    = ("Segoe UI", 10, "bold")


# ══════════════════════════════════════════════════════════════
# MÓDULO DE CONEXIÓN SEGURA
# ══════════════════════════════════════════════════════════════
class DatabaseManager:
    """Gestiona la conexión a Oracle de forma segura."""

    def __init__(self):
        self._conn = None

    def connect(self, user: str, password: str, dsn: str) -> bool:
        try:
            self._conn = oracledb.connect(user=user, password=password, dsn=dsn)
            return True
        except oracledb.DatabaseError as e:
            return False

    def disconnect(self):
        if self._conn:
            try:
                self._conn.close()
            except Exception:
                pass
            self._conn = None

    def execute_query(self, sql: str, params: dict = None) -> list:
        """Ejecuta un SELECT y retorna lista de tuplas."""
        if not self._conn:
            raise RuntimeError("Sin conexión activa.")
        cur = self._conn.cursor()
        try:
            cur.execute(sql, params or {})
            return cur.fetchall(), [d[0] for d in cur.description]
        finally:
            cur.close()

    def execute_dml(self, sql: str, params: dict = None) -> int:
        """Ejecuta INSERT/UPDATE/DELETE y hace commit. Retorna filas afectadas."""
        if not self._conn:
            raise RuntimeError("Sin conexión activa.")
        cur = self._conn.cursor()
        try:
            cur.execute(sql, params or {})
            rows = cur.rowcount
            self._conn.commit()
            return rows
        except Exception:
            self._conn.rollback()
            raise
        finally:
            cur.close()

    def call_proc(self, proc_name: str, params: list) -> list:
        """Llama a un stored procedure."""
        if not self._conn:
            raise RuntimeError("Sin conexión activa.")
        cur = self._conn.cursor()
        try:
            cur.callproc(proc_name, params)
            self._conn.commit()
            return params
        except Exception:
            self._conn.rollback()
            raise
        finally:
            cur.close()

    @property
    def is_connected(self) -> bool:
        return self._conn is not None


db = DatabaseManager()


# ══════════════════════════════════════════════════════════════
# VENTANA DE LOGIN
# ══════════════════════════════════════════════════════════════
class LoginWindow(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("SGFM — Iniciar Sesión")
        self.geometry("460x560")
        self.resizable(False, False)
        self.configure(bg=COLORS["bg_dark"])
        self._center_window(460, 560)
        self._build_ui()

    def _center_window(self, w, h):
        sw = self.winfo_screenwidth()
        sh = self.winfo_screenheight()
        x = (sw - w) // 2
        y = (sh - h) // 2
        self.geometry(f"{w}x{h}+{x}+{y}")

    def _build_ui(self):
        # Header
        header = tk.Frame(self, bg=COLORS["bg_medium"], pady=30)
        header.pack(fill="x")
        tk.Label(header, text="🏥", font=("Segoe UI", 36),
                 bg=COLORS["bg_medium"], fg=COLORS["accent"]).pack()
        tk.Label(header, text="SGFM", font=FONT_TITLE,
                 bg=COLORS["bg_medium"], fg=COLORS["text_main"]).pack()
        tk.Label(header, text="Sistema de Gestión de Facturación Médica",
                 font=FONT_SMALL, bg=COLORS["bg_medium"], fg=COLORS["text_sub"]).pack()

        # Form
        form = tk.Frame(self, bg=COLORS["bg_dark"], padx=50, pady=30)
        form.pack(fill="both", expand=True)

        def lbl(text):
            tk.Label(form, text=text, font=FONT_BODY,
                     bg=COLORS["bg_dark"], fg=COLORS["text_sub"]).pack(anchor="w", pady=(10, 2))

        def entry(show=None):
            e = tk.Entry(form, font=FONT_BODY, bg=COLORS["bg_light"],
                         fg=COLORS["text_main"], insertbackground=COLORS["accent"],
                         relief="flat", bd=0, show=show)
            e.pack(fill="x", ipady=8, pady=(0, 2))
            return e

        lbl("Usuario Oracle")
        self.e_user = entry()
        self.e_user.insert(0, DB_CONFIG["user"])

        lbl("Contraseña")
        self.e_pass = entry(show="●")
        self.e_pass.insert(0, DB_CONFIG["password"])

        lbl("DSN  (host/servicio)")
        self.e_dsn = entry()
        self.e_dsn.insert(0, DB_CONFIG["dsn"])

        self.lbl_status = tk.Label(form, text="", font=FONT_SMALL,
                                   bg=COLORS["bg_dark"], fg=COLORS["danger"])
        self.lbl_status.pack(pady=(8, 0))

        btn = tk.Button(form, text="Conectar y Entrar", font=FONT_BTN,
                        bg=COLORS["accent"], fg=COLORS["bg_dark"],
                        activebackground=COLORS["accent2"], relief="flat",
                        cursor="hand2", command=self._login)
        btn.pack(fill="x", ipady=10, pady=(16, 0))

        tk.Label(form, text="Grupo 11 · Universidad Fidélitas · 2024",
                 font=FONT_SMALL, bg=COLORS["bg_dark"],
                 fg=COLORS["text_sub"]).pack(side="bottom", pady=10)

        self.bind("<Return>", lambda e: self._login())

    def _login(self):
        user = self.e_user.get().strip()
        pwd  = self.e_pass.get().strip()
        dsn  = self.e_dsn.get().strip()

        if not all([user, pwd, dsn]):
            self.lbl_status.config(text="⚠ Complete todos los campos.")
            return

        self.lbl_status.config(text="Conectando…", fg=COLORS["warning"])
        self.update()

        if db.connect(user, pwd, dsn):
            self.lbl_status.config(text="✓ Conexión exitosa.", fg=COLORS["success"])
            self.after(400, self._open_main)
        else:
            self.lbl_status.config(
                text="✗ No se pudo conectar. Verifique credenciales y DSN.",
                fg=COLORS["danger"])

    def _open_main(self):
        self.withdraw()
        MainApp(self)


# ══════════════════════════════════════════════════════════════
# APLICACIÓN PRINCIPAL
# ══════════════════════════════════════════════════════════════
class MainApp(tk.Toplevel):
    def __init__(self, login_win):
        super().__init__()
        self.login_win = login_win
        self.title("SGFM — Sistema de Gestión de Facturación Médica")
        self.geometry("1200x720")
        self.minsize(1000, 600)
        self.configure(bg=COLORS["bg_dark"])
        self.protocol("WM_DELETE_WINDOW", self._on_close)
        self._build_ui()

    def _on_close(self):
        db.disconnect()
        self.login_win.destroy()

    def _build_ui(self):
        # ── Topbar ──
        topbar = tk.Frame(self, bg=COLORS["bg_medium"], height=54)
        topbar.pack(fill="x", side="top")
        topbar.pack_propagate(False)

        tk.Label(topbar, text="🏥  SGFM", font=("Segoe UI", 14, "bold"),
                 bg=COLORS["bg_medium"], fg=COLORS["accent"]).pack(side="left", padx=20, pady=12)

        self.lbl_time = tk.Label(topbar, text="", font=FONT_SMALL,
                                 bg=COLORS["bg_medium"], fg=COLORS["text_sub"])
        self.lbl_time.pack(side="right", padx=20)
        self._update_clock()

        tk.Button(topbar, text="⏻ Salir", font=FONT_BTN,
                  bg=COLORS["danger"], fg=COLORS["white"], relief="flat",
                  cursor="hand2", command=self._on_close).pack(side="right", padx=8, pady=10)

        # ── Notebook ──
        style = ttk.Style()
        style.theme_use("clam")
        style.configure("TNotebook",       background=COLORS["bg_dark"], borderwidth=0)
        style.configure("TNotebook.Tab",   background=COLORS["bg_medium"],
                        foreground=COLORS["text_sub"],  padding=[18, 8],
                        font=FONT_BODY)
        style.map("TNotebook.Tab",
                  background=[("selected", COLORS["bg_light"])],
                  foreground=[("selected", COLORS["accent"])])

        nb = ttk.Notebook(self)
        nb.pack(fill="both", expand=True, padx=0, pady=0)

        # ── Tabs ──
        tabs = [
            ("📊 Dashboard",   DashboardTab),
            ("🧑‍⚕️ Pacientes", PacientesTab),
            ("👨‍⚕️ Médicos",   MedicosTab),
            ("📅 Citas",       CitasTab),
            ("🧪 Servicios",   ServiciosTab),
            ("🧾 Facturas",    FacturasTab),
            ("💳 Pagos",       PagosTab),
            ("🛡 Seguros",    SegurosTab),
        ]
        for label, TabClass in tabs:
            frame = tk.Frame(nb, bg=COLORS["bg_dark"])
            nb.add(frame, text=label)
            TabClass(frame)

    def _update_clock(self):
        now = datetime.now().strftime("%d/%m/%Y  %H:%M:%S")
        self.lbl_time.config(text=now)
        self.after(1000, self._update_clock)


# ══════════════════════════════════════════════════════════════
# BASE PARA TABS CON CRUD
# ══════════════════════════════════════════════════════════════
class BaseCRUDTab(tk.Frame):
    """
    Tab genérico que provee:
    - Barra de búsqueda
    - Treeview con scrollbar
    - Botones: Nuevo | Editar | Eliminar | Actualizar
    Las subclases implementan: col_defs, load_data(), open_form()
    """
    TABLE_TITLE  = "Tabla"
    TABLE_ICON   = "📋"
    SEARCH_LABEL = "Buscar:"
    SHOW_DELETE  = True

    def __init__(self, parent):
        super().__init__(parent, bg=COLORS["bg_dark"])
        self.pack(fill="both", expand=True)
        self._build_header()
        self._build_toolbar()
        self._build_tree()
        self.load_data()

    # ── Header ──────────────────────────────────────────────
    def _build_header(self):
        h = tk.Frame(self, bg=COLORS["bg_medium"], pady=12)
        h.pack(fill="x")
        tk.Label(h, text=f"{self.TABLE_ICON}  {self.TABLE_TITLE}",
                 font=FONT_HEADER, bg=COLORS["bg_medium"],
                 fg=COLORS["text_main"]).pack(side="left", padx=20)

        # Search
        srch = tk.Frame(h, bg=COLORS["bg_medium"])
        srch.pack(side="right", padx=20)
        tk.Label(srch, text=self.SEARCH_LABEL, font=FONT_SMALL,
                 bg=COLORS["bg_medium"], fg=COLORS["text_sub"]).pack(side="left", padx=(0, 6))
        self.search_var = tk.StringVar()
        self.search_var.trace_add("write", lambda *_: self.load_data(self.search_var.get()))
        e = tk.Entry(srch, textvariable=self.search_var, width=26,
                     font=FONT_BODY, bg=COLORS["bg_light"],
                     fg=COLORS["text_main"], insertbackground=COLORS["accent"],
                     relief="flat", bd=0)
        e.pack(side="left", ipady=5)

    # ── Toolbar ─────────────────────────────────────────────
    def _build_toolbar(self):
        bar = tk.Frame(self, bg=COLORS["bg_dark"], pady=8)
        bar.pack(fill="x", padx=16)

        def btn(text, color, cmd):
            b = tk.Button(bar, text=text, font=FONT_BTN, bg=color, fg=COLORS["white"],
                          activebackground=color, relief="flat", cursor="hand2",
                          padx=14, pady=6, command=cmd)
            b.pack(side="left", padx=4)
            return b

        btn("＋ Nuevo",       COLORS["accent"],  self.action_new)
        btn("✏ Editar",      COLORS["bg_light"], self.action_edit)
        if self.SHOW_DELETE:
            btn("🗑 Eliminar", COLORS["danger"],  self.action_delete)
        btn("↻ Actualizar",   COLORS["bg_light"], self.load_data)

        self.lbl_count = tk.Label(bar, text="", font=FONT_SMALL,
                                  bg=COLORS["bg_dark"], fg=COLORS["text_sub"])
        self.lbl_count.pack(side="right", padx=8)

    # ── Treeview ─────────────────────────────────────────────
    def _build_tree(self):
        container = tk.Frame(self, bg=COLORS["bg_dark"])
        container.pack(fill="both", expand=True, padx=16, pady=(0, 12))

        style = ttk.Style()
        style.configure("Custom.Treeview",
                        background=COLORS["bg_medium"],
                        foreground=COLORS["text_main"],
                        fieldbackground=COLORS["bg_medium"],
                        rowheight=28,
                        font=FONT_BODY)
        style.configure("Custom.Treeview.Heading",
                        background=COLORS["bg_light"],
                        foreground=COLORS["accent"],
                        font=("Segoe UI", 10, "bold"),
                        relief="flat")
        style.map("Custom.Treeview",
                  background=[("selected", COLORS["accent"])],
                  foreground=[("selected", COLORS["bg_dark"])])

        self.tree = ttk.Treeview(container, style="Custom.Treeview",
                                 selectmode="browse", show="headings")
        self._setup_columns()

        vsb = ttk.Scrollbar(container, orient="vertical",   command=self.tree.yview)
        hsb = ttk.Scrollbar(container, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

        vsb.pack(side="right",  fill="y")
        hsb.pack(side="bottom", fill="x")
        self.tree.pack(fill="both", expand=True)
        self.tree.bind("<Double-1>", lambda e: self.action_edit())

    def _setup_columns(self):
        cols = self.col_defs()
        self.tree["columns"] = [c[0] for c in cols]
        for col_id, label, width in cols:
            self.tree.heading(col_id, text=label, anchor="w")
            self.tree.column(col_id, width=width, minwidth=60, anchor="w")

    def _populate_tree(self, rows):
        for item in self.tree.get_children():
            self.tree.delete(item)
        for i, row in enumerate(rows):
            tag = "even" if i % 2 == 0 else "odd"
            self.tree.insert("", "end", values=row, tags=(tag,))
        self.tree.tag_configure("even", background=COLORS["bg_medium"])
        self.tree.tag_configure("odd",  background=COLORS["bg_light"])
        self.lbl_count.config(text=f"{len(rows)} registro(s)")

    def selected_id(self):
        sel = self.tree.selection()
        if not sel:
            return None
        return self.tree.item(sel[0])["values"][0]

    # ── Acciones base ────────────────────────────────────────
    def action_new(self):
        self.open_form(record_id=None)

    def action_edit(self):
        rid = self.selected_id()
        if rid is None:
            messagebox.showinfo("Info", "Seleccione un registro para editar.")
            return
        self.open_form(record_id=rid)

    def action_delete(self):
        rid = self.selected_id()
        if rid is None:
            messagebox.showinfo("Info", "Seleccione un registro para eliminar.")
            return
        if messagebox.askyesno("Confirmar", f"¿Eliminar registro ID {rid}?"):
            self.do_delete(rid)
            self.load_data()

    # ── Métodos que las subclases DEBEN implementar ──────────
    def col_defs(self) -> list:
        """Retorna lista de (col_id, label, width)"""
        raise NotImplementedError

    def load_data(self, search=""):
        raise NotImplementedError

    def open_form(self, record_id):
        raise NotImplementedError

    def do_delete(self, record_id):
        raise NotImplementedError

    # ── Helper: mostrar errores de BD ────────────────────────
    def _db_error(self, exc):
        messagebox.showerror("Error de Base de Datos", str(exc))


# ══════════════════════════════════════════════════════════════
# HELPER: FORMULARIO MODAL GENÉRICO
# ══════════════════════════════════════════════════════════════
class FormDialog(tk.Toplevel):
    """Ventana modal con campos de formulario genérica."""

    def __init__(self, parent, title, fields: list, on_save, initial: dict = None):
        """
        fields: lista de dicts con keys: name, label, type (entry|combo|date), values (para combo)
        on_save: función(data_dict) llamada al confirmar
        initial: dict con valores iniciales para edición
        """
        super().__init__(parent)
        self.title(title)
        self.configure(bg=COLORS["bg_dark"])
        self.resizable(False, False)
        self.grab_set()
        self.on_save = on_save
        self.fields  = fields
        self.widgets = {}
        self._build(title, fields, initial or {})

    def _build(self, title, fields, initial):
        # Header
        h = tk.Frame(self, bg=COLORS["bg_medium"], pady=12)
        h.pack(fill="x")
        tk.Label(h, text=title, font=FONT_HEADER,
                 bg=COLORS["bg_medium"], fg=COLORS["accent"]).pack(padx=20)

        # Fields
        body = tk.Frame(self, bg=COLORS["bg_dark"], padx=30, pady=20)
        body.pack(fill="both", expand=True)

        for f in fields:
            tk.Label(body, text=f["label"], font=FONT_SMALL,
                     bg=COLORS["bg_dark"], fg=COLORS["text_sub"]).pack(anchor="w", pady=(8, 2))

            var = tk.StringVar(value=str(initial.get(f["name"], "")))

            if f.get("type") == "combo":
                w = ttk.Combobox(body, textvariable=var,
                                 values=f.get("values", []),
                                 state="readonly", font=FONT_BODY)
            else:
                w = tk.Entry(body, textvariable=var, font=FONT_BODY,
                             bg=COLORS["bg_light"], fg=COLORS["text_main"],
                             insertbackground=COLORS["accent"],
                             relief="flat", bd=0)
                w.pack(fill="x", ipady=7)

            if f.get("type") != "combo":
                pass  # already packed above
            else:
                w.pack(fill="x", ipady=4)

            self.widgets[f["name"]] = var

        # Buttons
        btn_row = tk.Frame(self, bg=COLORS["bg_dark"], padx=30, pady=16)
        btn_row.pack(fill="x")
        tk.Button(btn_row, text="Guardar", font=FONT_BTN,
                  bg=COLORS["success"], fg=COLORS["white"], relief="flat",
                  cursor="hand2", padx=20, pady=8,
                  command=self._save).pack(side="left", padx=(0, 10))
        tk.Button(btn_row, text="Cancelar", font=FONT_BTN,
                  bg=COLORS["bg_light"], fg=COLORS["text_main"], relief="flat",
                  cursor="hand2", padx=20, pady=8,
                  command=self.destroy).pack(side="left")

        self.update_idletasks()
        w_px = max(420, self.winfo_reqwidth())
        h_px = max(300, self.winfo_reqheight())
        sw = self.winfo_screenwidth()
        sh = self.winfo_screenheight()
        self.geometry(f"{w_px}x{h_px}+{(sw-w_px)//2}+{(sh-h_px)//2}")

    def _save(self):
        data = {name: var.get().strip() for name, var in self.widgets.items()}
        self.on_save(data)
        self.destroy()


# ══════════════════════════════════════════════════════════════
# TAB: DASHBOARD
# ══════════════════════════════════════════════════════════════
class DashboardTab(tk.Frame):
    def __init__(self, parent):
        super().__init__(parent, bg=COLORS["bg_dark"])
        self.pack(fill="both", expand=True)
        self._build()
        self.refresh()

    def _build(self):
        h = tk.Frame(self, bg=COLORS["bg_medium"], pady=14)
        h.pack(fill="x")
        tk.Label(h, text="📊  Dashboard — Resumen del Sistema",
                 font=FONT_HEADER, bg=COLORS["bg_medium"],
                 fg=COLORS["text_main"]).pack(padx=20, side="left")
        tk.Button(h, text="↻ Actualizar", font=FONT_BTN,
                  bg=COLORS["bg_light"], fg=COLORS["text_main"], relief="flat",
                  cursor="hand2", padx=12, pady=4,
                  command=self.refresh).pack(side="right", padx=16, pady=8)

        # Cards row
        self.cards_frame = tk.Frame(self, bg=COLORS["bg_dark"])
        self.cards_frame.pack(fill="x", padx=20, pady=20)
        self.card_widgets = {}
        cards = [
            ("pacientes",  "🧑‍⚕️", "Pacientes",       COLORS["accent"]),
            ("medicos",    "👨‍⚕️", "Médicos",          COLORS["accent2"]),
            ("citas_hoy",  "📅",   "Citas Hoy",        COLORS["warning"]),
            ("pendientes", "🧾",   "Facturas Pend.",   COLORS["danger"]),
            ("ingresos",   "💰",   "Cobrado Hoy (₡)",  COLORS["success"]),
        ]
        for key, icon, label, color in cards:
            card = self._make_card(self.cards_frame, icon, label, color)
            self.card_widgets[key] = card

        # Recent appointments
        sep = tk.Frame(self, bg=COLORS["bg_medium"], height=1)
        sep.pack(fill="x", padx=20, pady=(0, 16))
        tk.Label(self, text="Citas de Hoy", font=FONT_HEADER,
                 bg=COLORS["bg_dark"], fg=COLORS["text_main"]).pack(padx=20, anchor="w")

        self.today_tree = ttk.Treeview(self, style="Custom.Treeview",
                                       show="headings", height=8)
        cols = [("hora","Hora",80), ("paciente","Paciente",200),
                ("medico","Médico",180), ("especialidad","Especialidad",150),
                ("estado","Estado",100)]
        self.today_tree["columns"] = [c[0] for c in cols]
        for cid, label, w in cols:
            self.today_tree.heading(cid, text=label, anchor="w")
            self.today_tree.column(cid, width=w, anchor="w")
        self.today_tree.pack(fill="x", padx=20, pady=(8, 0))

    def _make_card(self, parent, icon, label, color):
        card = tk.Frame(parent, bg=COLORS["bg_medium"],
                        padx=20, pady=16, relief="flat", bd=0)
        card.pack(side="left", padx=8, fill="x", expand=True)
        tk.Label(card, text=icon, font=("Segoe UI", 28),
                 bg=COLORS["bg_medium"], fg=color).pack()
        val = tk.Label(card, text="—", font=("Segoe UI", 26, "bold"),
                       bg=COLORS["bg_medium"], fg=color)
        val.pack()
        tk.Label(card, text=label, font=FONT_SMALL,
                 bg=COLORS["bg_medium"], fg=COLORS["text_sub"]).pack()
        return val

    def refresh(self):
        queries = {
            "pacientes":  "SELECT COUNT(*) FROM PACIENTE",
            "medicos":    "SELECT COUNT(*) FROM MEDICO",
            "citas_hoy":  "SELECT COUNT(*) FROM CITA WHERE TRUNC(FECHA)=TRUNC(SYSDATE)",
            "pendientes": "SELECT COUNT(*) FROM FACTURA WHERE ESTADO_PAGO IN ('PENDIENTE','PARCIAL')",
            "ingresos":   "SELECT NVL(SUM(MONTO_PAGADO),0) FROM PAGO WHERE TRUNC(FECHA_PAGO)=TRUNC(SYSDATE) AND ESTADO='APROBADO'",
        }
        for key, sql in queries.items():
            try:
                rows, _ = db.execute_query(sql)
                val = rows[0][0]
                if key == "ingresos":
                    val = f"{val:,.0f}"
                self.card_widgets[key].config(text=str(val))
            except Exception:
                self.card_widgets[key].config(text="—")

        # Today's appointments
        for item in self.today_tree.get_children():
            self.today_tree.delete(item)
        try:
            rows, _ = db.execute_query(
                "SELECT C.HORA, P.NOMBRE||' '||P.APELLIDOS,"
                " M.NOMBRE||' '||M.APELLIDOS, M.ESPECIALIDAD, C.ESTADO"
                " FROM CITA C JOIN PACIENTE P ON C.ID_PACIENTE=P.ID_PACIENTE"
                " JOIN MEDICO M ON C.ID_MEDICO=M.ID_MEDICO"
                " WHERE TRUNC(C.FECHA)=TRUNC(SYSDATE) ORDER BY C.HORA"
            )
            for row in rows:
                self.today_tree.insert("", "end", values=row)
        except Exception:
            pass


# ══════════════════════════════════════════════════════════════
# TAB: PACIENTES
# ══════════════════════════════════════════════════════════════
class PacientesTab(BaseCRUDTab):
    TABLE_TITLE  = "Gestión de Pacientes"
    TABLE_ICON   = "🧑‍⚕️"
    SEARCH_LABEL = "Buscar paciente:"

    def col_defs(self):
        return [
            ("id",       "ID",            50),
            ("cedula",   "Cédula",       110),
            ("nombre",   "Nombre",       200),
            ("edad",     "Edad",          55),
            ("telefono", "Teléfono",     110),
            ("correo",   "Correo",       190),
            ("asegurad", "Aseguradora",  160),
            ("estado",   "Póliza",        80),
        ]

    def load_data(self, search=""):
        sql = (
            "SELECT P.ID_PACIENTE, P.CEDULA, P.NOMBRE||' '||P.APELLIDOS,"
            " TRUNC(MONTHS_BETWEEN(SYSDATE,P.FECHA_NACIMIENTO)/12),"
            " P.TELEFONO, P.CORREO,"
            " NVL(S.NOMBRE_ASEGURADORA,'Sin seguro'),"
            " CASE WHEN S.FECHA_VENCIMIENTO>=SYSDATE THEN 'VIGENTE' ELSE 'VENCIDA' END"
            " FROM PACIENTE P LEFT JOIN SEGURO_MEDICO S ON P.ID_SEGURO=S.ID_SEGURO"
        )
        if search:
            sql += (
                " WHERE UPPER(P.CEDULA) LIKE :s"
                "    OR UPPER(P.NOMBRE||' '||P.APELLIDOS) LIKE :s"
                "    OR UPPER(P.CORREO) LIKE :s"
            )
            params = {"s": f"%{search.upper()}%"}
        else:
            params = {}
        sql += " ORDER BY P.APELLIDOS, P.NOMBRE"
        try:
            rows, _ = db.execute_query(sql, params)
            self._populate_tree(rows)
        except Exception as e:
            self._db_error(e)

    def open_form(self, record_id=None):
        # Obtener seguros para combo
        try:
            seg_rows, _ = db.execute_query(
                "SELECT ID_SEGURO, NOMBRE_ASEGURADORA FROM SEGURO_MEDICO ORDER BY NOMBRE_ASEGURADORA")
            seg_opts = [""] + [f"{r[0]} - {r[1]}" for r in seg_rows]
        except Exception:
            seg_opts = [""]

        initial = {}
        if record_id:
            try:
                rows, _ = db.execute_query(
                    "SELECT P.ID_PACIENTE, P.ID_SEGURO, P.CEDULA, P.NOMBRE, P.APELLIDOS,"
                    " TO_CHAR(P.FECHA_NACIMIENTO,'YYYY-MM-DD'), P.TELEFONO, P.CORREO, P.DIRECCION"
                    " FROM PACIENTE P WHERE P.ID_PACIENTE=:id",
                    {"id": record_id})
                if rows:
                    r = rows[0]
                    initial = {
                        "cedula": r[2], "nombre": r[3], "apellidos": r[4],
                        "fecha_nac": r[5], "telefono": r[6],
                        "correo": r[7], "direccion": r[8],
                        "seguro": f"{r[1]} - " if r[1] else ""
                    }
            except Exception as e:
                self._db_error(e); return

        fields = [
            {"name": "seguro",    "label": "Seguro (ID - Nombre)",   "type": "combo", "values": seg_opts},
            {"name": "cedula",    "label": "Cédula *"},
            {"name": "nombre",    "label": "Nombre *"},
            {"name": "apellidos", "label": "Apellidos *"},
            {"name": "fecha_nac", "label": "Fecha Nacimiento (YYYY-MM-DD) *"},
            {"name": "telefono",  "label": "Teléfono *"},
            {"name": "correo",    "label": "Correo electrónico *"},
            {"name": "direccion", "label": "Dirección *"},
        ]

        title = f"{'Editar' if record_id else 'Nuevo'} Paciente"
        FormDialog(self, title, fields,
                   on_save=lambda d: self._save(d, record_id),
                   initial=initial)

    def _save(self, data, record_id):
        try:
            seg_id = None
            if data["seguro"]:
                seg_id = int(data["seguro"].split(" - ")[0])

            if record_id:
                db.execute_dml(
                    "UPDATE PACIENTE SET ID_SEGURO=:seg, NOMBRE=:nom, APELLIDOS=:ape,"
                    " TELEFONO=:tel, CORREO=:cor, DIRECCION=:dir WHERE ID_PACIENTE=:id",
                    {"seg": seg_id, "nom": data["nombre"], "ape": data["apellidos"],
                     "tel": data["telefono"], "cor": data["correo"],
                     "dir": data["direccion"], "id": record_id})
                messagebox.showinfo("Éxito", "Paciente actualizado.")
            else:
                db.execute_dml(
                    "INSERT INTO PACIENTE(ID_SEGURO,CEDULA,NOMBRE,APELLIDOS,"
                    "FECHA_NACIMIENTO,TELEFONO,CORREO,DIRECCION)"
                    " VALUES(:seg,:ced,:nom,:ape,TO_DATE(:fec,'YYYY-MM-DD'),:tel,:cor,:dir)",
                    {"seg": seg_id, "ced": data["cedula"], "nom": data["nombre"],
                     "ape": data["apellidos"], "fec": data["fecha_nac"],
                     "tel": data["telefono"], "cor": data["correo"],
                     "dir": data["direccion"]})
                messagebox.showinfo("Éxito", "Paciente registrado.")
            self.load_data()
        except Exception as e:
            self._db_error(e)

    def do_delete(self, record_id):
        try:
            db.execute_dml(
                "DELETE FROM PACIENTE WHERE ID_PACIENTE=:id", {"id": record_id})
            messagebox.showinfo("Éxito", "Paciente eliminado.")
        except Exception as e:
            self._db_error(e)


# ══════════════════════════════════════════════════════════════
# TAB: MÉDICOS
# ══════════════════════════════════════════════════════════════
class MedicosTab(BaseCRUDTab):
    TABLE_TITLE  = "Gestión de Médicos"
    TABLE_ICON   = "👨‍⚕️"
    SEARCH_LABEL = "Buscar médico:"

    def col_defs(self):
        return [
            ("id",         "ID",            50),
            ("cedula",     "Cédula",       110),
            ("nombre",     "Nombre",       200),
            ("especialidad","Especialidad",160),
            ("codigo",     "Código",        90),
            ("telefono",   "Teléfono",     110),
            ("correo",     "Correo",       190),
        ]

    def load_data(self, search=""):
        sql = (
            "SELECT ID_MEDICO, CEDULA, NOMBRE||' '||APELLIDOS,"
            " ESPECIALIDAD, CODIGO_MEDICO, TELEFONO, CORREO FROM MEDICO"
        )
        if search:
            sql += (" WHERE UPPER(CEDULA) LIKE :s OR UPPER(NOMBRE||' '||APELLIDOS) LIKE :s"
                    " OR UPPER(ESPECIALIDAD) LIKE :s")
            params = {"s": f"%{search.upper()}%"}
        else:
            params = {}
        sql += " ORDER BY ESPECIALIDAD, APELLIDOS"
        try:
            rows, _ = db.execute_query(sql, params)
            self._populate_tree(rows)
        except Exception as e:
            self._db_error(e)

    ESPECIALIDADES = ["Medicina General","Pediatría","Cardiología",
                      "Dermatología","Neurología","Ginecología","Ortopedia","Otro"]

    def open_form(self, record_id=None):
        initial = {}
        if record_id:
            try:
                rows, _ = db.execute_query(
                    "SELECT ID_MEDICO,CEDULA,NOMBRE,APELLIDOS,ESPECIALIDAD,"
                    "CODIGO_MEDICO,TELEFONO,CORREO FROM MEDICO WHERE ID_MEDICO=:id",
                    {"id": record_id})
                if rows:
                    r = rows[0]
                    initial = {"cedula": r[1], "nombre": r[2], "apellidos": r[3],
                               "especialidad": r[4], "codigo": r[5],
                               "telefono": r[6], "correo": r[7]}
            except Exception as e:
                self._db_error(e); return

        fields = [
            {"name": "cedula",       "label": "Cédula *"},
            {"name": "nombre",       "label": "Nombre *"},
            {"name": "apellidos",    "label": "Apellidos *"},
            {"name": "especialidad", "label": "Especialidad *", "type": "combo",
             "values": self.ESPECIALIDADES},
            {"name": "codigo",       "label": "Código Médico *"},
            {"name": "telefono",     "label": "Teléfono *"},
            {"name": "correo",       "label": "Correo *"},
        ]
        FormDialog(self, f"{'Editar' if record_id else 'Nuevo'} Médico",
                   fields, on_save=lambda d: self._save(d, record_id),
                   initial=initial)

    def _save(self, data, record_id):
        try:
            if record_id:
                db.execute_dml(
                    "UPDATE MEDICO SET NOMBRE=:nom,APELLIDOS=:ape,ESPECIALIDAD=:esp,"
                    "TELEFONO=:tel,CORREO=:cor WHERE ID_MEDICO=:id",
                    {"nom": data["nombre"], "ape": data["apellidos"],
                     "esp": data["especialidad"], "tel": data["telefono"],
                     "cor": data["correo"], "id": record_id})
            else:
                db.execute_dml(
                    "INSERT INTO MEDICO(CEDULA,NOMBRE,APELLIDOS,ESPECIALIDAD,"
                    "CODIGO_MEDICO,TELEFONO,CORREO) VALUES(:ced,:nom,:ape,:esp,:cod,:tel,:cor)",
                    {"ced": data["cedula"], "nom": data["nombre"],
                     "ape": data["apellidos"], "esp": data["especialidad"],
                     "cod": data["codigo"], "tel": data["telefono"],
                     "cor": data["correo"]})
            messagebox.showinfo("Éxito", "Médico guardado correctamente.")
            self.load_data()
        except Exception as e:
            self._db_error(e)

    def do_delete(self, record_id):
        try:
            db.execute_dml("DELETE FROM MEDICO WHERE ID_MEDICO=:id", {"id": record_id})
            messagebox.showinfo("Éxito", "Médico eliminado.")
        except Exception as e:
            self._db_error(e)


# ══════════════════════════════════════════════════════════════
# TAB: CITAS
# ══════════════════════════════════════════════════════════════
class CitasTab(BaseCRUDTab):
    TABLE_TITLE  = "Gestión de Citas"
    TABLE_ICON   = "📅"
    SEARCH_LABEL = "Buscar:"

    def col_defs(self):
        return [
            ("id",       "ID",          50),
            ("fecha",    "Fecha",      100),
            ("hora",     "Hora",        70),
            ("paciente", "Paciente",   200),
            ("medico",   "Médico",     180),
            ("motivo",   "Motivo",     220),
            ("estado",   "Estado",      90),
        ]

    def load_data(self, search=""):
        sql = (
            "SELECT C.ID_CITA, TO_CHAR(C.FECHA,'DD/MM/YYYY'), C.HORA,"
            " P.NOMBRE||' '||P.APELLIDOS, M.NOMBRE||' '||M.APELLIDOS,"
            " C.MOTIVO_CONSULTA, C.ESTADO"
            " FROM CITA C JOIN PACIENTE P ON C.ID_PACIENTE=P.ID_PACIENTE"
            " JOIN MEDICO M ON C.ID_MEDICO=M.ID_MEDICO"
        )
        if search:
            sql += (" WHERE UPPER(P.NOMBRE||' '||P.APELLIDOS) LIKE :s"
                    " OR UPPER(M.NOMBRE||' '||M.APELLIDOS) LIKE :s"
                    " OR UPPER(C.ESTADO) LIKE :s")
            params = {"s": f"%{search.upper()}%"}
        else:
            params = {}
        sql += " ORDER BY C.FECHA DESC, C.HORA"
        try:
            rows, _ = db.execute_query(sql, params)
            self._populate_tree(rows)
        except Exception as e:
            self._db_error(e)

    def _get_combos(self):
        pac_rows, _ = db.execute_query(
            "SELECT ID_PACIENTE, NOMBRE||' '||APELLIDOS FROM PACIENTE ORDER BY APELLIDOS")
        med_rows, _ = db.execute_query(
            "SELECT ID_MEDICO, NOMBRE||' '||APELLIDOS||' ('||ESPECIALIDAD||')' FROM MEDICO ORDER BY APELLIDOS")
        return ([""] + [f"{r[0]} - {r[1]}" for r in pac_rows],
                [""] + [f"{r[0]} - {r[1]}" for r in med_rows])

    def open_form(self, record_id=None):
        try:
            pac_opts, med_opts = self._get_combos()
        except Exception as e:
            self._db_error(e); return

        initial = {}
        if record_id:
            try:
                rows, _ = db.execute_query(
                    "SELECT ID_CITA,ID_PACIENTE,ID_MEDICO,"
                    " TO_CHAR(FECHA,'YYYY-MM-DD'),HORA,MOTIVO_CONSULTA,ESTADO"
                    " FROM CITA WHERE ID_CITA=:id", {"id": record_id})
                if rows:
                    r = rows[0]
                    initial = {"paciente": f"{r[1]} -", "medico": f"{r[2]} -",
                               "fecha": r[3], "hora": r[4],
                               "motivo": r[5], "estado": r[6]}
            except Exception as e:
                self._db_error(e); return

        fields = [
            {"name": "paciente", "label": "Paciente *",  "type": "combo", "values": pac_opts},
            {"name": "medico",   "label": "Médico *",    "type": "combo", "values": med_opts},
            {"name": "fecha",    "label": "Fecha (YYYY-MM-DD) *"},
            {"name": "hora",     "label": "Hora (HH:MM) *"},
            {"name": "motivo",   "label": "Motivo de consulta *"},
            {"name": "estado",   "label": "Estado *", "type": "combo",
             "values": ["PROGRAMADA","ATENDIDA","CANCELADA","NO_ASISTIO"]},
        ]
        FormDialog(self, f"{'Editar' if record_id else 'Nueva'} Cita",
                   fields, on_save=lambda d: self._save(d, record_id),
                   initial=initial)

    def _save(self, data, record_id):
        try:
            pac_id = int(data["paciente"].split(" - ")[0]) if data["paciente"] else None
            med_id = int(data["medico"].split(" - ")[0])   if data["medico"] else None
            if not pac_id or not med_id:
                messagebox.showwarning("Validación", "Seleccione paciente y médico.")
                return
            if record_id:
                db.execute_dml(
                    "UPDATE CITA SET ID_PACIENTE=:pac,ID_MEDICO=:med,"
                    " FECHA=TO_DATE(:fec,'YYYY-MM-DD'),HORA=:hor,"
                    " MOTIVO_CONSULTA=:mot,ESTADO=:est WHERE ID_CITA=:id",
                    {"pac": pac_id, "med": med_id, "fec": data["fecha"],
                     "hor": data["hora"], "mot": data["motivo"],
                     "est": data["estado"], "id": record_id})
            else:
                db.execute_dml(
                    "INSERT INTO CITA(ID_PACIENTE,ID_MEDICO,FECHA,HORA,MOTIVO_CONSULTA,ESTADO)"
                    " VALUES(:pac,:med,TO_DATE(:fec,'YYYY-MM-DD'),:hor,:mot,:est)",
                    {"pac": pac_id, "med": med_id, "fec": data["fecha"],
                     "hor": data["hora"], "mot": data["motivo"],
                     "est": data["estado"]})
            messagebox.showinfo("Éxito", "Cita guardada.")
            self.load_data()
        except Exception as e:
            self._db_error(e)

    def do_delete(self, record_id):
        try:
            db.execute_dml("DELETE FROM CITA WHERE ID_CITA=:id", {"id": record_id})
            messagebox.showinfo("Éxito", "Cita eliminada.")
        except Exception as e:
            self._db_error(e)


# ══════════════════════════════════════════════════════════════
# TAB: SERVICIOS
# ══════════════════════════════════════════════════════════════
class ServiciosTab(BaseCRUDTab):
    TABLE_TITLE  = "Catálogo de Servicios"
    TABLE_ICON   = "🧪"
    SEARCH_LABEL = "Buscar servicio:"

    def col_defs(self):
        return [
            ("id",       "ID",        50),
            ("nombre",   "Servicio", 230),
            ("desc",     "Descripción",260),
            ("precio",   "Precio (₡)",110),
            ("categoria","Categoría", 120),
        ]

    def load_data(self, search=""):
        sql = "SELECT ID_SERVICIO, NOMBRE_SERVICIO, DESCRIPCION, PRECIO_BASE, CATEGORIA FROM SERVICIO"
        if search:
            sql += " WHERE UPPER(NOMBRE_SERVICIO) LIKE :s OR UPPER(CATEGORIA) LIKE :s"
            params = {"s": f"%{search.upper()}%"}
        else:
            params = {}
        sql += " ORDER BY CATEGORIA, NOMBRE_SERVICIO"
        try:
            rows, _ = db.execute_query(sql, params)
            self._populate_tree(rows)
        except Exception as e:
            self._db_error(e)

    def open_form(self, record_id=None):
        initial = {}
        if record_id:
            try:
                rows, _ = db.execute_query(
                    "SELECT ID_SERVICIO,NOMBRE_SERVICIO,DESCRIPCION,PRECIO_BASE,CATEGORIA"
                    " FROM SERVICIO WHERE ID_SERVICIO=:id", {"id": record_id})
                if rows:
                    r = rows[0]
                    initial = {"nombre": r[1], "descripcion": r[2],
                               "precio": str(r[3]), "categoria": r[4]}
            except Exception as e:
                self._db_error(e); return

        fields = [
            {"name": "nombre",      "label": "Nombre del Servicio *"},
            {"name": "descripcion", "label": "Descripción *"},
            {"name": "precio",      "label": "Precio Base (₡) *"},
            {"name": "categoria",   "label": "Categoría *", "type": "combo",
             "values": ["CONSULTA","LABORATORIO","PROCEDIMIENTO","IMAGENOLOGIA","OTRO"]},
        ]
        FormDialog(self, f"{'Editar' if record_id else 'Nuevo'} Servicio",
                   fields, on_save=lambda d: self._save(d, record_id),
                   initial=initial)

    def _save(self, data, record_id):
        try:
            precio = float(data["precio"])
            if record_id:
                db.execute_dml(
                    "UPDATE SERVICIO SET NOMBRE_SERVICIO=:nom,DESCRIPCION=:des,"
                    "PRECIO_BASE=:pre,CATEGORIA=:cat WHERE ID_SERVICIO=:id",
                    {"nom": data["nombre"], "des": data["descripcion"],
                     "pre": precio, "cat": data["categoria"], "id": record_id})
            else:
                db.execute_dml(
                    "INSERT INTO SERVICIO(NOMBRE_SERVICIO,DESCRIPCION,PRECIO_BASE,CATEGORIA)"
                    " VALUES(:nom,:des,:pre,:cat)",
                    {"nom": data["nombre"], "des": data["descripcion"],
                     "pre": precio, "cat": data["categoria"]})
            messagebox.showinfo("Éxito", "Servicio guardado.")
            self.load_data()
        except ValueError:
            messagebox.showerror("Error", "El precio debe ser un número.")
        except Exception as e:
            self._db_error(e)

    def do_delete(self, record_id):
        try:
            db.execute_dml("DELETE FROM SERVICIO WHERE ID_SERVICIO=:id", {"id": record_id})
            messagebox.showinfo("Éxito", "Servicio eliminado.")
        except Exception as e:
            self._db_error(e)


# ══════════════════════════════════════════════════════════════
# TAB: FACTURAS
# ══════════════════════════════════════════════════════════════
class FacturasTab(BaseCRUDTab):
    TABLE_TITLE  = "Gestión de Facturas"
    TABLE_ICON   = "🧾"
    SEARCH_LABEL = "Buscar factura:"
    SHOW_DELETE  = False  # Facturas se anulan, no eliminan

    def col_defs(self):
        return [
            ("id",       "ID",          50),
            ("numero",   "Nº Factura",  160),
            ("fecha",    "Emisión",     100),
            ("paciente", "Paciente",    200),
            ("subtotal", "Subtotal",     90),
            ("descuento","Descuento",    90),
            ("iva",      "IVA",          80),
            ("total",    "Total (₡)",   100),
            ("estado",   "Estado",       90),
        ]

    def load_data(self, search=""):
        sql = (
            "SELECT F.ID_FACTURA, F.NUMERO_FACTURA_ELECTRONICA,"
            " TO_CHAR(F.FECHA_EMISION,'DD/MM/YYYY'),"
            " P.NOMBRE||' '||P.APELLIDOS,"
            " F.SUBTOTAL, F.DESCUENTO, F.IVA, F.TOTAL, F.ESTADO_PAGO"
            " FROM FACTURA F"
            " JOIN CITA C ON F.ID_CITA=C.ID_CITA"
            " JOIN PACIENTE P ON C.ID_PACIENTE=P.ID_PACIENTE"
        )
        if search:
            sql += (" WHERE UPPER(F.NUMERO_FACTURA_ELECTRONICA) LIKE :s"
                    " OR UPPER(P.NOMBRE||' '||P.APELLIDOS) LIKE :s"
                    " OR UPPER(F.ESTADO_PAGO) LIKE :s")
            params = {"s": f"%{search.upper()}%"}
        else:
            params = {}
        sql += " ORDER BY F.FECHA_EMISION DESC"
        try:
            rows, _ = db.execute_query(sql, params)
            self._populate_tree(rows)
        except Exception as e:
            self._db_error(e)

    def open_form(self, record_id=None):
        """Para facturas: si es nuevo, genera desde una cita; si editar, permite anular."""
        if record_id:
            # Anular factura
            if messagebox.askyesno("Anular Factura",
                                   f"¿Desea anular la factura ID {record_id}?"):
                try:
                    db.execute_dml(
                        "UPDATE FACTURA SET ESTADO_PAGO='ANULADA' WHERE ID_FACTURA=:id",
                        {"id": record_id})
                    messagebox.showinfo("Éxito", "Factura anulada.")
                    self.load_data()
                except Exception as e:
                    self._db_error(e)
        else:
            # Generar nueva factura desde cita
            self._nueva_factura()

    def _nueva_factura(self):
        try:
            citas, _ = db.execute_query(
                "SELECT C.ID_CITA, TO_CHAR(C.FECHA,'DD/MM/YYYY'),"
                " P.NOMBRE||' '||P.APELLIDOS, M.ESPECIALIDAD"
                " FROM CITA C JOIN PACIENTE P ON C.ID_PACIENTE=P.ID_PACIENTE"
                " JOIN MEDICO M ON C.ID_MEDICO=M.ID_MEDICO"
                " WHERE C.ESTADO='ATENDIDA'"
                " AND NOT EXISTS (SELECT 1 FROM FACTURA F"
                "   WHERE F.ID_CITA=C.ID_CITA AND F.ESTADO_PAGO!='ANULADA')"
                " ORDER BY C.FECHA DESC")
        except Exception as e:
            self._db_error(e); return

        opts = [""] + [f"{r[0]} | {r[1]} | {r[2]} | {r[3]}" for r in citas]
        fields = [
            {"name": "cita",      "label": "Cita (ID | Fecha | Paciente | Esp.) *",
             "type": "combo", "values": opts},
            {"name": "descuento", "label": "Descuento (₡, dejar 0 si no aplica)"},
        ]
        FormDialog(self, "Generar Factura", fields,
                   on_save=self._save_factura)

    def _save_factura(self, data):
        if not data["cita"]:
            messagebox.showwarning("Validación", "Seleccione una cita.")
            return
        cita_id   = int(data["cita"].split(" | ")[0])
        descuento = float(data["descuento"] or 0)
        try:
            # Calcular subtotal de los servicios de esa cita
            rows, _ = db.execute_query(
                "SELECT NVL(SUM(DF.SUBTOTAL_LINEA),0)"
                " FROM DETALLE_FACTURA DF"
                " JOIN FACTURA F ON DF.ID_FACTURA=F.ID_FACTURA"
                " WHERE F.ID_CITA=:id", {"id": cita_id})
            subtotal  = float(rows[0][0]) if rows else 0.0
            iva       = round((subtotal - descuento) * 0.13, 2)
            total     = round((subtotal - descuento) * 1.13, 2)
            num       = f"FE-{date.today().strftime('%Y%m%d')}-{cita_id:06d}"
            db.execute_dml(
                "INSERT INTO FACTURA(ID_CITA,NUMERO_FACTURA_ELECTRONICA,"
                "FECHA_EMISION,SUBTOTAL,DESCUENTO,IVA,TOTAL,ESTADO_PAGO)"
                " VALUES(:cit,:num,SYSDATE,:sub,:des,:iva,:tot,'PENDIENTE')",
                {"cit": cita_id, "num": num, "sub": subtotal,
                 "des": descuento, "iva": iva, "tot": total})
            messagebox.showinfo("Éxito", f"Factura generada: {num}")
            self.load_data()
        except Exception as e:
            self._db_error(e)

    def do_delete(self, record_id):
        pass  # Deshabilitado — se usa anular


# ══════════════════════════════════════════════════════════════
# TAB: PAGOS
# ══════════════════════════════════════════════════════════════
class PagosTab(BaseCRUDTab):
    TABLE_TITLE  = "Registro de Pagos"
    TABLE_ICON   = "💳"
    SEARCH_LABEL = "Buscar pago:"
    SHOW_DELETE  = False

    def col_defs(self):
        return [
            ("id",      "ID",          50),
            ("fecha",   "Fecha/Hora",  140),
            ("factura", "Nº Factura",  160),
            ("paciente","Paciente",    190),
            ("monto",   "Monto (₡)",  110),
            ("metodo",  "Método",      130),
            ("ref",     "Referencia",  150),
            ("estado",  "Estado",       90),
        ]

    def load_data(self, search=""):
        sql = (
            "SELECT PA.ID_PAGO, TO_CHAR(PA.FECHA_PAGO,'DD/MM/YYYY HH24:MI'),"
            " F.NUMERO_FACTURA_ELECTRONICA, P.NOMBRE||' '||P.APELLIDOS,"
            " PA.MONTO_PAGADO, PA.METODO_PAGO, PA.REFERENCIA_TRANSACCION, PA.ESTADO"
            " FROM PAGO PA"
            " JOIN FACTURA F  ON PA.ID_FACTURA=F.ID_FACTURA"
            " JOIN CITA C     ON F.ID_CITA=C.ID_CITA"
            " JOIN PACIENTE P ON C.ID_PACIENTE=P.ID_PACIENTE"
        )
        if search:
            sql += (" WHERE UPPER(F.NUMERO_FACTURA_ELECTRONICA) LIKE :s"
                    " OR UPPER(P.NOMBRE||' '||P.APELLIDOS) LIKE :s"
                    " OR UPPER(PA.METODO_PAGO) LIKE :s")
            params = {"s": f"%{search.upper()}%"}
        else:
            params = {}
        sql += " ORDER BY PA.FECHA_PAGO DESC"
        try:
            rows, _ = db.execute_query(sql, params)
            self._populate_tree(rows)
        except Exception as e:
            self._db_error(e)

    def open_form(self, record_id=None):
        if record_id:
            messagebox.showinfo("Info", "Los pagos no pueden editarse una vez registrados.")
            return
        # Registrar nuevo pago
        try:
            facts, _ = db.execute_query(
                "SELECT F.ID_FACTURA, F.NUMERO_FACTURA_ELECTRONICA, F.TOTAL, F.ESTADO_PAGO"
                " FROM FACTURA F WHERE F.ESTADO_PAGO IN ('PENDIENTE','PARCIAL')"
                " ORDER BY F.FECHA_EMISION DESC")
        except Exception as e:
            self._db_error(e); return

        opts = [""] + [f"{r[0]} | {r[1]} | ₡{r[2]:,.2f} | {r[3]}" for r in facts]
        fields = [
            {"name": "factura",   "label": "Factura (ID | Nº | Total | Estado) *",
             "type": "combo", "values": opts},
            {"name": "monto",     "label": "Monto a Pagar (₡) *"},
            {"name": "metodo",    "label": "Método de Pago *", "type": "combo",
             "values": ["EFECTIVO","TARJETA_CREDITO","TARJETA_DEBITO","TRANSFERENCIA","SEGURO"]},
            {"name": "referencia","label": "Referencia / Comprobante"},
        ]
        FormDialog(self, "Registrar Pago", fields, on_save=self._save_pago)

    def _save_pago(self, data):
        if not data["factura"] or not data["monto"]:
            messagebox.showwarning("Validación", "Complete los campos obligatorios.")
            return
        try:
            fact_id = int(data["factura"].split(" | ")[0])
            monto   = float(data["monto"])

            # Verificar saldo
            rows, _ = db.execute_query(
                "SELECT F.TOTAL, NVL(SUM(PA.MONTO_PAGADO),0)"
                " FROM FACTURA F LEFT JOIN PAGO PA ON F.ID_FACTURA=PA.ID_FACTURA"
                "   AND PA.ESTADO='APROBADO'"
                " WHERE F.ID_FACTURA=:id GROUP BY F.TOTAL", {"id": fact_id})
            if not rows:
                messagebox.showerror("Error", "Factura no encontrada.")
                return
            total, cobrado = float(rows[0][0]), float(rows[0][1])
            nuevo_cobrado  = cobrado + monto

            db.execute_dml(
                "INSERT INTO PAGO(ID_FACTURA,FECHA_PAGO,MONTO_PAGADO,"
                "METODO_PAGO,REFERENCIA_TRANSACCION,ESTADO)"
                " VALUES(:fid,SYSDATE,:mon,:met,:ref,'APROBADO')",
                {"fid": fact_id, "mon": monto, "met": data["metodo"],
                 "ref": data["referencia"] or None})

            nuevo_estado = "PAGADA" if nuevo_cobrado >= total else "PARCIAL"
            db.execute_dml(
                "UPDATE FACTURA SET ESTADO_PAGO=:est WHERE ID_FACTURA=:id",
                {"est": nuevo_estado, "id": fact_id})

            messagebox.showinfo("Éxito",
                f"Pago registrado. Estado factura: {nuevo_estado}")
            self.load_data()
        except ValueError:
            messagebox.showerror("Error", "El monto debe ser un número.")
        except Exception as e:
            self._db_error(e)

    def do_delete(self, record_id):
        pass


# ══════════════════════════════════════════════════════════════
# TAB: SEGUROS
# ══════════════════════════════════════════════════════════════
class SegurosTab(BaseCRUDTab):
    TABLE_TITLE  = "Seguros Médicos"
    TABLE_ICON   = "🛡"
    SEARCH_LABEL = "Buscar seguro:"

    def col_defs(self):
        return [
            ("id",        "ID",            50),
            ("aseguradora","Aseguradora",  200),
            ("poliza",    "Nº Póliza",     140),
            ("cobertura", "Cobertura %",    90),
            ("vencimiento","Vencimiento",  110),
            ("estado",    "Estado",         90),
        ]

    def load_data(self, search=""):
        sql = (
            "SELECT ID_SEGURO, NOMBRE_ASEGURADORA, NUMERO_POLIZA,"
            " COBERTURA_PORCENTAJE, TO_CHAR(FECHA_VENCIMIENTO,'DD/MM/YYYY'),"
            " CASE WHEN FECHA_VENCIMIENTO>=SYSDATE THEN 'VIGENTE' ELSE 'VENCIDA' END"
            " FROM SEGURO_MEDICO"
        )
        if search:
            sql += " WHERE UPPER(NOMBRE_ASEGURADORA) LIKE :s OR UPPER(NUMERO_POLIZA) LIKE :s"
            params = {"s": f"%{search.upper()}%"}
        else:
            params = {}
        sql += " ORDER BY NOMBRE_ASEGURADORA"
        try:
            rows, _ = db.execute_query(sql, params)
            self._populate_tree(rows)
        except Exception as e:
            self._db_error(e)

    def open_form(self, record_id=None):
        initial = {}
        if record_id:
            try:
                rows, _ = db.execute_query(
                    "SELECT ID_SEGURO, NOMBRE_ASEGURADORA, NUMERO_POLIZA,"
                    " COBERTURA_PORCENTAJE, TO_CHAR(FECHA_VENCIMIENTO,'YYYY-MM-DD')"
                    " FROM SEGURO_MEDICO WHERE ID_SEGURO=:id", {"id": record_id})
                if rows:
                    r = rows[0]
                    initial = {"aseguradora": r[1], "poliza": r[2],
                               "cobertura": str(r[3]), "vencimiento": r[4]}
            except Exception as e:
                self._db_error(e); return

        fields = [
            {"name": "aseguradora", "label": "Nombre Aseguradora *"},
            {"name": "poliza",      "label": "Número de Póliza *"},
            {"name": "cobertura",   "label": "Cobertura % (0-100) *"},
            {"name": "vencimiento", "label": "Fecha Vencimiento (YYYY-MM-DD) *"},
        ]
        FormDialog(self, f"{'Editar' if record_id else 'Nuevo'} Seguro",
                   fields, on_save=lambda d: self._save(d, record_id),
                   initial=initial)

    def _save(self, data, record_id):
        try:
            cob = float(data["cobertura"])
            if not (0 <= cob <= 100):
                messagebox.showerror("Error", "Cobertura debe estar entre 0 y 100.")
                return
            if record_id:
                db.execute_dml(
                    "UPDATE SEGURO_MEDICO SET NOMBRE_ASEGURADORA=:ase,"
                    " COBERTURA_PORCENTAJE=:cob,"
                    " FECHA_VENCIMIENTO=TO_DATE(:fec,'YYYY-MM-DD')"
                    " WHERE ID_SEGURO=:id",
                    {"ase": data["aseguradora"], "cob": cob,
                     "fec": data["vencimiento"], "id": record_id})
            else:
                db.execute_dml(
                    "INSERT INTO SEGURO_MEDICO(NOMBRE_ASEGURADORA,NUMERO_POLIZA,"
                    "COBERTURA_PORCENTAJE,FECHA_VENCIMIENTO)"
                    " VALUES(:ase,:pol,:cob,TO_DATE(:fec,'YYYY-MM-DD'))",
                    {"ase": data["aseguradora"], "pol": data["poliza"],
                     "cob": cob, "fec": data["vencimiento"]})
            messagebox.showinfo("Éxito", "Seguro guardado correctamente.")
            self.load_data()
        except ValueError:
            messagebox.showerror("Error", "Cobertura debe ser un número válido.")
        except Exception as e:
            self._db_error(e)

    def do_delete(self, record_id):
        try:
            db.execute_dml(
                "DELETE FROM SEGURO_MEDICO WHERE ID_SEGURO=:id", {"id": record_id})
            messagebox.showinfo("Éxito", "Seguro eliminado.")
        except Exception as e:
            self._db_error(e)


# ══════════════════════════════════════════════════════════════
# PUNTO DE ENTRADA
# ══════════════════════════════════════════════════════════════
if __name__ == "__main__":
    app = LoginWindow()
    app.mainloop()