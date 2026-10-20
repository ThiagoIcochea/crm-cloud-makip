#!/usr/bin/env python3
"""Genera la versión estática de prueba de la landing para GitHub Pages en _site/.
El catálogo se lee de app/seed/catalogo (mismo contenido que se carga en Odoo)."""
import json, pathlib, shutil
R = pathlib.Path(__file__).resolve().parent.parent
OUT = R / '_site'
shutil.rmtree(OUT, ignore_errors=True)
shutil.copytree(R / 'web', OUT, ignore=shutil.ignore_patterns('firebase.json'))
(OUT / 'img').mkdir(exist_ok=True)
prods = json.loads((R / 'app/seed/catalogo/productos.json').read_text(encoding='utf-8'))
salida = []
for i, p in enumerate(sorted(prods, key=lambda x: x['nombre'].lower()), 1):
    img = p['imagenes'][0]
    shutil.copy(R / f'app/seed/catalogo/img/{img}.jpg', OUT / 'img' / f'{img}.jpg')
    salida.append({'id': i, 'nombre': p['nombre'], 'categoria': p['categoria'], 'descripcion': p['descripcion'],
                   'precio': p['precio'], 'moneda': 'PEN', 'codigo': p['codigo'], 'imagen': f'img/{img}.jpg'})
(OUT / 'catalogo.json').write_text(json.dumps({'productos': salida}, ensure_ascii=False), encoding='utf-8')
cfg = OUT / 'config.js'
cfg.write_text(cfg.read_text(encoding='utf-8') + "\n// Versión de prueba en GitHub Pages: catálogo estático, sin registro en el CRM.\n"
               "window.MAKIP_CONFIG.catalogoEstatico = 'catalogo.json';\nwindow.MAKIP_CONFIG.useDemoFallback = false;\n", encoding='utf-8')
html = OUT / 'index.html'
html.write_text(html.read_text(encoding='utf-8').replace('<body>', '<body>\n  <p class="test-banner">🧪 Versión de prueba (GitHub Pages): el pedido se envía por WhatsApp; el registro automático en el CRM funciona en la versión de Google Cloud.</p>', 1), encoding='utf-8')
css = OUT / 'styles.css'
css.write_text(css.read_text(encoding='utf-8') + '\n.test-banner { margin: 0; padding: .45rem 1rem; text-align: center; background: #ffd400; font-weight: 700; font-size: .85rem; }\n', encoding='utf-8')
(OUT / '.nojekyll').write_text('')
print(f'_site listo: {len(salida)} productos')
