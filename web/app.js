(() => {
  const cfg = window.MAKIP_CONFIG || {};
  const grid = document.getElementById('grid');
  const status = document.querySelector('.status');
  const filters = document.querySelector('.filters');
  const tpl = document.getElementById('card');
  const bar = document.querySelector('.cart-bar');
  const dlg = document.querySelector('.cart');
  const form = document.querySelector('.cart-form');
  const list = document.querySelector('.cart-items');
  const errorBox = document.querySelector('.cart-error');
  const PAGE_URL = location.origin + location.pathname;
  const money = new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' });
  const api = (p) => (cfg.apiBase || '') + p;

  // Datos de demostración (sin precios reales): solo para desarrollo sin API.
  const DEMO = [
    { id: 1, nombre: 'Llavero personalizado', categoria: 'Llaveros', descripcion: 'Acrílico o MDF con nombre o diseño.', precio: null, codigo: 'DEMO-01' },
    { id: 2, nombre: 'Topper para torta', categoria: 'Fiestas', descripcion: 'Corte láser con el nombre y la temática que elijas.', precio: null, codigo: 'DEMO-02' },
  ];

  let productos = [];
  const pedido = new Map(); // id -> cantidad

  // ---------- Persistencia ligera del pedido en este navegador ----------
  const KEY = 'makip-pedido';
  function guardar() { try { localStorage.setItem(KEY, JSON.stringify([...pedido])); } catch { /* sin almacenamiento */ } }
  function restaurar() { try { for (const [id, q] of JSON.parse(localStorage.getItem(KEY) || '[]')) pedido.set(Number(id), Number(q)); } catch { /* vacío */ } }

  // ---------- WhatsApp ----------
  function waLink(text) {
    const n = (cfg.whatsappNumber || '').replace(/\D/g, '');
    return n ? `https://wa.me/${n}?text=${encodeURIComponent(text)}` : null;
  }
  function abrirWhatsApp(text, ventana) {
    const url = waLink(text);
    if (!url) { alert('Número de WhatsApp aún no configurado (web/config.js).'); return; }
    if (ventana && !ventana.closed) ventana.location.href = url;
    else if (!window.open(url, '_blank', 'noopener')) location.href = url;
  }
  function mensajeProducto(p) {
    const precio = Number.isFinite(p.precio) && p.precio > 0 ? ` (desde ${money.format(p.precio)})` : '';
    return `👋 ¡Hola, Makip Te Crea! Quisiera información de:\n🛍️ ${p.nombre}${p.codigo ? ` · código ${p.codigo}` : ''}${precio}\n🔗 ${PAGE_URL}#p-${p.id}`;
  }
  function mensajePedido(datos, ref) {
    const lineas = [...pedido].map(([id, q], i) => {
      const p = productos.find((x) => x.id === id);
      const precio = Number.isFinite(p?.precio) && p.precio > 0 ? ` — desde ${money.format(p.precio)} c/u` : '';
      return `${i + 1}. ${p?.nombre || 'Producto'} (${p?.codigo || 's/c'}) × ${q}${precio}`;
    });
    const entrega = datos.entrega === 'delivery' ? `🚚 Delivery a ${datos.distrito || 'mi distrito'}` : '🏪 Recojo en taller';
    return [
      '👋 ¡Hola, Makip Te Crea! Quiero cotizar este pedido:',
      ref ? `🧾 N.° de consulta: ${ref}` : null,
      '',
      '🛍️ Productos:', ...lineas,
      `💰 Total referencial: ${money.format(total())}`,
      '',
      `👤 Nombre: ${datos.nombre}`,
      `📱 Celular: ${datos.telefono}`,
      entrega,
      datos.fecha ? `📅 Lo necesito para: ${new Date(datos.fecha + 'T12:00').toLocaleDateString('es-PE', { day: 'numeric', month: 'long', year: 'numeric' })}` : null,
      datos.detalle ? `✏️ Personalización: ${datos.detalle}` : null,
      '',
      `🔗 Catálogo: ${PAGE_URL}`,
    ].filter((l) => l !== null).join('\n');
  }

  // ---------- Pedido ----------
  function total() {
    return [...pedido].reduce((s, [id, q]) => s + ((productos.find((p) => p.id === id)?.precio) || 0) * q, 0);
  }
  function actualizarPedido() {
    const n = [...pedido.values()].reduce((a, b) => a + b, 0);
    bar.hidden = pedido.size === 0;
    document.body.classList.toggle('has-cart', pedido.size > 0);
    document.querySelectorAll('.cart-count').forEach((e) => { e.textContent = `${pedido.size} producto${pedido.size === 1 ? '' : 's'} · ${n} u.`; });
    document.querySelectorAll('.cart-total').forEach((e) => { e.textContent = money.format(total()); });
    document.querySelectorAll('.btn-add').forEach((b) => {
      const en = pedido.has(Number(b.dataset.id));
      b.setAttribute('aria-pressed', String(en));
      b.textContent = en ? `✓ En tu pedido (${pedido.get(Number(b.dataset.id))})` : '🛍️ Agregar a mi pedido';
    });
    pintarLista();
    guardar();
  }
  function pintarLista() {
    list.textContent = '';
    for (const [id, q] of pedido) {
      const p = productos.find((x) => x.id === id);
      if (!p) continue;
      const li = document.createElement('li');
      li.innerHTML = `<img alt=""><div><div class="n"></div><div class="p"></div></div>
        <div class="qty"><button type="button" aria-label="Quitar uno">−</button><input type="number" min="0" max="1000" aria-label="Cantidad"><button type="button" aria-label="Agregar uno">+</button></div>`;
      li.querySelector('img').src = p.imagen ? api(p.imagen) : 'assets/logo-makip.jpg';
      li.querySelector('.n').textContent = p.nombre;
      li.querySelector('.p').textContent = `${p.codigo || ''}${Number.isFinite(p.precio) && p.precio > 0 ? ` · desde ${money.format(p.precio)}` : ''}`;
      const input = li.querySelector('input'); input.value = q;
      const set = (v) => { v = Math.max(0, Math.min(1000, Math.floor(v) || 0)); if (v === 0) pedido.delete(id); else pedido.set(id, v); actualizarPedido(); if (!pedido.size) dlg.close(); };
      const [menos, mas] = li.querySelectorAll('button');
      menos.onclick = () => set(q - 1); mas.onclick = () => set(q + 1); input.onchange = () => set(Number(input.value));
      list.appendChild(li);
    }
  }

  // ---------- Catálogo ----------
  function placeholder(p) {
    const colors = ['#8cc63f', '#2ba6b5', '#ffd400', '#e6007e', '#f7931e'];
    const c = colors[p.id % colors.length];
    const letter = (p.nombre || '?').trim().charAt(0).toUpperCase();
    const svg = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 400 400'><rect width='400' height='400' fill='%23f3ebe0'/><rect x='150' y='120' width='100' height='140' rx='14' fill='${c.replace('#', '%23')}'/><text x='200' y='215' font-family='sans-serif' font-size='64' font-weight='700' text-anchor='middle' fill='%23141414'>${letter}</text></svg>`;
    return `data:image/svg+xml;utf8,${svg}`;
  }
  function render(active = 'Todos') {
    grid.textContent = '';
    const lista = active === 'Todos' ? productos : productos.filter((p) => p.categoria === active);
    for (const p of lista) {
      const node = tpl.content.cloneNode(true);
      node.querySelector('.card').id = `p-${p.id}`;
      const img = node.querySelector('img');
      img.src = p.imagen ? api(p.imagen) : placeholder(p);
      img.alt = `${p.nombre} (imagen referencial)`;
      img.onerror = () => { img.onerror = null; img.src = placeholder(p); };
      node.querySelector('.cat').textContent = p.categoria || '';
      node.querySelector('h3').textContent = p.nombre;
      node.querySelector('.desc').textContent = p.descripcion || '';
      node.querySelector('.price').textContent = Number.isFinite(p.precio) && p.precio > 0 ? `Desde ${money.format(p.precio)}` : 'Consultar precio';
      node.querySelector('.sku').textContent = p.codigo ? `Código: ${p.codigo}` : '';
      const add = node.querySelector('.btn-add'); add.dataset.id = p.id;
      add.addEventListener('click', () => { pedido.set(p.id, (pedido.get(p.id) || 0) + 1); actualizarPedido(); });
      node.querySelector('.btn-icon').addEventListener('click', () => abrirWhatsApp(mensajeProducto(p)));
      grid.appendChild(node);
    }
    actualizarPedido();
  }
  function renderFilters() {
    const cats = ['Todos', ...new Set(productos.map((p) => p.categoria).filter(Boolean))];
    filters.textContent = '';
    for (const c of cats) {
      const b = document.createElement('button');
      b.className = 'chip'; b.type = 'button'; b.textContent = c;
      b.setAttribute('aria-pressed', String(c === 'Todos'));
      b.addEventListener('click', () => {
        filters.querySelectorAll('.chip').forEach((x) => x.setAttribute('aria-pressed', String(x === b)));
        render(c);
      });
      filters.appendChild(b);
    }
  }
  async function load() {
    status.textContent = 'Cargando catálogo…';
    try {
      const res = await fetch(api('/api/catalogo'), { headers: { Accept: 'application/json' } });
      if (!res.ok) throw new Error(res.status);
      productos = (await res.json()).productos;
    } catch {
      productos = [];
      if (cfg.catalogoEstatico) { // versión de prueba sin backend (GitHub Pages)
        try { productos = (await (await fetch(cfg.catalogoEstatico)).json()).productos; } catch { /* sin catálogo */ }
      }
    }
    status.textContent = '';
    if (!productos.length) {
      productos = cfg.useDemoFallback ? DEMO : [];
      status.textContent = cfg.useDemoFallback ? 'Mostrando productos de demostración (catálogo no disponible).' : 'El catálogo no está disponible en este momento. Escríbenos por WhatsApp.';
    }
    for (const id of [...pedido.keys()]) if (!productos.some((p) => p.id === id)) pedido.delete(id);
    renderFilters(); render();
  }

  // ---------- Panel y envío ----------
  bar.addEventListener('click', () => { errorBox.textContent = ''; dlg.showModal(); });
  document.querySelector('.cart-close').addEventListener('click', () => dlg.close());
  dlg.addEventListener('click', (e) => { if (e.target === dlg) dlg.close(); });
  form.addEventListener('change', (e) => {
    if (e.target.name === 'entrega') form.querySelector('.distrito').hidden = e.target.value !== 'delivery';
  });
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const datos = Object.fromEntries(new FormData(form));
    datos.nombre = (datos.nombre || '').trim(); datos.telefono = (datos.telefono || '').trim();
    if (datos.nombre.length < 2) { errorBox.textContent = '👤 Ingresa tu nombre.'; return; }
    if (datos.telefono.replace(/\D/g, '').length < 9) { errorBox.textContent = '📱 Ingresa un celular válido (9 dígitos).'; return; }
    if (datos.entrega === 'delivery' && !datos.distrito.trim()) { errorBox.textContent = '🚚 Indica el distrito para el delivery.'; return; }
    errorBox.textContent = '';
    const boton = form.querySelector('.btn-send'); boton.disabled = true; boton.textContent = 'Registrando tu pedido…';
    const ventana = window.open('', '_blank'); // se abre en el clic para que el navegador no la bloquee
    let ref = null;
    try {
      const res = await fetch(api('/api/consultas'), {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...datos, items: [...pedido].map(([id, cantidad]) => ({ id, cantidad })) }),
      });
      if (res.ok) ref = (await res.json()).ref;
    } catch { /* si el CRM no responde, igual se envía el WhatsApp */ }
    abrirWhatsApp(mensajePedido(datos, ref), ventana);
    boton.disabled = false; boton.textContent = '💬 Enviar pedido por WhatsApp';
    pedido.clear(); actualizarPedido(); form.reset(); form.querySelector('.distrito').hidden = true; dlg.close();
    status.textContent = ref ? `✅ ¡Listo! Tu consulta ${ref} fue registrada; continúa la conversación en WhatsApp.` : '✅ Continúa la conversación en WhatsApp.';
  });

  document.querySelectorAll('[data-wa-general]').forEach((b) =>
    b.addEventListener('click', () => abrirWhatsApp('👋 ¡Hola, Makip Te Crea! Vi su catálogo y quisiera cotizar un producto personalizado.')));
  document.getElementById('year').textContent = new Date().getFullYear();
  (function social() {
    const box = document.querySelector('.social');
    const names = { tiktok: 'TikTok', instagram: 'Instagram', facebook: 'Facebook' };
    for (const [k, url] of Object.entries(cfg.social || {})) {
      if (!url) continue;
      const a = document.createElement('a');
      a.href = url; a.target = '_blank'; a.rel = 'noopener'; a.textContent = names[k] || k;
      box.appendChild(a);
    }
  })();
  restaurar();
  load();
})();
