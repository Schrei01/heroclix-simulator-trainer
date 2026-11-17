import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/target_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';

import 'vision_contract.dart';
import 'target_contract.dart';

VisionSnapshot capable(
  VisionSnapshot world,
  Iterable<VisionAbility> abilities, {
  String id = 'figure-1',
}) => VisionSnapshot(
  dimensions: world.dimensions,
  terrain: world.terrain,
  walls: world.walls,
  characters: [
    for (final f in world.characters)
      f.id != id
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
                range: f.range,
                size: f.size,
                abilities: abilities,
              ),
            ),
  ],
);

Map<String, void Function()> advancedCases() => {
  'E01 §16.5c mismo nivel: superior bloquea e inferior no bloquea por altura':
      () {
        status(ve(vs(elevations: {'A1': 2, 'D1': 2})), VisionStatus.clear);
        status(
          ve(vs(elevations: {'A1': 2, 'D1': 2, 'B1': 3})),
          VisionStatus.blocked,
        );
        status(
          ve(vs(elevations: {'A1': 2, 'D1': 2, 'B1': 1})),
          VisionStatus.clear,
        );
        status(
          ve(
            vs(
              elevations: {'A1': 2, 'D1': 2, 'B1': 2},
              terrain: {'B1': TerrainType.hindering},
            ),
          ),
          VisionStatus.hindered,
        );
        status(
          ve(
            vs(
              elevations: {'A1': 2, 'D1': 2, 'B1': 2},
              terrain: {'B1': TerrainType.blocking},
            ),
          ),
          VisionStatus.blocked,
        );
      },
  'E02 §16.5c/d distintos niveles: borde y retirada del borde': () {
    final rim = vs(elevations: {'A1': 2});
    status(ve(rim), VisionStatus.clear);
    status(ve(rim, origin: 'D1', target: 'A1'), VisionStatus.clear);
    status(ve(vs(elevations: {'A1': 2, 'B1': 2})), VisionStatus.blocked);
    status(ve(vs(elevations: {'A1': 3, 'B1': 2})), VisionStatus.blocked);
    hasRule(ve(rim), VisionRule.rim);
  },
  'E03 §16.5c H solo de destino entre alturas y B en nivel inferior': () {
    final world = vs(
      elevations: {'D1': 2},
      terrain: {'B1': TerrainType.hindering},
    );
    status(ve(world), VisionStatus.clear);
    final h = vs(elevations: {'D1': 2}, terrain: {'D1': TerrainType.hindering});
    status(ve(h), VisionStatus.hindered);
    status(ve(h, origin: 'D1', target: 'A1'), VisionStatus.clear);
    status(
      ve(vs(elevations: {'D1': 2}, terrain: {'B1': TerrainType.blocking})),
      VisionStatus.blocked,
    );
  },
  'E04 §16.5c/21.2b tamaños de figuras intermedias': () {
    status(
      ve(vs(elevations: {'D1': 2}, extras: [vf(3, 'B1')])),
      VisionStatus.clear,
    );
    status(
      ve(vs(extras: [vf(3, 'B1', size: FigureSize.tiny)])),
      VisionStatus.clear,
    );
    for (final size in [FigureSize.giant, FigureSize.colossal]) {
      status(
        ve(
          vs(
            elevations: {'D1': 2},
            extras: [vf(3, 'B1', size: size)],
          ),
        ),
        VisionStatus.blocked,
      );
    }
  },
  'E05 §16.5e muro en borde ocupa ambos niveles': () {
    final edge = EdgeWall.between(vc('A1'), vc('B1'));
    final world = vs(elevations: {'A1': 2}, walls: [edge]);
    status(ve(world), VisionStatus.blocked);
    status(ve(capable(world, [VisionAbility.elevated])), VisionStatus.blocked);
    status(ve(capable(world, [VisionAbility.blocking])), VisionStatus.clear);
    status(
      ve(
        vs(
          elevations: {'A1': 2, 'D1': 2},
          walls: [EdgeWall.between(vc('B1'), vc('C1'))],
        ),
      ),
      VisionStatus.clear,
    );
  },
  'I01 §27.6a IT Elevación no ignora B ni muros': () {
    final world = vs(elevations: {'B1': 2});
    status(ve(capable(world, [VisionAbility.elevated])), VisionStatus.clear);
    final mixed = vs(
      elevations: {'B1': 2},
      terrain: {'C1': TerrainType.blocking},
    );
    status(ve(capable(mixed, [VisionAbility.elevated])), VisionStatus.blocked);
    status(ve(capable(mixed, [VisionAbility.blocking])), VisionStatus.blocked);
    status(
      ve(capable(mixed, [VisionAbility.elevated, VisionAbility.blocking])),
      VisionStatus.clear,
    );
  },
  'I02 §27.6b IT H no ignora muro ni personaje': () {
    final world = vs(terrain: {'B1': TerrainType.hindering});
    final r = ve(capable(world, [VisionAbility.hindering]));
    status(r, VisionStatus.clear);
    ensure(
      r.observations.any(
        (o) => o.description.contains('ignorado por IT Obstaculizado'),
      ),
      'explicar H ignorado',
    );
    status(
      ve(
        capable(
          vs(
            terrain: {'B1': TerrainType.hindering},
            walls: [EdgeWall.between(vc('C1'), vc('D1'))],
          ),
          [VisionAbility.hindering],
        ),
      ),
      VisionStatus.blocked,
    );
  },
  'I03 §27.6c IT B ignora terreno B y muro, no figura': () {
    final world = vs(
      terrain: {'B1': TerrainType.blocking},
      walls: [EdgeWall.between(vc('C1'), vc('D1'))],
    );
    status(ve(capable(world, [VisionAbility.blocking])), VisionStatus.clear);
    status(
      ve(
        capable(
          vs(terrain: {'B1': TerrainType.blocking}, extras: [vf(3, 'C1')]),
          [VisionAbility.blocking],
        ),
      ),
      VisionStatus.blocked,
    );
  },
  'I04 §27.6e IT personajes no ignora H ni B': () {
    final world = vs(extras: [vf(3, 'B1')]);
    status(ve(capable(world, [VisionAbility.characters])), VisionStatus.clear);
    status(
      ve(
        capable(
          vs(extras: [vf(3, 'B1')], terrain: {'C1': TerrainType.hindering}),
          [VisionAbility.characters],
        ),
      ),
      VisionStatus.hindered,
    );
    status(
      ve(
        capable(
          vs(extras: [vf(3, 'B1')], terrain: {'C1': TerrainType.blocking}),
          [VisionAbility.characters],
        ),
      ),
      VisionStatus.blocked,
    );
  },
  'I05 fuente de capacidad y laboratorio inmutable': () {
    final world = vs(terrain: {'B1': TerrainType.blocking});
    status(
      ve(capable(world, [VisionAbility.blocking], id: 'figure-2')),
      VisionStatus.blocked,
    );
    final saved = capable(world, [VisionAbility.blocking]);
    status(ve(saved), VisionStatus.clear);
    final lab = <VisionAbility>{};
    final context = VisionContext(laboratoryAbilities: lab);
    lab.add(VisionAbility.blocking);
    status(ve(saved, context: context), VisionStatus.blocked);
    ensure(
      saved.characters.first.abilities.contains(VisionAbility.blocking),
      'ficha intacta',
    );
  },
  'I06 SCOPE capacidades y tamaños de extremo sin soporte': () {
    status(
      ve(capable(vs(), [VisionAbility.other], id: 'figure-2')),
      VisionStatus.notEvaluated,
    );
    for (final a in VisionAbility.values.where((a) => !a.supported)) {
      final r = ve(capable(vs(), [a]));
      status(r, VisionStatus.notEvaluated);
      hasRule(r, VisionRule.limit);
    }
    for (final size in FigureSize.values.where((s) => s != FigureSize.normal)) {
      final world = vs(source: false, extras: [vf(1, 'A1', size: size)]);
      status(ve(world), VisionStatus.notEvaluated);
    }
  },
  'B01 §24.2/24.2e formatos y rotaciones reconocidos': () {
    for (final base in Footprint.supported) {
      final r = targets(
        ranged(vs(target: 'H8', rows: 8, columns: 8, sourceBase: base), 99),
      ).targets.single;
      ensure(r.status == TargetStatus.inRangeClear, 'base ${base.label}');
      ensure(
        r.vision.references.length == base.width * base.height,
        'todas las referencias',
      );
    }
    final r = targets(
      ranged(
        vs(
          target: 'G6',
          rows: 8,
          columns: 12,
          sourceBase: Footprint.rectangle(width: 3, height: 6),
          targetBase: Footprint.rectangle(width: 6, height: 3),
        ),
        99,
      ),
    ).targets.single;
    ensure(
      r.vision.references.length == 324 && r.distance.squares == 4,
      '18 por 18 pares, mismo par de distancia y visión',
    );
  },
  'B02 §11.5 rango y visión no se combinan de pares distintos': () {
    final world = vs(
      target: 'B3',
      targetBase: Footprint.rectangle(width: 1, height: 2),
      walls: [EdgeWall.between(vc('A2'), vc('B2'))],
    );
    final near = targets(ranged(world, 2)).targets.single;
    ensure(
      near.status == TargetStatus.blocked && near.distance.squares == 2,
      'cercana bloqueada, lejana visible fuera de rango',
    );
    final far = targets(ranged(world, 3)).targets.single;
    ensure(
      far.status == TargetStatus.inRangeClear &&
          far.distance.squares == 3 &&
          far.vision.destination!.cell == vc('B4'),
      'par B4 sí visible y en alcance 3',
    );
  },
  'B03 §16.5g base normal sobre varios niveles y base desconocida': () {
    status(
      ve(
        vs(target: 'D4', sourceBase: Footprint.square2, elevations: {'B2': 2}),
        target: 'D4',
      ),
      VisionStatus.notEvaluated,
    );
    status(
      ve(vs(sourceBase: Footprint.rectangle(width: 3, height: 3))),
      VisionStatus.notEvaluated,
    );
  },
  'B04 IT personajes ignora toda huella intermedia reconocida': () {
    final world = vs(
      target: 'D4',
      extras: [vf(3, 'B2', footprint: Footprint.square2)],
    );
    status(ve(world, target: 'D4'), VisionStatus.blocked);
    status(
      ve(capable(world, [VisionAbility.characters]), target: 'D4'),
      VisionStatus.clear,
    );
  },
  'E06 §16.8b esquina combina elevación y excepción independiente': () {
    final world = vs(
      target: 'B2',
      terrain: {'B1': TerrainType.blocking},
      elevations: {'A2': 2},
    );
    status(ve(world, target: 'B2'), VisionStatus.blocked);
    status(
      ve(capable(world, [VisionAbility.elevated]), target: 'B2'),
      VisionStatus.clear,
    );
    status(
      ve(capable(world, [VisionAbility.blocking]), target: 'B2'),
      VisionStatus.clear,
    );
  },
};
