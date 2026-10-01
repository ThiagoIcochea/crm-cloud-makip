// Configuración pública de la landing (no contiene secretos).
window.MAKIP_CONFIG = {
  // Número de WhatsApp en formato internacional sin "+" ni espacios, p. ej. "51XXXXXXXXX".
  // Lo proporciona la empresa; mientras esté vacío el botón mostrará un aviso.
  whatsappNumber: '',

  // URL base de la API de catálogo (Cloud Run). Vacío = mismo dominio (/api/catalogo).
  apiBase: '',

  // Redes sociales de la empresa (completar con los enlaces oficiales).
  social: {
    tiktok: '',
    instagram: '',
    facebook: '',
  },

  // Datos de demostración cuando la API no responde (solo desarrollo).
  useDemoFallback: true,
};
