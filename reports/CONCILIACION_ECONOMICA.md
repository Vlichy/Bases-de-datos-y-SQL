# Conciliación económica ejecutada

Importes EUR, redondeados por línea. Fuente sintética; devolución completa al precio tras descuento. No mide beneficio, impuestos ni caja comprobada.

| Concepto | EUR |
|---|---|
| Bruto a tarifa antes de descuentos | 1393.6 |
| Descuentos concedidos | 14.95 |
| Ventas tras descuento y antes de devolución | 1378.65 |
| Devoluciones modeladas | 200.4 |
| Ingreso neto modelado | 1178.25 |

Conciliaciones: 1393.60 − 14.95 = 1378.65; 1378.65 − 200.40 = 1178.25.

`importe_antes_descuento` es bruto a tarifa. `importe_descuento` es la diferencia redondeada entre tarifa y venta. `importe_venta` es la venta tras descuento. `importe_bruto` permanece como alias histórico de importe_venta, para conservar las diez consultas y sus resultados; su nombre no debe confundirse con tarifa antes de descuentos.

`vw_movimientos` contiene 35 ventas positivas y cuatro devoluciones negativas (39 movimientos). El movimiento de devolución usa fecha_devolucion, no la fecha de venta, y resta exactamente una vez el importe de la línea devuelta. En este dataset todas las ventas y devoluciones están dentro del periodo analizado, por lo que el neto total coincide con ventas menos devoluciones. La fuente no permite devoluciones parciales.

Se corrigieron dos diferencias de un céntimo respecto a la entrega previa: líneas 6 y 30. Se implementa HALF_UP con céntimos y puntos básicos enteros y se comprueban esos casos. Los precios originales permanecen intactos. La reconciliación nueva usa 1378.65 de ventas tras descuento, no los 1378,63 de la versión anterior.

Las pruebas recalculan importes con Decimal/ROUND_HALF_UP de forma independiente, comprueban los signos y concilian con las vistas. Q5 usa 4/35=11,43 % por líneas y 200.40/1378.65=14,54 % por importe; son denominadores distintos. Los costes de producción no se descuentan del ingreso neto y no se presenta éste como margen o beneficio.
