import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/rules/distance_service.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/target_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';

import 'vision_contract.dart';

TargetReport targets(
  VisionSnapshot world, {
  String source = 'figure-1',
  VisionContext? context,
}) => const TargetAnalysisService().evaluate(
  world,
  source,
  context ?? VisionContext(),
);
VisionSnapshot ranged(VisionSnapshot world, int range) => VisionSnapshot(
  dimensions: world.dimensions,
  terrain: world.terrain,
  walls: world.walls,
  characters: [
    for (final f in world.characters)
      f.id != 'figure-1'
          ? f
          : Character(
              id: f.id,
              label: f.label,
              data: CharacterDraft(
                name: f.name,
                teamId: f.teamId,
                position: f.position,
                footprint: f.footprint,
                speed: f.speed,
                range: range,
              ),
            ),
  ],
);

Map<String, void Function()> targetCases() => {
  'D01 §11.3a cuenta horizontal vertical diagonal oblicua y cero': () {
    final dims = BoardDimensions(rows: 40, columns: 40);
    for (final (a, b, expected) in [
      ('A1', 'D1', 3),
      ('A1', 'A6', 5),
      ('A1', 'D4', 3),
      ('A1', 'D6', 5),
      ('D6', 'B2', 4),
      ('C3', 'C3', 0),
      ('A1', 'AN40', 39),
    ]) {
      for (final (from, to) in [(a, b), (b, a)]) {
        final m = const DistanceService().measure(dims, vc(from), vc(to));
        ensure(m.squares == expected, '$from–$to debe contar $expected');
        ensure(m.rules.contains(TacticalRule.distance), 'referencia D01');
      }
    }
  },
  'D02 §11.3a diferencias y límites de medición': () {
    final m = const DistanceService().measure(
      BoardDimensions.initial,
      vc('A1'),
      vc('D3'),
    );
    ensure(
      m.rows == 2 && m.columns == 3 && m.squares == 3,
      'diferencias absolutas',
    );
    ensure(
      !const DistanceService()
          .measure(BoardDimensions.initial, vc('A1'), vc('D6'))
          .evaluated,
      'fuera de tablero',
    );
    ensure(
      !const DistanceService()
          .measure(
            BoardDimensions.initial,
            vc('A1'),
            vc('D3'),
            rulesVersion: 'futura',
          )
          .evaluated,
      'versión desconocida',
    );
  },
  'T01 §11.3b alcance igual distancia y uno menos o más': () {
    for (final (range, expected) in [
      (2, TargetStatus.outOfRange),
      (3, TargetStatus.inRangeClear),
      (4, TargetStatus.inRangeClear),
    ]) {
      final item = targets(ranged(vs(), range)).targets.single;
      ensure(
        item.distance.squares == 3 && item.status == expected,
        'distancia 3, alcance $range',
      );
      ensure(item.declaredRange == range, 'conservar alcance anotado');
    }
  },
  'T02 §11.3b/11.4 dos enemigos uno dentro y otro fuera': () {
    final world = ranged(
      vs(
        target: 'D1',
        columns: 8,
        extras: [vf(3, 'H4', team: 'team-2')],
      ),
      3,
    );
    final items = targets(world).targets;
    ensure(items.length == 2, 'excluir origen, evaluar las otras figuras');
    ensure(items[0].status == TargetStatus.inRangeClear, 'D1 a distancia 3');
    ensure(
      items[1].status == TargetStatus.outOfRange &&
          items[1].distance.squares == 7,
      'H4 fuera',
    );
  },
  'T03 §16.2b/16.3b visión obstaculizada y bloqueada dentro de alcance': () {
    for (final (terrain, expected) in [
      (TerrainType.hindering, TargetStatus.inRangeHindered),
      (TerrainType.blocking, TargetStatus.blocked),
    ]) {
      final item = targets(vs(terrain: {'B1': terrain})).targets.single;
      ensure(
        item.range == RangeStatus.within && item.status == expected,
        'dimensiones independientes',
      );
    }
  },
  'T04 §11.4c figura intermedia de ambos equipos': () {
    for (final team in ['team-1', 'team-2']) {
      final item = targets(vs(extras: [vf(3, 'B1', team: team)])).targets.first;
      ensure(item.status == TargetStatus.blocked, 'figura intermedia $team');
    }
  },
  'T05 §16.4b muro y fuera de alcance con visión bloqueada conservada': () {
    final world = vs(walls: [EdgeWall.between(vc('A1'), vc('B1'))]);
    ensure(
      targets(world).targets.single.status == TargetStatus.blocked,
      'muro',
    );
    final item = targets(ranged(world, 2)).targets.single;
    ensure(
      item.status == TargetStatus.outOfRange &&
          item.vision.status == VisionStatus.blocked,
      'no perder la dimensión de visión',
    );
  },
  'T06 SCOPE bases elevación poderes y versión': () {
    final base = targets(vs(sourceBase: Footprint.square2)).targets.single;
    ensure(
      base.status == TargetStatus.notEvaluated &&
          base.distance.squares == null &&
          base.range == RangeStatus.notEvaluated,
      'base no aprueba distancia',
    );
    final height = targets(vs(elevations: {'B1': 1})).targets.single;
    ensure(
      height.status == TargetStatus.notEvaluated &&
          height.vision.canSee == null &&
          height.distance.squares == 3,
      'distancia de casillas conocida, visión de altura pendiente',
    );
    for (final context in [
      VisionContext(features: [VisionFeature.powersOrSizes]),
      VisionContext(rulesVersion: 'futura'),
    ]) {
      final item = targets(vs(), context: context).targets.single;
      ensure(
        item.status == TargetStatus.notEvaluated &&
            item.range == RangeStatus.notEvaluated,
        'sin aprobado automático',
      );
    }
  },
  'T07 SCOPE origen inválido y escenario sin otros objetivos': () {
    ensure(targets(vs(), source: 'missing').error != null, 'origen borrado');
    ensure(targets(vs(destination: false)).targets.isEmpty, 'solo origen');
  },
  'T08 SCOPE ocupación incompatible': () {
    for (final world in [
      vs(extras: [vf(3, 'A1')]),
      vs(terrain: {'A1': TerrainType.blocking}),
    ]) {
      final item = targets(world).targets.first;
      ensure(
        item.status == TargetStatus.notEvaluated &&
            item.range == RangeStatus.notEvaluated,
        'escena inválida no aprobada',
      );
    }
  },
  'T09 §11.3b alcance cero y consulta de aliados': () {
    final report = targets(ranged(vs(extras: [vf(3, 'A3')]), 0));
    ensure(
      report.targets.every((t) => t.status == TargetStatus.outOfRange),
      'otras figuras fuera de alcance cero',
    );
    ensure(
      report.targets.last.pending.any((p) => p.contains('Mismo equipo')),
      'aliado consultable sin declarar legalidad',
    );
  },
  'T10 §11.5/12.1 referencias pendientes e inmutabilidad': () {
    final report = targets(vs());
    final item = report.targets.single;
    ensure(
      item.rules.contains(TacticalRule.targets) &&
          item.pending.any((s) => s.contains('Legalidad completa')),
      'no permiso de ataque',
    );
    var immutable = false;
    try {
      report.targets.clear();
    } on UnsupportedError {
      immutable = true;
    }
    ensure(immutable, 'salida inmutable');
    immutable = false;
    try {
      item.pending.clear();
    } on UnsupportedError {
      immutable = true;
    }
    ensure(immutable, 'pendientes inmutables');
  },
  'T11 §16.8b regresión oblicua A1–D6/B4 dentro de alcance': () {
    final item = targets(
      ranged(
        vs(target: 'D6', rows: 6, terrain: {'B4': TerrainType.blocking}),
        5,
      ),
    ).targets.single;
    ensure(
      item.distance.squares == 5 && item.status == TargetStatus.inRangeClear,
      'mantener corrección 06',
    );
  },
};
