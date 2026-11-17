# movement

MovementRulesService separa validación de paso, traslación y ruta. RoutePlanner
busca alternativas por BFS con costo unitario y vuelve a validar cada ruta ofrecida.
Snapshots, coordenadas, resultados y eventos son inmutables y no dependen de Flutter.
Perfil, límites y fuentes en docs/MATRIZ_MOVIMIENTO.md.
`dart run tool/verify_movement.dart` ejecuta los contratos sin Flutter.
