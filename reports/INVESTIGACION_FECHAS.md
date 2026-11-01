# Investigación de ventas anteriores al alta

## Conclusión y clasificación

Las trece discrepancias ya existen en los INSERT de la fuente sintética, reproducidos con sus claves originales. La comparación de todos los valores RAW/CORE y de los hashes descarta que se hayan introducido al copiar, transformar o migrar a SQLite. Son advertencias semánticas de origen, no fallos de ejecución o integridad referencial.

El esquema original usa `fecha_alta DATE NOT NULL DEFAULT CURRENT_DATE` y describe clientes registrados, pero no define el alta como primera compra, no impone alta≤venta y no prohíbe comprar antes de crear una cuenta. Bajo la interpretación «inicio de la relación comercial» estas filas serían incoherentes; bajo «registro de cuenta posterior» podrían ser legítimas. La fuente no permite elegir entre ambas interpretaciones.

Es compatible con una generación sintética sin validación temporal, pero no se encontró un generador del caso ni documentación que lo demuestre. Por tanto no se atribuye la causa exacta al generador ni se declara incorrecta una regla universal que la fuente no contiene. Falta confirmar la semántica con el autor. Las claves se conservan; no se desplazan clientes para encajar fechas.

## Correcciones justificadas

Se corrige la clasificación del control: advertencia, no error probado. Se añaden desfases e identificación exacta y una prueba que exige detectar las trece líneas. No se cambian fechas originales, ni se sustituye alta por MIN(fecha_venta), ni se excluyen ventas del ingreso. Una primera compra observada sería una métrica distinta de fecha de alta. Hasta aclarar el significado, no se presentan métricas de antigüedad o captación basadas en alta.

## Evidencia ejecutada

```sql
SELECT v.venta_id,c.cliente_id,c.nombre,f.fecha,c.fecha_alta,CAST(julianday(c.fecha_alta)-julianday(f.fecha) AS INTEGER) AS dias_antes_alta FROM fact_ventas v JOIN dim_clientes c USING(cliente_id) JOIN dim_fecha f USING(fecha_id) WHERE f.fecha<c.fecha_alta ORDER BY v.venta_id;
```

| venta_id | cliente_id | nombre | venta | alta | días antes |
|---|---|---|---|---|---|
| 1 | 2 | Laura | 2026-01-18 | 2026-02-02 | 15 |
| 2 | 4 | Marta | 2026-02-09 | 2026-03-03 | 22 |
| 4 | 5 | Daniel | 2026-03-02 | 2026-03-15 | 13 |
| 5 | 6 | Sergio | 2026-03-08 | 2026-04-12 | 35 |
| 7 | 7 | Elena | 2026-04-05 | 2026-05-05 | 30 |
| 8 | 8 | Ana | 2026-04-11 | 2026-06-01 | 51 |
| 10 | 9 | Mario | 2026-05-03 | 2026-06-15 | 43 |
| 11 | 10 | Rubén | 2026-05-09 | 2026-05-18 | 9 |
| 12 | 9 | Mario | 2026-05-21 | 2026-06-15 | 25 |
| 25 | 2 | Laura | 2026-01-12 | 2026-02-02 | 21 |
| 30 | 5 | Daniel | 2026-01-25 | 2026-03-15 | 49 |
| 31 | 5 | Daniel | 2026-02-04 | 2026-03-15 | 39 |
| 32 | 8 | Ana | 2026-02-22 | 2026-06-01 | 99 |

Clientes afectados: 8. Líneas: 13 de 35.
