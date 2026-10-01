import http from 'node:http';
import { pathToFileURL } from 'node:url';
import { createOdooClient, OdooError } from './odoo.js';
import { createCatalog, imageMime, DEFAULT_DOMAIN } from './catalog.js';

export function createApp({ catalog, allowedOrigins = [] }) {
  const log = (severity, message, extra = {}) =>
    console.log(JSON.stringify({ severity, message, ...extra })); // formato estructurado para Cloud Logging

  function cors(req, res) {
    const origin = req.headers.origin;
    if (origin && allowedOrigins.includes(origin)) {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Vary', 'Origin');
    }
  }

  function send(res, status, body, headers = {}) {
    const isBuf = Buffer.isBuffer(body);
    res.writeHead(status, {
      'Content-Type': isBuf ? headers['Content-Type'] : 'application/json; charset=utf-8',
      'X-Content-Type-Options': 'nosniff',
      ...headers,
    });
    res.end(isBuf ? body : JSON.stringify(body));
  }

  return http.createServer(async (req, res) => {
    const started = Date.now();
    cors(req, res);
    const url = new URL(req.url, 'http://localhost');
    try {
      if (req.method === 'OPTIONS') {
        res.writeHead(204, { 'Access-Control-Allow-Methods': 'GET', 'Access-Control-Max-Age': '600' });
        return res.end();
      }
      if (req.method !== 'GET') return send(res, 405, { error: 'Método no permitido' });

      if (url.pathname === '/healthz') return send(res, 200, { ok: true });

      if (url.pathname === '/api/catalogo') {
        const data = await catalog.list();
        return send(res, 200, data, { 'Cache-Control': 'public, max-age=120, s-maxage=300' });
      }

      const m = url.pathname.match(/^\/api\/catalogo\/(\d{1,9})\/imagen$/);
      if (m) {
        const img = await catalog.image(Number(m[1]));
        if (!img) return send(res, 404, { error: 'Imagen no disponible' });
        return send(res, 200, img, { 'Content-Type': imageMime(img), 'Cache-Control': 'public, max-age=3600' });
      }

      return send(res, 404, { error: 'No encontrado' });
    } catch (err) {
      const status = err instanceof OdooError ? 503 : 500;
      log('ERROR', err.message, { path: url.pathname });
      return send(res, status, { error: 'Catálogo no disponible temporalmente' });
    } finally {
      log('INFO', 'request', { method: req.method, path: url.pathname, status: res.statusCode, ms: Date.now() - started });
    }
  });
}

// Arranque solo cuando se ejecuta directamente (no en tests)
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const env = process.env;
  const odoo = createOdooClient({
    url: env.ODOO_URL,
    db: env.ODOO_DB || 'makip',
    apiKey: env.ODOO_API_KEY,
    mode: env.ODOO_API_MODE || 'json2',
    user: env.ODOO_API_USER || '',
  });
  const domain = env.CATALOG_DOMAIN ? JSON.parse(env.CATALOG_DOMAIN) : DEFAULT_DOMAIN;
  const catalog = createCatalog({ odoo, domain, ttlMs: Number(env.CACHE_TTL_MS || 300_000) });
  const allowedOrigins = (env.ALLOWED_ORIGINS || 'http://localhost:3000').split(',').map((s) => s.trim());
  const port = Number(env.PORT || 8080);
  createApp({ catalog, allowedOrigins }).listen(port, () => console.log(`API de catálogo en :${port}`));
}
