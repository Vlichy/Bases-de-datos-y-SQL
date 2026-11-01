-- ============================================================
-- PROYECTO FINAL SQL
-- Base de datos: tienda_impresion_3d
-- Script: 03_eda_analisis.sql
--
-- Objetivo:
-- Validar la calidad de los datos, realizar operaciones de
-- limpieza y responder preguntas de negocio mediante SQL.
-- ============================================================

-- ============================================================
-- 1. VALIDACIÓN DE CALIDAD DE DATOS
-- ============================================================

-- 1.1 Detectar valores almacenados incorrectamente como texto 'NULL'
-- El apellido es obligatorio por diseño (NOT NULL), por lo que
-- los problemas de calidad se buscan en campos que sí admiten ausencia.
SELECT *
FROM dim_clientes
WHERE email = 'NULL'
   OR ciudad = 'NULL';

-- 1.2 Detectar valores NULL reales después de la normalización
SELECT *
FROM dim_clientes
WHERE apellido IS NULL
   OR email IS NULL
   OR ciudad IS NULL;

-- 1.3 Validar NULL legítimos en tiendas
SELECT *
FROM dim_tiendas
WHERE ciudad IS NULL;

-- 1.4 Detectar emails duplicados
SELECT
    email,
    COUNT(*) AS repeticiones
FROM dim_clientes
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;

-- 1.5 Detectar productos duplicados por nombre
SELECT
    nombre_producto,
    COUNT(*) AS repeticiones
FROM dim_productos
GROUP BY nombre_producto
HAVING COUNT(*) > 1;

-- 1.6 Detectar valores fuera de rango en productos
SELECT *
FROM dim_productos
WHERE precio_base < 0
   OR coste_base < 0;

-- 1.7 Detectar valores fuera de rango en ventas
SELECT *
FROM fact_ventas
WHERE cantidad <= 0
   OR precio_unitario < 0
   OR coste_unitario < 0
   OR descuento NOT BETWEEN 0 AND 100;

-- 1.8 Validar coherencia temporal de devoluciones
SELECT
    v.venta_id,
    f.fecha AS fecha_venta,
    v.fecha_devolucion
FROM fact_ventas v
INNER JOIN dim_fecha f
    ON v.fecha_id = f.fecha_id
WHERE v.fecha_devolucion < f.fecha;

-- 1.9 Mostrar devoluciones válidas existentes
SELECT
    v.venta_id,
    f.fecha AS fecha_venta,
    v.fecha_devolucion,
    v.motivo_devolucion
FROM fact_ventas v
INNER JOIN dim_fecha f
    ON v.fecha_id = f.fecha_id
WHERE v.devuelto = TRUE
ORDER BY v.fecha_devolucion;

-- ============================================================
-- 2. LIMPIEZA Y MANIPULACIÓN
-- ============================================================

-- 2.1 REQUISITO: UPDATE
UPDATE dim_clientes
SET
    email = NULLIF(email, 'NULL'),
    ciudad = NULLIF(ciudad, 'NULL')
WHERE email = 'NULL'
   OR ciudad = 'NULL';

UPDATE dim_clientes
SET ciudad = 'Desconocida'
WHERE ciudad IS NULL;

SELECT *
FROM dim_clientes
WHERE apellido = 'Desconocido'
   OR email IS NULL
   OR ciudad = 'Desconocida';

-- 2.2 REQUISITOS: INSERT Y DELETE
INSERT INTO dim_clientes
(nombre, apellido, email, ciudad, fecha_alta)
VALUES
('Cliente', 'Prueba', 'cliente.prueba@email.com', 'Málaga', CURRENT_DATE);

SELECT *
FROM dim_clientes
WHERE email = 'cliente.prueba@email.com';

DELETE FROM dim_clientes
WHERE email = 'cliente.prueba@email.com';

SELECT *
FROM dim_clientes
WHERE email = 'cliente.prueba@email.com';

-- 2.3 REQUISITO: CAST
SELECT
    venta_id,
    precio_unitario,
    CAST(precio_unitario AS NUMERIC(10,2)) AS precio_formateado
FROM fact_ventas
ORDER BY venta_id;

-- 2.4 REQUISITO: FUNCIONES DE FECHA
SELECT DISTINCT
    EXTRACT(YEAR FROM fecha) AS anio,
    EXTRACT(MONTH FROM fecha) AS mes,
    EXTRACT(QUARTER FROM fecha) AS trimestre,
    TO_CHAR(fecha, 'TMMonth') AS nombre_mes
FROM dim_fecha
ORDER BY anio, mes;

-- ============================================================
-- 3. TRANSACCIÓN Y ROLLBACK
-- ============================================================

SELECT
    producto_id,
    nombre_producto,
    precio_base
FROM dim_productos
WHERE producto_id = 1;

BEGIN;

UPDATE dim_productos
SET precio_base = precio_base * 1.10
WHERE producto_id = 1;

SELECT
    producto_id,
    nombre_producto,
    precio_base
FROM dim_productos
WHERE producto_id = 1;

ROLLBACK;

SELECT
    producto_id,
    nombre_producto,
    precio_base
FROM dim_productos
WHERE producto_id = 1;

-- ============================================================
-- 4. CONSULTAS ANALÍTICAS DE NEGOCIO
-- ============================================================

-- CONSULTA 1: ¿Cómo evoluciona la facturación mensual?
SELECT
    f.anio,
    f.mes,
    f.nombre_mes,
    ROUND(
        SUM(v.cantidad * v.precio_unitario * (1 - v.descuento / 100)),
        2
    ) AS facturacion
FROM fact_ventas v
INNER JOIN dim_fecha f
    ON v.fecha_id = f.fecha_id
GROUP BY f.anio, f.mes, f.nombre_mes
ORDER BY f.anio, f.mes;

-- CONSULTA 2: ¿Qué categorías generan más ingresos?
SELECT
    c.nombre_categoria,
    ROUND(
        SUM(v.cantidad * v.precio_unitario * (1 - v.descuento / 100)),
        2
    ) AS ingresos
FROM fact_ventas v
INNER JOIN dim_productos p
    ON v.producto_id = p.producto_id
INNER JOIN dim_categorias c
    ON p.categoria_id = c.categoria_id
GROUP BY c.nombre_categoria
ORDER BY ingresos DESC;

-- CONSULTA 3: ¿Cuáles son los productos más vendidos?
SELECT
    p.nombre_producto,
    SUM(v.cantidad) AS unidades_vendidas
FROM fact_ventas v
INNER JOIN dim_productos p
    ON v.producto_id = p.producto_id
GROUP BY p.producto_id, p.nombre_producto
ORDER BY unidades_vendidas DESC;

-- CONSULTA 4: ¿Qué productos generan mayor margen?
SELECT
    p.nombre_producto,
    ROUND(
        SUM(
            v.cantidad *
            (
                v.precio_unitario * (1 - v.descuento / 100)
                - v.coste_unitario
            )
        ),
        2
    ) AS margen_total
FROM fact_ventas v
INNER JOIN dim_productos p
    ON v.producto_id = p.producto_id
GROUP BY p.producto_id, p.nombre_producto
ORDER BY margen_total DESC;

-- CONSULTA 5: devoluciones en los últimos tres meses del periodo analizado
SELECT
    COUNT(*) FILTER (WHERE v.devuelto = TRUE) AS devoluciones,
    COUNT(*) AS ventas_totales,
    ROUND(
        COUNT(*) FILTER (WHERE v.devuelto = TRUE) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS porcentaje_devoluciones
FROM fact_ventas v
INNER JOIN dim_fecha f
    ON v.fecha_id = f.fecha_id
WHERE f.fecha >= (
    SELECT MAX(fecha)
    FROM dim_fecha
) - INTERVAL '3 months';

SELECT
    c.nombre_categoria,
    COUNT(*) AS devoluciones
FROM fact_ventas v
INNER JOIN dim_productos p
    ON v.producto_id = p.producto_id
INNER JOIN dim_categorias c
    ON p.categoria_id = c.categoria_id
WHERE v.devuelto = TRUE
GROUP BY c.nombre_categoria
ORDER BY devoluciones DESC;

-- CONSULTA 6: clientes sin compras
SELECT
    c.cliente_id,
    c.nombre,
    c.apellido,
    c.email
FROM dim_clientes c
LEFT JOIN fact_ventas v
    ON c.cliente_id = v.cliente_id
WHERE v.venta_id IS NULL
ORDER BY c.cliente_id;

-- CONSULTA 7: facturación por tienda/canal
SELECT
    t.nombre_tienda,
    t.tipo_canal,
    ROUND(
        SUM(v.cantidad * v.precio_unitario * (1 - v.descuento / 100)),
        2
    ) AS facturacion
FROM fact_ventas v
INNER JOIN dim_tiendas t
    ON v.tienda_id = t.tienda_id
GROUP BY t.tienda_id, t.nombre_tienda, t.tipo_canal
ORDER BY facturacion DESC;

-- CONSULTA 8: gasto medio por cliente comprador
SELECT
    ROUND(AVG(total_cliente), 2) AS gasto_medio_cliente
FROM (
    SELECT
        cliente_id,
        SUM(cantidad * precio_unitario * (1 - descuento / 100)) AS total_cliente
    FROM fact_ventas
    GROUP BY cliente_id
) AS gasto_por_cliente;

-- CONSULTA 9: ranking de productos dentro de cada categoría
WITH ventas_producto AS (
    SELECT
        c.nombre_categoria,
        p.nombre_producto,
        SUM(v.cantidad) AS unidades_vendidas
    FROM fact_ventas v
    INNER JOIN dim_productos p
        ON v.producto_id = p.producto_id
    INNER JOIN dim_categorias c
        ON p.categoria_id = c.categoria_id
    GROUP BY c.nombre_categoria, p.nombre_producto
),
ranking_productos AS (
    SELECT
        nombre_categoria,
        nombre_producto,
        unidades_vendidas,
        RANK() OVER (
            PARTITION BY nombre_categoria
            ORDER BY unidades_vendidas DESC
        ) AS posicion
    FROM ventas_producto
)
SELECT *
FROM ranking_productos
ORDER BY nombre_categoria, posicion;

-- CONSULTA 10: evolución frente al mes anterior
WITH ventas_mensuales AS (
    SELECT
        f.anio,
        f.mes,
        ROUND(
            SUM(v.cantidad * v.precio_unitario * (1 - v.descuento / 100)),
            2
        ) AS facturacion
    FROM fact_ventas v
    INNER JOIN dim_fecha f
        ON v.fecha_id = f.fecha_id
    GROUP BY f.anio, f.mes
),
comparacion AS (
    SELECT
        anio,
        mes,
        facturacion,
        LAG(facturacion) OVER (
            ORDER BY anio, mes
        ) AS facturacion_mes_anterior
    FROM ventas_mensuales
)
SELECT
    anio,
    mes,
    facturacion,
    facturacion_mes_anterior,
    ROUND(
        (facturacion - facturacion_mes_anterior) * 100.0
        / NULLIF(facturacion_mes_anterior, 0),
        2
    ) AS variacion_porcentual
FROM comparacion
ORDER BY anio, mes;

-- CONSULTA 11: clasificación de productos según demanda
WITH ventas_producto AS (
    SELECT
        p.nombre_producto,
        SUM(v.cantidad) AS unidades_vendidas
    FROM fact_ventas v
    INNER JOIN dim_productos p
        ON v.producto_id = p.producto_id
    GROUP BY p.producto_id, p.nombre_producto
)
SELECT
    nombre_producto,
    unidades_vendidas,
    CASE
        WHEN unidades_vendidas >= 8 THEN 'ALTA'
        WHEN unidades_vendidas >= 4 THEN 'MEDIA'
        ELSE 'BAJA'
    END AS nivel_demanda,
    DENSE_RANK() OVER (
        ORDER BY unidades_vendidas DESC
    ) AS ranking
FROM ventas_producto
ORDER BY ranking, nombre_producto;
