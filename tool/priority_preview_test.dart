// Explicit Flutter renders; not a native Android device test.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_screen.dart';
import 'package:heroclix_simulator_trainer/presentation/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final sdk =
        Platform.environment['FLUTTER_ROOT'] ??
        '${Platform.environment['USERPROFILE']}/develop/flutter';
    for (final (family, file) in [
      ('sans-serif', 'roboto-regular.ttf'),
      ('MaterialIcons', 'materialicons-regular.otf'),
    ]) {
      final bytes = await File('$sdk/bin/cache/artifacts/material_fonts/$file')
          .readAsBytes();
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  for (final (name, count, size, setup) in [
    ('setup', 6, const Size(360, 800), true),
    ('two', 2, const Size(360, 800), false),
    ('three', 3, const Size(360, 800), false),
    ('four', 4, const Size(360, 800), false),
    ('three-landscape', 3, const Size(800, 360), false),
    ('four-landscape', 4, const Size(800, 360), false),
    ('five', 5, const Size(360, 800), false),
    ('six', 6, const Size(360, 800), false),
    ('six-landscape', 6, const Size(800, 360), false),
    ('six-small', 6, const Size(320, 568), false),
    ('clock-two', 2, const Size(360, 800), false),
    ('clock-six', 6, const Size(360, 800), false),
    ('clock-landscape', 6, const Size(800, 360), false),
    ('clock-expired', 3, const Size(360, 800), false),
    ('player-management', 3, const Size(360, 800), false),
    ('eliminated', 6, const Size(360, 800), false),
    ('final-standings', 3, const Size(360, 800), false),
    ('clock-setup', 2, const Size(360, 800), true),
    ('score-streak', 3, const Size(360, 800), false),
    ('active-highlight', 4, const Size(360, 800), false),
    ('score-ranking', 6, const Size(800, 360), false),
    ('seat-swap', 3, const Size(360, 800), false),
    ('seat-drag', 3, const Size(360, 800), false),
  ]) {
    testWidgets('Priority $name', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = size;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      var elapsed = Duration.zero;
      final controller = PriorityController(
        inputCooldown: Duration.zero,
        elapsedClock: () => elapsed,
      );
      addTearDown(controller.dispose);
      if (!setup) {
        controller.start(
          PriorityConfiguration(
            clockEnabled:
                name.startsWith('clock') ||
                name == 'player-management' ||
                name == 'eliminated' ||
                name == 'final-standings',
            players: [
              for (var i = 1; i <= count; i++)
                PriorityPlayerConfiguration(
                  id: 'J$i',
                  name: [
                    'Ana',
                    'Bruno',
                    'Carla',
                    'Diego',
                    'Elena',
                    'Fabio',
                  ][i - 1],
                  buildPoints: 300,
                ),
            ],
          ),
        );
        controller.dispatch(
          const PriorityCommand.action('J1'),
          expectedRevision: controller.value!.revision,
        );
        if (name.startsWith('clock') ||
            name == 'eliminated' ||
            name == 'final-standings') {
          controller.dispatch(
            const PriorityCommand.setVictoryPoints('J1', 100),
            expectedRevision: controller.value!.revision,
          );
          controller.dispatch(
            const PriorityCommand.setVictoryPoints('J2', 150),
            expectedRevision: controller.value!.revision,
          );
        }
        if (name == 'clock-expired') {
          elapsed = const Duration(minutes: 31);
          controller.synchronizeClock();
        }
        if (name == 'eliminated' || name == 'final-standings') {
          controller.dispatch(
            const PriorityCommand.eliminate('J3'),
            expectedRevision: controller.value!.revision,
          );
        }
        if (name == 'final-standings') {
          controller.dispatch(
            const PriorityCommand.eliminate('J2'),
            expectedRevision: controller.value!.revision,
          );
        }
        if (name == 'score-ranking') {
          for (var i = 1; i <= count; i++) {
            controller.dispatch(
              PriorityCommand.setVictoryPoints('J$i', (count + 1 - i) * 25),
              expectedRevision: controller.value!.revision,
            );
          }
        }
      }
      final boundaryKey = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            theme: AppTheme.dark,
            debugShowCheckedModeBanner: false,
            locale: const Locale('es'),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('es')],
            home: PriorityScreen(controller: controller),
          ),
        ),
      );
      if (name == 'active-highlight') {
        await t.pump();
        await t.pump(const Duration(milliseconds: 800));
      } else {
        await t.pumpAndSettle();
      }
      TestGesture? seatGesture;
      if (name == 'seat-swap') {
        controller.swapVisualSeats(
          'J1',
          'J3',
          configuration: controller.value!.configuration,
        );
        await t.pumpAndSettle();
      }
      if (name == 'seat-drag') {
        final source = find.byKey(const ValueKey('priority-drag-J1'));
        final target = find.byKey(const ValueKey('priority-drop-J3'));
        seatGesture = await t.startGesture(t.getCenter(source));
        await t.pump(const Duration(milliseconds: 600));
        await seatGesture.moveTo(t.getCenter(target));
        await t.pump(const Duration(milliseconds: 50));
      }
      if (name == 'player-management') {
        final player = find.byKey(const ValueKey('priority-player-menu-J2'));
        await t.ensureVisible(player);
        await t.tap(player);
        await t.pumpAndSettle();
      }
      if (name == 'clock-setup') {
        final toggle = find.byKey(const ValueKey('priority-clock-enabled'));
        await t.ensureVisible(toggle);
        await t.tap(toggle);
        await t.pumpAndSettle();
      }
      if (name == 'score-streak') {
        final plus = find.byKey(const ValueKey('priority-score-plus-J2'));
        await t.ensureVisible(plus);
        for (var i = 0; i < 3; i++) {
          await t.tap(plus);
          await t.pump(const Duration(milliseconds: 100));
        }
      }
      expect(t.takeException(), isNull);
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await t.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory(
          'build/verification/priority-seat-drag/previews',
        );
        await directory.create(recursive: true);
        await File('${directory.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      if (seatGesture != null) {
        await seatGesture.up();
        await t.pumpAndSettle();
      }
    });
  }
}
