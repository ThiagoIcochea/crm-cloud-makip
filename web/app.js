(() => {
  const cfg = window.MAKIP_CONFIG || {};
  const $ = (s, el = document) => el.querySelector(s);
  const $$ = (s, el = document) => [...el.querySelectorAll(s)];
  const grid = $('#grid');
  const status = $('.status');
  const filters = $('.filters');
  const tpl = $('#card');
  const bar = $('.list-bar');
  const sheet = $('.sheet');
  const form = $('.sheet-form');
  const items = $('.sheet-items');
  const errorBox = $('.form-error');
  const search = $('.search input');
  const PAGE_URL = location.origin + location.pathname;
  const money = new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' });
  const api = (p) => (/^https?:|^img\//.test(p) ? p : (cfg.apiBase || '') + p);
  const COLOR = { 'Mundo Lazos': 'var(--pink)', 'Apliques Cerámica': 'var(--teal)', Otros: 'var(--orange)' };

  let productos = [];
  let categoria = 'Todos';
  const pedido = new Map(); // id -> cantidad

  // ---------- Persistencia ligera de la lista en este navegador ----------
  const KEY = 'makip-lista';
  const guardar = () => { try { localStorage.setItem(KEY, JSON.stringify([...pedido])); } catch { /* sin almacenamiento */ } };
  const restaurar = () => { try { for (const [id, q] of JSON.parse(localStorage.getItem(KEY) || '[]')) pedido.set(Number(id), Number(q)); } catch { /* vacío */ } };

  // ---------- WhatsApp ----------
  // La página intermedia de wa.me y api.whatsapp.com reemplaza los emojis por «�»,
  // así que en el celular se abre la app directamente y en la computadora WhatsApp Web.
  const esMovil = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
  function waLink(text) {
    const n = (cfg.whatsappNumber || '').replace(/\D/g, '');
    if (!n) return null;
    const q = `phone=${n}&text=${encodeURIComponent(text)}`;
    return esMovil ? `whatsapp://send?${q}` : `https://web.whatsapp.com/send?${q}`;
  }
  function abrirWhatsApp(text, ventana) {
    const url = waLink(text);
    if (!url) return;
    if (esMovil) { if (ventana && !ventana.closed) ventana.close(); location.href = url; return; }
    if (ventana && !ventana.closed) ventana.location.href = url;
    else if (!window.open(url, '_blank', 'noopener')) location.href = url;
  }
  const precioTxt = (p) => (Number.isFinite(p?.precio) && p.precio > 0 ? money.format(p.precio) : null);
  function mensajeProducto(p) {
    return ['Hola, Makip Te Crea 👋', 'Quisiera información de este producto:', `🛍️ ${p.nombre}${p.codigo ? ` (${p.codigo})` : ''}${precioTxt(p) ? ` · desde ${precioTxt(p)}` : ''}`, `🔗 ${PAGE_URL}#p-${p.id}`].join('\n');
  }
  function mensajePedido(d, ref) {
    const lineas = [...pedido].map(([id, q]) => {
      const p = productos.find((x) => x.id === id);
      return `▪️ ${q} × ${p?.nombre || 'Producto'}${p?.codigo ? ` (${p.codigo})` : ''}${precioTxt(p) ? ` · desde ${precioTxt(p)} c/u` : ''}`;
    });
    const fecha = d.fecha ? new Date(d.fecha + 'T12:00').toLocaleDateString('es-PE', { day: 'numeric', month: 'long' }) : null;
    return [
      'Hola, Makip Te Crea 👋',
      'Quiero cotizar este pedido:',
      ref ? `🧾 Consulta ${ref}` : null,
      '',
      ...lineas,
      `💰 Total referencial: ${money.format(total())}`,
      '',
      `👤 ${d.nombre}`,
      `📱 ${d.telefono}`,
      d.entrega === 'delivery' ? `🚚 Delivery a ${d.distrito}` : '🏪 Recojo en taller',
      fecha ? `📅 Para el ${fecha}` : null,
      d.detalle ? `✏️ Personalización: ${d.detalle}` : null,
    ].filter((l) => l !== null).join('\n');
  }

  // ---------- Lista de pedido ----------
  const total = () => [...pedido].reduce((s, [id, q]) => s + ((productos.find((p) => p.id === id)?.precio) || 0) * q, 0);
  function setCantidad(id, q) {
    q = Math.max(0, Math.min(1000, Math.floor(q) || 0));
    if (q === 0) pedido.delete(id); else pedido.set(id, q);
    actualizar();
    if (!pedido.size && sheet.open) sheet.close();
  }
  function stepper(el, id) {
    $('.qty-out', el).textContent = pedido.get(id) || 0;
    $('.dec', el).onclick = () => setCantidad(id, (pedido.get(id) || 0) - 1);
    $('.inc', el).onclick = () => setCantidad(id, (pedido.get(id) || 0) + 1);
  }
  // La barra es oscura: al pasar sobre el pie (también oscuro) cambia a la versión clara para que se distinga.
  function contrasteBarra() {
    const pie = document.querySelector('.foot');
    if (!pie || bar.hidden) return;
    const zona = window.innerHeight - bar.offsetHeight / 2 - 16;
    bar.classList.toggle('sobre-pie', pie.getBoundingClientRect().top < zona);
  }
  addEventListener('scroll', contrasteBarra, { passive: true });
  addEventListener('resize', contrasteBarra);

  function actualizar() {
    const unidades = [...pedido.values()].reduce((a, b) => a + b, 0);
    bar.hidden = pedido.size === 0;
    document.body.classList.toggle('has-list', pedido.size > 0);
    contrasteBarra();
    $$('.list-count').forEach((e) => { e.textContent = unidades; });
    $$('.list-total').forEach((e) => { e.textContent = money.format(total()); });
    $$('.card').forEach((card) => {
      const id = Number(card.dataset.id);
      const en = pedido.has(id);
      $('.btn-add', card).hidden = en;
      $('.stepper', card).hidden = !en;
      if (en) stepper(card, id);
    });
    pintarLista();
    guardar();
  }
  function pintarLista() {
    items.textContent = '';
    for (const [id] of pedido) {
      const p = productos.find((x) => x.id === id);
      if (!p) continue;
      const li = document.createElement('li');
      li.innerHTML = `<img alt=""><div><div class="n"></div><div class="p"></div></div>
        <div class="stepper"><button type="button" class="dec" aria-label="Quitar uno"><svg><use href="#i-minus"/></svg></button><output class="qty-out"></output><button type="button" class="inc" aria-label="Agregar uno"><svg><use href="#i-plus"/></svg></button></div>`;
      $('img', li).src = p.imagen ? api(p.imagen) : 'assets/logo-makip.jpg';
      $('.n', li).textContent = p.nombre;
      $('.p', li).textContent = [p.codigo, precioTxt(p) && `desde ${precioTxt(p)}`].filter(Boolean).join(' · ');
      stepper(li, id);
      items.appendChild(li);
    }
  }
  let toastTimer;
  function aviso(texto) {
    const t = $('.toast');
    t.innerHTML = '<svg><use href="#i-check"/></svg><span></span>';
    $('span', t).textContent = texto; t.hidden = false;
    clearTimeout(toastTimer); toastTimer = setTimeout(() => { t.hidden = true; }, 3200);
  }

  // ---------- Catálogo ----------
  function render() {
    grid.textContent = '';
    const q = search.value.trim().toLowerCase();
    const lista = productos.filter((p) => (categoria === 'Todos' || p.categoria === categoria)
      && (!q || `${p.nombre} ${p.descripcion} ${p.codigo}`.toLowerCase().includes(q)));
    status.textContent = lista.length || !productos.length ? '' : 'No encontramos productos con esa búsqueda. Prueba con otra palabra o escríbenos por WhatsApp.';
    for (const p of lista) {
      const node = tpl.content.cloneNode(true);
      const card = $('.card', node);
      card.id = `p-${p.id}`; card.dataset.id = p.id;
      card.style.setProperty('--c', COLOR[p.categoria] || 'var(--ink)');
      const img = $('img', node);
      img.src = p.imagen ? api(p.imagen) : 'assets/logo-makip.jpg';
      img.alt = p.nombre;
      $('.cat', node).textContent = p.categoria || '';
      $('h3', node).textContent = p.nombre;
      $('.desc', node).textContent = p.descripcion || '';
      $('.price', node).innerHTML = precioTxt(p) ? `<small>desde</small> ${precioTxt(p)}` : '<small>Precio según diseño</small>';
      $('.btn-add', node).addEventListener('click', () => { setCantidad(p.id, 1); aviso(`${p.nombre} se agregó a tu lista`); });
      $('.btn-ask', node).addEventListener('click', () => abrirWhatsApp(mensajeProducto(p)));
      grid.appendChild(node);
    }
    actualizar();
  }
  function renderFilters() {
    const cats = ['Todos', ...new Set(productos.map((p) => p.categoria).filter(Boolean))];
    filters.textContent = '';
    for (const c of cats) {
      const b = document.createElement('button');
      b.className = 'chip'; b.type = 'button';
      if (c !== 'Todos') { const i = document.createElement('i'); i.style.setProperty('--c', COLOR[c] || 'var(--ink)'); b.appendChild(i); }
      b.append(c);
      b.setAttribute('aria-pressed', String(c === categoria));
      b.addEventListener('click', () => { categoria = c; $$('.chip', filters).forEach((x) => x.setAttribute('aria-pressed', String(x === b))); render(); });
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
      if (cfg.catalogoEstatico) {
        try { productos = (await (await fetch(cfg.catalogoEstatico)).json()).productos; } catch { /* sin catálogo */ }
      }
    }
    for (const id of [...pedido.keys()]) if (!productos.some((p) => p.id === id)) pedido.delete(id);
    renderFilters(); render();
    if (!productos.length) status.textContent = 'El catálogo no está disponible en este momento. Escríbenos por WhatsApp y te enviamos los precios.';
  }

  // ---------- Hoja de pedido y envío ----------
  $$('[data-open-list]').forEach((b) => b.addEventListener('click', () => {
    if (!pedido.size) { document.getElementById('catalogo').scrollIntoView({ behavior: 'smooth' }); aviso('Agrega productos del catálogo para armar tu lista'); return; }
    errorBox.textContent = ''; sheet.showModal();
  }));
  $('.sheet-close').addEventListener('click', () => sheet.close());
  sheet.addEventListener('click', (e) => { if (e.target === sheet) sheet.close(); });
  form.addEventListener('change', (e) => { if (e.target.name === 'entrega') $('.distrito', form).hidden = e.target.value !== 'delivery'; });
  search.addEventListener('input', () => render());

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const d = Object.fromEntries(new FormData(form));
    d.nombre = (d.nombre || '').trim(); d.telefono = (d.telefono || '').trim(); d.distrito = (d.distrito || '').trim();
    const error = d.nombre.length < 2 ? 'Escribe tu nombre y apellido.'
      : d.telefono.replace(/\D/g, '').length < 9 ? 'Escribe un celular de 9 dígitos.'
      : d.entrega === 'delivery' && !d.distrito ? 'Indica el distrito para el delivery.'
      : !d.acepto ? 'Para enviar el pedido acepta el uso de tus datos.' : '';
    if (error) { errorBox.textContent = error; return; }
    errorBox.textContent = '';
    const boton = $('.btn-send', form); boton.disabled = true;
    const ventana = esMovil ? null : window.open('', '_blank'); // se abre en el mismo clic para que el navegador no la bloquee
    let ref = null;
    try {
      const res = await fetch(api('/api/consultas'), {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...d, items: [...pedido].map(([id, cantidad]) => ({ id, cantidad })) }),
      });
      if (res.ok) ref = (await res.json()).ref;
    } catch { /* si el CRM no responde, igual se envía el WhatsApp */ }
    abrirWhatsApp(mensajePedido(d, ref), ventana);
    boton.disabled = false;
    pedido.clear(); form.reset(); $('.distrito', form).hidden = true; sheet.close(); actualizar();
    aviso(ref ? `Pedido enviado. Tu número de consulta es ${ref}.` : 'Pedido enviado. Continúa la conversación en WhatsApp.');
  });

  $$('[data-wa-general]').forEach((b) => b.addEventListener('click', () => abrirWhatsApp('Hola, Makip Te Crea 👋\nVi su catálogo y quisiera cotizar un producto personalizado.')));
  $('#year').textContent = new Date().getFullYear();
  restaurar();
  load();
})();
