#!/usr/bin/env python3
"""Carga el catálogo real de Makip Te Crea y el pipeline comercial en Odoo Community (XML-RPC).

Uso (con un túnel IAP abierto a la VM en localhost:8069):
    python3 scripts/cargar_odoo.py --url http://localhost:8069 --db makip \
        --admin-password "$ADMIN_PW" --api-password "$API_PW"

Es idempotente: si un registro ya existe (por código o nombre) lo actualiza.
"""
import argparse
import base64
import csv
import json
import pathlib
import xmlrpc.client

RAIZ = pathlib.Path(__file__).resolve().parent.parent
SEED = RAIZ / "app" / "seed"

EQUIPO = [
    ("Thiago Paolo Icochea Rodriguez", "thiago.icochea"),
    ("Carlos Enrique Giussepe Gonzales Aguilar", "carlos.gonzales"),
    ("Eddyson Cesar Huamani Pereira", "eddyson.huamani"),
    ("Huber Eduardo Remuzgo Tovar", "eduardo.remuzgo"),
    ("Karen Meylin Quispe Saavedra", "karen.quispe"),
]

# Clientes y oportunidades de prueba (datos ficticios) para demostrar el flujo comercial.
CLIENTES = [
    ("Colegio Santa Rosa de Lima", "colegio.santarosa@ejemplo.pe", "+51 900 000 101"),
    ("María Fernanda Ríos", "mariafernanda@ejemplo.pe", "+51 900 000 102"),
    ("Emprendimiento Lazos Mágicos", "lazosmagicos@ejemplo.pe", "+51 900 000 103"),
    ("Institución Educativa San Martín", "ie.sanmartin@ejemplo.pe", "+51 900 000 104"),
    ("Lucía Paredes", "lucia.paredes@ejemplo.pe", "+51 900 000 105"),
    ("Bazar Escolar Arcoíris", "bazar.arcoiris@ejemplo.pe", "+51 900 000 106"),
]
OPORTUNIDADES = [
    # (título, cliente, etapa, monto, vendedor, origen, productos)
    ("Insignias 5 cm para 3.er grado", 0, "Nueva consulta", 270.0, 0, "TikTok", "ML-INS"),
    ("Nombres para lazos x 3 docenas", 1, "Cotizado", 54.0, 1, "WhatsApp", "ML-NOM"),
    ("Apliques sublimados x ciento", 2, "Confirmado - pendiente de adelanto", 135.0, 2, "TikTok", "ML-ASU"),
    ("Reglas personalizadas 30 cm x 2 docenas", 3, "Adelanto recibido", 264.0, 3, "Facebook", "ML-REG"),
    ("Etiquetas textil para uniforme", 4, "Diseño", 45.0, 4, "WhatsApp", "OT-ETQ"),
    ("Llaveros acrílicos con logo", 5, "Diseño en revisión del cliente", 110.0, 0, "Instagram", "OT-LLA"),
    ("Portalápices + lápiz para aula", 0, "Aprobado para producción", 170.0, 1, "WhatsApp", "OT-PLA"),
    ("Pack cofre + miniportalazos", 2, "Producción", 150.0, 2, "TikTok", "ML-CMP"),
    ("Exhibidores de lazos", 5, "Pendiente de saldo", 108.0, 3, "WhatsApp", "OT-EXL"),
    ("Colores grabados x 6 cajas", 4, "Entregado", 69.0, 4, "TikTok", "OT-COL"),
]


class Odoo:
    def __init__(self, url, db, user, password):
        self.db, self.password = db, password
        common = xmlrpc.client.ServerProxy(f"{url}/xmlrpc/2/common", allow_none=True)
        self.uid = common.authenticate(db, user, password, {})
        if not self.uid:
            raise SystemExit(f"No se pudo iniciar sesión en Odoo como {user}")
        self.m = xmlrpc.client.ServerProxy(f"{url}/xmlrpc/2/object", allow_none=True)

    def __call__(self, model, method, *args, **kw):
        return self.m.execute_kw(self.db, self.uid, self.password, model, method, list(args), kw)

    def search(self, model, domain, **kw):
        return self(model, "search", domain, **kw)

    def upsert(self, model, domain, vals):
        ids = self.search(model, domain, limit=1, context={"active_test": False})
        if ids:
            self(model, "write", ids, vals)
            return ids[0]
        return self(model, "create", vals)

    def ref(self, xmlid):
        mod, name = xmlid.split(".")
        r = self("ir.model.data", "search_read", [["module", "=", mod], ["name", "=", name]], fields=["res_id"], limit=1)
        return r[0]["res_id"] if r else False


def b64(path):
    return base64.b64encode(path.read_bytes()).decode()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default="http://localhost:8069")
    ap.add_argument("--db", default="makip")
    ap.add_argument("--admin-password", default="admin")
    ap.add_argument("--nuevo-admin-password", default="", help="Si se indica, cambia la contraseña de admin al final")
    ap.add_argument("--api-password", required=True, help="Contraseña del usuario técnico api_catalogo")
    a = ap.parse_args()

    o = Odoo(a.url, a.db, "admin", a.admin_password)
    print(f"Conectado a Odoo ({a.db}) como admin, uid={o.uid}")

    # ---------- Empresa ----------
    pen = o.ref("base.PEN")
    if pen:
        o("res.currency", "write", [pen], {"active": True})
    pe = o.ref("base.pe")
    company_vals = {"name": "Makip Te Crea", "city": "Lima", "phone": "+51 923 119 167",
                    "website": "https://makiptecrea.pe", "logo": b64(RAIZ / "web" / "assets" / "logo-makip.jpg")}
    if pe:
        company_vals["country_id"] = pe
    o("res.company", "write", [1], company_vals)
    try:
        if pen:
            o("res.company", "write", [1], {"currency_id": pen})
    except xmlrpc.client.Fault as e:
        print("Aviso: no se pudo cambiar la moneda a PEN:", e.faultString.splitlines()[-1])
    print("Empresa: Makip Te Crea (Lima, PEN)")

    # ---------- Equipo comercial (usuarios internos sin acceso por contraseña) ----------
    vendedores = []
    for nombre, login in EQUIPO:
        vendedores.append(o.upsert("res.users", [["login", "=", login]], {"name": nombre, "login": login}))
    o("res.users", "write", [o.uid], {"name": "Administrador Makip"})
    team = o.upsert("crm.team", [["name", "=", "Ventas Makip Te Crea"]],
                    {"name": "Ventas Makip Te Crea", "user_id": vendedores[0], "member_ids": [(6, 0, vendedores)]})
    print(f"Equipo de ventas con {len(vendedores)} integrantes")

    # Usuario técnico de solo lectura para la API de catálogo (Cloud Run)
    api_uid = o.upsert("res.users", [["login", "=", "api_catalogo"]],
                       {"name": "API Catálogo (Cloud Run)", "login": "api_catalogo"})
    o("res.users", "write", [api_uid], {"password": a.api_password})
    print("Usuario técnico api_catalogo listo")

    # ---------- Catálogo ----------
    raiz_cat = o.upsert("product.category", [["name", "=", "Makip Te Crea"], ["parent_id", "=", False]], {"name": "Makip Te Crea"})
    productos = json.loads((SEED / "catalogo" / "productos.json").read_text(encoding="utf-8"))
    cats = {}
    for c in sorted({p["categoria"] for p in productos}):
        cats[c] = o.upsert("product.category", [["name", "=", c], ["parent_id", "=", raiz_cat]], {"name": c, "parent_id": raiz_cat})
    # Ocultar los productos ficticios de pruebas si existieran
    demo = o.search("product.template", [["default_code", "like", "DEMO-"]])
    if demo:
        o("product.template", "write", demo, {"sale_ok": False, "active": False})
    for p in productos:
        img = SEED / "catalogo" / "img" / f"{p['imagenes'][0]}.jpg"
        vals = {"name": p["nombre"], "default_code": p["codigo"], "categ_id": cats[p["categoria"]],
                "list_price": p["precio"] or 0.0, "description_sale": p["descripcion"], "sale_ok": True,
                "purchase_ok": False, "image_1920": b64(img)}
        o.upsert("product.template", [["default_code", "=", p["codigo"]]], vals)
    print(f"Productos cargados: {len(productos)} en {len(cats)} categorías")

    # ---------- Pipeline CRM ----------
    etapas = {}
    with open(SEED / "etapas_pipeline.csv", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            vals = {"name": row["name"], "sequence": int(row["sequence"]), "is_won": row["name"] == "Entregado"}
            etapas[row["name"]] = o.upsert("crm.stage", [["name", "=", row["name"]]], vals)
    otras = o.search("crm.stage", [["id", "not in", list(etapas.values())]])
    leads_otras = o.search("crm.lead", [["stage_id", "in", otras]]) if otras else []
    if otras and not leads_otras:
        o("crm.stage", "unlink", otras)
    print(f"Etapas del pipeline: {len(etapas)}")

    # ---------- Clientes y oportunidades de prueba ----------
    clientes = [o.upsert("res.partner", [["name", "=", n]], {"name": n, "email": e, "phone": t, "city": "Lima",
                                                                "is_company": n.startswith(("Colegio", "Institución", "Emprendimiento", "Bazar"))})
                for n, e, t in CLIENTES]
    tags = {}
    for _, _, _, _, _, origen, _ in OPORTUNIDADES:
        tags[origen] = o.upsert("crm.tag", [["name", "=", origen]], {"name": origen})
    prod_ids = {p["codigo"]: o.search("product.template", [["default_code", "=", p["codigo"]]])[0] for p in productos}
    for titulo, ci, etapa, monto, vi, origen, cod in OPORTUNIDADES:
        o.upsert("crm.lead", [["name", "=", titulo]], {
            "name": titulo, "type": "opportunity", "partner_id": clientes[ci], "expected_revenue": monto,
            "stage_id": etapas[etapa], "user_id": vendedores[vi], "team_id": team, "tag_ids": [(6, 0, [tags[origen]])],
            "description": f"Producto de interés: {cod}. Origen del contacto: {origen}. Flujo: adelanto 50 % y saldo antes de la entrega."})
    print(f"Oportunidades: {len(OPORTUNIDADES)} (datos de prueba)")

    # ---------- Cotizaciones ----------
    def variante(cod):
        return o("product.template", "read", [prod_ids[cod]], fields=["product_variant_id"])[0]["product_variant_id"][0]

    cot = [
        ("Colegio Santa Rosa de Lima", 0, [("ML-INS", 12), ("ML-MPL", 24)], True),
        ("María Fernanda Ríos", 1, [("ML-NOM", 36), ("ML-VIN", 12)], False),
        ("Institución Educativa San Martín", 3, [("ML-REG", 24), ("OT-POR", 12)], True),
    ]
    for cliente, ci, lineas, confirmar in cot:
        ref = f"Cotización de prueba – {cliente}"
        existe = o.search("sale.order", [["client_order_ref", "=", ref]])
        if existe:
            continue
        so = o("sale.order", "create", {"partner_id": clientes[ci], "client_order_ref": ref, "user_id": vendedores[ci % len(vendedores)],
                                        "team_id": team, "note": "Adelanto del 50 % para iniciar el diseño; saldo antes de la entrega.",
                                        "order_line": [(0, 0, {"product_id": variante(c), "product_uom_qty": q}) for c, q in lineas]})
        if confirmar:
            o("sale.order", "action_confirm", [so])
    print("Cotizaciones de prueba creadas")

    if a.nuevo_admin_password:
        o("res.users", "write", [o.uid], {"password": a.nuevo_admin_password})
        print("Contraseña de admin actualizada")
    print("Carga completa.")


if __name__ == "__main__":
    main()
