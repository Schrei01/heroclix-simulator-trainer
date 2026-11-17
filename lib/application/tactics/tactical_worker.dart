import 'dart:isolate';

import '../../domain/board/cell_coordinate.dart';
import '../../domain/rules/line_of_sight.dart';
import '../../domain/tactics/tactical_analysis_service.dart';
import '../../domain/tactics/tactical_diagnostic.dart';

final class TacticalJob {
  TacticalJob(
    this.port,
    this.world,
    this.sourceId,
    this.context,
    this.cells,
    this.compare,
  );
  final SendPort port;
  final VisionSnapshot world;
  final String sourceId;
  final TacticalContext context;
  final List<CellCoordinate> cells;
  final bool compare;
}

final class TacticalProgress {
  const TacticalProgress(this.position, this.total, this.enemy, this.enemies);
  final int position, total, enemy, enemies;
}

final class TacticalCurrent {
  const TacticalCurrent(this.position, this.alternate);
  final PositionDiagnostic position;
  final PositionDiagnostic? alternate;
}

final class TacticalCompleted {
  const TacticalCompleted();
}

final class TacticalFailure {
  const TacticalFailure(this.message);
  final String message;
}

/// Este isolate contiene todo el CPU costoso, incluida la búsqueda de rutas.
/// Cancelar desde UI termina el isolate incluso dentro de una línea o búsqueda.
void runTacticalJob(TacticalJob job) {
  try {
    const service = TacticalAnalysisService();
    void progress(int position, int enemy, int enemies) => job.port.send(
      TacticalProgress(position, job.cells.length + 1, enemy, enemies),
    );
    progress(0, 0, 0);
    final current = service.inspect(
      job.world,
      job.sourceId,
      job.context,
      onEnemy: (n, total) => progress(0, n, total),
    );
    final alternate = job.compare
        ? service.inspect(job.world, job.sourceId, job.context.without)
        : null;
    job.port.send(TacticalCurrent(current, alternate));
    for (var i = 0; i < job.cells.length; i++) {
      progress(i + 1, 0, 0);
      job.port.send(
        service.candidate(
          job.world,
          job.sourceId,
          job.cells[i],
          job.context,
          compareImprovements: job.compare,
          onEnemy: (n, total) => progress(i + 1, n, total),
        ),
      );
    }
    job.port.send(const TacticalCompleted());
  } catch (e) {
    job.port.send(TacticalFailure('No se pudo completar el diagnóstico: $e'));
  }
}
