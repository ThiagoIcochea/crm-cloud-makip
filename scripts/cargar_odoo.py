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

    # ---------- Idioma español (Perú) ----------
    lang = o("res.lang", "search_read", [["code", "=", "es_PE"]], fields=["id", "active"], context={"active_test": False})
    if lang and not lang[0]["active"]:
        wiz = o("base.language.install", "create", {"lang_ids": [(6, 0, [lang[0]["id"]])], "overwrite": False})
        o("base.language.install", "lang_install", [wiz])
        print("Idioma español (Perú) instalado")

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
    if pen:  # las cotizaciones toman la moneda de la tarifa
        tarifas = o.search("product.pricelist", [], context={"active_test": False})
        if tarifas:
            o("product.pricelist", "write", tarifas, {"currency_id": pen, "name": "Tarifa Makip (S/)"})
            otras = o.search("sale.order", [["currency_id", "!=", pen]])
            # cotizaciones creadas antes del cambio de moneda: una orden confirmada
            # no admite otra tarifa, así que vuelve a borrador y se reconfirma con su fecha
            for so in o("sale.order", "read", otras, ["state", "date_order"]):
                confirmada = so["state"] == "sale"
                if confirmada:
                    o("sale.order", "action_cancel", [so["id"]], context={"disable_cancel_warning": True})
                    o("sale.order", "action_draft", [so["id"]])
                o("sale.order", "write", [so["id"]], {"pricelist_id": tarifas[0]})
                o("sale.order", "action_update_prices", [so["id"]])
                if confirmada:
                    o("sale.order", "action_confirm", [so["id"]])
                o("sale.order", "write", [so["id"]], {"date_order": so["date_order"]})
            if otras:
                print(f"{len(otras)} cotizaciones pasadas a soles")
    print("Empresa: Makip Te Crea (Lima, PEN)")

    # ---------- Equipo comercial (usuarios internos sin acceso por contraseña) ----------
    vendedores = []
    for nombre, login in EQUIPO:
        vendedores.append(o.upsert("res.users", [["login", "=", login]], {"name": nombre, "login": login}))
    o("res.users", "write", [o.uid], {"name": "Administrador Makip"})
    if lang:
        todos = o.search("res.users", [["share", "=", False]])
        o("res.users", "write", todos, {"lang": "es_PE", "tz": "America/Lima"})
    team = o.upsert("crm.team", [["name", "=", "Ventas Makip Te Crea"]],
                    {"name": "Ventas Makip Te Crea", "user_id": vendedores[0], "member_ids": [(6, 0, vendedores)]})
    print(f"Equipo de ventas con {len(vendedores)} integrantes")

    # Usuario técnico de solo lectura para la API de catálogo (Cloud Run)
    api_uid = o.upsert("res.users", [["login", "=", "api_catalogo"]],
                       {"name": "API Catálogo (Cloud Run)", "login": "api_catalogo"})
    o("res.users", "write", [api_uid], {"password": a.api_password})
    # Puede leer el catálogo y registrar consultas de la landing como oportunidades (rol Ventas: usuario).
    grupo = o.ref("sales_team.group_sale_salesman")
    campo = "group_ids" if "group_ids" in o("res.users", "fields_get", [], attributes=["type"]) else "groups_id"
    if grupo:
        o("res.users", "write", [api_uid], {campo: [(4, grupo)]})
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
                "purchase_ok": False}
        if not o.search("product.template", [["default_code", "=", p["codigo"]]]):
            vals["image_1920"] = b64(img)  # la foto se sube solo al crear (el túnel IAP es lento)
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

    # ---------- Historial de pedidos (datos de prueba) para la segmentación ----------
    historial = [  # (cliente, días atrás, [(código, cantidad)])
        (0, 150, [("ML-INS", 24)]), (0, 75, [("OT-ETQ", 10)]),
        (5, 120, [("OT-SUJ", 20), ("OT-STX", 10)]), (5, 40, [("OT-LLA", 24)]),
        (4, 210, [("OT-COL", 3)]),
        (2, 20, [("ML-NOM", 48)]),
    ]
    import datetime
    for ci, dias, lineas in historial:
        ref = f"Pedido histórico {ci}-{dias}"
        if o.search("sale.order", [["client_order_ref", "=", ref]]):
            continue
        fecha = (datetime.datetime.now() - datetime.timedelta(days=dias)).strftime("%Y-%m-%d %H:%M:%S")
        so = o("sale.order", "create", {"partner_id": clientes[ci], "client_order_ref": ref, "date_order": fecha,
                                        "user_id": vendedores[ci % len(vendedores)], "team_id": team,
                                        "order_line": [(0, 0, {"product_id": variante(c), "product_uom_qty": q}) for c, q in lineas]})
        o("sale.order", "action_confirm", [so])
        o("sale.order", "write", [so], {"date_order": fecha})
    print("Historial de pedidos de prueba listo")

    # ---------- Fidelización: segmentación de clientes ----------
    segmentos = {
        "Cliente frecuente": "Ofrecer 10 % de descuento por docena en su próximo pedido.",
        "Institución / colegio": "Proponer campaña escolar: insignias, etiquetas y reglas por aula con precio por volumen.",
        "Potencial para fidelizar": "Regalar el diseño personalizado en su siguiente pedido para convertirlo en recurrente.",
        "Por reactivar": "Enviar recordatorio de fechas especiales (inicio de clases, Día de la Madre) con delivery gratis en Lima.",
    }
    cat_ids = {n: o.upsert("res.partner.category", [["name", "=", n]], {"name": n}) for n in segmentos}
    hoy = datetime.datetime.now()
    todo_tipo = o.ref("mail.mail_activity_data_todo")
    modelo_partner = o("ir.model", "search", [["model", "=", "res.partner"]])[0]
    resumen = []
    for pid in clientes:
        pedidos = o("sale.order", "search_read", [["partner_id", "=", pid], ["state", "=", "sale"]],
                    fields=["amount_total", "date_order", "user_id"], order="date_order desc")
        abiertas = o("crm.lead", "search_count", [["partner_id", "=", pid], ["stage_id.is_won", "=", False], ["active", "=", True]])
        p = o("res.partner", "read", [pid], fields=["name", "is_company"])[0]
        monto = sum(x["amount_total"] for x in pedidos)
        ultimo = datetime.datetime.strptime(pedidos[0]["date_order"], "%Y-%m-%d %H:%M:%S") if pedidos else None
        segs = []
        if len(pedidos) >= 2: segs.append("Cliente frecuente")
        if p["is_company"] and any(w in p["name"] for w in ("Colegio", "Institución")): segs.append("Institución / colegio")
        if ultimo and (hoy - ultimo).days > 90: segs.append("Por reactivar")
        if not segs and (abiertas or monto >= 150): segs.append("Potencial para fidelizar")
        o("res.partner", "write", [pid], {"category_id": [(6, 0, [cat_ids[x] for x in segs])],
                                          "comment": "<p>Fidelización: " + " ".join(segmentos[x] for x in segs) + "</p>" if segs else False})
        resp = (pedidos[0]["user_id"][0] if pedidos and pedidos[0]["user_id"] else vendedores[0])
        for sname in segs:
            resumen_act = f"Fidelización · {sname}"
            if todo_tipo and not o("mail.activity", "search", [["res_model_id", "=", modelo_partner], ["res_id", "=", pid], ["summary", "=", resumen_act]]):
                o("mail.activity", "create", {"res_model_id": modelo_partner, "res_id": pid, "activity_type_id": todo_tipo,
                                              "summary": resumen_act, "note": segmentos[sname], "user_id": resp,
                                              "date_deadline": (hoy + datetime.timedelta(days=3)).strftime("%Y-%m-%d")})
        resumen.append(f"  - {p['name']}: {len(pedidos)} pedidos, S/ {monto:.2f} → {', '.join(segs) or 'sin segmento'}")
    print("Segmentación para fidelización:")
    print("\n".join(resumen))

    if a.nuevo_admin_password:
        o("res.users", "write", [o.uid], {"password": a.nuevo_admin_password})
        print("Contraseña de admin actualizada")
    print("Carga completa.")


if __name__ == "__main__":
    main()
