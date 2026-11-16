import 'dart:convert';
import 'dart:io';

import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/board/sight_probe.dart';
import 'package:heroclix_simulator_trainer/application/board/tactical_analysis.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/rules/line_of_sight.dart';
import 'package:heroclix_simulator_trainer/domain/rules/target_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';

BoardSession benchmarkSession(int side, int figures) {
  var session = BoardSession.initial().changeDimensions(
    BoardDimensions(rows: side, columns: side),
  );
  for (var i = 0; i < figures; i++) {
    final index = (i * 13) % (side * side);
    session = session.createCharacter(
      CharacterDraft(
        name: 'Figura ${i + 1}',
        teamId: i.isEven ? 'team-1' : 'team-2',
        range: side ~/ 2,
        position: CellCoordinate(row: index ~/ side, column: index % side),
      ),
    );
  }
  return session;
}

double elapsedMs(Stopwatch watch) => watch.elapsedMicroseconds / 1000;
void main(List<String> arguments) {
  stdout.writeln(
    'Dart ${Platform.version}; ${Platform.operatingSystem}; ${Platform.numberOfProcessors} procesadores lógicos.',
  );
  for (final (side, count) in [(20, 40), (40, 120)]) {
    var session = benchmarkSession(side, count);
    if (arguments.contains('--mixed')) {
      var terrain = session.terrain;
      final edges = <EdgeWall>[];
      for (var i = 0; i < side * 2; i++) {
        final cell = CellCoordinate(
          column: (i * 11) % side,
          row: (i * 11 ~/ side) % side,
        );
        terrain = terrain.put(
          cell,
          CellTerrain(
            type: session.characters.at(cell) != null || i.isEven
                ? TerrainType.hindering
                : TerrainType.blocking,
          ),
          session.dimensions,
        );
        edges.add(
          EdgeWall(
            axis: EdgeAxis.vertical,
            column: 1 + i % (side - 1),
            row: i % side,
          ),
        );
      }
      session = session.replaceLayers(
        terrain: terrain,
        walls: session.walls.edit(edges, session.dimensions, erase: false),
        characters: session.characters,
      );
    }
    final snapshot = VisionSnapshot(
      dimensions: session.dimensions,
      characters: session.characters.all,
      terrain: session.terrain,
      walls: session.walls,
    );
    final service = const TargetAnalysisService(), context = VisionContext();
    final cold = Stopwatch()..start();
    final first = service.evaluate(snapshot, 'figure-1', context);
    cold.stop();
    final samples = <double>[];
    for (var i = 0; i < 25; i++) {
      final watch = Stopwatch()..start();
      service.evaluate(snapshot, 'figure-1', context);
      watch.stop();
      samples.add(elapsedMs(watch));
    }
    samples.sort();
    final tactical = TacticalAnalysis()
      ..enabled = true
      ..sourceId = 'figure-1';
    final probe = SightProbe();
    tactical.sync(session, probe, context);
    final calls = tactical.cache.evaluations;
    final cached = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      tactical.filter = TargetFilter.values[i % 3];
      tactical.sync(session, probe, context);
    }
    cached.stop();
    final source = session.characters.byId('figure-1')!;
    final rangeChange = session.editCharacter(
      source.id,
      CharacterDraft(
        name: source.name,
        teamId: source.teamId,
        position: source.position,
        range: source.range + 1,
      ),
    );
    final rangeWatch = Stopwatch()..start();
    tactical.sync(rangeChange, probe, context);
    rangeWatch.stop();
    stdout.writeln(
      jsonEncode({
        'board': '${side}x$side',
        'figures': count,
        'targets': first.targets.length,
        'cold_ms': elapsedMs(cold),
        'samples': samples.length,
        'median_ms': samples[12],
        'p95_ms': samples[23],
        'max_ms': samples.last,
        'cached_filter_mean_ms': elapsedMs(cached) / 100,
        'range_change_ms': elapsedMs(rangeWatch),
        'vision_calls_before': calls,
        'vision_calls_after': tactical.cache.evaluations,
        'terrain_cells': session.terrain.cells.length,
        'walls': session.walls.edges.length,
        'fixture': arguments.contains('--mixed')
            ? 'Plano con terreno H/B y muros; figuras intermedias'
            : 'Plano, sin muros ni terreno; figuras intermedias',
      }),
    );
    if (calls != tactical.cache.evaluations ||
        first.targets.length != count - 1) {
      throw StateError(
        'La caché o la cantidad de objetivos no coincide con el contrato.',
      );
    }
  }
}
