// Expectativas derivadas de secciones verificadas antes del motor; ver matriz.
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight_service.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';

CellCoordinate vc(String label) => CellCoordinate.parse(label);
void ensure(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Character vf(
  int number,
  String position, {
  String team = 'team-1',
  Footprint footprint = Footprint.single,
  int range = 4,
}) => Character(
  id: 'figure-$number',
  label: String.fromCharCode(64 + number),
  data: CharacterDraft(
    name: 'Figura $number',
    teamId: team,
    position: vc(position),
    footprint: footprint,
    range: range,
  ),
);
VisionSnapshot vs({
  String origin = 'A1',
  String target = 'D1',
  int rows = 4,
  int columns = 4,
  Map<String, TerrainType> terrain = const {},
  List<EdgeWall> walls = const [],
  List<Character> extras = const [],
  bool source = true,
  bool destination = true,
  Footprint sourceBase = Footprint.single,
  Map<String, int> elevations = const {},
}) {
  final dimensions = BoardDimensions(rows: rows, columns: columns);
  var layer = const TerrainLayer.empty();
  for (final label in {...terrain.keys, ...elevations.keys}) {
    layer = layer.put(
      vc(label),
      CellTerrain(
        type: terrain[label] ?? TerrainType.clear,
        elevation: elevations[label] ?? 0,
      ),
      dimensions,
    );
  }
  return VisionSnapshot(
    dimensions: dimensions,
    characters: [
      if (source) vf(1, origin, footprint: sourceBase),
      if (destination) vf(2, target, team: 'team-2'),
      ...extras,
    ],
    terrain: layer,
    walls: const WallLayer.empty().edit(walls, dimensions, erase: false),
  );
}

VisionEvaluation ve(
  VisionSnapshot world, {
  String origin = 'A1',
  String target = 'D1',
  VisionContext? context,
  String? sourceId,
  String? targetId,
}) => const LineOfSightService().evaluate(
  world,
  VisionEndpoint(vc(origin), figureId: sourceId),
  VisionEndpoint(vc(target), figureId: targetId),
  context ?? VisionContext(),
);
void status(VisionEvaluation evaluation, VisionStatus expected) => ensure(
  evaluation.status == expected,
  '${evaluation.status} != $expected: ${evaluation.explanation}',
);
void hasRule(VisionEvaluation evaluation, VisionRule rule) => ensure(
  evaluation.observations.any((o) => o.rules.contains(rule)),
  'Falta ${rule.id}',
);

Map<String, void Function()> visionCases() => {
  'R01 §11.4/11.4c horizontal y vertical despejadas': () {
    for (final target in ['D1', 'A4']) {
      final r = ve(vs(target: target), target: target);
      status(r, VisionStatus.clear);
      ensure(r.canSee == true, 'puede trazar');
      hasRule(r, VisionRule.center);
      ensure(
        r.observations.any((o) => o.description.contains('extremo excluida')),
        'excluir figuras de extremos',
      );
    }
  },
  'R02 §16.2b obstaculizado intermedio permite visión': () {
    final r = ve(vs(terrain: {'B1': TerrainType.hindering}));
    status(r, VisionStatus.hindered);
    ensure(r.canSee == true, 'obstaculizada no bloquea');
    hasRule(r, VisionRule.hindering);
    ensure(r.decisive.any((o) => o.cells.contains(vc('B1'))), 'identificar B1');
  },
  'R03 §16.3b bloqueado intermedio': () {
    final r = ve(vs(terrain: {'B1': TerrainType.blocking}));
    status(r, VisionStatus.blocked);
    ensure(r.canSee == false, 'no puede trazar');
    hasRule(r, VisionRule.blocking);
  },
  'R04 §16.4b muro cruzado por el interior': () {
    final wall = EdgeWall.between(vc('A1'), vc('B1'));
    final r = ve(vs(walls: [wall]));
    status(r, VisionStatus.blocked);
    hasRule(r, VisionRule.wall);
    ensure(r.decisive.any((o) => o.edges.contains(wall)), 'identificar muro');
  },
  'R05 §11.4c figura intermedia aliada o enemiga': () {
    for (final team in ['team-1', 'team-2']) {
      final r = ve(vs(extras: [vf(3, 'B1', team: team)]));
      status(r, VisionStatus.blocked);
      hasRule(r, VisionRule.character);
      ensure(
        r.decisive.any((o) => o.figures.contains('figure-3')),
        'identificar figura C',
      );
    }
  },
  'R06 §16.2b obstaculizado de origen excluido y destino incluido': () {
    status(ve(vs(terrain: {'A1': TerrainType.hindering})), VisionStatus.clear);
    status(
      ve(vs(terrain: {'D1': TerrainType.hindering})),
      VisionStatus.hindered,
    );
  },
  'R07 §13.2 ocupación incompatible y §16.3b casilla objetivo bloqueada': () {
    for (final cell in ['A1', 'D1']) {
      final r = ve(vs(terrain: {cell: TerrainType.blocking}));
      status(r, VisionStatus.notEvaluated);
      hasRule(r, VisionRule.occupancy);
    }
    status(
      ve(vs(destination: false, terrain: {'D1': TerrainType.blocking})),
      VisionStatus.blocked,
    );
  },
  'R08 §16.8b nueve combinaciones de terrenos laterales': () {
    const c = TerrainType.clear,
        h = TerrainType.hindering,
        b = TerrainType.blocking;
    // Tabla literal de la regla del lado menos restrictivo, no generada por el motor.
    for (final (one, two, expected) in [
      (c, c, VisionStatus.clear),
      (c, h, VisionStatus.clear),
      (c, b, VisionStatus.clear),
      (h, c, VisionStatus.clear),
      (h, h, VisionStatus.hindered),
      (h, b, VisionStatus.hindered),
      (b, c, VisionStatus.clear),
      (b, h, VisionStatus.hindered),
      (b, b, VisionStatus.blocked),
    ]) {
      final r = ve(
        vs(target: 'B2', terrain: {'B1': one, 'A2': two}),
        target: 'B2',
      );
      status(r, expected);
      hasRule(r, VisionRule.corner);
      ensure(
        r.observations
                .where(
                  (o) => !o.contributes && o.description.startsWith('Lado'),
                )
                .length ==
            2,
        'registrar ambos lados',
      );
    }
  },
  'R09 §16.8b dieciséis configuraciones de muros terminales': () {
    final edges = [
      EdgeWall(axis: EdgeAxis.vertical, column: 1, row: 0),
      EdgeWall(axis: EdgeAxis.horizontal, column: 1, row: 1),
      EdgeWall(axis: EdgeAxis.horizontal, column: 0, row: 1),
      EdgeWall(axis: EdgeAxis.vertical, column: 1, row: 1),
    ];
    const expected = [
      VisionStatus.clear,
      VisionStatus.clear,
      VisionStatus.clear,
      VisionStatus.clear,
      VisionStatus.clear,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.clear,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.clear,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.blocked,
    ];
    for (var mask = 0; mask < 16; mask++) {
      status(
        ve(
          vs(
            target: 'B2',
            walls: [
              for (var i = 0; i < 4; i++)
                if (mask & (1 << i) != 0) edges[i],
            ],
          ),
          target: 'B2',
        ),
        expected[mask],
      );
    }
  },
  'R10 §16.8b personajes laterales y terreno mixto': () {
    status(
      ve(
        vs(target: 'B2', extras: [vf(3, 'B1')]),
        target: 'B2',
      ),
      VisionStatus.clear,
    );
    status(
      ve(
        vs(
          target: 'B2',
          extras: [
            vf(3, 'B1'),
            vf(4, 'A2', team: 'team-2'),
          ],
        ),
        target: 'B2',
      ),
      VisionStatus.blocked,
    );
    status(
      ve(
        vs(
          target: 'B2',
          extras: [vf(3, 'B1')],
          terrain: {'A2': TerrainType.hindering},
        ),
        target: 'B2',
      ),
      VisionStatus.hindered,
    );
  },
  'R11 §16.3b bloqueo interior domina obstaculizado y esquinas libres': () {
    final r = ve(
      vs(
        target: 'D4',
        terrain: {'B2': TerrainType.hindering, 'C3': TerrainType.blocking},
      ),
      target: 'D4',
    );
    status(r, VisionStatus.blocked);
    ensure(
      r.decisive.every((o) => o.effect == VisionEffect.blocking),
      'solo causas del resultado final',
    );
    ensure(r.decisive.any((o) => o.cells.contains(vc('C3'))), 'C3 decisiva');
  },
  'R12 §11.4c/16.2b/16.3b modificación y determinismo': () {
    final original = vs();
    status(ve(original), VisionStatus.clear);
    status(
      ve(vs(terrain: {'B1': TerrainType.hindering})),
      VisionStatus.hindered,
    );
    final altered = vs(terrain: {'B1': TerrainType.blocking});
    final a = ve(altered), b = ve(altered);
    status(a, VisionStatus.blocked);
    ensure(
      a.observations
              .map((o) => '${o.effect}:${o.description}:${o.rules}')
              .join('|') ==
          b.observations
              .map((o) => '${o.effect}:${o.description}:${o.rules}')
              .join('|'),
      'registro determinista',
    );
    ensure(original.terrain.isEmpty, 'snapshot no mutado');
  },
  'R13 cobertura versión y capacidades especiales no soportadas': () {
    status(
      ve(vs(), context: VisionContext(rulesVersion: '2099-01-01')),
      VisionStatus.notEvaluated,
    );
    for (final feature in VisionFeature.values) {
      final r = ve(vs(), context: VisionContext(features: [feature]));
      status(r, VisionStatus.notEvaluated);
      hasRule(r, switch (feature) {
        VisionFeature.powersOrSizes => VisionRule.powers,
        VisionFeature.remoteSource => VisionRule.hindering,
        VisionFeature.specialMap => VisionRule.specialMap,
      });
      ensure(r.canSee == null, 'visibilidad desconocida');
    }
  },
  'R14 cobertura §16.5c elevación relevante': () {
    for (final cell in ['A1', 'B1', 'D1']) {
      final r = ve(vs(elevations: {cell: 1}));
      status(r, VisionStatus.notEvaluated);
      hasRule(r, VisionRule.elevation);
    }
    status(ve(vs(elevations: {'A4': 2})), VisionStatus.clear);
  },
  'R15 cobertura §24.2e bases múltiples relevantes': () {
    status(
      ve(
        vs(target: 'D4', sourceBase: Footprint.square2),
        target: 'D4',
      ),
      VisionStatus.notEvaluated,
    );
    status(
      ve(
        vs(
          target: 'D4',
          extras: [vf(3, 'B2', footprint: Footprint.square2)],
        ),
        target: 'D4',
      ),
      VisionStatus.notEvaluated,
    );
    status(
      ve(vs(extras: [vf(3, 'A3', footprint: Footprint.square2)])),
      VisionStatus.clear,
    );
  },
  'R16 cobertura identidades, referencias y superposición inválidas': () {
    status(ve(vs(), sourceId: 'missing'), VisionStatus.notEvaluated);
    status(ve(vs(), targetId: 'missing'), VisionStatus.notEvaluated);
    status(ve(vs(), sourceId: 'figure-2'), VisionStatus.notEvaluated);
    final outside = ve(vs(), target: 'E1');
    status(outside, VisionStatus.notEvaluated);
    ensure(outside.trace == null, 'sin línea inválida');
    for (final extra in [
      vf(3, 'A1'),
      vf(1, 'B1'),
      vf(3, 'D4', footprint: Footprint.square2),
    ]) {
      status(ve(vs(extras: [extra])), VisionStatus.notEvaluated);
    }
  },
  'R17 §16.8b vértices con pendiente distinta de 45 grados': () {
    status(
      ve(vs(target: 'D10', rows: 10, columns: 4), target: 'D10'),
      VisionStatus.clear,
    );
    status(
      ve(vs(target: 'E3', rows: 3, columns: 6), target: 'E3'),
      VisionStatus.clear,
    );
  },
  'R18 §11.4b sí mismo despejado y clasificación pendiente sobre H': () {
    final r = ve(vs(destination: false), target: 'A1');
    status(r, VisionStatus.clear);
    hasRule(r, VisionRule.self);
    status(
      ve(
        vs(destination: false, terrain: {'A1': TerrainType.hindering}),
        target: 'A1',
      ),
      VisionStatus.notEvaluated,
    );
  },
  'R19 cobertura origen vacío y casilla objetivo sin figura': () {
    status(ve(vs(source: false)), VisionStatus.notEvaluated);
    status(ve(vs(destination: false)), VisionStatus.clear);
    status(
      ve(vs(destination: false, terrain: {'D1': TerrainType.hindering})),
      VisionStatus.hindered,
    );
  },
  'R20 §11.4 tablero 40×40 e inmutabilidad de salida': () {
    final r = ve(vs(target: 'AN40', rows: 40, columns: 40), target: 'AN40');
    status(r, VisionStatus.clear);
    ensure(r.trace!.segments.length == 40, 'geometría completa');
    var immutable = false;
    try {
      r.observations.clear();
    } on UnsupportedError {
      immutable = true;
    }
    ensure(immutable, 'registro inmutable');
  },
  'R21 §16.2b dirección importa en terreno de extremos': () {
    final world = vs(terrain: {'A1': TerrainType.hindering});
    status(ve(world), VisionStatus.clear);
    status(ve(world, origin: 'D1', target: 'A1'), VisionStatus.hindered);
  },
  'R22 §11.4 registro vincula eventos y no evalúa alcance': () {
    final world = VisionSnapshot(
      dimensions: BoardDimensions.initial,
      characters: [
        vf(1, 'A1', range: 0),
        vf(2, 'D1', team: 'team-2'),
      ],
    );
    final r = ve(world);
    status(r, VisionStatus.clear);
    for (final o in r.observations) {
      ensure(o.rules.isNotEmpty, 'referencia de regla');
      if (o.eventIndex != null) {
        ensure(
          o.eventIndex! >= 0 && o.eventIndex! < r.trace!.events.length,
          'evento existente',
        );
      }
    }
  },
  'R23 §16.8b regresión A1–D6 con B4 bloqueado': () {
    final world = vs(
      target: 'D6',
      rows: 6,
      terrain: {'B4': TerrainType.blocking},
    );
    for (final (origin, target) in [('A1', 'D6'), ('D6', 'A1')]) {
      final r = ve(world, origin: origin, target: target);
      status(r, VisionStatus.clear);
      ensure(r.canSee == true, 'el contacto aislado con B4 no bloquea');
      final vertex = r.trace!.crossings.singleWhere((c) => c.isVertex);
      ensure(
        vertex.cornerOnly.toSet().containsAll([vc('B4'), vc('C3')]),
        'B4 y C3 son laterales; no se atraviesa su interior',
      );
      ensure(
        !r.trace!.segments.any((s) => s.cell == vc('B4')),
        'B4 solo toca el vértice',
      );
      hasRule(r, VisionRule.corner);
      ensure(
        r.observations.any(
          (o) =>
              o.contributes &&
              o.rules.contains(VisionRule.corner) &&
              o.effect == VisionEffect.none &&
              o.cells.contains(vc('C3')),
        ),
        'el registro identifica el lado C3 sin restricción',
      );
    }
  },
  'R24 §16.8b A1–D6 nueve pares laterales y otras restricciones': () {
    const c = TerrainType.clear,
        h = TerrainType.hindering,
        b = TerrainType.blocking;
    for (final (one, two, expected) in [
      (c, c, VisionStatus.clear),
      (c, h, VisionStatus.clear),
      (c, b, VisionStatus.clear),
      (h, c, VisionStatus.clear),
      (h, h, VisionStatus.hindered),
      (h, b, VisionStatus.hindered),
      (b, c, VisionStatus.clear),
      (b, h, VisionStatus.hindered),
      (b, b, VisionStatus.blocked),
    ]) {
      final world = vs(target: 'D6', rows: 6, terrain: {'B4': one, 'C3': two});
      for (final (origin, target) in [('A1', 'D6'), ('D6', 'A1')]) {
        status(ve(world, origin: origin, target: target), expected);
      }
    }
    // El lado libre del vértice no evita bloqueos realmente atravesados.
    for (final cell in ['B3', 'C4']) {
      status(
        ve(
          vs(target: 'D6', rows: 6, terrain: {'B4': b, cell: b}),
          target: 'D6',
        ),
        VisionStatus.blocked,
      );
    }
    status(
      ve(
        vs(target: 'D6', rows: 6, extras: [vf(3, 'B4')]),
        target: 'D6',
      ),
      VisionStatus.clear,
    );
    status(
      ve(
        vs(target: 'D6', rows: 6, extras: [vf(3, 'B4'), vf(4, 'C3')]),
        target: 'D6',
      ),
      VisionStatus.blocked,
    );
    status(
      ve(
        vs(target: 'D6', rows: 6, terrain: {'B4': b}, elevations: {'C3': 1}),
        target: 'D6',
      ),
      VisionStatus.notEvaluated,
    );
  },
  'R25 §16.8b A1–D6 dieciséis pares de muros incidentes': () {
    // Primero los dos bordes de B4; después los dos de C3.
    final edges = [
      EdgeWall.between(vc('B3'), vc('B4')),
      EdgeWall.between(vc('B4'), vc('C4')),
      EdgeWall.between(vc('B3'), vc('C3')),
      EdgeWall.between(vc('C3'), vc('C4')),
    ];
    const expected = [
      VisionStatus.clear,
      VisionStatus.clear,
      VisionStatus.clear,
      VisionStatus.clear,
      VisionStatus.clear,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.clear,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.clear,
      VisionStatus.blocked,
      VisionStatus.blocked,
      VisionStatus.blocked,
    ];
    for (var mask = 0; mask < 16; mask++) {
      final world = vs(
        target: 'D6',
        rows: 6,
        walls: [
          for (var i = 0; i < 4; i++)
            if (mask & (1 << i) != 0) edges[i],
        ],
      );
      status(ve(world, target: 'D6'), expected[mask]);
      status(ve(world, origin: 'D6', target: 'A1'), expected[mask]);
    }
  },
};
