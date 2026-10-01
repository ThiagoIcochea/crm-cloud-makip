(() => {
  const cfg = window.MAKIP_CONFIG || {};
  const grid = document.getElementById('grid');
  const status = document.querySelector('.status');
  const filters = document.querySelector('.filters');
  const tpl = document.getElementById('card');
  const PAGE_URL = location.origin + location.pathname;
  const money = new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' });

  // Datos de demostración (sin precios reales): solo para desarrollo sin API.
  const DEMO = [
    { id: 1, nombre: 'Llavero personalizado', categoria: 'Llaveros', descripcion: 'Acrílico o MDF con nombre o diseño.', precio: null, codigo: 'DEMO-01' },
    { id: 2, nombre: 'Topper para torta', categoria: 'Fiestas', descripcion: 'Corte láser con el nombre y la temática que elijas.', precio: null, codigo: 'DEMO-02' },
    { id: 3, nombre: 'Medallero', categoria: 'Decoración', descripcion: 'Porta medallas en MDF pintado.', precio: null, codigo: 'DEMO-03' },
    { id: 4, nombre: 'Cuadro con marco', categoria: 'Decoración', descripcion: 'Marco en MDF con foto o diseño.', precio: null, codigo: 'DEMO-04' },
  ];

  function waLink(text) {
    const n = (cfg.whatsappNumber || '').replace(/\D/g, '');
    return n ? `https://wa.me/${n}?text=${encodeURIComponent(text)}` : null;
  }

  function openWhatsApp(text) {
    const url = waLink(text);
    if (!url) { alert('Número de WhatsApp aún no configurado (web/config.js).'); return; }
    window.open(url, '_blank', 'noopener');
  }

  function productMessage(p) {
    const code = p.codigo ? ` (código ${p.codigo})` : '';
    return `Hola, estoy interesado en ${p.nombre}${code} que vi en la página de Makip Te Crea. Quisiera recibir más información. ${PAGE_URL}#p-${p.id}`;
  }

  function placeholder(p) {
    const colors = ['#8cc63f', '#2ba6b5', '#ffd400', '#e6007e', '#f7931e'];
    const c = colors[p.id % colors.length];
    const letter = (p.nombre || '?').trim().charAt(0).toUpperCase();
    const svg = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 400 300'><rect width='400' height='300' fill='%23f3ebe0'/><rect x='150' y='80' width='100' height='140' rx='14' fill='${c.replace('#', '%23')}'/><text x='200' y='175' font-family='sans-serif' font-size='64' font-weight='700' text-anchor='middle' fill='%23141414'>${letter}</text></svg>`;
    return `data:image/svg+xml;utf8,${svg}`;
  }

  function render(products, active = 'Todos') {
    grid.textContent = '';
    const list = active === 'Todos' ? products : products.filter((p) => p.categoria === active);
    for (const p of list) {
      const node = tpl.content.cloneNode(true);
      const card = node.querySelector('.card');
      card.id = `p-${p.id}`;
      const img = node.querySelector('img');
      img.src = p.imagen ? (cfg.apiBase || '') + p.imagen : placeholder(p);
      img.alt = `${p.nombre} (imagen referencial)`;
      img.onerror = () => { img.onerror = null; img.src = placeholder(p); };
      node.querySelector('.cat').textContent = p.categoria || '';
      node.querySelector('h3').textContent = p.nombre;
      node.querySelector('.desc').textContent = p.descripcion || '';
      node.querySelector('.price').textContent = Number.isFinite(p.precio) ? `Desde ${money.format(p.precio)}` : 'Consultar precio';
      node.querySelector('.sku').textContent = p.codigo ? `Código: ${p.codigo}` : '';
      node.querySelector('.btn-wa').addEventListener('click', () => openWhatsApp(productMessage(p)));
      grid.appendChild(node);
    }
  }

  function renderFilters(products) {
    const cats = ['Todos', ...new Set(products.map((p) => p.categoria).filter(Boolean))];
    filters.textContent = '';
    for (const c of cats) {
      const b = document.createElement('button');
      b.className = 'chip'; b.type = 'button'; b.textContent = c;
      b.setAttribute('aria-pressed', String(c === 'Todos'));
      b.addEventListener('click', () => {
        filters.querySelectorAll('.chip').forEach((x) => x.setAttribute('aria-pressed', String(x === b)));
        render(products, c);
      });
      filters.appendChild(b);
    }
  }

  async function load() {
    status.textContent = 'Cargando catálogo…';
    try {
      const res = await fetch(`${cfg.apiBase || ''}/api/catalogo`, { headers: { Accept: 'application/json' } });
      if (!res.ok) throw new Error(res.status);
      const { productos } = await res.json();
      status.textContent = productos.length ? '' : 'Pronto publicaremos nuestros productos.';
      renderFilters(productos); render(productos);
    } catch {
      if (cfg.useDemoFallback) {
        status.textContent = 'Mostrando productos de demostración (catálogo no disponible).';
        renderFilters(DEMO); render(DEMO);
      } else {
        status.textContent = 'El catálogo no está disponible en este momento. Escríbenos por WhatsApp.';
      }
    }
  }

  function renderSocial() {
    const box = document.querySelector('.social');
    const names = { tiktok: 'TikTok', instagram: 'Instagram', facebook: 'Facebook' };
    for (const [k, url] of Object.entries(cfg.social || {})) {
      if (!url) continue;
      const a = document.createElement('a');
      a.href = url; a.target = '_blank'; a.rel = 'noopener'; a.textContent = names[k] || k;
      box.appendChild(a);
    }
  }

  document.querySelectorAll('[data-wa-general]').forEach((b) =>
    b.addEventListener('click', () => openWhatsApp('Hola, vi la página de Makip Te Crea y quisiera cotizar un producto personalizado.')));
  document.getElementById('year').textContent = new Date().getFullYear();
  renderSocial();
  load();
})();
