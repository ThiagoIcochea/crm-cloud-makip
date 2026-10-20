# Gestión del proyecto en Trello

Tablero: https://trello.com/b/p78Xemzg/servicios-cloud-grupo-2 (privado; pedir acceso al equipo).

Flujo Kanban: **Por hacer → En proceso → Hecho**. Cada tarjeta tiene etiqueta de área, prioridad, responsable, descripción (objetivo, entregable y criterio de terminado) y subtareas.

## Responsabilidades por integrante

### Thiago Paolo Icochea Rodriguez — Líder del proyecto · Arquitectura GCP, IaC y CI/CD
- **Arquitectura GCP e infraestructura con Terraform**
  - [x] Diseñar la arquitectura en southamerica-west1 (red, cómputo, datos y servicios)
  - [x] Módulos Terraform: network, security, database, compute, cloudrun, observability y analytics
  - [x] Backend remoto del estado en Cloud Storage con versionado
  - [x] terraform plan y apply del entorno dev (72 recursos)
  - [x] IAM: integrantes como Editor y cuentas de servicio con mínimo privilegio
- **Repositorio, CI/CD y despliegue**
  - [x] Crear el repositorio crm-cloud-makip y su estructura
  - [x] CI en GitHub Actions: Terraform fmt/validate/tflint/checkov, Gitleaks, pruebas de la API y validación HTML
  - [x] Publicar la API y la landing en Cloud Run con Cloud Build
  - [x] Workflow de GitHub Pages para la landing de prueba
  - [x] Scripts probar_gcp, demo_gcp y destruir_gcp
- **Cierre del entorno cloud**
  - [x] Destruir la infraestructura con terraform destroy
  - [x] Eliminar restos (Cloud SQL, peering, IP serverless, VPC) con limpiar_restos_gcp.sh
  - [x] Verificar con inventario_gcp.sh que no queden recursos

### Carlos Enrique Giussepe Gonzales Aguilar — CRM y procesos comerciales (Odoo)
- **Configuración de Odoo CRM**
  - [x] Datos de la empresa, idioma es_PE, moneda PEN y logo
  - [x] Tarifa en soles e IGV 18 % en productos y cotizaciones
  - [x] Equipo de ventas con los cinco integrantes
  - [x] Pipeline de 12 etapas desde Nueva consulta hasta Entregado
  - [x] Carga del catálogo real de 43 productos con fotos y precios
- **Flujo comercial y cotizaciones**
  - [x] Modelar el flujo: consulta, cotización, adelanto del 50 %, diseño, producción y entrega
  - [x] Clientes, oportunidades y cotizaciones de prueba (datos ficticios)
  - [x] Validar el registro automático de consultas web en Odoo (MK-xxxx)
- **Fidelización de clientes en el CRM**
  - [x] Definir segmentos: frecuente, institución/colegio, potencial y por reactivar
  - [x] Etiquetas de segmento en los clientes
  - [x] Actividades de fidelización asignadas a la vendedora

### Eddyson Cesar Huamani Pereira — Landing, integración con WhatsApp y API
- **Landing y catálogo web**
  - [x] Diseño de la landing: encabezado, hero, catálogo con filtros y búsqueda
  - [x] Logotipo vectorizado (SVG) y favicon
  - [x] Vista móvil y accesibilidad (HTML válido)
  - [x] Pie con redes sociales, enlaces legales y datos del proveedor (RUC)
- **Pedido por WhatsApp**
  - [x] Lista de pedido con cantidades y total referencial
  - [x] Formulario: nombre, celular, recojo o delivery, fecha y personalización
  - [x] Mensaje estructurado con emojis hacia el WhatsApp de la empresa
  - [x] Abrir la app en celular y WhatsApp Web en computadora (sin página intermedia)
- **API de catálogo e integración con Odoo**
  - [x] API Node.js en Cloud Run que lee el catálogo de Odoo por JSON-RPC
  - [x] Endpoint /api/consultas que crea la oportunidad en Odoo
  - [x] Límite de envíos por minuto y validación de datos
  - [x] Pruebas automáticas de la API

### Huber Eduardo Remuzgo Tovar — Datos, observabilidad y costos
- **Analítica en BigQuery**
  - [x] Datasets makip_staging y makip_marts
  - [x] Extracción del resumen de clientes desde Odoo (dentro de la VPC)
  - [x] Carga en makip_staging.clientes_odoo
  - [x] Tabla makip_marts.segmentacion_clientes con la acción sugerida
- **Monitoreo y registros**
  - [x] Uptime check de la API desde varias regiones
  - [x] Políticas de alerta y canal de correo
  - [x] Registros estructurados de la API en Cloud Logging
  - [x] Revisión de disponibilidad del primer día
- **Análisis de costos**
  - [x] Estimación mensual con Google Cloud Pricing Calculator
  - [x] Comparación con un centro de datos local a tres años
  - [x] Recomendaciones de ahorro (apagado de la VM, compromisos de uso)

### Karen Meylin Quispe Saavedra — Calidad, aspectos legales y documentación
- **Pruebas y control de calidad**
  - [x] Plan y casos de prueba del flujo de punta a punta
  - [x] Prueba del pedido desde la landing hasta Odoo y WhatsApp
  - [x] Verificación de montos en soles e IGV en las cotizaciones
  - [x] Registro de evidencias con fecha y hora reales
- **Cumplimiento legal de la landing**
  - [x] Términos y condiciones (precios referenciales, adelanto, cambios)
  - [x] Política de privacidad según la Ley 29733
  - [x] Libro de Reclamaciones virtual según la Ley 29571
  - [x] Validar los datos del proveedor: MAKIP TE CREA E.I.R.L., RUC 20608602811
- **Documento final y presentación**
  - [x] Informe según la estructura del Proyecto Final Integrador
  - [x] Anexos: repositorio, tablero de Trello y evidencias
  - [x] Presentación para la sustentación

## Tarjetas de planificación y seguimiento

| Tarjeta | Área | Prioridad | Entregable |
|---|---|---|---|
| Realizar reunión inicial del equipo | Gestión y documentación | Alta | Acta con acuerdos y próximos pasos. |
| Registrar acuerdos de la reunión inicial | Gestión y documentación | Media | Acta en el documento compartido. |
| Definir el problema | Gestión y documentación | Alta | Sección 2.2 Problema identificado. |
| Analizar las causas del problema | Gestión y documentación | Media | Diagrama de causa y efecto (Ishikawa). |
| Analizar las consecuencias del problema | Gestión y documentación | Media | Lista de riesgos operativos, de información y de gestión. |
| Identificar procesos que gestionará el CRM | CRM Odoo | Alta | Pipeline de 12 etapas (comercial y operativo). |
| Definir requerimientos funcionales | Landing y WhatsApp | Alta | Tabla de requerimientos funcionales priorizados (MoSCoW). |
| Definir requerimientos no funcionales | Infraestructura y CI/CD | Alta | Tabla RNF-01 a RNF-10. |
| Validar requerimientos | CRM Odoo | Media | Requerimientos aprobados. |
| Priorizar requerimientos | CRM Odoo | Media | Clasificación MoSCoW. |
| Validar el alcance con el equipo | Gestión y documentación | Media | Alcance y exclusiones del proyecto. |
| Definir arquitectura general del CRM | Infraestructura y CI/CD | Alta | Diagrama de arquitectura (ver adjunto). |
| Diseñar dashboard | Datos, monitoreo y costos | Baja | Boceto del tablero en Looker Studio. |
| Crear repositorio del proyecto | Infraestructura y CI/CD | Alta | Repositorio crm-cloud-makip. |
| Configurar estructura del proyecto | Infraestructura y CI/CD | Media | Carpetas infra, api, web, app, analytics, scripts y docs. |
| Implementar dashboard | Datos, monitoreo y costos | Baja | Tablero en Looker Studio conectado a makip_marts. |
| Integrar servicios Cloud | Infraestructura y CI/CD | Alta | Flujo de punta a punta funcionando en GCP. |
| Elaborar plan de pruebas | Calidad y legal | Media | Plan de pruebas. |
| Definir casos de prueba | Calidad y legal | Media | Casos de prueba documentados. |
| Validar funcionamiento del CRM | CRM Odoo | Alta | Evidencias de pipeline, productos y cotizaciones. |
| Realizar pruebas finales | Calidad y legal | Alta | Capturas con fecha y hora reales. |
| Evaluar cumplimiento de requerimientos | Calidad y legal | Media | Matriz de cumplimiento. |
| Evaluar cumplimiento de objetivos | Gestión y documentación | Media | Conclusiones del informe. |
| Identificar oportunidades de mejora | Datos, monitoreo y costos | Baja | Recomendaciones del informe. |
| Realizar ensayo de presentación | Gestión y documentación | Alta | Presentación ensayada con tiempos. |
| Realizar reunión de revisión final | Gestión y documentación | Alta | Lista de verificación de entregables. |
| Realizar revisión final del documento | Calidad y legal | Alta | Documento en Word y PDF. |
| Elaborar el planteamiento del estudio | Gestión y documentación | Alta | Planteamiento del estudio. |
| Analizar costos de los servicios Cloud | Datos, monitoreo y costos | Media | Sección 10 Análisis costo-beneficio. |
| Asignar roles y responsabilidades | Gestión y documentación | Alta | Anexo D del informe y tarjetas por integrante. |
| Definir metodología de trabajo | Gestión y documentación | Media | Metodología ágil con tablero Kanban. |
| Definir tema del proyecto | Gestión y documentación | Alta | Tema aprobado: plataforma cloud para Makip Te Crea. |
| Crear tablero de Trello | Gestión y documentación | Media | Tablero Servicios Cloud Grupo 2. |
| Elaborar el enunciado del estudio | Gestión y documentación | Media | Enunciado del estudio. |
| Investigar la empresa | Gestión y documentación | Alta | Descripción de la organización. |
| Recopilar información de la empresa | Gestión y documentación | Alta | Fotos, precios y descripción de productos. |
| Analizar el contexto de la organización | Gestión y documentación | Media | Contexto de la organización. |
| Identificar usuarios de la organización | Gestión y documentación | Media | Mapa de usuarios. |
| Identificar procesos actuales | Gestión y documentación | Media | Flujo AS-IS. |
| Identificar problemas actuales | Gestión y documentación | Media | Problemas operativos y de información. |
| Identificar necesidades de los usuarios | Gestión y documentación | Media | Necesidades que guían los requerimientos. |
| Crear documento compartido del proyecto | Gestión y documentación | Media | Documento compartido. |
| Definir el objetivo general | Gestión y documentación | Alta | Objetivo general. |
| Definir los objetivos específicos | Gestión y documentación | Alta | Objetivos específicos. |
| Definir el alcance del proyecto | Gestión y documentación | Alta | Alcance del proyecto. |
| Definir las limitaciones del proyecto | Gestión y documentación | Baja | Limitaciones. |
| Definir las restricciones del proyecto | Gestión y documentación | Baja | Restricciones. |
| Definir modelo de implementación Cloud | Infraestructura y CI/CD | Media | Nube pública (Google Cloud). |
| Definir modelo de servicio Cloud | Infraestructura y CI/CD | Media | Modelo mixto: IaaS para Odoo y PaaS/serverless para el resto. |
| Estimar recursos necesarios | Datos, monitoreo y costos | Media | Tamaños de VM, base de datos y servicios. |
| Definir entregables | Calidad y legal | Media | Lista de entregables. |
| Definir entregables de la solución | Infraestructura y CI/CD | Media | Componentes de la solución. |
| Elaborar cronograma del proyecto | Calidad y legal | Media | Cronograma con hitos. |
