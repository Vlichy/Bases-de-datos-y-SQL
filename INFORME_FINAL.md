# Informe de entrega definitiva

Ubicación: `C:\Users\panio\Documents\Curso\DataScience\Bbdd SQL`. Raíz única para VS Code; sin subcarpetas duplicadas de proyecto. La copia previa y los cinco originales quedan conservados. El código no lee ninguna ruta externa al proyecto.

## Estructura

```text
Bbdd SQL/
├── .git/                       # Repositorio local, excluido del ZIP
├── .vscode/                    # Tareas, depuración y configuración
├── originales/                 # Cinco originales sin cambios
├── reports/                    # Auditoría, pruebas, resultados e investigación
├── 01_schema.sql
├── 02_data.sql
├── 03_eda.sql                  # Exactamente diez preguntas
├── 04_quality_checks.sql
├── 05_presentacion.sql          # Selección Q2, Q4 y Q5
├── run.py / run.ps1 / queries.json
├── tienda.sqlite
├── model.png / model.mmd
├── Bbdd SQL.code-workspace
├── README.md / PRESENTACION.md / MATRIZ_CUMPLIMIENTO.md
├── AUDITORIA_INICIAL.md / CAMBIOS.md / GITHUB.md / INFORME_FINAL.md
├── .gitignore / .gitattributes
└── entrega_sql_tienda_3d.zip (+ checksum SHA256)
```

## Traslado y modificaciones

Todos los archivos previos se copiaron y contrastaron antes de modificarlos; relación exacta en reports/traslado.json. Se trasladó también Git local. El trabajo anterior no se borró ni se modificó. Se actualizaron README, matriz, guion, esquema de vistas, controles 03/04, run.py, cambios y estado Git. Se añadieron lanzador, tareas VS Code, selección SQL, investigación de fechas, conciliación, este informe y evidencia de empaquetado. Las rutas antiguas en auditoría e inventario son procedencia histórica, no instrucciones de ejecución.

## Ejecución y cumplimiento

71 comprobaciones PASS por ejecución: siete tablas (seis CORE y RAW), cinco FK, cinco índices de apoyo, dos vistas, diez consultas, restricciones, función escalar Python, DML y ROLLBACK, controles con errores inyectados y segunda carga idéntica. Se ejecutaron dos procesos de construcción consecutivos, reconstrucción limpia en memoria y lanzador PowerShell desde esta raíz. La evidencia lleva ubicación y fecha UTC. La selección de presentación también se ejecutó: tres resultados.

La matriz revisa individualmente cada requisito original y cada nuevo requisito. No hay errores de ejecución. La prueba de ZIP reconstruye además una base en disco inexistente tras extraerlo en otra ruta, repite la ejecución y verifica desde cero. Detalles y salidas en reports/ZIP_VERIFICACION.json. No se necesita instalar dependencias Python externas.

## Límites que permanecen

Trece advertencias de fecha de origen: investigación realizada, semántica de alta pendiente de confirmar con el autor; ninguna fecha inventada. No hay factura ni código de cancelación para producir métricas que no existen. Devoluciones completas asumidas y datos sintéticos; REAL redondeado por línea, validado con Decimal. La duración oral exacta requiere ensayo (guion previsto 5:30, margen 0:30). Las recomendaciones de Javier se aplican según lo transmitido por el usuario, sin acceso a la grabación. Publicación posterior autorizada en https://github.com/Vlichy/Bases-de-datos-y-SQL, rama main; la decisión anterior de no publicar queda sustituida por la solicitud actual.

## Tres preguntas e insights elegidos

1. Q2, categorías: Figuras lidera con 340,11 EUR netos. Utilidad: revisar surtido y disponibilidad, sin afirmar beneficio.
2. Q4, canales: Granada Centro aporta 727,64 EUR, el 61,76 % del neto. Utilidad: validar asignación de recursos y corregir el liderazgo online narrado previamente.
3. Q5, devoluciones: 4/35 líneas (11,43 %), 200,40 EUR, un 14,54 % de la venta tras descuento. Utilidad: investigar causas y calidad, sin inferir causalidad.

Conciliación global: tarifa 1393.60 − descuentos 14.95 = ventas 1378.65; menos devoluciones 200.40 = ingreso neto 1178.25 EUR.
