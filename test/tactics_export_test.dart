import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/tactics/diagnostic_summary.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/team.dart';
import 'package:heroclix_simulator_trainer/domain/tactics/tactical_analysis_service.dart';
import 'package:heroclix_simulator_trainer/domain/tactics/tactical_diagnostic.dart';
import 'package:heroclix_simulator_trainer/presentation/tactics/diagnostic_png.dart';

import 'support/tactics_contract.dart';
import 'support/vision_contract.dart';
import 'vision_state_test.dart' show visionSession;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('resumen y etiquetas de imagen excluyen nombres, equipos y metadatos libres', () {
    var session = visionSession(tacticalWorld());
    final f = session.characters.byId('figure-1')!;
    session = session.editCharacter(
      f.id,
      CharacterDraft(
        name: 'PERSONA correo@example.org TOKEN_ABC',
        teamId: f.teamId,
        position: f.position,
      ),
    );
    session = session.addTeam(
      name: 'credencial-SECRETA',
      color: 0xffeeeeee,
      pattern: TeamPattern.solid,
    );
    final public = publicDiagnosticBoard(session);
    expect(public.characters.all.any((f) => f.name.contains('PERSONA')), false);
    expect(public.teams.any((t) => t.name.contains('SECRETA')), false);
    final current = const TacticalAnalysisService().inspect(
      tacticalWorld(),
      'figure-1',
      const TacticalContext(rulesVersion: 'TOKEN_ABC'),
    );
    final text = diagnosticSummary(
      current,
      null,
      TacticalPriority.seeMore,
      evaluated: 0,
      requested: 12,
      cancelled: true,
    );
    final pngText = diagnosticImageLines(
      current,
      null,
      TacticalPriority.seeMore,
    ).join(' ');
    for (final secret in ['PERSONA', 'example.org', 'TOKEN_ABC', 'SECRETA']) {
      expect(text, isNot(contains(secret)));
      expect(pngText, isNot(contains(secret)));
    }
    expect(text, contains('cancelada'));
    expect(text, contains('no soportada'));
  });
  test(
    'PNG generado y decodificado tiene límites y datos de comparación',
    () async {
      const s = TacticalAnalysisService(), ctx = TacticalContext();
      final w = tacticalWorld();
      final current = s.inspect(w, 'figure-1', ctx),
          candidate = s.candidate(w, 'figure-1', vc('B2'), ctx);
      final bytes = await diagnosticPng(
        visionSession(w),
        current,
        [candidate],
        candidate,
        TacticalPriority.seeMore,
      );
      expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        expect(frame.image.width, lessThanOrEqualTo(2048));
        expect(frame.image.height, lessThanOrEqualTo(2048));
        expect(frame.image.height, greaterThan(400));
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    },
  );
}
