-- Controles de calidad y análisis descriptivo. Nulos y anomalías no son siempre fallos técnicos.
PRAGMA foreign_keys=ON;
-- Q01: nulos legítimos, perfil descriptivo.
SELECT COUNT(*) AS clientes, SUM(email IS NULL) AS sin_email,SUM(ciudad IS NULL) AS sin_ciudad FROM dim_clientes;
-- Q02: duplicados potenciales de líneas (no se borran automáticamente).
SELECT fecha_id,cliente_id,producto_id,tienda_id,cantidad,precio_unitario,COUNT(*) AS n FROM fact_ventas GROUP BY fecha_id,cliente_id,producto_id,tienda_id,cantidad,precio_unitario HAVING COUNT(*)>1;
-- Q03: fechas y conversiones; STRICT rechaza tipos incompatibles en CORE.
SELECT fecha_id FROM dim_fecha WHERE date(fecha,'+0 days') IS NULL OR date(fecha,'+0 days')<>fecha OR CAST(strftime('%Y',fecha) AS INTEGER)<>anio OR CAST(strftime('%m',fecha) AS INTEGER)<>mes OR CAST(strftime('%d',fecha) AS INTEGER)<>dia OR (mes+2)/3<>trimestre;
-- Q04: rangos y coherencia de devoluciones.
SELECT venta_id FROM fact_ventas v JOIN dim_fecha f USING(fecha_id) WHERE cantidad<=0 OR precio_unitario<0 OR coste_unitario<0 OR descuento NOT BETWEEN 0 AND 100 OR (devuelto=1 AND (fecha_devolucion<f.fecha OR date(fecha_devolucion,'+0 days') IS NULL));
-- Q05: integridad referencial.
PRAGMA foreign_key_check;
-- Q06: coherencia RAW/CORE por entidad.
SELECT target_table,COUNT(*) AS raw_filas FROM raw_statements GROUP BY target_table ORDER BY target_table;
-- Q07: advertencia semántica de origen: venta previa al alta; no es una restricción universal.
SELECT v.venta_id,c.cliente_id,f.fecha,c.fecha_alta,CAST(julianday(c.fecha_alta)-julianday(f.fecha) AS INTEGER) AS dias_antes_alta FROM fact_ventas v JOIN dim_clientes c USING(cliente_id) JOIN dim_fecha f USING(fecha_id) WHERE f.fecha<c.fecha_alta;
-- Q08: campos de devolución incoherentes y rangos extremos para revisión.
SELECT venta_id FROM fact_ventas WHERE (devuelto=0 AND (fecha_devolucion IS NOT NULL OR motivo_devolucion IS NOT NULL)) OR cantidad>1000000 OR precio_unitario>1000000 OR coste_unitario>1000000;

-- Ejemplos DML aislados, sin alterar datos finales. BEGIN/COMMIT y ROLLBACK.
DROP TABLE IF EXISTS temp.demo;
CREATE TEMP TABLE IF NOT EXISTS demo(id INTEGER PRIMARY KEY, nota TEXT NOT NULL DEFAULT 'prueba');
BEGIN;
INSERT INTO demo(id) VALUES(1);
UPDATE demo SET nota='actualizado' WHERE id=1;
COMMIT;
BEGIN;
DELETE FROM demo WHERE id=1;
ROLLBACK;
SELECT COUNT(*) AS debe_ser_uno FROM demo;
DELETE FROM demo WHERE id=1;
DROP TABLE IF EXISTS temp.demo;

-- ANALISIS 01: ¿Cómo evoluciona el ingreso neto mensual?
-- Técnica: CTE encadenadas, SUM, GROUP BY y LAG; se agregan movimientos por fecha real.
-- Resultados e interpretación ampliada: reports/analisis.md, Q01.
-- Interpretación: Comparar meses permite planificar actividad, pero ocho meses sintéticos no prueban estacionalidad.
WITH mensual AS (
SELECT strftime('%Y-%m',fecha_movimiento) AS mes,ROUND(SUM(importe),2) AS neto
FROM vw_movimientos GROUP BY 1), comparacion AS (
SELECT *,LAG(neto) OVER(ORDER BY mes) AS anterior FROM mensual)
SELECT *,ROUND(100.0*(neto-anterior)/NULLIF(anterior,0),2) AS variacion_pct FROM comparacion ORDER BY mes;

-- ANALISIS 02: ¿Qué categorías generan mayor ingreso neto?
-- Técnica: JOIN de movimientos, productos y categorías; los reembolsos se restan.
-- Resultados e interpretación ampliada: reports/analisis.md, Q02.
-- Interpretación: Priorizar la categoría líder, sujeto a validar demanda real y costes.
SELECT c.nombre_categoria, ROUND(SUM(m.importe),2) AS neto
FROM vw_movimientos m INNER JOIN dim_productos p USING(producto_id)
INNER JOIN dim_categorias c USING(categoria_id) GROUP BY c.categoria_id ORDER BY neto DESC;

-- ANALISIS 03: ¿Qué productos acumulan más unidades brutas?
-- Técnica: SUM y GROUP BY sobre líneas de venta, antes de devoluciones.
-- Resultados e interpretación ampliada: reports/analisis.md, Q03.
-- Interpretación: El volumen bruto no equivale a demanda retenida; contrastar con las devoluciones de Q7.
SELECT nombre_producto,SUM(cantidad) AS unidades_brutas,ROUND(SUM(importe_bruto),2) AS bruto
FROM vw_ventas_detalle GROUP BY producto_id ORDER BY unidades_brutas DESC,nombre_producto;

-- ANALISIS 04: ¿Qué canal concentra el ingreso neto?
-- Técnica: JOIN, CTE y ventana OVER para calcular participación sobre el total.
-- Resultados e interpretación ampliada: reports/analisis.md, Q04.
-- Interpretación: Concentrar recursos en el canal líder requiere antes corregir la discrepancia del README original.
WITH canal AS (SELECT t.nombre_tienda,ROUND(SUM(m.importe),2) AS neto
FROM vw_movimientos m JOIN dim_tiendas t USING(tienda_id) GROUP BY t.tienda_id)
SELECT *,ROUND(100.0*neto/SUM(neto) OVER(),2) AS cuota_pct FROM canal ORDER BY neto DESC;

-- ANALISIS 05: ¿Qué proporción de líneas termina devuelta?
-- Técnica: COUNT, SUM y CASE WHEN; denominador explícito de líneas, no facturas.
-- Resultados e interpretación ampliada: reports/analisis.md, Q05.
-- Interpretación: La tasa es de líneas devueltas; no hay identificador de factura ni devoluciones parciales.
SELECT COUNT(*) AS lineas,SUM(devuelto) AS devueltas,
ROUND(100.0*SUM(devuelto)/COUNT(*),2) AS pct_lineas,
ROUND(SUM(CASE WHEN devuelto=1 THEN importe_bruto ELSE 0 END),2) AS reembolso,
ROUND(100.0*SUM(CASE WHEN devuelto=1 THEN importe_bruto ELSE 0 END)/SUM(importe_bruto),2) AS pct_importe
FROM vw_ventas_detalle;

-- ANALISIS 06: ¿Qué clientes registrados no tienen compras?
-- Técnica: LEFT JOIN para conservar clientes sin hechos.
-- Resultados e interpretación ampliada: reports/analisis.md, Q06.
-- Interpretación: Son candidatos a revisar en una campaña, pero las fechas de alta originales presentan incoherencias.
SELECT c.cliente_id,c.nombre,c.apellido FROM dim_clientes c
LEFT JOIN fact_ventas v USING(cliente_id) WHERE v.venta_id IS NULL ORDER BY c.cliente_id;

-- ANALISIS 07: ¿Qué productos presentan mayores devoluciones?
-- Técnica: HAVING filtra grupos; CASE y SUM distinguen ventas de devoluciones.
-- Resultados e interpretación ampliada: reports/analisis.md, Q07.
-- Interpretación: Investigar los motivos de devolución de los productos líderes; la muestra no permite inferir causalidad.
SELECT nombre_producto,SUM(cantidad) AS unidades_brutas,
SUM(CASE WHEN devuelto=1 THEN cantidad ELSE 0 END) AS unidades_devueltas,
ROUND(SUM(CASE WHEN devuelto=1 THEN importe_bruto ELSE 0 END),2) AS reembolso
FROM vw_ventas_detalle GROUP BY producto_id HAVING SUM(devuelto)>0 ORDER BY reembolso DESC;

-- ANALISIS 08: ¿Qué clientes concentran más ingresos netos?
-- Técnica: JOIN, agrupación y ventana acumulada para concentración.
-- Resultados e interpretación ampliada: reports/analisis.md, Q08.
-- Interpretación: La concentración identifica dependencia comercial, sin confundir ingreso con beneficio.
WITH clientes AS (SELECT cliente_id,ROUND(SUM(importe),2) AS neto FROM vw_movimientos GROUP BY cliente_id)
SELECT c.cliente_id,d.nombre,c.neto,ROUND(100.0*SUM(c.neto) OVER(ORDER BY c.neto DESC,c.cliente_id ROWS UNBOUNDED PRECEDING)/SUM(c.neto) OVER(),2) AS cuota_acumulada_pct
FROM clientes c JOIN dim_clientes d USING(cliente_id) ORDER BY neto DESC,c.cliente_id;

-- ANALISIS 09: ¿Cómo se ordenan los productos dentro de su categoría?
-- Técnica: CTE encadenadas, RANK con OVER y PARTITION BY; sin categorías inventadas.
-- Resultados e interpretación ampliada: reports/analisis.md, Q09.
-- Interpretación: El ranking compara únicamente el catálogo sintético cargado, no todo un mercado.
WITH producto AS (SELECT p.producto_id,p.nombre_producto,c.nombre_categoria,ROUND(SUM(m.importe),2) AS neto
FROM vw_movimientos m JOIN dim_productos p USING(producto_id) JOIN dim_categorias c USING(categoria_id)
GROUP BY p.producto_id), ranking AS (SELECT *,RANK() OVER(PARTITION BY nombre_categoria ORDER BY neto DESC) AS posicion FROM producto)
SELECT * FROM ranking ORDER BY nombre_categoria,posicion,producto_id;

-- ANALISIS 10: ¿Qué proporción de compradores repite líneas de compra?
-- Técnica: Subconsulta, AVG, COUNT y CAST; recurrencia de líneas, no pedidos.
-- Resultados e interpretación ampliada: reports/analisis.md, Q10.
-- Interpretación: Varias líneas no demuestran varias facturas. No se puede calcular ticket medio por factura con esta fuente.
SELECT COUNT(*) AS compradores,SUM(CASE WHEN compras>1 THEN 1 ELSE 0 END) AS recurrentes,
ROUND(100.0*SUM(CASE WHEN compras>1 THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_recurrentes,
ROUND(AVG(CAST(compras AS REAL)),2) AS lineas_por_comprador
FROM (SELECT cliente_id,COUNT(*) AS compras FROM fact_ventas GROUP BY cliente_id);
