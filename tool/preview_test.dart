// Ejecutar explícitamente: flutter test tool/preview_test.dart
// Capturas de render Flutter; no representan una prueba en Android real.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_screen.dart';
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

  for (final (name, size, dimensions) in [
    ('inicio_vertical', const Size(400, 900), null),
    ('inicio_horizontal', const Size(1000, 700), null),
    (
      'figuras_vertical',
      const Size(400, 900),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'figuras_horizontal',
      const Size(1000, 600),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'ficha_vertical',
      const Size(400, 900),
      BoardDimensions(rows: 4, columns: 4),
    ),
    (
      'editor_vertical',
      const Size(400, 900),
      BoardDimensions(rows: 8, columns: 12),
    ),
    (
      'editor_horizontal',
      const Size(1000, 600),
      BoardDimensions(rows: 8, columns: 12),
    ),
    (
      'editor_40x40',
      const Size(1000, 700),
      BoardDimensions(rows: 40, columns: 40),
    ),
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
      if (dimensions != null) {
        await tester.ensureVisible(find.text('Abrir editor'));
        await tester.tap(find.text('Abrir editor'));
        await tester.pumpAndSettle();
        final controller = tester
            .widget<EditorScreen>(find.byType(EditorScreen))
            .controller;
        controller.changeDimensions(dimensions);
        for (final (position, team, footprint) in [
          ('A1', 'team-1', Footprint.single),
          ('C1', 'team-2', Footprint.single),
          ('B3', 'team-2', Footprint.square2),
        ]) {
          controller.saveCharacter(
            CharacterDraft(
              name: 'Figura de prueba',
              teamId: team,
              position: CellCoordinate.parse(position),
              footprint: footprint,
            ),
          );
        }
        await tester.pumpAndSettle();
        final cell = CellCoordinate.parse(
          dimensions.columns == 40
              ? 'AA20'
              : dimensions.columns == 4
              ? 'D2'
              : 'D6',
        );
        final point = controller.value.camera.sceneToViewport(
          const BoardGeometry().cellCenter(cell, dimensions),
        );
        await tester.tapAt(
          tester.getTopLeft(find.byKey(const ValueKey('board-viewport'))) +
              Offset(point.x, point.y),
        );
        await tester.pumpAndSettle();
        expect(controller.value.selectedCell, cell);
        if (name.startsWith('figuras') || name.startsWith('ficha')) {
          controller.selectCharacter(controller.value.characters.all.last.id);
          await tester.pumpAndSettle();
        }
        if (name.startsWith('ficha')) {
          await tester.tap(find.byKey(const ValueKey('edit-character')));
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File('build/previews/prompt-02/$name.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    });
  }
}
