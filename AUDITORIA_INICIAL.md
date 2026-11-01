# Auditoría inicial — 1 de noviembre de 2026

Se inventariaron los archivos accesibles bajo Documents/Curso; inventario.json excluye entornos, dependencias y metadatos Git. No equivale a inspección semántica de todos los binarios. Se leyeron los cinco archivos del proyecto SQL, el README y limpieza del proyecto Python y cabecera del CSV. No se modifica la carpeta original.

| Elemento | Estado inicial | Evidencia |
|---|---|---|
| Proyecto SQL previo | EXISTE PERO REQUIERE CORRECCIONES. | Curso/Proyecto SQL, cinco archivos PostgreSQL, seis tablas y datos sintéticos |
| 01_schema.sql / 02_data.sql / 03_eda.sql | NO ENCONTRADO. | Existen equivalentes 01_esquema, 02_carga y 03_eda_analisis |
| Modelo, restricciones, índices | EXISTE PERO REQUIERE CORRECCIONES. | SERIAL, PL/pgSQL y CREATE OR REPLACE incompatibles con SQLite |
| Análisis | EXISTE PERO REQUIERE CORRECCIONES. | Once consultas; ingreso sin descontar devoluciones; resultados del README requieren contraste |
| RAW, segunda vista, diagrama, pruebas automáticas | NO ENCONTRADO. | No figuran entre los cinco archivos |
| Base SQLite .db / .sqlite del caso | NO ENCONTRADO. | Inventario por extensión y carpeta SQL |
| Ejecución anterior en PostgreSQL | NO VERIFICABLE CON EL ACCESO DISPONIBLE. | No se dispone de evidencia de ejecución ni conexión del servidor |
| CSV Python Online Retail | COMPLETO Y VERIFICADO. | DataScience/proyecto_python/data/processed/onlineRetail_clean.csv accesible y cabecera válida; conteo y hash en evidencia_datos.json |
| Código de limpieza Python | COMPLETO Y VERIFICADO. | src/cleaning.py conserva clientes desconocidos, cantidades negativas y documentos C; no reejecutado en esta auditoría |
| Git SQL | NO ENCONTRADO. | No hay .git en Curso/Proyecto SQL |
| Git de otros proyectos | COMPLETO Y VERIFICADO. | Remotos locales ML y online-retail-data-analysis; su existencia pública no se presupone |

Decisión: recuperar el caso existente, como exige la fase 2. Online Retail es preferente solo si el proyecto no existe. Se preservan los cinco originales con SHA256. No se mezclan datos reales con simulados. Se adapta y completa una entrega independiente en MachineLearning/proyecto_sql_final.
