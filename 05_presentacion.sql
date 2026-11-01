-- Solo tres preguntas seleccionadas de las diez principales; no son análisis nuevos.
PRAGMA foreign_keys=ON;
-- Q2: ¿Qué categorías generan mayor ingreso neto?
SELECT c.nombre_categoria, ROUND(SUM(m.importe),2) AS neto
FROM vw_movimientos m INNER JOIN dim_productos p USING(producto_id)
INNER JOIN dim_categorias c USING(categoria_id) GROUP BY c.categoria_id ORDER BY neto DESC;

-- Q4: ¿Qué canal concentra el ingreso neto?
WITH canal AS (SELECT t.nombre_tienda,ROUND(SUM(m.importe),2) AS neto
FROM vw_movimientos m JOIN dim_tiendas t USING(tienda_id) GROUP BY t.tienda_id)
SELECT *,ROUND(100.0*neto/SUM(neto) OVER(),2) AS cuota_pct FROM canal ORDER BY neto DESC;

-- Q5: ¿Qué proporción de líneas termina devuelta?
SELECT COUNT(*) AS lineas,SUM(devuelto) AS devueltas,
ROUND(100.0*SUM(devuelto)/COUNT(*),2) AS pct_lineas,
ROUND(SUM(CASE WHEN devuelto=1 THEN importe_bruto ELSE 0 END),2) AS reembolso,
ROUND(100.0*SUM(CASE WHEN devuelto=1 THEN importe_bruto ELSE 0 END)/SUM(importe_bruto),2) AS pct_importe
FROM vw_ventas_detalle;