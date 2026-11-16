import '../../domain/rules/distance_service.dart';
import '../../domain/rules/line_of_sight.dart';
import '../../domain/rules/line_of_sight_service.dart';
import '../../domain/rules/target_analysis_service.dart';
import 'board_session.dart';
import 'sight_probe.dart';

/// Caché acotada a un mundo y contexto. Cambiar alcance/nombre no repite visión.
final class TacticalVisionCache implements VisionEvaluator {
  TacticalVisionCache({this.delegate = const LineOfSightService()});
  final VisionEvaluator delegate;
  final _entries = <Object, VisionEvaluation>{};
  Object? _world;
  List<Object> _figures = const [];
  int evaluations = 0;
  void prepare(VisionSnapshot snapshot, VisionContext context) {
    final figures = <Object>[
      for (final f in snapshot.characters)
        (f.id, f.label, f.teamId, f.position, f.footprint),
    ];
    final key = (
      snapshot.dimensions,
      snapshot.terrain,
      snapshot.walls,
      context.rulesVersion,
      context.features.map((f) => f.index).toList()..sort(),
    );
    // La lista de capacidades se compara por contenido, no por identidad.
    final signature = (key.$1, key.$2, key.$3, key.$4, key.$5.join(','));
    var sameFigures = figures.length == _figures.length;
    if (sameFigures) {
      for (var i = 0; i < figures.length; i++) {
        if (figures[i] != _figures[i]) {
          sameFigures = false;
          break;
        }
      }
    }
    if (_world != signature || !sameFigures) {
      _world = signature;
      _figures = figures;
      _entries.clear();
    }
  }

  void clear() {
    _world = null;
    _figures = const [];
    _entries.clear();
  }

  @override
  VisionEvaluation evaluate(
    VisionSnapshot snapshot,
    VisionEndpoint origin,
    VisionEndpoint destination,
    VisionContext context,
  ) {
    final key = (
      origin.cell,
      origin.figureId,
      destination.cell,
      destination.figureId,
    );
    if (_entries.length >= 256 && !_entries.containsKey(key)) _entries.clear();
    return _entries.putIfAbsent(key, () {
      evaluations++;
      return delegate.evaluate(snapshot, origin, destination, context);
    });
  }
}

/// Estado de consulta transitorio; no entra en JSON, historial ni autoguardado.
final class TacticalAnalysis {
  TacticalAnalysis() {
    service = TargetAnalysisService(vision: cache);
  }
  final cache = TacticalVisionCache();
  late final TargetAnalysisService service;
  String? sourceId, selectedTargetId;
  TargetFilter filter = TargetFilter.enemies;
  bool enabled = false, showDeltas = false;
  DistanceMeasurement? measurement;
  TargetReport? report;
  List<TargetEvaluation> visible = const [];
  Object? _previous, _measurementKey;
  TargetEvaluation? get selected {
    for (final item in report?.targets ?? <TargetEvaluation>[]) {
      if (item.target.id == selectedTargetId) return item;
    }
    return null;
  }

  void clear() {
    sourceId = selectedTargetId = null;
    report = null;
    visible = const [];
    measurement = null;
    _previous = _measurementKey = null;
    enabled = false;
    filter = TargetFilter.enemies;
    showDeltas = false;
    cache.clear();
  }

  void sync(BoardSession session, SightProbe probe, VisionContext context) {
    try {
      final a = probe.origin?.resolve(session),
          b = probe.destination?.resolve(session);
      final key = (session.dimensions, a, b, context.rulesVersion);
      if (_measurementKey != key) {
        _measurementKey = key;
        measurement = a == null || b == null
            ? null
            : const DistanceService().measure(
                session.dimensions,
                a,
                b,
                rulesVersion: context.rulesVersion,
              );
      }
    } on ArgumentError catch (e) {
      measurement = DistanceMeasurement(reason: e.message.toString());
      _measurementKey = null;
    }
    if (!enabled) return;
    final key = (
      session.dimensions,
      session.characters,
      session.terrain,
      session.walls,
      sourceId,
      context.rulesVersion,
      context.features.map((f) => f.index).join(','),
    );
    if (key != _previous) {
      _previous = key;
      final snapshot = VisionSnapshot(
        dimensions: session.dimensions,
        characters: session.characters.all,
        terrain: session.terrain,
        walls: session.walls,
      );
      cache.prepare(snapshot, context);
      report = sourceId == null
          ? null
          : service.evaluate(snapshot, sourceId!, context);
      if (selected == null) selectedTargetId = null;
    }
    visible = List.unmodifiable(
      (report?.targets ?? <TargetEvaluation>[]).where(
        (item) =>
            filter == TargetFilter.all ||
            (item.source.teamId == item.target.teamId) ==
                (filter == TargetFilter.allies),
      ),
    );
  }
}
