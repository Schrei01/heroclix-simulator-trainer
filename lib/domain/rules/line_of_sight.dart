import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';
import '../characters/character.dart';
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
  wall('V06', '16.4b', 40),
  corner('V07', '16.8b', 44),
  elevation('V08', '16.5c', 42),
  multiBase('V09', '24.2e', 70),
  occupancy('V10', '13.2', 35),
  powers('V11', '19.3', 54),
  specialMap('V12', '15.6', 38),
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
  }) : features = Set.unmodifiable(features);
  static const supportedVersion = '2026-07-01';
  final String rulesVersion;
  final Set<VisionFeature> features;
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
  }) : observations = List.unmodifiable(observations);
  final VisionStatus status;
  final VisionContext context;
  final VisionEndpoint? origin, destination;
  final GeometricTrace? trace;
  final List<VisionObservation> observations;
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
