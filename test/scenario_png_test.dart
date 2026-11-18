import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';
import 'package:heroclix_simulator_trainer/presentation/scenarios/board_png_exporter.dart';

import 'scenario_codec_test.dart' show character, cell;

void main() {
  setUpAll(() async {
    final sdk =
        Platform.environment['FLUTTER_ROOT'] ??
        '${Platform.environment['USERPROFILE']}/develop/flutter';
    final font = await File(
      '$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    ).readAsBytes();
    await (FontLoader(
      'sans-serif',
    )..addFont(Future.value(ByteData.sublistView(font)))).load();
  });
  testWidgets(
    'PNG 4×4 sin controles ni selección; coordenadas y leyenda opcionales',
    (tester) async {
      final state = BoardSession.initial()
          .changeDimensions(BoardDimensions(rows: 4, columns: 4))
          .createCharacter(character('B2'))
          .paintTerrain([cell('A1')], TerrainType.hindering)
          .paintTerrain([cell('D1')], TerrainType.water);
      final selected = state.selectedCharacterId;
      final plain = (await tester.runAsync(
        () => const BoardPngExporter().render(state, legend: false),
      ))!;
      expect(plain.width, 640);
      expect(plain.height, 640);
      expect(plain.bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(plain.bytes);
        final frame = await codec.getNextFrame();
        final pixels = (await frame.image.toByteData())!;
        const geometry = BoardGeometry();
        final point = geometry.cellCenter(cell('D1'), state.dimensions);
        final x = (point.x * 2).round(), y = (point.y * 2 + 4).round();
        final offset = (y * plain.width + x) * 4;
        expect(pixels.getUint8(offset + 2), greaterThan(90));
        expect(
          pixels.getUint8(offset + 2),
          greaterThan(pixels.getUint8(offset + 1)),
        );
        frame.image.dispose();
        codec.dispose();
      });
      final changedView = state.clearSelection().withCamera(
        BoardCamera(scale: 3, offsetX: -999, offsetY: 222),
      );
      final same = (await tester.runAsync(
        () => const BoardPngExporter().render(changedView, legend: false),
      ))!;
      expect(same.bytes, plain.bytes);
      expect(state.selectedCharacterId, selected);
      final noCoordinates = (await tester.runAsync(
        () => const BoardPngExporter().render(
          state,
          legend: false,
          coordinates: false,
        ),
      ))!;
      expect(noCoordinates.bytes, isNot(plain.bytes));
      final legend = (await tester.runAsync(
        () => const BoardPngExporter().render(state),
      ))!;
      expect(legend.height, greaterThan(plain.height));
      await tester.runAsync(() async {
        final file = File('build/verification/prompt-04/export_4x4.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(legend.bytes);
      });
    },
  );
  for (final limit in [2048, 4096]) {
    testWidgets('PNG 40×40 con máximo $limit e imagen decodificable', (
      tester,
    ) async {
      final state = BoardSession.initial()
          .changeDimensions(BoardDimensions(rows: 40, columns: 40))
          .createCharacter(character('AN40'))
          .paintTerrain([cell('A1'), cell('B1')], TerrainType.blocking);
      final png = (await tester.runAsync(
        () => const BoardPngExporter().render(state, maxDimension: limit),
      ))!;
      expect(png.width, lessThanOrEqualTo(limit));
      expect(png.height, limit);
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(png.bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, png.width);
        expect(frame.image.height, png.height);
        frame.image.dispose();
        codec.dispose();
        final file = File(
          'build/verification/prompt-04/export_40x40_$limit.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png.bytes);
      });
    });
  }
}
