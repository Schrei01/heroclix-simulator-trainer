import '../../domain/rules/line_of_sight.dart';
import '../../domain/rules/line_of_sight_service.dart';
import '../../domain/rules/target_analysis_service.dart';
import '../../domain/characters/vision_ability.dart';
import 'board_session.dart';
import 'sight_probe.dart';

/// Caché transitoria de la única evaluación, compartida por todas las vistas.
final class VisionAnalysis {
  VisionAnalysis({this.service = const LineOfSightService()});
  final VisionEvaluator service;
  bool enabled = false;
  bool specialEffects = false;
  bool showCauses = true;
  bool automaticReferences = true;
  Set<VisionAbility>? laboratoryAbilities;
  String? _laboratory;
  bool? _automatic;
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
    laboratoryAbilities = null;
    automaticReferences = true;
    _laboratory = null;
  }

  void evaluate(
    BoardSession session,
    SightProbe probe,
    String version, {
    VisionEvaluation? selectedTarget,
  }) {
    if (selectedTarget != null) {
      result = selectedTarget;
      _previous = null;
      return;
    }
    final context = VisionContext(
      rulesVersion: version,
      features: [if (specialEffects) VisionFeature.powersOrSizes],
      laboratoryAbilities: laboratoryAbilities,
    );
    final previous = _previous;
    if (previous != null &&
        previous.dimensions == session.dimensions &&
        previous.characters == session.characters &&
        previous.terrain == session.terrain &&
        previous.walls == session.walls &&
        _origin == probe.origin &&
        _destination == probe.destination &&
        _version == version &&
        _special == specialEffects &&
        _laboratory == context.laboratoryKey &&
        _automatic == automaticReferences) {
      return;
    }
    _previous = session;
    _origin = probe.origin;
    _destination = probe.destination;
    _version = version;
    _special = specialEffects;
    _laboratory = context.laboratoryKey;
    _automatic = automaticReferences;
    result = null;
    if (probe.origin == null || probe.destination == null) return;
    try {
      final snapshot = VisionSnapshot(
        dimensions: session.dimensions,
        characters: session.characters.all,
        terrain: session.terrain,
        walls: session.walls,
      );
      final source = session.characters.byId(probe.origin!.figureId ?? '');
      final target = session.characters.byId(probe.destination!.figureId ?? '');
      if (automaticReferences &&
          source != null &&
          target != null &&
          (source.footprint.width * source.footprint.height > 1 ||
              target.footprint.width * target.footprint.height > 1)) {
        result = TargetAnalysisService(vision: service)
            .evaluateTarget(snapshot, source, target, context, visionOnly: true)
            .vision;
        return;
      }
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
