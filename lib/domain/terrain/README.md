# Terreno y bordes — etapa 03

Dominio Dart puro: TerrainType, CellTerrain con elevación preparada, TerrainLayer
inmutable, EdgeWall canónico y WallLayer. El terreno predeterminado es despejado
con elevación cero; no se almacena una entrada por cada celda vacía.

EdgeWall usa eje horizontal/vertical y vértice de menor índice; IDs h:col:fila o
v:col:fila. Solo bordes internos. Las casillas vecinas en cualquier orden producen
el mismo borde. EditingGeometry interpola trazos por cruces de cuadrícula y ofrece
hit test de borde con franja 0,22 de casilla y tolerancia de empate 1e-9.
No contiene reglas de visión, movimiento o elevación.
