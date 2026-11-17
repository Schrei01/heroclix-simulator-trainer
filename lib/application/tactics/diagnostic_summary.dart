import '../../domain/tactics/tactical_diagnostic.dart';
import '../../domain/rules/line_of_sight.dart';

/// Solo datos de juego y textos controlados. No incluye nombres de escenario,
/// personajes/equipos, IDs privados, fecha, rutas de archivos ni evidencia libre.
String diagnosticSummary(
  PositionDiagnostic current,
  TacticalCandidate? chosen,
  TacticalPriority priority, {
  required int evaluated,
  required int requested,
  required bool cancelled,
}) {
  final out = StringBuffer('HeroClix · diagnóstico de posiciones\n');
  out.writeln(
    'Edición: ${current.context.rulesVersion == VisionContext.supportedVersion ? VisionContext.supportedVersion : 'no soportada'}',
  );
  out.writeln(
    'Prioridad de orden: ${priority.label}. No es una jugada óptima ni una probabilidad de victoria.',
  );
  out.writeln(
    'Página: $evaluated de $requested posiciones procesadas${cancelled ? ' · cancelada' : ''}.',
  );
  void position(String label, PositionDiagnostic d) {
    out.writeln(
      '$label: ${d.cell.label}. Enemigos analizados ${d.enemies.length}/${d.totalEnemies}.',
    );
    for (final m in TacticalMetric.values) {
      out.writeln('${m.label}: ${d.metrics[m]!.text}. §${m.rules}.');
    }
    out.writeln(
      'Terreno: ${d.terrain.map((t) => t.name).join(', ')}. Niveles: ${d.levels.join(', ')}.',
    );
    out.writeln(
      'Métricas ${d.complete ? 'completas bajo el perfil' : 'incompletas; no hay valoración categórica'}.',
    );
  }

  position('Actual', current);
  if (chosen?.position != null) {
    position('Hipótesis con ficha declarada', chosen!.position!);
    out.writeln(
      'Costo: ${chosen.route!.cost}. Ruta: ${chosen.route!.route.map((c) => c.label).join(' / ')}.',
    );
    if (chosen.alternate != null) {
      position(
        'Hipótesis sin mejoras soportadas del activo',
        chosen.alternate!,
      );
      out.writeln(
        'Esa misma ruta sin mejoras: ${chosen.alternateMovement!.status.name}.',
      );
    }
  }
  out.writeln(TacticalMetric.excluded);
  out.writeln(
    'Se conservan los límites de visión, alcance y movimiento implementados. No se recomienda una estrategia universal.',
  );
  return out.toString();
}
