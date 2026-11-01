# Informe de ejecución real

Ubicación ejecutada: C:\Users\panio\Documents\Curso\DataScience\Bbdd SQL. Fecha UTC: 2026-11-01T16:45:05.492809+00:00.

Python 3.14.5 (tags/v3.14.5:5607950, May 10 2026, 10:43:50) [MSC v.1944 64 bit (AMD64)]; SQLite 3.50.4. Modo: base temporal limpia.

| Tabla | Filas |
|---|---|
| dim_categorias | 5 |
| dim_productos | 10 |
| dim_clientes | 12 |
| dim_tiendas | 3 |
| dim_fecha | 227 |
| fact_ventas | 35 |

| Prueba | Estado |
|---|---|
| foreign_keys activado | PASS |
| foreign_key_check vacío | PASS |
| integrity_check ok | PASS |
| Todas las tablas tienen PK | PASS |
| RAW/CORE dim_categorias | PASS |
| RAW/CORE dim_productos | PASS |
| RAW/CORE dim_clientes | PASS |
| RAW/CORE dim_tiendas | PASS |
| RAW/CORE dim_fecha | PASS |
| RAW/CORE fact_ventas | PASS |
| Originales SHA256 intactos | PASS |
| Trazabilidad valores completos dim_categorias | PASS |
| Trazabilidad valores completos dim_productos | PASS |
| Trazabilidad valores completos dim_clientes | PASS |
| Trazabilidad valores completos dim_tiendas | PASS |
| Trazabilidad valores completos dim_fecha | PASS |
| Trazabilidad valores completos fact_ventas | PASS |
| Índice ix_sales_date | PASS |
| Índice ix_sales_product | PASS |
| Índice ix_sales_customer | PASS |
| Índice ix_sales_store | PASS |
| Índice ix_product_category | PASS |
| Cuatro FK de hechos y FK producto-categoría | PASS |
| Trece advertencias de origen identificadas | PASS |
| Rechazo PRIMARY KEY | PASS |
| Rechazo UNIQUE | PASS |
| Rechazo NOT NULL | PASS |
| Rechazo CHECK rango | PASS |
| Rechazo CHECK cantidad | PASS |
| Rechazo STRICT conversión inválida | PASS |
| Rechazo FOREIGN KEY | PASS |
| Rechazo CHECK fecha imposible | PASS |
| Rechazo trigger UPDATE | PASS |
| Rechazo trigger INSERT | PASS |
| ROLLBACK cambia estado dentro de transacción | PASS |
| ROLLBACK restaura todo CORE y RAW | PASS |
| DEFAULT activo | PASS |
| Función Python registrada | PASS |
| Vista vw_ventas_detalle | PASS |
| Vista vw_movimientos | PASS |
| Exactamente diez consultas | PASS |
| Consulta 01 ejecutada | PASS |
| Consulta 02 ejecutada | PASS |
| Consulta 03 ejecutada | PASS |
| Consulta 04 ejecutada | PASS |
| Consulta 05 ejecutada | PASS |
| Consulta 06 ejecutada | PASS |
| Consulta 07 ejecutada | PASS |
| Consulta 08 ejecutada | PASS |
| Consulta 09 ejecutada | PASS |
| Consulta 10 ejecutada | PASS |
| Control técnico Q2 | PASS |
| Control técnico Q3 | PASS |
| Control técnico Q4 | PASS |
| Control técnico Q5 | PASS |
| Control técnico Q8 | PASS |
| Detector de calendario detecta error inyectado | PASS |
| Detector de duplicados detecta línea inyectada | PASS |
| Pruebas de calidad no persisten | PASS |
| INSERT funcional | PASS |
| UPDATE funcional | PASS |
| DELETE funcional | PASS |
| Bruto, descuento y ventas conciliados con Decimal | PASS |
| Ventas, devoluciones y neto conciliados con Decimal | PASS |
| Movimientos: 35 ventas positivas y 4 devoluciones negativas | PASS |
| Regresión de redondeo: líneas 6 y 30 | PASS |
| Precios y descuentos de fuente admiten céntimos y puntos básicos | PASS |
| Resultados de 03_eda coinciden con informe | PASS |
| 03_eda completo ejecutado sin cambios persistentes | PASS |
| Segunda ejecución sin duplicados ni cambios | PASS |
| Venta bruta menos devolución igual a ingreso neto | PASS |

## Calidad observada

| clientes | sin_email | sin_ciudad |
|---|---|---|
| 12 | 1 | 3 |

| fecha_id | cliente_id | producto_id | tienda_id | cantidad | precio_unitario | n |
|---|---|---|---|---|---|---|

| fecha_id |
|---|

| venta_id |
|---|

| table | rowid | parent | fkid |
|---|---|---|---|

| target_table | raw_filas |
|---|---|
| dim_categorias | 5 |
| dim_clientes | 12 |
| dim_fecha | 227 |
| dim_productos | 10 |
| dim_tiendas | 3 |
| fact_ventas | 35 |

| venta_id | cliente_id | fecha | fecha_alta | dias_antes_alta |
|---|---|---|---|---|
| 1 | 2 | 2026-01-18 | 2026-02-02 | 15 |
| 2 | 4 | 2026-02-09 | 2026-03-03 | 22 |
| 4 | 5 | 2026-03-02 | 2026-03-15 | 13 |
| 5 | 6 | 2026-03-08 | 2026-04-12 | 35 |
| 7 | 7 | 2026-04-05 | 2026-05-05 | 30 |
| 8 | 8 | 2026-04-11 | 2026-06-01 | 51 |
| 10 | 9 | 2026-05-03 | 2026-06-15 | 43 |
| 11 | 10 | 2026-05-09 | 2026-05-18 | 9 |
| 12 | 9 | 2026-05-21 | 2026-06-15 | 25 |
| 25 | 2 | 2026-01-12 | 2026-02-02 | 21 |
| 30 | 5 | 2026-01-25 | 2026-03-15 | 49 |
| 31 | 5 | 2026-02-04 | 2026-03-15 | 39 |
| 32 | 8 | 2026-02-22 | 2026-06-01 | 99 |

| venta_id |
|---|

