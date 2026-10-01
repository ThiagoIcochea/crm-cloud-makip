// Cliente mínimo de la API externa de Odoo (solo lectura).
// Modos:
//   json2   -> POST /json/2/<modelo>/<método> con clave de API (Odoo 19+)
//   jsonrpc -> POST /jsonrpc execute_kw (versiones anteriores)
// El modo efectivo se confirma en la prueba de concepto con la versión fijada.

export class OdooError extends Error {
  constructor(message, status = 502) {
    super(message);
    this.status = status;
  }
}

export function createOdooClient({ url, db, apiKey, mode = 'json2', user = '', timeoutMs = 8000, fetchImpl = fetch }) {
  if (!url) throw new Error('ODOO_URL no configurado');
  if (!apiKey) throw new Error('ODOO_API_KEY no configurado');
  const base = url.replace(/\/$/, '');
  let uid = null;

  async function post(path, body, headers = {}) {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), timeoutMs);
    try {
      const res = await fetchImpl(base + path, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...headers },
        body: JSON.stringify(body),
        signal: ctrl.signal,
      });
      if (!res.ok) throw new OdooError(`Odoo respondió ${res.status}`);
      return await res.json();
    } catch (err) {
      if (err instanceof OdooError) throw err;
      throw new OdooError(err.name === 'AbortError' ? 'Tiempo de espera agotado con Odoo' : 'Odoo no disponible');
    } finally {
      clearTimeout(t);
    }
  }

  async function rpc(service, method, args) {
    const data = await post('/jsonrpc', { jsonrpc: '2.0', method: 'call', id: Date.now(), params: { service, method, args } });
    if (data.error) throw new OdooError(data.error.message || 'Error de Odoo');
    return data.result;
  }

  async function searchRead(model, domain, fields, extra = {}) {
    if (mode === 'json2') {
      return post(`/json/2/${model}/search_read`, { domain, fields, ...extra }, {
        Authorization: `bearer ${apiKey}`,
        'X-Odoo-Database': db,
      });
    }
    if (uid === null) {
      uid = await rpc('common', 'login', [db, user, apiKey]);
      if (!uid) throw new OdooError('Autenticación con Odoo rechazada', 502);
    }
    return rpc('object', 'execute_kw', [db, uid, apiKey, model, 'search_read', [domain], { fields, ...extra }]);
  }

  return { searchRead };
}
