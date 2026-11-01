# Presentación final — máximo seis minutos

Aplicación de las recomendaciones de Javier del 18 de junio comunicadas por el usuario. No se ha consultado una grabación. Empezar con `model.png` visible. Preparar antes la conexión SQLite y los resultados de Q2, Q4 y Q5; enseñar solo esos fragmentos de `03_eda.sql`. Las diez consultas permanecen en el proyecto.

Guion previsto para 5 minutos y 30 segundos, con 30 segundos de margen. Aproximadamente 600 palabras habladas más las pausas de demostración. La duración oral debe ensayarse con cronómetro; las preguntas van después de la exposición.

## 0:00–0:50 — Mostrar primero el modelo y situar el negocio

“Este es el modelo dimensional de una tienda de impresión 3D. En el centro, cada fila de fact_ventas representa una línea de venta, identificada por venta_id. Se relaciona con productos, clientes, tiendas y fechas. Las categorías se conectan al catálogo de productos. Así podemos analizar el mismo negocio desde varias perspectivas sin repetir todos los atributos en cada operación.

El caso utiliza datos sintéticos: 35 líneas de venta, diez productos, cinco categorías y tres tiendas. Recuperé el proyecto existente, conservé los originales y lo adapté a SQLite para ejecutarlo sin servidor.”

## 0:50–1:35 — Problema, implicaciones y necesidad

“La tienda necesita decidir qué categorías y canales priorizar y dónde investigar devoluciones. El problema es que una documentación previa atribuía el liderazgo al canal online y llamaba facturación a importes que incluían líneas posteriormente devueltas. Decidir con esas cifras podía orientar mal los recursos.

La solución separa cuatro capas: originales y trazabilidad en RAW, tablas relacionales en CORE, vistas con reglas económicas y diez consultas analíticas. La vista de movimientos suma ventas y resta devoluciones en su fecha. Asumo devolución completa porque no hay información de reembolsos parciales. El ingreso neto modelado no es beneficio.”

## 1:35–2:30 — Pregunta 1: ¿Qué categorías aportan más ingreso neto?

Mostrar Q2: SELECT, SUM, JOIN y GROUP BY; después las cinco filas de resultado.

“La primera pregunta es qué categorías aportan más ingreso neto. Uno movimientos, productos y categorías mediante sus claves, agrupo por categoría y sumo los importes firmados. Figuras lidera con 340,11 euros; Gaming aporta 300,17 euros.

Esto ayuda a priorizar la revisión del surtido y la disponibilidad. No demuestra qué categoría es más rentable, porque faltan costes completos. Al usar las categorías presentes en la fuente no invento segmentos comerciales ni confundo el catálogo sintético con la demanda de un mercado real.”

## 2:30–3:25 — Pregunta 2: ¿Qué canal concentra el ingreso neto?

Mostrar Q4: CTE y expresión SUM(neto) OVER(); después sus tres filas.

“La segunda pregunta es dónde se concentra el ingreso. La CTE calcula el total por tienda y la ventana permite dividir cada importe entre el total general sin perder las filas de detalle.

Granada Centro aporta 727,64 euros, el 61,76 por ciento del neto. Online aporta 180,41 euros, el 15,31 por ciento. Por tanto, los datos cargados contradicen el liderazgo online del README anterior. La utilidad empresarial es revisar la asignación de recursos y validar las claves de tienda antes de invertir. La conclusión describe lo que contiene la fuente; no cambia sus etiquetas para hacerlas coincidir con la narración anterior.”

## 3:25–4:25 — Pregunta 3: ¿Cuánto afectan las devoluciones?

Mostrar Q5: CASE WHEN, SUM y denominadores; después la única fila de resultado.

“La tercera pregunta es cuánto reducen las devoluciones el ingreso. Hay cuatro líneas devueltas de 35: el 11,43 por ciento. Su importe es 200,40 euros, el 14,54 por ciento de las ventas tras descuento. No son porcentajes de pedidos: la fuente no contiene facturas.

La conciliación distingue precio antes de descuento, descuento, venta tras descuento, devolución e ingreso neto. Los reembolsos se restan una sola vez y en su fecha real. Este resultado orienta una revisión de los motivos de devolución y del proceso de calidad, sin demostrar por sí solo una causa. Con una muestra sintética tan pequeña no podemos generalizar la tasa a una empresa real.”

## 4:25–5:30 — Evidencia, límites y cierre

“He reconstruido la base desde cero, ejecutado las diez consultas y probado claves, restricciones, índices y vistas. También he demostrado INSERT, UPDATE, DELETE y una modificación que desaparece tras ROLLBACK. La segunda carga conserva exactamente el mismo contenido. El ZIP se ha extraído y ejecutado fuera de la ubicación original.

Investigué trece ventas anteriores a la fecha de alta: ya están así en la fuente, y esta no define si el alta significa primera relación comercial o creación posterior de una cuenta. Por eso las señalo y no invento fechas corregidas. Afectan a estudios de antigüedad, pero no alteran la suma económica de las operaciones.

La entrega permite defender las decisiones desde SQL: qué categoría lidera, qué tienda concentra el ingreso y qué impacto tienen las devoluciones. Antes de usarla para decisiones reales, habría que confirmar la semántica de las fechas y sustituir la simulación por datos de negocio validados.”

## Cinco posibles preguntas del profesor

1. **¿Por qué venta_id y no factura?** Una factura puede tener varias líneas y esta fuente ni siquiera contiene factura. Cada PK identifica una línea; no fabrico tickets ni recurrencia de pedidos.
2. **¿Cómo verificas las FK y el ROLLBACK?** PRAGMA foreign_keys=ON en cada conexión, foreign_key_check vacío y prueba de FK inexistente rechazada. Para ROLLBACK comparo el estado completo antes, durante y después de la transacción.
3. **¿Qué aportan CTE y ventanas?** En Q4 la CTE separa el agregado por canal y OVER calcula el total general conservando las tres filas. Q9, fuera de la presentación, usa PARTITION BY para reiniciar el ranking por categoría.
4. **¿Por qué no corregiste las trece fechas?** El problema se reproduce desde los INSERT originales; no hay una regla alta≤venta declarada ni un generador disponible. Cambiar fechas supondría inventar información. Mantengo la advertencia y evito análisis de antigüedad no fiables.
5. **¿Cuál es la diferencia entre bruto y neto y qué limita SQLite?** Separo tarifa, descuento, venta tras descuento y devolución; el neto resta reembolsos y no equivale a beneficio. SQLite no tiene CREATE FUNCTION almacenada; registro una escalar Python con Decimal y la pruebo. Las consultas no dependen de esa función. Para contabilidad de producción usaría importes enteros en céntimos.
