// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import '../test/support/movement_contract.dart';
import '../test/support/vision_contract.dart';

import 'package:heroclix_simulator_trainer/domain/movement/route_planner.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';

void main() {
  print(
    '${Platform.version}; ${Platform.operatingSystem}; ${Platform.numberOfProcessors} procesadores lógicos',
  );
  for (final n in [20, 40]) {
    final world = mw(
      rows: n,
      columns: n,
      speed: 99,
      extras: [
        for (var i = 1; i < 40; i++)
          vf(
            i + 1,
            '${String.fromCharCode(65 + (i % 18))}${2 + (i ~/ 18) * 3}',
          ),
      ],
      terrain: {for (var r = 3; r < n - 1; r += 3) 'F$r': TerrainType.blocking},
      walls: [
        for (var r = 0; r < n - 2; r++)
          EdgeWall.between(vc('J${r + 1}'), vc('K${r + 1}')),
      ],
    );
    final destination = world.dimensions.columns == 20 ? vc('T20') : vc('AN40');
    final samples = <double>[];
    var visited = 0, cost = 0;
    for (var i = 0; i < 5; i++) {
      final watch = Stopwatch()..start();
      final result = const RoutePlanner().search(
        world,
        'figure-1',
        destination,
      );
      watch.stop();
      if (result.routes.isEmpty) throw StateError(result.reason);
      samples.add(watch.elapsedMicroseconds / 1000);
      visited = result.visited;
      cost = result.routes.first.cost;
    }
    final cold = samples.first;
    samples.sort();
    print(
      jsonEncode({
        'board': '${n}x$n',
        'figures': world.characters.length,
        'speed': 99,
        'samples': 5,
        'first_ms': cold,
        'median_ms': samples[2],
        'max_ms': samples.last,
        'visited': visited,
        'shortest_cost': cost,
      }),
    );
  }
}
