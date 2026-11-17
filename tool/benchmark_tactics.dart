// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import '../test/support/movement_contract.dart';
import '../test/support/vision_contract.dart';

import 'package:heroclix_simulator_trainer/domain/tactics/tactical_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/tactics/tactical_diagnostic.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';

void main() {
  print(
    '${Platform.version}; ${Platform.operatingSystem}; ${Platform.numberOfProcessors} procesadores lógicos',
  );
  for (final n in [20, 40]) {
    final world = mw(
      rows: n,
      columns: n,
      speed: 4,
      extras: [
        for (var i = 0; i < 35; i++)
          vf(
            i + 2,
            '${String.fromCharCode(65 + i % 18)}${6 + i ~/ 18}',
            team: 'team-2',
          ),
      ],
      walls: [EdgeWall.between(vc('B1'), vc('C1'))],
    );
    const service = TacticalAnalysisService(), context = TacticalContext();
    final cells = service.pool(world, 'figure-1', context).take(12).toList();
    final samples = <double>[];
    var legal = 0;
    for (var sample = 0; sample < 5; sample++) {
      final watch = Stopwatch()..start();
      service.inspect(world, 'figure-1', context);
      legal = 0;
      for (final c in cells) {
        if (service.candidate(world, 'figure-1', c, context).status ==
            CandidateStatus.legal) {
          legal++;
        }
      }
      watch.stop();
      samples.add(watch.elapsedMicroseconds / 1000);
    }
    final first = samples.first;
    samples.sort();
    print(
      jsonEncode({
        'board': '${n}x$n',
        'figures': world.characters.length,
        'enemies': 35,
        'enemy_limit': 32,
        'candidate_cells': cells.length,
        'legal': legal,
        'samples': 5,
        'first_ms': first,
        'median_ms': samples[2],
        'max_ms': samples.last,
      }),
    );
  }
}
