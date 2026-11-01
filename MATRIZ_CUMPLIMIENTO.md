# Matriz de cumplimiento y evidencia

Estado tras la ejecución. COMPLETO Y VERIFICADO significa que hay evidencia concreta; los límites de la fuente y publicación se explicitan.

| Requisito | Estado | Evidencia |
|---|---|---|
| Auditoría anterior a cambios, búsqueda SQL/DB/diagramas/README | COMPLETO Y VERIFICADO. | AUDITORIA_INICIAL.md; inventario de archivos de usuario, sin dependencias |
| Inspección semántica de todos los archivos binarios del curso | NO VERIFICABLE CON EL ACCESO DISPONIBLE. | Inventario no supone ejecución o interpretación de todos los binarios ajenos |
| Examinar Python y CSV procesado | COMPLETO Y VERIFICADO. | Lectura de README y cleaning.py; evidencia_datos.json con 535186 filas y SHA256 |
| Recuperar SQL existente | COMPLETO Y VERIFICADO. | Seis tablas y carga recuperadas; originales/ y hashes |
| No borrar/sobrescribir trabajo previo | COMPLETO Y VERIFICADO. | Entrega en carpeta independiente; hashes originales verificados |
| RAW inalterado y procedencia | COMPLETO Y VERIFICADO. | originales/, raw_statements, source_line y SHA256 |
| Hechos y al menos cuatro dimensiones | COMPLETO Y VERIFICADO. | Una de hechos y cinco dimensiones en 01_schema.sql |
| Granularidad de cada tabla | COMPLETO Y VERIFICADO. | Tabla de capas en README; venta_id identifica línea |
| Dos vistas semánticas | COMPLETO Y VERIFICADO. | vw_ventas_detalle y vw_movimientos, ambas devuelven resultados |
| PK en todas las tablas y FK | COMPLETO Y VERIFICADO. | 01_schema.sql y pruebas de PK, FK y PRAGMA |
| NOT NULL, UNIQUE, CHECK, DEFAULT | COMPLETO Y VERIFICADO. | Pruebas positivas/negativas en run.py y PRUEBAS.md |
| Relaciones y normalización justificadas | COMPLETO Y VERIFICADO. | README, model.png y model.mmd |
| Índices y utilidad | COMPLETO Y VERIFICADO. | Cinco índices; comentarios y README; sin promesa de rendimiento medida |
| PRAGMA foreign_keys activado y comprobado | COMPLETO Y VERIFICADO. | Cada conexión connect; foreign_key_check vacío |
| INSERT, UPDATE, DELETE | COMPLETO Y VERIFICADO. | 02_data y tabla temporal demo en 03_eda ejecutada |
| CAST y funciones de fecha | COMPLETO Y VERIFICADO. | Q10, controles de fecha, strftime en Q1 |
| SUM, COUNT, AVG, GROUP BY, HAVING | COMPLETO Y VERIFICADO. | Q1, Q3, Q5, Q7 y Q10 |
| Subconsulta | COMPLETO Y VERIFICADO. | Q10 |
| Tres JOIN, INNER JOIN y LEFT JOIN | COMPLETO Y VERIFICADO. | vw_ventas_detalle, Q2, Q6, Q9 |
| CASE WHEN | COMPLETO Y VERIFICADO. | Q5, Q7, Q10 |
| CTE simples y encadenadas | COMPLETO Y VERIFICADO. | Q4/Q8 simples y Q1/Q9 encadenadas |
| OVER y PARTITION BY | COMPLETO Y VERIFICADO. | Q9 RANK por categoría; Q1 LAG |
| BEGIN, COMMIT, ROLLBACK con restauración | COMPLETO Y VERIFICADO. | demo, carga y prueba snapshot antes/durante/después |
| IF EXISTS / IF NOT EXISTS SQLite | COMPLETO Y VERIFICADO. | CREATE TABLE/VIEW/INDEX/TRIGGER IF NOT EXISTS; DROP TABLE IF EXISTS |
| FUNCTION compatible y prueba | COMPLETO Y VERIFICADO. | create_function con Decimal; SELECT devuelve 23.22; limitación documentada |
| Nulos y duplicados | COMPLETO Y VERIFICADO. | Controles Q01/Q02; nulos legítimos separados de errores |
| Fechas, conversiones, importes y cantidades | COMPLETO Y VERIFICADO. | Controles Q03/Q04/Q08 y rechazos STRICT/CHECK/triggers |
| Integridad referencial y reglas de negocio | COMPLETO Y VERIFICADO. | Q05/Q07; trece anomalías de fuente señaladas |
| RAW/CORE y trazabilidad | COMPLETO Y VERIFICADO. | Conteos por entidad y comparación de todos los valores en run.py |
| Limpieza justificada, devoluciones legítimas | COMPLETO Y VERIFICADO. | Se normaliza texto NULL; se conserva fuente; movimientos negativos legítimos |
| Exactamente diez consultas documentadas | COMPLETO Y VERIFICADO. | 03_eda; diez secciones con SQL/técnica/pregunta; analisis.md contiene todas las filas e interpretación |
| Resultados sin inventar y tres insights | COMPLETO Y VERIFICADO. | resultados.json y PRESENTACION.md, calculados desde SQLite |
| Sin categorías inventadas | COMPLETO Y VERIFICADO. | Se usan las categorías explícitas de la fuente 3D |
| Ventas, devoluciones, cancelaciones y clientes sin ID | COMPLETO Y VERIFICADO. | README distingue lo representado de lo ausente; no se simulan cancelaciones ni clientes desconocidos inexistentes |
| Ticket por factura y recurrencia por pedidos | NO VERIFICABLE CON EL ACCESO DISPONIBLE. | La fuente no tiene factura; no son requisitos de consulta obligatoria sino ejemplos propuestos; Q10 usa líneas con limitación expresa |
| Archivos SQL obligatorios y README español | COMPLETO Y VERIFICADO. | Archivos 01–04 y README |
| model.png | COMPLETO Y VERIFICADO. | Diagrama inspeccionado visualmente, más fuente Mermaid |
| requirements.txt si hay dependencias | COMPLETO Y VERIFICADO. | Ejecución y pruebas solo usan stdlib; no se necesita requirements.txt |
| Base o procedimiento reproducible | COMPLETO Y VERIFICADO. | tienda.sqlite y run.py |
| Creación/carga/vistas/consultas/constraints reales | COMPLETO Y VERIFICADO. | PRUEBAS.md y pruebas.json |
| Reconstrucción limpia y segunda ejecución | COMPLETO Y VERIFICADO. | --verify usa SQLite vacía en memoria; cada corrida recarga dos veces y compara todos los valores |
| Informe de pruebas reales | COMPLETO Y VERIFICADO. | PRUEBAS.md, pruebas.json, ejecuciones.txt |
| Guion seis minutos, narrativa y cinco respuestas | COMPLETO Y VERIFICADO. | PRESENTACION.md: modelo primero, tres preguntas Q2/Q4/Q5 y guion 5:30 + 0:30 de margen; recomendaciones aportadas por usuario; duración exacta depende del ritmo oral |
| Repositorio local preparado y .gitignore | COMPLETO Y VERIFICADO. | Git local en rama codex/sql-finalizacion; git_status.txt |
| Publicación y permisos GitHub | COMPLETO Y VERIFICADO. | Repositorio público Vlichy/Bases-de-datos-y-SQL; revisión remota, commit y push a main sin force; GITHUB.md |
| Investigar fechas de alta y corregir solo con evidencia | COMPLETO Y VERIFICADO. | INVESTIGACION_FECHAS.md: trece advertencias reproducidas desde originales; no hay base para cambiar fechas; semántica definitiva pendiente del autor |

Los requisitos de implementación comprobables están cubiertos. No se afirma publicación, perfección de los datos originales ni métricas que la fuente no permite calcular.

## Ampliación de requisitos de ubicación y entrega

| Requisito | Estado | Evidencia |
|---|---|---|
| Ubicación definitiva y copia íntegra | COMPLETO Y VERIFICADO. | DataScience/Bbdd SQL; reports/traslado.json compara cada archivo previo |
| Conservar originales y trabajo anterior | COMPLETO Y VERIFICADO. | Originales con SHA256, .git copiado y carpeta antigua intacta como respaldo |
| No mezclar con Machine Learning | COMPLETO Y VERIFICADO. | Raíz y repositorio independientes; ejecución sin rutas ML ni CSV externo |
| Rutas, VS Code y ejecución portátil | COMPLETO Y VERIFICADO. | run.ps1, .vscode, Bbdd SQL.code-workspace; ROOT relativo a run.py |
| Pruebas desde la ubicación nueva | COMPLETO Y VERIFICADO. | pruebas.json registra project_root; ejecuciones.txt documenta procesos reales |
| Índices y detector de problemas comprobados | COMPLETO Y VERIFICADO. | Pruebas de cinco índices, FK y errores inyectados reversibles |
| Investigar las trece fechas sin inventar | COMPLETO Y VERIFICADO. | Investigación de fuente, claves y semántica; trece filas y desfases |
| Causa específica del generador / significado de alta | NO VERIFICABLE CON EL ACCESO DISPONIBLE. | No hay generador o contrato semántico aportado; advertencia abierta de origen |
| Bruto, descuentos, devoluciones y neto | COMPLETO Y VERIFICADO. | CONCILIACION_ECONOMICA.md; comparación con Decimal |
| Recomendaciones de Javier del 18 de junio | COMPLETO Y VERIFICADO. | Se aplican las indicadas por el usuario: modelo inicial, narrativa y tres preguntas; no se presume acceso a la grabación |
| Diez análisis conservados y tres para exponer | COMPLETO Y VERIFICADO. | 03_eda.sql contiene exactamente diez; 05_presentacion.sql selecciona Q2/Q4/Q5 |
| Exposición máxima de seis minutos | COMPLETO Y VERIFICADO. | Guion previsto 5:30 con margen 0:30; duración oral exacta sujeta a ensayo |
| ZIP dentro de raíz y ejecución independiente | COMPLETO Y VERIFICADO. | entrega_sql_tienda_3d.zip y ZIP_VERIFICACION.json; extracción, eliminación de base extraída y reconstrucción real |
| No publicar antes de revisión | COMPLETO Y VERIFICADO. | Se respetó durante la entrega anterior; publicación autorizada expresamente en la solicitud posterior |

No queda código con error de ejecución ni requisito obligatorio de implementación sin revisar. Permanecen límites de la fuente: semántica de alta, inexistencia de factura/cancelaciones y supuestos de reembolso completo. No se convierten esos límites en datos inventados.

## Publicación autorizada

Se revisó el remoto, inicialmente vacío y público, con rama principal main. Se publica sin force, conservando SQLite y excluyendo respaldos, temporales y credenciales. Los originales conservan sus hashes y la lógica SQL permanece intacta. La comprobación posterior contrasta la rama remota, el commit y el contenido servido por GitHub. URL de entrega: https://github.com/Vlichy/Bases-de-datos-y-SQL.
