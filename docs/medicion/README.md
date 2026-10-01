# Medición (indicadores de investigación)

Diseño de comparación de la sección 16.3: 20 a 30 operaciones comerciales representativas, ejecutadas primero con el método manual vigente y luego con la plataforma, con datos ficticios o anonimizados.

| Indicador | Unidad | Archivo |
|---|---|---|
| Tiempo para localizar información de un cliente/pedido | minutos | `ficha_cronometraje.csv` |
| Tiempo de registro de un pedido | minutos | `ficha_cronometraje.csv` |
| Tiempo para generar el resumen semanal | minutos | `ficha_cronometraje.csv` |
| Registros incompletos o duplicados | n.° y % | `ficha_cronometraje.csv` (columna `incidencia`) |
| Pedidos sin estado conocido | n.° | `ficha_cronometraje.csv` (columna `estado_conocido`) |

Análisis: mediana, promedio y dispersión por indicador y modalidad (`analizar.py`).

Las metas (p. ej., reducción ≥ 40 % del tiempo de localización) son criterios de validación definidos antes de medir; los resultados se reportan solo después de la medición.
