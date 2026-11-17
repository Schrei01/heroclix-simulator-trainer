import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/movement_ability.dart';
import 'package:heroclix_simulator_trainer/domain/characters/vision_ability.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/target_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/tactics/tactical_diagnostic.dart';
import 'package:heroclix_simulator_trainer/domain/tactics/tactical_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';

import 'movement_contract.dart';
import 'vision_contract.dart';

VisionSnapshot tacticalWorld({bool wall = true}) => mw(
  speed: 4,
  extras: [vf(2, 'D1', team: 'team-2')],
  walls: wall ? [EdgeWall.between(vc('B1'), vc('C1'))] : const [],
);
void tacticalCheck(bool condition, String reason) {
  if (!condition) throw StateError(reason);
}

VisionSnapshot tacticCaps(
  VisionSnapshot w, {
  Iterable<VisionAbility> it = const [],
  Iterable<MovementAbility> im = const [],
}) => VisionSnapshot(
  dimensions: w.dimensions,
  terrain: w.terrain,
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
                range: f.range,
                speed: f.speed,
                abilities: it,
                movementAbilities: im,
                size: f.size,
              ),
            ),
  ],
);
Map<String, void Function()> tacticsCases() => {
  'A01 dos posiciones cambian visión y exposición sin mutar origen': () {
    const s = TacticalAnalysisService(), ctx = TacticalContext();
    final w = tacticalWorld();
    final before = s.inspect(w, 'figure-1', ctx),
        after = s.candidate(w, 'figure-1', vc('B2'), ctx);
    tacticalCheck(
      before.metrics[TacticalMetric.visible]!.known == 0,
      'Muro bloquea origen',
    );
    tacticalCheck(
      after.status == CandidateStatus.legal &&
          after.position!.metrics[TacticalMetric.visible]!.known == 1,
      'B2 permite ver destino',
    );
    tacticalCheck(
      after.position!.metrics[TacticalMetric.seenBy]!.known == 1 &&
          after.position!.metrics[TacticalMetric.threats]!.known == 1,
      'Exposición recíproca con alcance declarado',
    );
    tacticalCheck(
      w.characters.first.position == vc('A1'),
      'Snapshot inicial intacto',
    );
  },
  'A02 casilla B o figura no entra en candidatas legales': () {
    const s = TacticalAnalysisService(), ctx = TacticalContext();
    final w = mw(
      terrain: {'B1': TerrainType.blocking},
      extras: [vf(2, 'D1', team: 'team-2')],
    );
    for (final cell in ['B1', 'D1']) {
      tacticalCheck(
        s.candidate(w, 'figure-1', vc(cell), ctx).status ==
            CandidateStatus.invalid,
        'Destino incompatible descartado',
      );
    }
  },
  'A03 cambiar muro cambia exposición': () {
    const s = TacticalAnalysisService(), ctx = TacticalContext();
    final wall = s.inspect(tacticalWorld(), 'figure-1', ctx),
        clear = s.inspect(tacticalWorld(wall: false), 'figure-1', ctx);
    tacticalCheck(
      wall.metrics[TacticalMetric.seenBy]!.known == 0 &&
          clear.metrics[TacticalMetric.seenBy]!.known == 1,
      'No retiene el muro anterior',
    );
  },
  'A04 H sigue visible y se registra aparte': () {
    final d = const TacticalAnalysisService().inspect(
      mw(
        extras: [vf(2, 'D1', team: 'team-2')],
        terrain: {'B1': TerrainType.hindering},
      ),
      'figure-1',
      const TacticalContext(),
    );
    tacticalCheck(
      d.metrics[TacticalMetric.visible]!.known == 1 &&
          d.metrics[TacticalMetric.hindered]!.known == 1,
      'H visible',
    );
    tacticalCheck(
      d.metrics[TacticalMetric.blocked]!.known == 0,
      'H no equivale a B',
    );
  },
  'A05 dos direcciones usan la ficha de quien traza la línea': () {
    const s = TacticalAnalysisService();
    final w = tacticCaps(tacticalWorld(), it: [VisionAbility.blocking]);
    final on = s.inspect(w, 'figure-1', const TacticalContext()),
        off = s.inspect(
          w,
          'figure-1',
          const TacticalContext(withoutImprovements: true),
        );
    tacticalCheck(
      on.metrics[TacticalMetric.visible]!.known == 1 &&
          on.metrics[TacticalMetric.seenBy]!.known == 0,
      'IT del activo no se presta al enemigo',
    );
    tacticalCheck(
      off.metrics[TacticalMetric.visible]!.known == 0,
      'Hipótesis sin IT B',
    );
    tacticalCheck(
      w.characters.first.abilities.contains(VisionAbility.blocking),
      'Ficha real conservada',
    );
  },
  'A06 hipótesis sin mejoras conserva condiciones sin soporte': () {
    const s = TacticalAnalysisService();
    final w = tacticCaps(
      tacticalWorld(),
      it: [VisionAbility.blocking, VisionAbility.other],
      im: [MovementAbility.elevated, MovementAbility.other],
    );
    final off = s
        .contextualize(
          w,
          'figure-1',
          const TacticalContext(withoutImprovements: true),
        )
        .characters
        .first;
    tacticalCheck(
      off.abilities.length == 1 && off.abilities.contains(VisionAbility.other),
      'Other no se borra',
    );
    tacticalCheck(
      off.movementAbilities.length == 1 &&
          off.movementAbilities.contains(MovementAbility.other),
      'IM sin soporte no se borra',
    );
    tacticalCheck(
      !s
          .inspect(
            w,
            'figure-1',
            const TacticalContext(withoutImprovements: true),
          )
          .complete,
      'No convierte desconocido en completo',
    );
  },
  'A07 sin enemigos y tablero 40x40': () {
    const s = TacticalAnalysisService();
    final w = mw(rows: 40, columns: 40, speed: 1);
    final d = s.inspect(w, 'figure-1', const TacticalContext());
    tacticalCheck(
      d.complete &&
          d.totalEnemies == 0 &&
          d.metrics.values.every((v) => v.known == 0 && v.unknown == 0),
      'Cero enemigos conocido',
    );
    tacticalCheck(
      s.pool(w, 'figure-1', const TacticalContext()).length == 3,
      'Casillas acotadas por distancia y velocidad',
    );
    tacticalCheck(
      s.candidate(w, 'figure-1', vc('B2'), const TacticalContext()).status ==
          CandidateStatus.legal,
      'Diagonal libre',
    );
  },
  'A08 límite de enemigos produce mínimos y No evaluados, no ceros': () {
    final w = mw(
      rows: 40,
      columns: 40,
      extras: [
        for (var i = 0; i < 35; i++)
          vf(
            i + 2,
            '${String.fromCharCode(65 + i % 18)}${5 + i ~/ 18}',
            team: 'team-2',
          ),
      ],
    );
    final d = const TacticalAnalysisService().inspect(
      w,
      'figure-1',
      const TacticalContext(),
    );
    tacticalCheck(
      d.totalEnemies == 35 && d.enemies.length == 32 && d.omitted == 3,
      'Límite explícito32',
    );
    tacticalCheck(
      !d.complete && d.metrics.values.every((m) => m.unknown == 3),
      'Tres no procesados en cada métrica',
    );
  },
  'A09 visibilidad y alcance de bases no fabrican amenaza con pares distintos':
      () {
        var w = vs(
          target: 'B3',
          targetBase: Footprint.rectangle(width: 1, height: 2),
          walls: [EdgeWall.between(vc('A2'), vc('B2'))],
        );
        w = VisionSnapshot(
          dimensions: w.dimensions,
          terrain: w.terrain,
          walls: w.walls,
          characters: [
            for (final f in w.characters)
              f.revised(
                CharacterDraft(
                  name: f.name,
                  teamId: f.teamId,
                  position: f.position,
                  footprint: f.footprint,
                  range: 2,
                ),
              ),
          ],
        );
        final d = const TacticalAnalysisService().inspect(
              w,
              'figure-1',
              const TacticalContext(),
            ),
            e = d.enemies.single;
        tacticalCheck(
          d.metrics[TacticalMetric.visible]!.known == 1 &&
              d.metrics[TacticalMetric.inRange]!.known == 1,
          'Dimensiones independientes conocidas',
        );
        tacticalCheck(
          e.outgoing.combined == TargetStatus.blocked &&
              d.metrics[TacticalMetric.threats]!.known == 0,
          'Mismo par para amenaza, sin mezclar B3/B4',
        );
        tacticalCheck(
          e.outgoing.from != e.outgoing.rangeFrom ||
              e.outgoing.to != e.outgoing.rangeTo,
          'Evidencia de pares distintos',
        );
      },
  'A10 prioridades ordenan métricas diferentes con desempate explícito': () {
    const s = TacticalAnalysisService(), ctx = TacticalContext();
    final w = tacticalWorld();
    final a = s.candidate(w, 'figure-1', vc('B1'), ctx),
        b = s.candidate(w, 'figure-1', vc('B2'), ctx);
    tacticalCheck(
      s.ordered([a, b], TacticalPriority.seeMore).first.cell == vc('B2'),
      'Más visibles',
    );
    tacticalCheck(
      s.ordered([a, b], TacticalPriority.reduceExposure).first.cell == vc('B1'),
      'Menos líneas enemigas',
    );
    tacticalCheck(
      s.ordered([a, b], TacticalPriority.minimizeMovement).first.cell ==
          vc('B1'),
      'Costo empatado, coordenada',
    );
  },
  'A11 resultados parciales no se ordenan como propuestas completas': () {
    const s = TacticalAnalysisService();
    final w = tacticCaps(tacticalWorld(), it: [VisionAbility.other]);
    final c = s.candidate(w, 'figure-1', vc('B2'), const TacticalContext());
    tacticalCheck(
      c.status == CandidateStatus.legal && !c.position!.complete,
      'Solo ruta verificada',
    );
    tacticalCheck(
      s.ordered([c], TacticalPriority.seeMore).isEmpty,
      'Sin recomendación categórica',
    );
    tacticalCheck(
      c.position!.metrics[TacticalMetric.visible]!.unknown == 1,
      'Visión No evaluada',
    );
  },
  'A12 la misma ruta sin IM puede ser inválida; no cambia ficha': () {
    final w = tacticCaps(
      mw(
        walls: [
          EdgeWall.between(vc('A1'), vc('B1')),
          EdgeWall.between(vc('A1'), vc('A2')),
        ],
      ),
      im: [MovementAbility.blocking],
    );
    final c = const TacticalAnalysisService().candidate(
      w,
      'figure-1',
      vc('C1'),
      const TacticalContext(),
      compareImprovements: true,
    );
    tacticalCheck(
      c.status == CandidateStatus.legal &&
          c.alternateMovement != null &&
          !c.alternateMovement!.canConfirm,
      'Hipótesis de ruta separada',
    );
    tacticalCheck(
      w.characters.first.movementAbilities.contains(MovementAbility.blocking),
      'IM real conservada',
    );
  },
  'A13 versión o efecto general sin soporte no aprueban movimientos': () {
    const s = TacticalAnalysisService();
    for (final ctx in [
      const TacticalContext(rulesVersion: 'futura'),
      const TacticalContext(unknownEffects: true),
    ]) {
      final c = s.candidate(tacticalWorld(), 'figure-1', vc('B2'), ctx);
      tacticalCheck(
        c.status == CandidateStatus.notEvaluated,
        'No aprueba condiciones desconocidas',
      );
    }
  },
  'A14 delta solo es exacto con ambos recuentos completos': () {
    tacticalCheck(
      const MetricDifference(MetricCount(1, 0), MetricCount(3, 0)).exact == 2,
      'Diferencia exacta',
    );
    tacticalCheck(
      const MetricDifference(MetricCount(1, 1), MetricCount(3, 0)).exact ==
          null,
      'No resta mínimos como certeza',
    );
  },
};
