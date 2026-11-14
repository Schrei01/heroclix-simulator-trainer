import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('arranca en español: editor disponible y tres modos futuros', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const HeroClixApp());

      expect(find.text('HeroClix Simulator & Trainer'), findsOneWidget);
      expect(find.text('Próximamente'), findsNWidgets(3));
      expect(
        Localizations.localeOf(tester.element(find.byType(Scaffold))),
        const Locale('es'),
      );

      final editor = tester.getSemantics(
        find.byKey(const ValueKey('mode-editor')),
      );
      expect(editor.flagsCollection.isEnabled, Tristate.isTrue);
      expect(editor.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      for (final id in ['simulator', 'trainer', 'referee']) {
        final card = find.byKey(ValueKey('mode-$id'));
        await tester.ensureVisible(card);
        final node = tester.getSemantics(card);
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.text('HeroClix Simulator & Trainer'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final size in [
    const Size(320, 568),
    const Size(360, 800),
    const Size(800, 360),
    const Size(568, 320),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('sin desbordes en $size con texto x$scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(const HeroClixApp());
        for (final id in ['editor', 'simulator', 'trainer', 'referee']) {
          final card = find.byKey(ValueKey('mode-$id'));
          await tester.ensureVisible(card);
          expect(tester.getRect(card).width, greaterThan(0));
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
