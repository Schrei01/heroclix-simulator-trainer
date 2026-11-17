import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/presentation/scenarios/board_png_exporter.dart';

void main() {
  for (final (name, high) in [('vertical', 'B1'), ('horizontal', 'A2')]) {
    testWidgets(
      'transición $name: triángulos dentro de ambas casillas, PNG, JSON y retirada',
      (tester) async {
        final source = CellCoordinate.parse('A1'),
            destination = CellCoordinate.parse(high);
        final edge = EdgeWall.between(source, destination);
        final baseline = BoardSession.initial()
            .changeDimensions(BoardDimensions(rows: 2, columns: 2))
            .paintElevation([destination], 2);
        final marked = baseline.setTransition(edge, remove: false);
        final decoded = const ScenarioCodec().decode(
          const ScenarioCodec().encode(ScenarioDocument.fresh(session: marked)),
        );
        expect(decoded.session.terrain.transitions, {edge});
        expect(decoded.session.terrain.at(source).level, 1);
        expect(decoded.session.terrain.at(destination).level, 2);
        final a = const BoardGeometry().cellCenter(source, baseline.dimensions),
            b = const BoardGeometry().cellCenter(
              destination,
              baseline.dimensions,
            );
        final center = Offset((a.x + b.x) / 2, (a.y + b.y) / 2);
        final areas = edge.axis == EdgeAxis.vertical
            ? [
                Rect.fromLTRB(
                  center.dx - 18,
                  center.dy - 2,
                  center.dx - 14,
                  center.dy + 2,
                ),
                Rect.fromLTRB(
                  center.dx + 14,
                  center.dy - 2,
                  center.dx + 18,
                  center.dy + 2,
                ),
              ]
            : [
                Rect.fromLTRB(
                  center.dx - 2,
                  center.dy - 18,
                  center.dx + 2,
                  center.dy - 14,
                ),
                Rect.fromLTRB(
                  center.dx - 2,
                  center.dy + 14,
                  center.dx + 2,
                  center.dy + 18,
                ),
              ];
        await tester.runAsync(() async {
          Future<List<int>> whitePixels(
            BoardSession state, {
            bool save = false,
          }) async {
            final png = await const BoardPngExporter().render(
              state,
              coordinates: false,
              legend: false,
            );
            if (save) {
              final file = File(
                'build/verification/editor-transitions/transition_$name.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(png.bytes);
            }
            final codec = await ui.instantiateImageCodec(png.bytes);
            final image = (await codec.getNextFrame()).image;
            try {
              final rgba = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              final scale =
                  image.width / const BoardGeometry().width(state.dimensions);
              return [
                for (final region in areas)
                  (() {
                    var white = 0;
                    for (
                      var y = (region.top * scale).floor();
                      y < (region.bottom * scale).ceil();
                      y++
                    ) {
                      for (
                        var x = (region.left * scale).floor();
                        x < (region.right * scale).ceil();
                        x++
                      ) {
                        final index = (y * image.width + x) * 4;
                        if (rgba.getUint8(index) >= 245 &&
                            rgba.getUint8(index + 1) >= 245 &&
                            rgba.getUint8(index + 2) >= 245) {
                          white++;
                        }
                      }
                    }
                    return white;
                  })(),
              ];
            } finally {
              image.dispose();
              codec.dispose();
            }
          }

          expect(await whitePixels(baseline), [0, 0]);
          final triangles = await whitePixels(marked, save: true);
          expect(triangles[0], greaterThan(10));
          expect(triangles[1], greaterThan(10));
          expect(await whitePixels(marked.setTransition(edge, remove: true)), [
            0,
            0,
          ]);
        });
      },
    );
  }
}
