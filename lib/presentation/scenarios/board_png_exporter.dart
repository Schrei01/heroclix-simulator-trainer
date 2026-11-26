import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/terrain/terrain.dart';

import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/characters/team.dart';
import '../editor/board_painter.dart';
import '../editor/character_dialog.dart' show patternName;
import '../theme/app_theme.dart';

final class BoardPng {
  const BoardPng(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width, height;
}

final class BoardPngExporter {
  const BoardPngExporter();
  Future<BoardPng> render(
    BoardSession source, {
    bool coordinates = true,
    bool legend = true,
    int maxDimension = 2048,
  }) async {
    if (maxDimension != 2048 && maxDimension != 4096) {
      throw ArgumentError('El límite PNG debe ser 2048 o 4096.');
    }
    final session = source.clearSelection();
    const geometry = BoardGeometry();
    final boardWidth = geometry.width(session.dimensions),
        boardHeight = geometry.height(session.dimensions);
    final width = legend ? math.max(420.0, boardWidth) : boardWidth;
    final rows = <({TextPainter text, Team? team})>[];
    void row(String value, {Team? team}) {
      final text = TextPainter(
        text: TextSpan(
          text: value,
          style: const TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 14,
            color: Colors.white,
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width - 72);
      rows.add((text: text, team: team));
    }

    if (legend) {
      row(
        'Mapa ${session.terrain.environment == MapEnvironment.indoor
            ? 'Indoor'
            : session.terrain.indoorCells.isNotEmpty
            ? 'Outdoor / Indoor'
            : 'Outdoor'} · Amarillo / I: Indoor (no es muro).',
      );
      row(
        'D Despejado · H puntos: obstaculizado · B rayas: bloqueado · || muro',
      );
      row('A ondas azules: agua (despejado salvo efectos específicos).');
      row('Db piedras: debris/escombros; terreno obstaculizado.');
      row(
        'Elevación: borde rojo y E2/E3… · Transición: dos triángulos numerados unidos por el borde.',
      );
      row(
        '! Figura sobre bloqueado: representación incompatible para estudio. No se evalúan reglas.',
      );
      for (final team in session.teams) {
        row(
          '${team.code} · ${team.name} · ${patternName(team.pattern)}',
          team: team,
        );
      }
    }
    final legendHeight = legend
        ? rows.fold<double>(
            24,
            (height, row) => height + math.max(24, row.text.height) + 8,
          )
        : 0.0;
    final height = boardHeight + legendHeight,
        scale = math.min(2.0, maxDimension / math.max(width, height));
    final pixelWidth = math.min(maxDimension, (width * scale).ceil()),
        pixelHeight = math.min(maxDimension, (height * scale).ceil());
    final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
    canvas.scale(scale);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = AppTheme.background,
    );
    canvas.save();
    canvas.translate((width - boardWidth) / 2, 0);
    BoardPainter(
      dimensions: session.dimensions,
      selectedCell: null,
      showGrid: session.showGrid,
      showCoordinates: coordinates,
      session: session,
    ).paint(canvas, Size(boardWidth, boardHeight));
    canvas.restore();
    var y = boardHeight + 12;
    for (final entry in rows) {
      final team = entry.team;
      if (team != null) {
        final rect = Rect.fromLTWH(16, y, 22, 22);
        canvas.drawRect(rect, Paint()..color = Color(team.color));
        canvas.save();
        canvas.clipRect(rect);
        if (team.pattern == TeamPattern.stripes) {
          for (var x = -16.0; x < 24; x += 6) {
            canvas.drawLine(
              Offset(16 + x, y),
              Offset(38 + x, y + 22),
              Paint()
                ..color = const Color(0x77000000)
                ..strokeWidth = 2,
            );
          }
        }
        if (team.pattern == TeamPattern.dots) {
          for (var x = 20.0; x < 38; x += 6) {
            for (var yy = y + 4; yy < y + 22; yy += 6) {
              canvas.drawCircle(
                Offset(x, yy),
                1.5,
                Paint()..color = const Color(0x88000000),
              );
            }
          }
        }
        canvas.restore();
      }
      entry.text.paint(canvas, Offset(48, y));
      y += math.max(24, entry.text.height) + 8;
      entry.text.dispose();
    }
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(pixelWidth, pixelHeight);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('No se pudo generar el PNG.');
        return BoardPng(
          Uint8List.fromList(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          ),
          pixelWidth,
          pixelHeight,
        );
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }
}
