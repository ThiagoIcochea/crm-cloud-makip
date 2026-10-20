// Configuración pública de la landing (no contiene secretos).
window.MAKIP_CONFIG = {
  // Número de WhatsApp en formato internacional sin "+" ni espacios, p. ej. "51XXXXXXXXX".
  whatsappNumber: '51923119167', // +51 923 119 167 (Makip Te Crea)

  // URL base de la API de catálogo (Cloud Run). Vacío = mismo dominio (/api/catalogo).
  apiBase: '',

  // Redes sociales oficiales (también enlazadas en el pie de index.html).
  social: {
    tiktok: 'https://www.tiktok.com/@makip.tecrea',
    instagram: 'https://www.instagram.com/makiptecrea/',
    facebook: 'https://www.facebook.com/MakipCREA',
  },

  // Datos del proveedor exigidos por el Código de Protección y Defensa del Consumidor (completar con los datos reales).
  proveedor: {
    razonSocial: 'MAKIP TE CREA E.I.R.L.',
    ruc: '20608602811',
    direccion: 'Santa Rosa, Lima, Perú',
  },

  // Datos de demostración cuando la API no responde (solo desarrollo).
  useDemoFallback: true,
};
