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
    ('five', 5, const Size(360, 800), false),
    ('six', 6, const Size(360, 800), false),
    ('six-landscape', 6, const Size(800, 360), false),
    ('six-small', 6, const Size(320, 568), false),
  ]) {
    testWidgets('Priority $name', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = size;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      final controller = PriorityController(inputCooldown: Duration.zero);
      addTearDown(controller.dispose);
      if (!setup) {
        controller.start(
          PriorityConfiguration(
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
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await t.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory(
          'build/verification/priority-stage2/previews',
        );
        await directory.create(recursive: true);
        await File('${directory.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
