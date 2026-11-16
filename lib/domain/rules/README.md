# rules

LineOfSightService implementa en Dart puro el perfil básico de visión de 06.
Entrada: snapshot inmutable, extremos y contexto versionado. Salida: estado,
visibilidad, observaciones, geometría y referencias. Alcance y ataques no se evalúan.
Cobertura y límites en docs/MATRIZ_REGLAS_VISION.md. Capacidades avanzadas siguen
pendientes. `dart run tool/verify_vision.dart` verifica los contratos sin Flutter.

Desde 07, DistanceService cuenta casillas conforme a §11.3a y TargetAnalysisService
combina esa distancia, alcance declarado y el mismo VisionEvaluator. Conserva
dimensiones independientes y límites pendientes; no autoriza ataques. Referencias
y contratos en docs/MATRIZ_DISTANCIAS_OBJETIVOS.md y tool/verify_targets.dart.
