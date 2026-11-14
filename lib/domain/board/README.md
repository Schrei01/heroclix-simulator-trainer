# board

Implementado en 01 con Dart puro, sin Flutter:

- `BoardDimensions`: filas y columnas independientes de 2 a 40.
- `CellCoordinate`: índices desde cero y etiquetas A1…AN40, con igualdad por valor.
- `BoardGeometry`: centros y selección en unidades de escena, no píxeles almacenados.
- `BoardCamera` y `ViewportSize`: conversión bidireccional, zoom anclado y ajuste.

Los bordes compartidos seleccionan la casilla derecha/inferior. El borde externo
derecho/inferior queda fuera del área seleccionable. Una tolerancia de 1e-9 de
casilla corrige el redondeo de las transformaciones en un borde exacto.

No contiene terreno, muros, figuras, visión ni reglas de HeroClix.
