# Cambios realizados

1. Recuperados los cinco originales sin sobrescribirlos; copia literal con hashes verificados.
2. Adaptado PostgreSQL a SQLite: claves INTEGER, tipos STRICT, funciones de fecha, vistas y triggers SQLite; eliminada la necesidad de CREATE DATABASE y PL/pgSQL.
3. Conservados catálogo, 35 líneas, dimensiones y claves del caso 3D. No se cambió a Online Retail para respetar la recuperación del proyecto existente.
4. Añadida capa RAW con línea, tabla y hash por INSERT, y comparación íntegra RAW/CORE.
5. Añadida segunda vista con movimientos de devolución negativos por fecha efectiva. Corregida la interpretación del ingreso neto.
6. Reducidas a exactamente diez preguntas principales y recalculados todos los resultados. Corregido el liderazgo atribuido al canal online: los datos vinculan el mayor importe a Granada (tienda_id=3).
7. Añadidos controles y pruebas negativas de claves, restricciones, tipos, fechas y triggers; ROLLBACK verificado con comparación completa de estado.
8. Añadida ejecución idempotente, reconstrucción limpia, función escalar Python, diagrama, informe, matriz y guion.
9. Detectadas trece incoherencias alta–venta y documentadas sin corregir arbitrariamente la fuente.
10. Preparado repositorio local separado, sin publicar ni modificar remotos existentes.

## Revisión definitiva y reorganización

- Copia completa (incluido Git local) en DataScience/Bbdd SQL, contrastada byte a byte antes de modificar. La carpeta anterior se conserva como respaldo.
- Actualizadas instrucciones sin dependencia de entornos ML; añadidos lanzador Windows, espacio de trabajo y tareas VS Code.
- Añadidas métricas explícitas de tarifa, descuento y venta; mantenido alias histórico para compatibilidad.
- Investigadas trece advertencias de fechas: proceden de la fuente; regla temporal no definida. Ninguna fecha se altera arbitrariamente.
- Ampliadas pruebas: índices, relaciones exactas, controles con anomalías inyectadas, DML verificado y conciliación Decimal.
- Reformulada presentación: modelo primero, tres preguntas (Q2/Q4/Q5), guion previsto 5:30 y 30 segundos de margen.
- ZIP creado en la ubicación definitiva y probado mediante extracción y reconstrucción independiente.

- Corregidas dos líneas por redondeo monetario: 52,155→52,16 y 23,655→23,66; vistas en céntimos y puntos básicos, con regresión automatizada.

## Publicación autorizada en GitHub

Revisado remoto vacío/público y rama main. Configurado origin, incluida expresamente tienda.sqlite y reforzadas exclusiones. Actualizada documentación de publicación. Sin cambios de lógica SQL ni de las pruebas. Commit y push normales, sin force y sin borrar contenido remoto.
