// Registro de consultas de la landing como oportunidades en el CRM (Odoo).
// El precio y el nombre de cada producto se toman del catálogo del servidor, nunca del navegador.

export class ConsultaInvalida extends Error {}

const limpiar = (v, max) => (typeof v === 'string' ? v.replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, max) : '');

export function validarConsulta(body, productos) {
  if (!body || typeof body !== 'object') throw new ConsultaInvalida('Datos inválidos');
  const nombre = limpiar(body.nombre, 80);
  const telefono = limpiar(body.telefono, 20).replace(/[^\d+]/g, '');
  if (nombre.length < 2) throw new ConsultaInvalida('Ingresa tu nombre');
  if (telefono.replace(/\D/g, '').length < 9) throw new ConsultaInvalida('Ingresa un celular válido');
  const entrega = body.entrega === 'delivery' ? 'delivery' : 'recojo';
  const distrito = entrega === 'delivery' ? limpiar(body.distrito, 60) : '';
  const fecha = /^\d{4}-\d{2}-\d{2}$/.test(body.fecha || '') ? body.fecha : '';
  const detalle = limpiar(body.detalle, 500);
  if (!Array.isArray(body.items) || body.items.length === 0 || body.items.length > 30) throw new ConsultaInvalida('Elige al menos un producto');
  const porId = new Map(productos.map((p) => [p.id, p]));
  const items = body.items.map((it) => {
    const p = porId.get(Number(it.id));
    const cantidad = Math.min(1000, Math.max(1, Math.floor(Number(it.cantidad) || 1)));
    if (!p) throw new ConsultaInvalida('Producto no disponible');
    return { id: p.id, codigo: p.codigo, nombre: p.nombre, precio: p.precio, cantidad };
  });
  const total = Math.round(items.reduce((s, i) => s + (i.precio || 0) * i.cantidad, 0) * 100) / 100;
  return { nombre, telefono, entrega, distrito, fecha, detalle, items, total };
}

export function textoOportunidad(c) {
  const lineas = c.items.map((i) => `• ${i.nombre} (${i.codigo || 's/c'}) × ${i.cantidad}` + (i.precio ? ` — desde S/ ${i.precio.toFixed(2)} c/u` : ''));
  return [
    'Consulta registrada desde la landing (catálogo web).',
    '', 'Productos:', ...lineas,
    `Total referencial: S/ ${c.total.toFixed(2)}`, '',
    `Contacto: ${c.nombre} · ${c.telefono}`,
    `Entrega: ${c.entrega === 'delivery' ? `delivery a ${c.distrito || 'por confirmar'}` : 'recojo en taller'}`,
    c.fecha ? `Fecha requerida: ${c.fecha}` : '',
    c.detalle ? `Personalización: ${c.detalle}` : '',
  ].filter((l, i, a) => l !== '' || a[i - 1] !== '').join('\n');
}

export function crearRegistro({ odoo }) {
  const cache = {};
  async function idPorNombre(model, name, crear) {
    if (cache[model + name]) return cache[model + name];
    const ids = await odoo.call(model, 'search', [[['name', '=', name]]], { limit: 1 });
    let id = ids[0];
    if (!id && crear) id = await odoo.call(model, 'create', [{ name }]);
    if (id) cache[model + name] = id;
    return id || false;
  }

  return async function registrar(c) {
    let partner = (await odoo.call('res.partner', 'search', [[['phone', '=', c.telefono]]], { limit: 1 }))[0];
    if (!partner) partner = await odoo.call('res.partner', 'create', [{ name: c.nombre, phone: c.telefono, city: 'Lima' }]);
    const etapa = await idPorNombre('crm.stage', 'Nueva consulta', false);
    const tag = await idPorNombre('crm.tag', 'Landing web', true);
    const equipo = await idPorNombre('crm.team', 'Ventas Makip Te Crea', false);
    const vals = {
      name: `Consulta web – ${c.nombre} (${c.items.length} producto${c.items.length > 1 ? 's' : ''})`,
      type: 'opportunity', partner_id: partner, contact_name: c.nombre, phone: c.telefono,
      expected_revenue: c.total, description: textoOportunidad(c), tag_ids: [[6, 0, [tag]]],
    };
    if (etapa) vals.stage_id = etapa;
    if (equipo) vals.team_id = equipo;
    const id = await odoo.call('crm.lead', 'create', [vals]);
    return { ref: `MK-${String(id).padStart(4, '0')}`, total: c.total };
  };
}

// ---------- Libro de Reclamaciones virtual ----------
export function validarReclamo(b) {
  if (!b || typeof b !== 'object') throw new ConsultaInvalida('Datos inválidos');
  const r = {
    nombre: limpiar(b.nombre, 100), documento: limpiar(b.documento, 20), domicilio: limpiar(b.domicilio, 150),
    telefono: limpiar(b.telefono, 20), correo: limpiar(b.correo, 100), menor: Boolean(b.menor),
    bien: b.bien === 'Servicio' ? 'Servicio' : 'Producto', monto: Number(b.monto) > 0 ? Math.round(Number(b.monto) * 100) / 100 : 0,
    pedido: limpiar(b.pedido, 20), descripcion: limpiar(b.descripcion, 200),
    tipo: b.tipo === 'Queja' ? 'Queja' : 'Reclamo', detalle: limpiar(b.detalle, 1500), solicitud: limpiar(b.solicitud, 500),
  };
  for (const k of ['nombre', 'documento', 'domicilio', 'telefono', 'correo', 'descripcion', 'detalle', 'solicitud']) {
    if (!r[k]) throw new ConsultaInvalida('Completa los campos obligatorios');
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(r.correo)) throw new ConsultaInvalida('Correo inválido');
  return r;
}

export function crearRegistroReclamo({ odoo }) {
  return async function registrar(r) {
    const tags = await odoo.call('crm.tag', 'search', [[['name', '=', 'Libro de Reclamaciones']]], { limit: 1 });
    const tag = tags[0] || (await odoo.call('crm.tag', 'create', [{ name: 'Libro de Reclamaciones' }]));
    const texto = [
      `${r.tipo} registrado en el Libro de Reclamaciones virtual (plazo de respuesta: 15 días hábiles).`,
      `Consumidor: ${r.nombre} · ${r.documento} · ${r.domicilio}`, `Contacto: ${r.telefono} · ${r.correo}`,
      `Menor de edad: ${r.menor ? 'sí (apoderado)' : 'no'}`,
      `${r.bien}: ${r.descripcion} · Monto: S/ ${r.monto.toFixed(2)} · Pedido: ${r.pedido || '—'}`,
      `Detalle: ${r.detalle}`, `Pedido del consumidor: ${r.solicitud}`,
    ].join('\n');
    const id = await odoo.call('crm.lead', 'create', [{
      name: `${r.tipo} – ${r.nombre}`, type: 'lead', contact_name: r.nombre, phone: r.telefono, email_from: r.correo,
      description: texto, tag_ids: [[6, 0, [tag]]], priority: '3',
    }]);
    return { ref: `LR-${String(id).padStart(5, '0')}` };
  };
}
