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
