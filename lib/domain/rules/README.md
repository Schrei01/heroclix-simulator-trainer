# rules

LineOfSightService implementa en Dart puro el perfil básico de visión de 06.
Entrada: snapshot inmutable, extremos y contexto versionado. Salida: estado,
visibilidad, observaciones, geometría y referencias. Alcance y ataques no se evalúan.
Cobertura y límites en docs/MATRIZ_REGLAS_VISION.md. Capacidades avanzadas siguen
pendientes. `dart run tool/verify_vision.dart` verifica los contratos sin Flutter.
