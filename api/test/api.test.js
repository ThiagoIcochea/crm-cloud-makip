import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createCatalog, toPublicProduct, imageMime } from '../src/catalog.js';
import { createApp } from '../src/server.js';
import { createOdooClient, OdooError } from '../src/odoo.js';

const ROWS = [
  { id: 7, name: ' Llavero acrílico ', list_price: 12.5, categ_id: [3, 'Todos / Llaveros'], description_sale: 'Personalizado', default_code: 'LLA-001', currency_id: [1, 'PEN'], standard_price: 4 },
];

function fakeOdoo({ fail = false } = {}) {
  const calls = [];
  return {
    calls,
    async searchRead(model, domain, fields) {
      calls.push({ model, domain, fields });
      if (fail) throw new OdooError('Odoo no disponible');
      if (fields.includes('image_512')) return [{ image_512: Buffer.from([0x89, 0x50, 1, 2]).toString('base64') }];
      return ROWS;
    },
  };
}

test('solo expone campos públicos', () => {
  const p = toPublicProduct(ROWS[0]);
  assert.deepEqual(Object.keys(p).sort(), ['categoria', 'codigo', 'descripcion', 'id', 'imagen', 'moneda', 'nombre', 'precio']);
  assert.equal(p.nombre, 'Llavero acrílico');
  assert.equal(p.categoria, 'Llaveros');
  assert.equal(p.standard_price, undefined); // el costo no se publica
});

test('cachea el listado dentro del TTL', async () => {
  let t = 0;
  const odoo = fakeOdoo();
  const cat = createCatalog({ odoo, ttlMs: 1000, now: () => t });
  await cat.list(); t = 500; await cat.list();
  assert.equal(odoo.calls.length, 1);
  t = 2000; await cat.list();
  assert.equal(odoo.calls.length, 2);
});

test('la imagen reaplica el dominio de productos publicables', async () => {
  const odoo = fakeOdoo();
  const cat = createCatalog({ odoo });
  const img = await cat.image(7);
  assert.equal(imageMime(img), 'image/png');
  assert.deepEqual(odoo.calls[0].domain.at(-1), ['id', '=', 7]);
  assert.ok(odoo.calls[0].domain.some((d) => d[0] === 'sale_ok'));
});

async function withServer(app, fn) {
  await new Promise((r) => app.listen(0, r));
  const { port } = app.address();
  try { await fn(`http://127.0.0.1:${port}`); } finally { app.close(); }
}

test('endpoints HTTP, CORS y métodos', async () => {
  const app = createApp({ catalog: createCatalog({ odoo: fakeOdoo() }), allowedOrigins: ['https://makiptecrea.pe'] });
  await withServer(app, async (base) => {
    let r = await fetch(base + '/api/catalogo', { headers: { Origin: 'https://makiptecrea.pe' } });
    assert.equal(r.status, 200);
    assert.equal(r.headers.get('access-control-allow-origin'), 'https://makiptecrea.pe');
    assert.equal((await r.json()).productos[0].codigo, 'LLA-001');

    r = await fetch(base + '/api/catalogo', { headers: { Origin: 'https://otro.com' } });
    assert.equal(r.headers.get('access-control-allow-origin'), null);

    r = await fetch(base + '/api/catalogo', { method: 'POST' });
    assert.equal(r.status, 405);

    r = await fetch(base + '/api/catalogo/abc/imagen');
    assert.equal(r.status, 404);

    r = await fetch(base + '/healthz');
    assert.equal(r.status, 200);
  });
});

test('error controlado si Odoo no responde', async () => {
  const app = createApp({ catalog: createCatalog({ odoo: fakeOdoo({ fail: true }) }) });
  await withServer(app, async (base) => {
    const r = await fetch(base + '/api/catalogo');
    assert.equal(r.status, 503);
    assert.match((await r.json()).error, /no disponible/);
  });
});

test('cliente json2 envía clave y base de datos en cabeceras', async () => {
  let seen;
  const fetchImpl = async (url, opts) => { seen = { url, opts }; return { ok: true, json: async () => ROWS }; };
  const c = createOdooClient({ url: 'http://odoo:8069/', db: 'makip', apiKey: 'k', fetchImpl });
  await c.searchRead('product.template', [], ['name']);
  assert.equal(seen.url, 'http://odoo:8069/json/2/product.template/search_read');
  assert.equal(seen.opts.headers.Authorization, 'bearer k');
  assert.equal(seen.opts.headers['X-Odoo-Database'], 'makip');
});

test('cliente jsonrpc autentica y luego consulta', async () => {
  const bodies = [];
  const fetchImpl = async (url, opts) => {
    const b = JSON.parse(opts.body); bodies.push(b);
    return { ok: true, json: async () => ({ result: b.params.service === 'common' ? 5 : ROWS }) };
  };
  const c = createOdooClient({ url: 'http://odoo:8069', db: 'makip', apiKey: 'k', mode: 'jsonrpc', user: 'api_catalogo', fetchImpl });
  const rows = await c.searchRead('product.template', [], ['name']);
  assert.equal(rows.length, 1);
  assert.equal(bodies[1].params.args[1], 5);
});

// ---------- Consultas desde la landing ----------
import { validarConsulta, textoOportunidad, crearRegistro } from '../src/consultas.js';

const PRODS = [{ id: 7, codigo: 'LLA-001', nombre: 'Llavero acrílico', precio: 12.5 }];

test('valida la consulta y toma precios del servidor', () => {
  const c = validarConsulta({ nombre: ' Ana ', telefono: '987 654 321', entrega: 'delivery', distrito: 'Surco',
    items: [{ id: 7, cantidad: 3, precio: 0.01 }] }, PRODS);
  assert.equal(c.nombre, 'Ana');
  assert.equal(c.total, 37.5);
  assert.equal(c.items[0].precio, 12.5);
  assert.match(textoOportunidad(c), /delivery a Surco/);
  assert.throws(() => validarConsulta({ nombre: 'A', telefono: '1', items: [] }, PRODS));
  assert.throws(() => validarConsulta({ nombre: 'Ana', telefono: '987654321', items: [{ id: 99 }] }, PRODS));
});

test('registra la oportunidad en el CRM con referencia MK', async () => {
  const calls = [];
  const odoo = { async call(model, method, args) { calls.push([model, method]); return method === 'search' ? [] : 12; } };
  const r = await crearRegistro({ odoo })(validarConsulta({ nombre: 'Ana', telefono: '987654321', items: [{ id: 7, cantidad: 2 }] }, PRODS));
  assert.equal(r.ref, 'MK-0012');
  assert.ok(calls.some(([m, f]) => m === 'crm.lead' && f === 'create'));
});

test('POST /api/consultas responde 201 y limita abusos', async () => {
  const catalog = { list: async () => ({ productos: PRODS }), image: async () => null };
  const app = createApp({ catalog, registrar: async (c) => ({ ref: 'MK-0001', total: c.total }), limitePorMinuto: 2 });
  await withServer(app, async (base) => {
    const body = JSON.stringify({ nombre: 'Ana', telefono: '987654321', items: [{ id: 7, cantidad: 1 }] });
    const opts = { method: 'POST', headers: { 'Content-Type': 'application/json' }, body };
    let r = await fetch(base + '/api/consultas', opts);
    assert.equal(r.status, 201);
    assert.equal((await r.json()).ref, 'MK-0001');
    r = await fetch(base + '/api/consultas', { ...opts, body: '{"nombre":"x"}' });
    assert.equal(r.status, 400);
    r = await fetch(base + '/api/consultas', opts);
    assert.equal(r.status, 429);
  });
});

import { validarReclamo } from '../src/consultas.js';
test('valida la hoja del Libro de Reclamaciones', () => {
  const base = { nombre: 'Ana Ruiz', documento: 'DNI 12345678', domicilio: 'Av. Lima 123', telefono: '987654321', correo: 'ana@correo.pe', descripcion: 'Reglas', detalle: 'Llegó rota', solicitud: 'Reposición' };
  assert.equal(validarReclamo({ ...base, tipo: 'Queja' }).tipo, 'Queja');
  assert.throws(() => validarReclamo({ ...base, correo: 'x' }));
  assert.throws(() => validarReclamo({ ...base, detalle: '' }));
});
