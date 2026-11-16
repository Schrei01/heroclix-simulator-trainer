import '../../domain/rules/line_of_sight.dart';
import '../../domain/rules/line_of_sight_service.dart';
import 'board_session.dart';
import 'sight_probe.dart';

/// Caché transitoria de la única evaluación, compartida por todas las vistas.
final class VisionAnalysis {
  VisionAnalysis({this.service = const LineOfSightService()});
  final VisionEvaluator service;
  bool enabled = false;
  bool specialEffects = false;
  bool showCauses = true;
  BoardSession? _previous;
  ProbeEndpoint? _origin, _destination;
  String? _version;
  bool? _special;
  VisionEvaluation? result;
  void clear() {
    _previous = null;
    _origin = _destination = null;
    result = null;
    specialEffects = false;
  }

  void evaluate(BoardSession session, SightProbe probe, String version) {
    final previous = _previous;
    if (previous != null &&
        previous.dimensions == session.dimensions &&
        previous.characters == session.characters &&
        previous.terrain == session.terrain &&
        previous.walls == session.walls &&
        _origin == probe.origin &&
        _destination == probe.destination &&
        _version == version &&
        _special == specialEffects) {
      return;
    }
    _previous = session;
    _origin = probe.origin;
    _destination = probe.destination;
    _version = version;
    _special = specialEffects;
    result = null;
    if (probe.origin == null || probe.destination == null) return;
    final context = VisionContext(
      rulesVersion: version,
      features: [if (specialEffects) VisionFeature.powersOrSizes],
    );
    try {
      result = service.evaluate(
        VisionSnapshot(
          dimensions: session.dimensions,
          characters: session.characters.all,
          terrain: session.terrain,
          walls: session.walls,
        ),
        VisionEndpoint(
          probe.origin!.resolve(session),
          figureId: probe.origin!.figureId,
        ),
        VisionEndpoint(
          probe.destination!.resolve(session),
          figureId: probe.destination!.figureId,
        ),
        context,
      );
    } on ArgumentError catch (error) {
      // Un extremo eliminado/no resoluble nunca deja publicado el último dictamen.
      result = VisionEvaluation(
        status: VisionStatus.notEvaluated,
        context: context,
        origin: probe.origin!.cell == null
            ? null
            : VisionEndpoint(probe.origin!.cell!),
        destination: probe.destination!.cell == null
            ? null
            : VisionEndpoint(probe.destination!.cell!),
        observations: [
          VisionObservation(
            effect: VisionEffect.unsupported,
            description: error.message.toString(),
            rules: [VisionRule.limit],
          ),
        ],
      );
    }
  }
}
