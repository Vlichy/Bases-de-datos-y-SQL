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

CREATE TABLE dim_categorias (
    categoria_id SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
);


-- ============================================================
-- 2. DIMENSIÓN PRODUCTOS
-- ============================================================
-- Contiene el catálogo de productos.
-- Cada producto pertenece a una categoría.

CREATE TABLE dim_productos (
    producto_id SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(150) NOT NULL,
    categoria_id INT NOT NULL,
    precio_base NUMERIC(10,2) NOT NULL,
    coste_base NUMERIC(10,2) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (categoria_id)
        REFERENCES dim_categorias(categoria_id),

    CONSTRAINT chk_precio_base
        CHECK (precio_base >= 0),

    CONSTRAINT chk_coste_base
        CHECK (coste_base >= 0)
);


-- ============================================================
-- 3. DIMENSIÓN CLIENTES
-- ============================================================
-- Contiene los datos básicos de los clientes registrados.

CREATE TABLE dim_clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    ciudad VARCHAR(100),
    fecha_alta DATE NOT NULL DEFAULT CURRENT_DATE
);


-- ============================================================
-- 4. DIMENSIÓN TIENDAS / CANALES
-- ============================================================
-- Representa los distintos puntos o canales de venta.
-- Puede tratarse de una tienda física o del canal online.

CREATE TABLE dim_tiendas (
    tienda_id SERIAL PRIMARY KEY,
    nombre_tienda VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100),
    tipo_canal VARCHAR(30) NOT NULL,

    CONSTRAINT chk_tipo_canal
        CHECK (tipo_canal IN ('FISICA', 'ONLINE'))
);


-- ============================================================
-- 5. DIMENSIÓN FECHA
-- ============================================================
-- Calendario utilizado para facilitar los análisis temporales.

CREATE TABLE dim_fecha (
    fecha_id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    anio INT NOT NULL,
    trimestre INT NOT NULL,
    mes INT NOT NULL,
    nombre_mes VARCHAR(20) NOT NULL,
    dia INT NOT NULL,
    dia_semana VARCHAR(20) NOT NULL,

    CONSTRAINT chk_trimestre
        CHECK (trimestre BETWEEN 1 AND 4),

    CONSTRAINT chk_mes
        CHECK (mes BETWEEN 1 AND 12),

    CONSTRAINT chk_dia
        CHECK (dia BETWEEN 1 AND 31)
);


-- ============================================================
-- 6. TABLA DE HECHOS: VENTAS
-- ============================================================
-- Granularidad:
-- Cada fila representa la venta de un producto concreto
-- a un cliente concreto, en una fecha y canal determinados.
--
-- Además se almacena información sobre posibles devoluciones.

CREATE TABLE fact_ventas (
    venta_id SERIAL PRIMARY KEY,

    fecha_id INT NOT NULL,
    cliente_id INT NOT NULL,
    producto_id INT NOT NULL,
    tienda_id INT NOT NULL,

    cantidad INT NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,
    coste_unitario NUMERIC(10,2) NOT NULL,
    descuento NUMERIC(5,2) NOT NULL DEFAULT 0,

    devuelto BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_devolucion DATE,
    motivo_devolucion VARCHAR(150),

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
        CHECK (cantidad > 0),

    CONSTRAINT chk_precio_unitario
        CHECK (precio_unitario >= 0),

    CONSTRAINT chk_coste_unitario
        CHECK (coste_unitario >= 0),

    CONSTRAINT chk_descuento
        CHECK (descuento BETWEEN 0 AND 100),

    CONSTRAINT chk_devolucion_fecha
        CHECK (
            (devuelto = FALSE AND fecha_devolucion IS NULL)
            OR
            (devuelto = TRUE AND fecha_devolucion IS NOT NULL)
        )
);


-- ============================================================
-- 7. ÍNDICES
-- ============================================================

-- Facilita búsquedas, filtros y agrupaciones de ventas por fecha.
CREATE INDEX idx_fact_ventas_fecha
ON fact_ventas(fecha_id);

-- Facilita análisis de ventas agrupadas por producto.
CREATE INDEX idx_fact_ventas_producto
ON fact_ventas(producto_id);


-- ============================================================
-- 8. VISTA DE VENTAS DETALLADAS
-- ============================================================
-- Centraliza los JOIN utilizados habitualmente y calcula
-- importe, coste y margen de cada línea de venta.

CREATE OR REPLACE VIEW vw_ventas_detalle AS
SELECT
    v.venta_id,
    f.fecha,
    c.nombre || ' ' || c.apellido AS cliente,
    p.nombre_producto,
    cat.nombre_categoria,
    t.nombre_tienda,
    t.tipo_canal,
    v.cantidad,
    v.precio_unitario,
    v.descuento,

    ROUND(
        v.cantidad
        * v.precio_unitario
        * (1 - v.descuento / 100),
        2
    ) AS importe_venta,

    ROUND(
        v.cantidad * v.coste_unitario,
        2
    ) AS coste_total,

    ROUND(
        (
            v.cantidad
            * v.precio_unitario
            * (1 - v.descuento / 100)
        )
        - (v.cantidad * v.coste_unitario),
        2
    ) AS margen,

    v.devuelto,
    v.fecha_devolucion,
    v.motivo_devolucion

FROM fact_ventas v

INNER JOIN dim_fecha f
    ON v.fecha_id = f.fecha_id

INNER JOIN dim_clientes c
    ON v.cliente_id = c.cliente_id

INNER JOIN dim_productos p
    ON v.producto_id = p.producto_id

INNER JOIN dim_categorias cat
    ON p.categoria_id = cat.categoria_id

INNER JOIN dim_tiendas t
    ON v.tienda_id = t.tienda_id;


-- ============================================================
-- 9. FUNCIÓN ALMACENADA
-- ============================================================
-- Calcula el importe neto de una venta teniendo en cuenta
-- cantidad, precio unitario y porcentaje de descuento.

CREATE OR REPLACE FUNCTION calcular_importe_venta(
    p_cantidad INT,
    p_precio NUMERIC,
    p_descuento NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN ROUND(
        p_cantidad
        * p_precio
        * (1 - p_descuento / 100),
        2
    );

END;
$$;


-- ============================================================
-- 10. FUNCIÓN DEL TRIGGER
-- ============================================================
-- Impide registrar una devolución con una fecha anterior
-- a la fecha original de venta.

CREATE OR REPLACE FUNCTION validar_fecha_devolucion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    fecha_venta DATE;
BEGIN

    IF NEW.devuelto = TRUE THEN

        SELECT fecha
        INTO fecha_venta
        FROM dim_fecha
        WHERE fecha_id = NEW.fecha_id;

        IF NEW.fecha_devolucion < fecha_venta THEN

            RAISE EXCEPTION
                'La fecha de devolución no puede ser anterior a la fecha de venta';

        END IF;

    END IF;

    RETURN NEW;

END;
$$;


-- ============================================================
-- 11. TRIGGER
-- ============================================================
-- Se ejecuta antes de INSERT o UPDATE sobre fact_ventas.

CREATE TRIGGER trg_validar_fecha_devolucion
BEFORE INSERT OR UPDATE
ON fact_ventas
FOR EACH ROW
EXECUTE FUNCTION validar_fecha_devolucion();