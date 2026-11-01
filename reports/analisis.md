# Diez análisis ejecutados

Datos sintéticos recuperados. Moneda: EUR según documentación original. Resultados calculados con SQLite, sin estimaciones.

## Q01. ¿Cómo evoluciona el ingreso neto mensual?

CTE encadenadas, SUM, GROUP BY y LAG; se agregan movimientos por fecha real.

```sql
WITH mensual AS (
SELECT strftime('%Y-%m',fecha_movimiento) AS mes,ROUND(SUM(importe),2) AS neto
FROM vw_movimientos GROUP BY 1), comparacion AS (
SELECT *,LAG(neto) OVER(ORDER BY mes) AS anterior FROM mensual)
SELECT *,ROUND(100.0*(neto-anterior)/NULLIF(anterior,0),2) AS variacion_pct FROM comparacion ORDER BY mes;
```

| mes | neto | anterior | variacion_pct |
|---|---|---|---|
| 2026-01 | 89.36 | NULL | NULL |
| 2026-02 | 140.51 | 89.36 | 57.24 |
| 2026-03 | 153.56 | 140.51 | 9.29 |
| 2026-04 | 80.6 | 153.56 | -47.51 |
| 2026-05 | 229.4 | 80.6 | 184.62 |
| 2026-06 | 158.71 | 229.4 | -30.82 |
| 2026-07 | 181.91 | 158.71 | 14.62 |
| 2026-08 | 144.2 | 181.91 | -20.73 |

Comparar meses permite planificar actividad, pero ocho meses sintéticos no prueban estacionalidad.

## Q02. ¿Qué categorías generan mayor ingreso neto?

JOIN de movimientos, productos y categorías; los reembolsos se restan.

```sql
SELECT c.nombre_categoria, ROUND(SUM(m.importe),2) AS neto
FROM vw_movimientos m INNER JOIN dim_productos p USING(producto_id)
INNER JOIN dim_categorias c USING(categoria_id) GROUP BY c.categoria_id ORDER BY neto DESC;
```

| nombre_categoria | neto |
|---|---|
| Figuras | 340.11 |
| Gaming | 300.17 |
| Personalizados | 196.56 |
| Hogar | 184.81 |
| Accesorios | 156.6 |

Priorizar la categoría líder, sujeto a validar demanda real y costes.

## Q03. ¿Qué productos acumulan más unidades brutas?

SUM y GROUP BY sobre líneas de venta, antes de devoluciones.

```sql
SELECT nombre_producto,SUM(cantidad) AS unidades_brutas,ROUND(SUM(importe_bruto),2) AS bruto
FROM vw_ventas_detalle GROUP BY producto_id ORDER BY unidades_brutas DESC,nombre_producto;
```

| nombre_producto | unidades_brutas | bruto |
|---|---|---|
| Soporte para móvil | 10 | 129.0 |
| Figura Dragón | 9 | 355.11 |
| Organizador de cables | 6 | 53.4 |
| Torre para dados | 6 | 179.4 |
| Maceta geométrica | 5 | 99.5 |
| Nombre personalizado | 5 | 89.5 |
| Soporte mando consola | 5 | 120.77 |
| Figura Guerrero | 3 | 104.7 |
| Miniatura personalizada | 3 | 161.96 |
| Lámpara decorativa | 2 | 85.31 |

El volumen bruto no equivale a demanda retenida; contrastar con las devoluciones de Q7.

## Q04. ¿Qué canal concentra el ingreso neto?

JOIN, CTE y ventana OVER para calcular participación sobre el total.

```sql
WITH canal AS (SELECT t.nombre_tienda,ROUND(SUM(m.importe),2) AS neto
FROM vw_movimientos m JOIN dim_tiendas t USING(tienda_id) GROUP BY t.tienda_id)
SELECT *,ROUND(100.0*neto/SUM(neto) OVER(),2) AS cuota_pct FROM canal ORDER BY neto DESC;
```

| nombre_tienda | neto | cuota_pct |
|---|---|---|
| Tienda Granada Centro | 727.64 | 61.76 |
| Tienda Málaga Centro | 270.2 | 22.93 |
| Tienda Online | 180.41 | 15.31 |

Concentrar recursos en el canal líder requiere antes corregir la discrepancia del README original.

## Q05. ¿Qué proporción de líneas termina devuelta?

COUNT, SUM y CASE WHEN; denominador explícito de líneas, no facturas.

```sql
SELECT COUNT(*) AS lineas,SUM(devuelto) AS devueltas,
ROUND(100.0*SUM(devuelto)/COUNT(*),2) AS pct_lineas,
ROUND(SUM(CASE WHEN devuelto=1 THEN importe_bruto ELSE 0 END),2) AS reembolso,
ROUND(100.0*SUM(CASE WHEN devuelto=1 THEN importe_bruto ELSE 0 END)/SUM(importe_bruto),2) AS pct_importe
FROM vw_ventas_detalle;
```

| lineas | devueltas | pct_lineas | reembolso | pct_importe |
|---|---|---|---|---|
| 35 | 4 | 11.43 | 200.4 | 14.54 |

La tasa es de líneas devueltas; no hay identificador de factura ni devoluciones parciales.

## Q06. ¿Qué clientes registrados no tienen compras?

LEFT JOIN para conservar clientes sin hechos.

```sql
SELECT c.cliente_id,c.nombre,c.apellido FROM dim_clientes c
LEFT JOIN fact_ventas v USING(cliente_id) WHERE v.venta_id IS NULL ORDER BY c.cliente_id;
```

| cliente_id | nombre | apellido |
|---|---|---|
| 1 | Lucía | Martín |
| 3 | Javier | Pérez |

Son candidatos a revisar en una campaña, pero las fechas de alta originales presentan incoherencias.

## Q07. ¿Qué productos presentan mayores devoluciones?

HAVING filtra grupos; CASE y SUM distinguen ventas de devoluciones.

```sql
SELECT nombre_producto,SUM(cantidad) AS unidades_brutas,
SUM(CASE WHEN devuelto=1 THEN cantidad ELSE 0 END) AS unidades_devueltas,
ROUND(SUM(CASE WHEN devuelto=1 THEN importe_bruto ELSE 0 END),2) AS reembolso
FROM vw_ventas_detalle GROUP BY producto_id HAVING SUM(devuelto)>0 ORDER BY reembolso DESC;
```

| nombre_producto | unidades_brutas | unidades_devueltas | reembolso |
|---|---|---|---|
| Figura Dragón | 9 | 3 | 119.7 |
| Miniatura personalizada | 3 | 1 | 54.9 |
| Soporte para móvil | 10 | 2 | 25.8 |

Investigar los motivos de devolución de los productos líderes; la muestra no permite inferir causalidad.

## Q08. ¿Qué clientes concentran más ingresos netos?

JOIN, agrupación y ventana acumulada para concentración.

```sql
WITH clientes AS (SELECT cliente_id,ROUND(SUM(importe),2) AS neto FROM vw_movimientos GROUP BY cliente_id)
SELECT c.cliente_id,d.nombre,c.neto,ROUND(100.0*SUM(c.neto) OVER(ORDER BY c.neto DESC,c.cliente_id ROWS UNBOUNDED PRECEDING)/SUM(c.neto) OVER(),2) AS cuota_acumulada_pct
FROM clientes c JOIN dim_clientes d USING(cliente_id) ORDER BY neto DESC,c.cliente_id;
```

| cliente_id | nombre | neto | cuota_acumulada_pct |
|---|---|---|---|
| 5 | Daniel | 285.32 | 24.22 |
| 2 | Laura | 264.01 | 46.62 |
| 6 | Sergio | 132.9 | 57.9 |
| 8 | Ana | 124.5 | 68.47 |
| 10 | Rubén | 89.7 | 76.08 |
| 4 | Marta | 77.21 | 82.63 |
| 7 | Elena | 75.6 | 89.05 |
| 11 | Paula | 53.7 | 93.61 |
| 12 | Carlos | 40.41 | 97.04 |
| 9 | Mario | 34.9 | 100.0 |

La concentración identifica dependencia comercial, sin confundir ingreso con beneficio.

## Q09. ¿Cómo se ordenan los productos dentro de su categoría?

CTE encadenadas, RANK con OVER y PARTITION BY; sin categorías inventadas.

```sql
WITH producto AS (SELECT p.producto_id,p.nombre_producto,c.nombre_categoria,ROUND(SUM(m.importe),2) AS neto
FROM vw_movimientos m JOIN dim_productos p USING(producto_id) JOIN dim_categorias c USING(categoria_id)
GROUP BY p.producto_id), ranking AS (SELECT *,RANK() OVER(PARTITION BY nombre_categoria ORDER BY neto DESC) AS posicion FROM producto)
SELECT * FROM ranking ORDER BY nombre_categoria,posicion,producto_id;
```

| producto_id | nombre_producto | nombre_categoria | neto | posicion |
|---|---|---|---|---|
| 3 | Soporte para móvil | Accesorios | 103.2 | 1 |
| 4 | Organizador de cables | Accesorios | 53.4 | 2 |
| 1 | Figura Dragón | Figuras | 235.41 | 1 |
| 2 | Figura Guerrero | Figuras | 104.7 | 2 |
| 8 | Torre para dados | Gaming | 179.4 | 1 |
| 7 | Soporte mando consola | Gaming | 120.77 | 2 |
| 5 | Maceta geométrica | Hogar | 99.5 | 1 |
| 6 | Lámpara decorativa | Hogar | 85.31 | 2 |
| 10 | Miniatura personalizada | Personalizados | 107.06 | 1 |
| 9 | Nombre personalizado | Personalizados | 89.5 | 2 |

El ranking compara únicamente el catálogo sintético cargado, no todo un mercado.

## Q10. ¿Qué proporción de compradores repite líneas de compra?

Subconsulta, AVG, COUNT y CAST; recurrencia de líneas, no pedidos.

```sql
SELECT COUNT(*) AS compradores,SUM(CASE WHEN compras>1 THEN 1 ELSE 0 END) AS recurrentes,
ROUND(100.0*SUM(CASE WHEN compras>1 THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_recurrentes,
ROUND(AVG(CAST(compras AS REAL)),2) AS lineas_por_comprador
FROM (SELECT cliente_id,COUNT(*) AS compras FROM fact_ventas GROUP BY cliente_id);
```

| compradores | recurrentes | pct_recurrentes | lineas_por_comprador |
|---|---|---|---|
| 10 | 9 | 90.0 | 3.5 |

Varias líneas no demuestran varias facturas. No se puede calcular ticket medio por factura con esta fuente.

