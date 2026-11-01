# Proyecto Final de SQL — Tienda de impresión 3D

## 1. Descripción del proyecto

Este proyecto implementa una base de datos relacional en PostgreSQL para simular la actividad comercial de una tienda de productos fabricados mediante impresión 3D.

El objetivo es almacenar información sobre productos, categorías, clientes, tiendas/canales, fechas y ventas, manteniendo la integridad de los datos y permitiendo realizar análisis útiles para el negocio.

La base de datos se ha trabajado mediante DBeaver utilizando PostgreSQL como sistema gestor.

## 2. Origen de los datos

Los datos utilizados son sintéticos y representan un escenario ficticio de una tienda de impresión 3D.

Se incluyen distintas categorías y productos, clientes, dos tiendas físicas y un canal online, así como operaciones de venta realizadas entre enero y agosto de 2026.

También se incorporaron deliberadamente algunos problemas de calidad de datos para poder demostrar procesos de detección y limpieza.

## 3. Modelo de datos

El modelo sigue una estructura de tabla de hechos y dimensiones.

### Tabla de hechos

**fact_ventas**

Cada fila representa una línea de venta de un producto concreto a un cliente, en una fecha y canal determinados.

Incluye cantidad, precio unitario, coste unitario, descuento y datos relacionados con posibles devoluciones.

### Tablas de dimensión

**dim_categorias**  
Clasifica los productos según su categoría comercial.

**dim_productos**  
Contiene el catálogo de productos, sus precios, costes y categoría.

**dim_clientes**  
Contiene los datos básicos de los clientes registrados.

**dim_tiendas**  
Representa los distintos canales de venta: tiendas físicas y tienda online.

**dim_fecha**  
Dimensión calendario utilizada para facilitar los análisis temporales por año, mes y trimestre.

## 4. Integridad de datos

Todas las tablas disponen de una clave primaria.

La tabla `fact_ventas` utiliza claves foráneas para relacionarse con clientes, productos, tiendas y fechas.

Se han utilizado restricciones como `NOT NULL`, `UNIQUE`, `CHECK` y claves foráneas para evitar datos incoherentes, por ejemplo:

- cantidades de venta iguales o inferiores a cero;
- precios o costes negativos;
- descuentos fuera del intervalo 0–100;
- relaciones con registros inexistentes;
- inconsistencias en los datos de devolución.

También se creó un trigger para impedir que una devolución tenga una fecha anterior a la venta original.

## 5. Calidad y limpieza de datos

El análisis incluye controles para detectar:

- valores nulos;
- cadenas de texto `"NULL"` utilizadas incorrectamente como si fueran valores nulos;
- registros potencialmente duplicados;
- precios, costes, cantidades o descuentos fuera de rango;
- fechas de devolución incoherentes.

Los valores `"NULL"` encontrados en clientes se normalizan mediante `UPDATE`, aplicando tratamientos diferentes según el campo.

No todos los valores nulos se consideran errores. Por ejemplo, una tienda online puede tener una ciudad nula porque no representa una ubicación física.

## 6. Análisis de negocio

El proyecto contiene 11 consultas analíticas que estudian, entre otros aspectos:

- evolución mensual de la facturación;
- ingresos por categoría;
- productos más vendidos;
- margen generado por producto;
- devoluciones recientes;
- clientes registrados sin compras;
- facturación por tienda y canal;
- gasto medio por cliente comprador;
- ranking de productos dentro de cada categoría;
- evolución de la facturación frente al mes anterior;
- clasificación de productos según su nivel de demanda.

Entre los resultados obtenidos destacan:

- **Figuras** es la categoría con mayor facturación, con **459,81 €**.
- **Soporte para móvil** es el producto con mayor volumen de ventas, con **10 unidades**, mientras que **Figura Dragón** genera el mayor margen, con **224,61 €**.
- El canal **Tienda Online** genera **928,03 €**, aproximadamente el 67 % de la facturación total.
- En los últimos tres meses del periodo analizado se registraron **3 devoluciones sobre 18 ventas**, equivalentes al **16,67 %**.

## 7. Requisitos SQL incluidos

El proyecto utiliza, entre otros:

- `INSERT`, `UPDATE` y `DELETE`;
- `CAST`;
- funciones de fecha;
- `SUM`, `COUNT` y `AVG`;
- subconsultas;
- `INNER JOIN` y `LEFT JOIN`;
- `CASE`;
- CTEs encadenadas;
- `RANK`, `DENSE_RANK`, `PARTITION BY` y `LAG`;
- transacciones y `ROLLBACK`;
- índices;
- vistas;
- funciones almacenadas;
- triggers.

## 8. Archivos del proyecto

```text
proyecto_sql/
├── 00_CreacionBBDD.sql
├── 01_esquema.sql
├── 02_carga.sql
├── 03_eda_analisis.sql
└── README.md
```

### 00_CreacionBBDD.sql

Crea la base de datos `tienda_impresion_3d`. Debe ejecutarse conectado previamente a una base existente del servidor PostgreSQL, por ejemplo `postgres`.

PostgreSQL no dispone de `CREATE DATABASE IF NOT EXISTS`, por lo que antes de ejecutar el `CREATE DATABASE` puede comprobarse si la base ya existe con:

```sql
SELECT datname
FROM pg_database
WHERE datname = 'tienda_impresion_3d';
```

Si la consulta devuelve una fila, la base ya existe y no debe volver a ejecutarse el `CREATE DATABASE`.

### 01_esquema.sql

Crea las tablas, relaciones, restricciones, índices, vista, función almacenada y trigger.

### 02_carga.sql

Carga los datos utilizados en el proyecto.

### 03_eda_analisis.sql

Contiene las validaciones de calidad, operaciones de limpieza, ejemplos de manipulación y las consultas analíticas de negocio.

## 9. Orden de ejecución

Para reconstruir el proyecto desde cero:

### Paso 1. Crear la base de datos

Conectarse a una base existente del servidor PostgreSQL, por ejemplo `postgres`, y ejecutar:

```sql
SELECT datname
FROM pg_database
WHERE datname = 'tienda_impresion_3d';
```

Si no devuelve ninguna fila, ejecutar `00_CreacionBBDD.sql`:

```sql
CREATE DATABASE tienda_impresion_3d;
```

Si la base ya existe, no es necesario volver a crearla.

### Paso 2. Conectarse a la nueva base

En DBeaver, seleccionar o abrir una conexión a:

```text
tienda_impresion_3d
```

Los siguientes scripts deben ejecutarse dentro de esta base de datos.

### Paso 3. Crear el esquema

Ejecutar:

```text
01_esquema.sql
```

Este script crea las tablas, claves primarias y foráneas, restricciones, índices y demás objetos del modelo.

### Paso 4. Cargar los datos

Ejecutar:

```text
02_carga.sql
```

Este script incorpora los datos sintéticos utilizados por el proyecto.

### Paso 5. Ejecutar la limpieza y el análisis

Ejecutar:

```text
03_eda_analisis.sql
```

Este script realiza las validaciones de calidad, las operaciones de limpieza y las 11 consultas analíticas de negocio.

Por tanto, el orden completo es:

```text
00_CreacionBBDD.sql
        ↓
01_esquema.sql
        ↓
02_carga.sql
        ↓
03_eda_analisis.sql
```

Para realizar una prueba completa desde cero se recomienda utilizar una base vacía y ejecutar los scripts siguiendo exactamente este orden.
