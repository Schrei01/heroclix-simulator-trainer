// Ejecutar explícitamente: flutter test tool/preview_test.dart
// Capturas de render Flutter; no representan una prueba en Android real.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final sdkPath =
        Platform.environment['FLUTTER_ROOT'] ??
        '${Platform.environment['USERPROFILE']}/develop/flutter';
    final font = File(
      '$sdkPath/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    );
    final loader = FontLoader('sans-serif')
      ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
    await loader.load();
    final iconFont = File(
      '$sdkPath/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(ByteData.sublistView(await iconFont.readAsBytes())),
      );
    await iconLoader.load();
  });

  for (final (name, size) in [
    ('inicio_vertical', const Size(400, 900)),
    ('inicio_horizontal', const Size(1000, 700)),
  ]) {
    testWidgets('renderiza $name', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: const HeroClixApp()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File('build/previews/$name.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    });
  }
}
