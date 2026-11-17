import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/movement_ability.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/domain/movement/movement.dart';
import 'package:heroclix_simulator_trainer/domain/movement/movement_rules_service.dart';
import 'package:heroclix_simulator_trainer/domain/movement/route_planner.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';

import 'vision_contract.dart';

VisionSnapshot mw({
  String origin = 'A1',
  int speed = 6,
  int rows = 4,
  int columns = 4,
  Footprint base = Footprint.single,
  Iterable<MovementAbility> abilities = const [],
  List<Character> extras = const [],
  Map<String, TerrainType> terrain = const {},
  Map<String, int> elevations = const {},
  List<EdgeWall> walls = const [],
  List<EdgeWall> transitions = const [],
}) {
  final w = vs(
    origin: origin,
    destination: false,
    sourceBase: base,
    rows: rows,
    columns: columns,
    extras: extras,
    terrain: terrain,
    elevations: elevations,
    walls: walls,
  );
  var layer = w.terrain;
  for (final edge in transitions) {
    layer = layer.setTransition(edge, w.dimensions, remove: false);
  }
  return VisionSnapshot(
    dimensions: w.dimensions,
    terrain: layer,
    walls: w.walls,
    characters: [
      for (final f in w.characters)
        f.id != 'figure-1'
            ? f
            : f.revised(
                CharacterDraft(
                  name: f.name,
                  teamId: f.teamId,
                  position: f.position,
                  footprint: f.footprint,
                  speed: speed,
                  range: f.range,
                  movementAbilities: abilities,
                ),
              ),
    ],
  );
}

RouteEvaluation me(
  VisionSnapshot w,
  String route, {
  MovementContext context = const MovementContext(),
}) => const MovementRulesService().evaluate(
  w,
  'figure-1',
  route.split(' ').map(vc),
  context: context,
);
void ms(RouteEvaluation result, MovementStatus expected) {
  if (result.status != expected) {
    throw StateError(
      'Esperado $expected, obtenido ${result.status}: ${result.reason}',
    );
  }
}

void checkMove(bool condition, String reason) {
  if (!condition) throw StateError(reason);
}

Map<String, void Function()> movementCases() => {
  'M27 §24.2d separación de toda la base, pasos de la referencia elegida': () {
    ms(
      me(
        mw(
          base: Footprint.square2,
          extras: [vf(2, 'D3', team: 'team-2')],
        ),
        'A1 B1 C1',
      ),
      MovementStatus.valid,
    );
    ms(
      me(
        mw(
          base: Footprint.square2,
          extras: [vf(2, 'A3', team: 'team-2')],
        ),
        'A1 B1',
      ),
      MovementStatus.notEvaluated,
    );
    final world = mw(
      base: Footprint.square2,
      extras: [vf(2, 'D3', team: 'team-2')],
    );
    checkMove(
      const RoutePlanner()
              .search(world, 'figure-1', vc('C1'))
              .routes
              .first
              .cost ==
          2,
      'El buscador usa la misma referencia para la parada de la base.',
    );
  },
  'M25 SCOPE tamaños especiales, bases desconocidas y ocupación incompatible':
      () {
        ms(
          me(mw(extras: [vf(2, 'D4', size: FigureSize.giant)]), 'A1 B1'),
          MovementStatus.notEvaluated,
        );
        ms(
          me(mw(base: Footprint.rectangle(width: 3, height: 3)), 'A1 B1'),
          MovementStatus.notEvaluated,
        );
        ms(me(mw(extras: [vf(2, 'A1')]), 'A1 B1'), MovementStatus.notEvaluated);
      },
  'M26 §24.2d formatos reconocidos: traslación libre sin giro': () {
    for (final base in Footprint.supported) {
      ms(
        me(mw(base: base, rows: 8, columns: 8), 'A1 B2'),
        MovementStatus.valid,
      );
    }
  },
  'M01 §10.2 recto y diagonal cuestan un paso; límite exacto': () {
    for (final path in ['A1 B1 C1 D1', 'A1 B2 C3 D4']) {
      final r = me(mw(speed: 3), path);
      ms(r, MovementStatus.valid);
      checkMove(r.cost == 3 && r.remaining == 0, 'Costo y presupuesto exactos');
    }
  },
  'M02 §10.2 exceder velocidad por una casilla es inválido': () {
    ms(me(mw(speed: 2), 'A1 B1 C1 D1'), MovementStatus.invalid);
  },
  'M03 §10.2/10.5 cero permitido, salto y repetición no son pasos': () {
    final w = mw(speed: 0);
    ms(me(w, 'A1'), MovementStatus.valid);
    checkMove(!me(w, 'A1').canConfirm, 'Sin operación para cero pasos');
    ms(me(mw(), 'A1 C1'), MovementStatus.invalid);
    ms(me(mw(), 'A1 A1'), MovementStatus.invalid);
  },
  'M04 §16.2a H no reduce velocidad ni fuerza parada': () {
    final r = me(
      mw(speed: 3, terrain: {'B1': TerrainType.hindering}),
      'A1 B1 C1 D1',
    );
    ms(r, MovementStatus.valid);
    checkMove(r.cost == 3, 'H sin costo adicional');
  },
  'M05 §16.3a/16.4a B y muro bloquean paso': () {
    ms(
      me(mw(terrain: {'B1': TerrainType.blocking}), 'A1 B1 C1'),
      MovementStatus.invalid,
    );
    ms(
      me(mw(walls: [EdgeWall.between(vc('A1'), vc('B1'))]), 'A1 B1'),
      MovementStatus.invalid,
    );
  },
  'M06 §16.8a esquina: lado menos restrictivo y dos bloqueados': () {
    ms(
      me(mw(terrain: {'B1': TerrainType.blocking}), 'A1 B2'),
      MovementStatus.valid,
    );
    ms(
      me(
        mw(terrain: {'B1': TerrainType.blocking, 'A2': TerrainType.blocking}),
        'A1 B2',
      ),
      MovementStatus.invalid,
    );
    ms(
      me(
        mw(
          walls: [
            EdgeWall.between(vc('A1'), vc('B1')),
            EdgeWall.between(vc('A1'), vc('A2')),
          ],
        ),
        'A1 B2',
      ),
      MovementStatus.invalid,
    );
  },
  'M07 §16.8a un muro a cada lado inspecciona ambos tramos': () {
    ms(
      me(
        mw(
          walls: [
            EdgeWall.between(vc('A1'), vc('B1')),
            EdgeWall.between(vc('A2'), vc('B2')),
          ],
        ),
        'A1 B2',
      ),
      MovementStatus.invalid,
    );
  },
  'M08 §10.7a/13.2 atraviesa aliado, no termina ocupado': () {
    final w = mw(extras: [vf(2, 'B1')]);
    ms(me(w, 'A1 B1 C1'), MovementStatus.valid);
    ms(me(w, 'A1 B1'), MovementStatus.invalid);
  },
  'M09 §10.8 separación sin dados permanece no evaluada': () {
    for (final a in [
      <MovementAbility>[],
      [MovementAbility.moveThrough],
    ]) {
      ms(
        me(
          mw(
            extras: [vf(2, 'A2', team: 'team-2')],
            abilities: a,
          ),
          'A1 B1',
        ),
        MovementStatus.notEvaluated,
      );
    }
  },
  'M10 §10.7b entrar en adyacencia permite terminar pero no continuar': () {
    final w = mw(extras: [vf(2, 'D2', team: 'team-2')]);
    ms(me(w, 'A1 B1 C1'), MovementStatus.valid);
    ms(me(w, 'A1 B1 C1 D1'), MovementStatus.invalid);
  },
  'M11 §16.4c/16.8c muro/esquina B retiran adyacencia': () {
    final rules = const MovementRulesService();
    final w = mw(
      extras: [vf(2, 'A2', team: 'team-2')],
      walls: [EdgeWall.between(vc('A1'), vc('A2'))],
    );
    checkMove(
      !rules.besideEnemy(w, w.characters.first, vc('A1')),
      'Muro retira adyacencia',
    );
    ms(me(w, 'A1 B1'), MovementStatus.valid);
    final corner = mw(
      extras: [vf(2, 'B2', team: 'team-2')],
      terrain: {'A2': TerrainType.blocking, 'B1': TerrainType.blocking},
    );
    checkMove(
      !rules.besideEnemy(corner, corner.characters.first, vc('A1')),
      'Esquina cerrada no es adyacente',
    );
  },
  'M12 §16.5a cruzar altura obliga a terminar, no impide entrar': () {
    final w = mw(elevations: {'B1': 2, 'C1': 2});
    ms(me(w, 'A1 B1'), MovementStatus.valid);
    ms(me(w, 'A1 B1 C1'), MovementStatus.invalid);
    ms(
      me(mw(origin: 'B1', elevations: {'B1': 2}), 'B1 A1'),
      MovementStatus.valid,
    );
  },
  'M13 §16.7b transición conectada permite continuar ortogonalmente': () {
    final w = mw(
      elevations: {'B1': 2, 'C1': 2},
      transitions: [EdgeWall.between(vc('A1'), vc('B1'))],
    );
    ms(me(w, 'A1 B1 C1'), MovementStatus.valid);
    final diagonal = mw(
      elevations: {'B1': 2, 'B2': 2, 'C2': 2},
      transitions: [EdgeWall.between(vc('A1'), vc('B1'))],
    );
    ms(me(diagonal, 'A1 B2 C2'), MovementStatus.invalid);
  },
  'M14 §16.8a mezcla B/altura detiene; IM específico abre solo su lado': () {
    final w = mw(terrain: {'B1': TerrainType.blocking}, elevations: {'A2': 2});
    ms(me(w, 'A1 B2'), MovementStatus.valid);
    ms(me(w, 'A1 B2 C2'), MovementStatus.invalid);
    ms(
      me(
        mw(
          terrain: {'B1': TerrainType.blocking},
          elevations: {'A2': 2},
          abilities: [MovementAbility.elevated],
        ),
        'A1 B2 C2',
      ),
      MovementStatus.valid,
    );
  },
  'M15 §27.5a IM altura conserva muros y B': () {
    ms(
      me(
        mw(
          elevations: {'B1': 2, 'C1': 2},
          abilities: [MovementAbility.elevated],
        ),
        'A1 B1 C1',
      ),
      MovementStatus.valid,
    );
    ms(
      me(
        mw(
          terrain: {'B1': TerrainType.blocking},
          abilities: [MovementAbility.elevated],
        ),
        'A1 B1 C1',
      ),
      MovementStatus.invalid,
    );
  },
  'M16 §27.5b/13.2 IM B atraviesa B/muro, no acaba en B': () {
    final w = mw(
      terrain: {'B1': TerrainType.blocking},
      walls: [EdgeWall.between(vc('A1'), vc('B1'))],
      abilities: [MovementAbility.blocking],
    );
    ms(me(w, 'A1 B1 C1'), MovementStatus.valid);
    ms(me(w, 'A1 B1'), MovementStatus.invalid);
  },
  'M17 §27.5e IM personajes separa y atraviesa, no termina ocupado': () {
    final w = mw(
      extras: [vf(2, 'B1', team: 'team-2')],
      abilities: [MovementAbility.characters],
    );
    ms(me(w, 'A1 B1 C1'), MovementStatus.valid);
    ms(me(w, 'A1 B1'), MovementStatus.invalid);
    ms(
      me(
        mw(
          extras: [vf(2, 'B1', team: 'team-2')],
          terrain: {'A2': TerrainType.blocking},
          abilities: [MovementAbility.characters],
        ),
        'A1 A2',
      ),
      MovementStatus.invalid,
    );
  },
  'M18 §27.5f IM atravesar ignora parada por enemigo nuevo': () {
    final w = mw(
      extras: [vf(2, 'D2', team: 'team-2')],
      abilities: [MovementAbility.moveThrough],
    );
    ms(me(w, 'A1 B1 C1 D1'), MovementStatus.valid);
  },
  'M19 §24.2d traslación 2x2 libre y final fuera del tablero': () {
    final w = mw(base: Footprint.square2);
    ms(me(w, 'A1 B1 C1'), MovementStatus.valid);
    ms(me(w, 'A1 B1 C1 D1'), MovementStatus.invalid);
  },
  'M20 §24.2d huella lateral no se aprueba sobre obstáculo': () {
    final w = mw(
      base: Footprint.square2,
      walls: [EdgeWall.between(vc('B2'), vc('C2'))],
    );
    ms(me(w, 'A1 B1 C1'), MovementStatus.notEvaluated);
    ms(me(w, 'A1 B1'), MovementStatus.invalid);
    ms(
      me(
        mw(base: Footprint.square2, terrain: {'C2': TerrainType.blocking}),
        'A1 B1',
      ),
      MovementStatus.invalid,
    );
  },
  'M21 §3.1 límite y perfil/versionado desconocidos': () {
    ms(me(mw(), 'A1 A2 A3 A4 A5'), MovementStatus.invalid);
    ms(
      me(mw(), 'A1 B1', context: const MovementContext(rulesVersion: 'futura')),
      MovementStatus.notEvaluated,
    );
    for (final a in MovementAbility.values.where((a) => !a.supported)) {
      ms(me(mw(abilities: [a]), 'A1 B1'), MovementStatus.notEvaluated);
    }
    ms(
      me(mw(), 'A1 B1', context: const MovementContext(specialEffects: true)),
      MovementStatus.notEvaluated,
    );
  },
  'M22 §10.2/16.4a búsqueda rodea muro: más larga que distancia directa': () {
    final w = mw(
      speed: 4,
      walls: [
        EdgeWall.between(vc('A1'), vc('B1')),
        EdgeWall.between(vc('A2'), vc('B2')),
      ],
    );
    ms(me(w, 'A1 B1 C1'), MovementStatus.invalid);
    final search = const RoutePlanner().search(w, 'figure-1', vc('C1'));
    checkMove(search.routes.isNotEmpty, 'Existe alternativa verificada');
    checkMove(
      search.routes.first.cost == 4,
      'Muro hasta fila 2 exige cuatro pasos',
    );
    for (final r in search.routes) {
      ms(r, MovementStatus.valid);
      ms(me(w, r.route.map((c) => c.label).join(' ')), MovementStatus.valid);
    }
    final short = mw(
      speed: 3,
      walls: [
        EdgeWall.between(vc('A1'), vc('B1')),
        EdgeWall.between(vc('A2'), vc('B2')),
      ],
    );
    checkMove(
      const RoutePlanner().search(short, 'figure-1', vc('C1')).routes.isEmpty,
      'No promete una ruta fuera de presupuesto',
    );
  },
  'M23 §10.7a/27.5b buscador admite prefijos ocupados o B': () {
    for (final w in [
      mw(
        terrain: {
          'A2': TerrainType.blocking,
          'B2': TerrainType.blocking,
          'C2': TerrainType.blocking,
        },
        extras: [vf(2, 'B1')],
        speed: 2,
      ),
      mw(
        terrain: {
          'A2': TerrainType.blocking,
          'B2': TerrainType.blocking,
          'C2': TerrainType.blocking,
          'B1': TerrainType.blocking,
        },
        abilities: [MovementAbility.blocking],
        speed: 2,
      ),
    ]) {
      final r = const RoutePlanner().search(w, 'figure-1', vc('C1'));
      checkMove(
        r.routes.isNotEmpty && r.routes.first.cost == 2,
        'Prefijo transitable no es necesariamente un destino legal',
      );
    }
  },
  'M24 snapshot y resultados inmutables; sin ruta no demuestra imposibilidad general':
      () {
        final w = mw(speed: 1), p = [vc('A1'), vc('B1')];
        final r = const MovementRulesService().evaluate(w, 'figure-1', p);
        p.clear();
        checkMove(
          r.route.length == 2 && w.characters.first.position == vc('A1'),
          'No muta ruta ni origen',
        );
        final none = const RoutePlanner().search(w, 'figure-1', vc('D4'));
        checkMove(
          none.routes.isEmpty &&
              none.reason.contains('bajo las reglas implementadas'),
          'Mensaje acotado',
        );
      },
};
