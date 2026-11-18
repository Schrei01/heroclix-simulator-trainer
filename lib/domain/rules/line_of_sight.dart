import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';
import '../characters/character.dart';
import '../characters/vision_ability.dart';
import '../geometry/sight_geometry.dart';
import '../terrain/edge_wall.dart';
import '../terrain/terrain.dart';

enum VisionStatus { clear, hindered, blocked, notEvaluated }

enum VisionEffect { none, hindering, blocking, unsupported }

enum VisionFeature { powersOrSizes, remoteSource, specialMap }

/// Referencias verificadas; limit marca una política de cobertura, no una regla.
enum VisionRule {
  center('V01', '11.4', 27),
  self('V02', '11.4b', 27),
  character('V03', '11.4c', 27),
  hindering('V04', '16.2b', 39),
  blocking('V05', '16.3b', 40),
  water('W01', '16.6', 42),
  environment('M01', '15.1', 37),
  debris('Db01', '17.14d', 51),
  wall('V06', '16.4b', 40),
  corner('V07', '16.8b', 44),
  elevation('V08', '16.5c', 42),
  multiBase('V09', '24.2e', 70),
  occupancy('V10', '13.2', 35),
  powers('V11', '19.3', 54),
  specialMap('V12', '15.6', 38),
  rim('E02', '16.5d', 42),
  wallElevation('E03', '16.5e', 42),
  baseElevation('E04', '16.5g', 42),
  size('E05', '21.2b', 60),
  improvedElevated('I01', '27.6a', 87),
  improvedHindering('I02', '27.6b', 87),
  improvedBlocking('I03', '27.6c', 87),
  improvedCharacters('I04', '27.6e', 87),
  destroyBlocking('I05', '27.6d', 87),
  adjacent('I06', '27.6f', 87),
  limit('SCOPE', 'Límite de implementación', null);

  const VisionRule(this.id, this.section, this.page);
  final String id, section;
  final int? page;
  static const sourceUrl =
      'https://wizkids.com/wp-content/uploads/2026/07/HeroClix%20Comprehensive%20Rules%2007.01.26.pdf';
  String get citation =>
      '$id · ${page == null ? section : '§$section · p. $page'}';
}

final class VisionContext {
  VisionContext({
    this.rulesVersion = supportedVersion,
    Iterable<VisionFeature> features = const [],
    Iterable<VisionAbility>? laboratoryAbilities,
  }) : features = Set.unmodifiable(features),
       laboratoryAbilities = laboratoryAbilities == null
           ? null
           : Set.unmodifiable(laboratoryAbilities);
  static const supportedVersion = '2026-07-01';
  final String rulesVersion;
  final Set<VisionFeature> features;
  final Set<VisionAbility>? laboratoryAbilities;
  String get laboratoryKey => laboratoryAbilities == null
      ? 'ficha'
      : ((laboratoryAbilities!.map((a) => a.index).toList()..sort()).join(','));
}

VisionRule abilityRule(VisionAbility ability) => switch (ability) {
  VisionAbility.elevated => VisionRule.improvedElevated,
  VisionAbility.hindering => VisionRule.improvedHindering,
  VisionAbility.blocking => VisionRule.improvedBlocking,
  VisionAbility.characters => VisionRule.improvedCharacters,
  VisionAbility.destroyBlocking => VisionRule.destroyBlocking,
  VisionAbility.adjacent => VisionRule.adjacent,
  VisionAbility.other => VisionRule.powers,
};

final class VisionReference {
  const VisionReference(
    this.origin,
    this.destination,
    this.status,
    this.distance,
  );
  final CellCoordinate origin, destination;
  final VisionStatus status;
  final int? distance;
}

/// Copia de la colección e instancias inmutables; no depende de la sesión/UI.
final class VisionSnapshot {
  VisionSnapshot({
    required this.dimensions,
    required Iterable<Character> characters,
    this.terrain = const TerrainLayer.empty(),
    this.walls = const WallLayer.empty(),
  }) : characters = List.unmodifiable(characters);
  final BoardDimensions dimensions;
  final List<Character> characters;
  final TerrainLayer terrain;
  final WallLayer walls;
}

final class VisionEndpoint {
  const VisionEndpoint(this.cell, {this.figureId});
  final CellCoordinate cell;
  final String? figureId;
}

final class VisionObservation {
  VisionObservation({
    required this.effect,
    required this.description,
    required Iterable<VisionRule> rules,
    this.eventIndex,
    this.contributes = true,
    Iterable<CellCoordinate> cells = const [],
    Iterable<EdgeWall> edges = const [],
    Iterable<String> figures = const [],
  }) : rules = List.unmodifiable(rules),
       cells = List.unmodifiable(cells),
       edges = List.unmodifiable(edges),
       figures = List.unmodifiable(figures);
  final VisionEffect effect;
  final String description;
  final List<VisionRule> rules;
  final int? eventIndex;

  /// False para alternativas inspeccionadas y excepciones que no restringen.
  final bool contributes;
  final List<CellCoordinate> cells;
  final List<EdgeWall> edges;
  final List<String> figures;
}

final class VisionEvaluation {
  VisionEvaluation({
    required this.status,
    required this.context,
    required this.origin,
    required this.destination,
    required Iterable<VisionObservation> observations,
    this.trace,
    Iterable<VisionReference> references = const [],
  }) : observations = List.unmodifiable(observations),
       references = List.unmodifiable(references);
  final VisionStatus status;
  final VisionContext context;
  final VisionEndpoint? origin, destination;
  final GeometricTrace? trace;
  final List<VisionObservation> observations;
  final List<VisionReference> references;
  VisionEvaluation withReferences(Iterable<VisionReference> values) =>
      VisionEvaluation(
        status: status,
        context: context,
        origin: origin,
        destination: destination,
        trace: trace,
        observations: observations,
        references: values,
      );
  bool? get canSee => switch (status) {
    VisionStatus.clear || VisionStatus.hindered => true,
    VisionStatus.blocked => false,
    VisionStatus.notEvaluated => null,
  };
  Iterable<VisionObservation> get decisive => observations.where(
    (item) =>
        item.contributes &&
        item.effect ==
            switch (status) {
              VisionStatus.clear => VisionEffect.none,
              VisionStatus.hindered => VisionEffect.hindering,
              VisionStatus.blocked => VisionEffect.blocking,
              VisionStatus.notEvaluated => VisionEffect.unsupported,
            },
  );
  String get explanation => status == VisionStatus.clear
      ? 'La trayectoria no presenta restricciones bajo el perfil básico evaluado.'
      : decisive.first.description;
}

abstract interface class VisionEvaluator {
  VisionEvaluation evaluate(
    VisionSnapshot snapshot,
    VisionEndpoint origin,
    VisionEndpoint destination,
    VisionContext context,
  );
}
