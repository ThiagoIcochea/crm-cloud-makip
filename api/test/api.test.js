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
