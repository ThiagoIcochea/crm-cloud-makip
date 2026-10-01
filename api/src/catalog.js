// Lógica del catálogo: solo campos públicos, caché corta y Odoo como fuente única.

export const PRODUCT_FIELDS = ['id', 'name', 'list_price', 'categ_id', 'description_sale', 'default_code', 'currency_id'];
export const DEFAULT_DOMAIN = [['sale_ok', '=', true], ['active', '=', true]];

const clean = (v) => (typeof v === 'string' ? v.trim() : '');

export function toPublicProduct(p, currency = 'PEN') {
  return {
    id: p.id,
    nombre: clean(p.name),
    categoria: Array.isArray(p.categ_id) ? clean(String(p.categ_id[1]).split('/').pop()) : '',
    descripcion: clean(p.description_sale),
    precio: Number.isFinite(p.list_price) ? Math.round(p.list_price * 100) / 100 : null,
    moneda: Array.isArray(p.currency_id) ? clean(p.currency_id[1]) || currency : currency,
    codigo: clean(p.default_code) || null,
    imagen: `/api/catalogo/${p.id}/imagen`,
  };
}

export function createCatalog({ odoo, ttlMs = 300_000, domain = DEFAULT_DOMAIN, now = () => Date.now() }) {
  let cache = null;
  const images = new Map();
  const MAX_IMAGES = 200;

  async function list() {
    if (cache && now() - cache.at < ttlMs) return cache.value;
    const rows = await odoo.searchRead('product.template', domain, PRODUCT_FIELDS, { order: 'name asc', limit: 500 });
    const value = { productos: rows.map((r) => toPublicProduct(r)), actualizado: new Date(now()).toISOString() };
    cache = { at: now(), value };
    return value;
  }

  async function image(id) {
    const hit = images.get(id);
    if (hit && now() - hit.at < ttlMs) return hit.value;
    // Solo productos publicables: el dominio se reaplica para no exponer otros registros.
    const rows = await odoo.searchRead('product.template', [...domain, ['id', '=', id]], ['image_512'], { limit: 1 });
    const b64 = rows[0]?.image_512;
    const value = b64 ? Buffer.from(b64, 'base64') : null;
    if (images.size >= MAX_IMAGES) images.delete(images.keys().next().value);
    images.set(id, { at: now(), value });
    return value;
  }

  return { list, image };
}

export function imageMime(buf) {
  if (buf[0] === 0x89 && buf[1] === 0x50) return 'image/png';
  if (buf[0] === 0xff && buf[1] === 0xd8) return 'image/jpeg';
  if (buf.subarray(0, 4).toString() === 'RIFF') return 'image/webp';
  if (buf.subarray(0, 5).toString().startsWith('<svg') || buf.subarray(0, 5).toString() === '<?xml') return 'image/svg+xml';
  return 'application/octet-stream';
}
