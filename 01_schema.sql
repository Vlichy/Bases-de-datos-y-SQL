PRAGMA foreign_keys = ON;
-- ============================================================
-- PROYECTO FINAL SQL
-- Base de datos: tienda_impresion_3d
-- Script: 01_esquema.sql
--
-- Objetivo:
-- Crear la estructura de la base de datos, definiendo tablas,
-- claves primarias, claves foráneas, restricciones, índices,
-- vista, función almacenada y trigger.
--
-- Modelo:
-- Una tabla de hechos (fact_ventas) y cinco dimensiones.
-- ============================================================


-- ============================================================
-- 1. DIMENSIÓN CATEGORÍAS
-- ============================================================
-- Contiene las categorías comerciales de los productos.
-- PK: categoria_id, identificador único de cada categoría.

CREATE TABLE IF NOT EXISTS dim_categorias (
    categoria_id INTEGER PRIMARY KEY,
    nombre_categoria TEXT NOT NULL UNIQUE,
    descripcion TEXT
) STRICT;


-- ============================================================
-- 2. DIMENSIÓN PRODUCTOS
-- ============================================================
-- Contiene el catálogo de productos.
-- Cada producto pertenece a una categoría.

CREATE TABLE IF NOT EXISTS dim_productos (
    producto_id INTEGER PRIMARY KEY,
    nombre_producto TEXT NOT NULL,
    categoria_id INTEGER NOT NULL,
    precio_base REAL NOT NULL,
    coste_base REAL NOT NULL,
    activo INTEGER NOT NULL DEFAULT TRUE CHECK(activo IN (0,1)),

    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (categoria_id)
        REFERENCES dim_categorias(categoria_id),

    CONSTRAINT chk_precio_base
        CHECK (precio_base >= 0),

    CONSTRAINT chk_coste_base
        CHECK (coste_base >= 0)
) STRICT;


-- ============================================================
-- 3. DIMENSIÓN CLIENTES
-- ============================================================
-- Contiene los datos básicos de los clientes registrados.

CREATE TABLE IF NOT EXISTS dim_clientes (
    cliente_id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    apellido TEXT NOT NULL,
    email TEXT UNIQUE,
    ciudad TEXT,
    fecha_alta TEXT NOT NULL DEFAULT CURRENT_DATE
) STRICT;


-- ============================================================
-- 4. DIMENSIÓN TIENDAS / CANALES
-- ============================================================
-- Representa los distintos puntos o canales de venta.
-- Puede tratarse de una tienda física o del canal online.

CREATE TABLE IF NOT EXISTS dim_tiendas (
    tienda_id INTEGER PRIMARY KEY,
    nombre_tienda TEXT NOT NULL,
    ciudad TEXT,
    tipo_canal TEXT NOT NULL,

    CONSTRAINT chk_tipo_canal
        CHECK (tipo_canal IN ('FISICA', 'ONLINE'))
) STRICT;


-- ============================================================
-- 5. DIMENSIÓN FECHA
-- ============================================================
-- Calendario utilizado para facilitar los análisis temporales.

CREATE TABLE IF NOT EXISTS dim_fecha (
    fecha_id INTEGER PRIMARY KEY,
    fecha TEXT NOT NULL UNIQUE CHECK(date(fecha, '+0 days') IS NOT NULL AND date(fecha, '+0 days') = fecha),
    anio INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    nombre_mes TEXT NOT NULL,
    dia INTEGER NOT NULL,
    dia_semana TEXT NOT NULL,

    CONSTRAINT chk_trimestre
        CHECK (trimestre BETWEEN 1 AND 4),

    CONSTRAINT chk_mes
        CHECK (mes BETWEEN 1 AND 12),

    CONSTRAINT chk_dia
        CHECK (dia BETWEEN 1 AND 31)
) STRICT;


-- ============================================================
-- 6. TABLA DE HECHOS: VENTAS
-- ============================================================
-- Granularidad:
-- Cada fila representa la venta de un producto concreto
-- a un cliente concreto, en una fecha y canal determinados.
--
-- Además se almacena información sobre posibles devoluciones.

CREATE TABLE IF NOT EXISTS fact_ventas (
    venta_id INTEGER PRIMARY KEY,

    fecha_id INTEGER NOT NULL,
    cliente_id INTEGER NOT NULL,
    producto_id INTEGER NOT NULL,
    tienda_id INTEGER NOT NULL,

    cantidad INTEGER NOT NULL,
    precio_unitario REAL NOT NULL,
    coste_unitario REAL NOT NULL,
    descuento REAL NOT NULL DEFAULT 0,

    devuelto INTEGER NOT NULL DEFAULT FALSE,
    fecha_devolucion TEXT,
    motivo_devolucion TEXT,

    CONSTRAINT fk_venta_fecha
        FOREIGN KEY (fecha_id)
        REFERENCES dim_fecha(fecha_id),

    CONSTRAINT fk_venta_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES dim_clientes(cliente_id),

    CONSTRAINT fk_venta_producto
        FOREIGN KEY (producto_id)
        REFERENCES dim_productos(producto_id),

    CONSTRAINT fk_venta_tienda
        FOREIGN KEY (tienda_id)
        REFERENCES dim_tiendas(tienda_id),

    CONSTRAINT chk_cantidad
        CHECK (cantidad > 0 AND cantidad <= 1000000),

    CONSTRAINT chk_precio_unitario
        CHECK (precio_unitario >= 0),

    CONSTRAINT chk_coste_unitario
        CHECK (coste_unitario >= 0),

    CONSTRAINT chk_descuento
        CHECK (descuento BETWEEN 0 AND 100),

    CONSTRAINT chk_devolucion_fecha
        CHECK (devuelto IN (0,1)),
    CHECK (
            (devuelto = FALSE AND fecha_devolucion IS NULL)
            OR
            (devuelto = TRUE AND fecha_devolucion IS NOT NULL)
        )
) STRICT;


-- ============================================================

CREATE TABLE IF NOT EXISTS raw_statements (
 raw_id INTEGER PRIMARY KEY, source_file TEXT NOT NULL DEFAULT '02_carga.sql',
 source_line INTEGER NOT NULL UNIQUE, target_table TEXT NOT NULL,
 original_sql TEXT NOT NULL, sha256 TEXT NOT NULL CHECK(length(sha256)=64)
) STRICT;
-- Índices de FK: filtros de fecha, agrupación por producto, cliente y canal.
CREATE INDEX IF NOT EXISTS ix_sales_date ON fact_ventas(fecha_id);
CREATE INDEX IF NOT EXISTS ix_sales_product ON fact_ventas(producto_id);
CREATE INDEX IF NOT EXISTS ix_sales_customer ON fact_ventas(cliente_id);
CREATE INDEX IF NOT EXISTS ix_sales_store ON fact_ventas(tienda_id);
CREATE INDEX IF NOT EXISTS ix_product_category ON dim_productos(categoria_id);
CREATE TRIGGER IF NOT EXISTS validate_return_insert BEFORE INSERT ON fact_ventas
WHEN NEW.devuelto=1 AND (date(NEW.fecha_devolucion,'+0 days') IS NULL
 OR date(NEW.fecha_devolucion,'+0 days')<>NEW.fecha_devolucion
 OR NEW.fecha_devolucion < (SELECT fecha FROM dim_fecha WHERE fecha_id=NEW.fecha_id))
BEGIN SELECT RAISE(ABORT,'Fecha de devolución inválida'); END;
CREATE TRIGGER IF NOT EXISTS validate_return_update BEFORE UPDATE ON fact_ventas
WHEN NEW.devuelto=1 AND (date(NEW.fecha_devolucion,'+0 days') IS NULL
 OR date(NEW.fecha_devolucion,'+0 days')<>NEW.fecha_devolucion
 OR NEW.fecha_devolucion < (SELECT fecha FROM dim_fecha WHERE fecha_id=NEW.fecha_id))
BEGIN SELECT RAISE(ABORT,'Fecha de devolución inválida'); END;
-- Reconstrucción de vistas para aplicar cambios de definición de forma reproducible.
DROP VIEW IF EXISTS vw_movimientos;
DROP VIEW IF EXISTS vw_ventas_detalle;
-- Separación explícita: precio de tarifa, descuento e importe de venta.
-- importe_bruto se conserva como alias histórico de importe_venta (tras descuento).
CREATE VIEW IF NOT EXISTS vw_ventas_detalle AS
SELECT v.*, f.fecha, f.anio, f.mes, p.nombre_producto, cat.nombre_categoria,
 t.nombre_tienda, t.tipo_canal, c.nombre || ' ' || c.apellido AS cliente,
 ROUND(v.cantidad*v.precio_unitario,2) AS importe_antes_descuento,
 ROUND(ROUND(v.cantidad*v.precio_unitario,2)-((v.cantidad * CAST(ROUND(v.precio_unitario*100) AS INTEGER) * (10000-CAST(ROUND(v.descuento*100) AS INTEGER)) + 5000) / 10000) / 100.0,2) AS importe_descuento,
 ((v.cantidad * CAST(ROUND(v.precio_unitario*100) AS INTEGER) * (10000-CAST(ROUND(v.descuento*100) AS INTEGER)) + 5000) / 10000) / 100.0 AS importe_venta,
 ((v.cantidad * CAST(ROUND(v.precio_unitario*100) AS INTEGER) * (10000-CAST(ROUND(v.descuento*100) AS INTEGER)) + 5000) / 10000) / 100.0 AS importe_bruto,
 ROUND(v.cantidad*v.coste_unitario,2) AS coste_total
FROM fact_ventas v
INNER JOIN dim_fecha f ON f.fecha_id=v.fecha_id
INNER JOIN dim_productos p ON p.producto_id=v.producto_id
INNER JOIN dim_categorias cat ON cat.categoria_id=p.categoria_id
INNER JOIN dim_tiendas t ON t.tienda_id=v.tienda_id
LEFT JOIN dim_clientes c ON c.cliente_id=v.cliente_id;
-- Hipótesis explícita: devuelto=1 revierte la línea completa al mismo importe.
-- Cada devolución se fecha en su fecha real, no en la fecha de venta.
CREATE VIEW IF NOT EXISTS vw_movimientos AS
SELECT venta_id, fecha AS fecha_movimiento, 'VENTA' AS tipo,
 importe_bruto AS importe, cantidad AS unidades, producto_id,cliente_id,tienda_id
FROM vw_ventas_detalle
UNION ALL
SELECT venta_id, fecha_devolucion, 'DEVOLUCION', -importe_bruto, -cantidad,
 producto_id,cliente_id,tienda_id FROM vw_ventas_detalle WHERE devuelto=1;
