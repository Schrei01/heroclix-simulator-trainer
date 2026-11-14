import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_dimensions.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../theme/app_theme.dart';
import '../../application/board/board_session.dart';
import '../../domain/characters/character.dart';
import '../../domain/characters/team.dart';

final class FigureDragPreview {
  const FigureDragPreview(
    this.figure,
    this.position,
    this.point,
    this.valid,
    this.message,
  );
  final Character figure;
  final CellCoordinate? position;
  final BoardPoint point;
  final bool valid;
  final String message;
}

/// Proyección de cuadrícula, figuras y preview; la ocupación vive en el dominio.
final class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.dimensions,
    required this.selectedCell,
    required this.showGrid,
    required this.showCoordinates,
    this.session,
    this.preview,
  });

  final BoardDimensions dimensions;
  final CellCoordinate? selectedCell;
  final bool showGrid;
  final bool showCoordinates;
  final BoardSession? session;
  final FigureDragPreview? preview;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = BoardGeometry.cellExtent;
    const gutter = BoardGeometry.gutter;
    final grid = Rect.fromLTWH(
      gutter,
      gutter,
      dimensions.columns * cell,
      dimensions.rows * cell,
    );
    canvas.drawRect(grid, Paint()..color = AppTheme.surface);

    final selected = selectedCell;
    if (selected != null) {
      final rect = Rect.fromLTWH(
        gutter + selected.column * cell,
        gutter + selected.row * cell,
        cell,
        cell,
      );
      canvas.drawRect(
        rect,
        Paint()..color = AppTheme.accent.withValues(alpha: 0.24),
      );
      canvas.drawRect(
        rect.deflate(2),
        Paint()
          ..color = AppTheme.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      // Un marcador geométrico diferencia la selección además del color.
      canvas.drawCircle(rect.center, 5, Paint()..color = AppTheme.accent);
    }

    final line = Paint()
      ..color = const Color(0xFF688097)
      ..strokeWidth = 1;
    if (showGrid) {
      final path = Path();
      for (var column = 0; column <= dimensions.columns; column++) {
        final x = gutter + column * cell;
        path.moveTo(x, gutter);
        path.lineTo(x, grid.bottom);
      }
      for (var row = 0; row <= dimensions.rows; row++) {
        final y = gutter + row * cell;
        path.moveTo(gutter, y);
        path.lineTo(grid.right, y);
      }
      canvas.drawPath(path, line..style = PaintingStyle.stroke);
    } else {
      canvas.drawRect(grid, line..style = PaintingStyle.stroke);
    }

    if (showCoordinates) {
      void label(String value, Offset center) {
        final text = TextPainter(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              color: AppTheme.muted,
              fontFamily: 'sans-serif',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
        text.dispose();
      }

      for (var column = 0; column < dimensions.columns; column++) {
        label(
          CellCoordinate.columnLabel(column),
          Offset(gutter + (column + 0.5) * cell, gutter / 2),
        );
      }
      for (var row = 0; row < dimensions.rows; row++) {
        label('${row + 1}', Offset(gutter / 2, gutter + (row + 0.5) * cell));
      }
    }
    final state = session;
    if (state != null) {
      for (final figure in state.characters.all) {
        final team = state.teamById(figure.teamId);
        final rect = Rect.fromLTWH(
          gutter + figure.position.column * cell,
          gutter + figure.position.row * cell,
          figure.footprint.width * cell,
          figure.footprint.height * cell,
        ).deflate(6);
        final shape = Path();
        if (figure.footprint == Footprint.single) {
          shape.addOval(rect);
        } else {
          shape.addRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(16)),
          );
        }
        canvas.drawPath(shape, Paint()..color = Color(team.color));
        canvas.save();
        canvas.clipPath(shape);
        final pattern = Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = 3;
        if (team.pattern == TeamPattern.stripes) {
          for (double x = rect.left - rect.height; x < rect.right; x += 12) {
            canvas.drawLine(
              Offset(x, rect.top),
              Offset(x + rect.height, rect.bottom),
              pattern,
            );
          }
        } else if (team.pattern == TeamPattern.dots) {
          for (double x = rect.left; x < rect.right; x += 12) {
            for (double y = rect.top; y < rect.bottom; y += 12) {
              canvas.drawCircle(Offset(x, y), 2, pattern);
            }
          }
        }
        canvas.restore();
        final selectedFigure = state.selectedCharacterId == figure.id;
        canvas.drawPath(
          shape,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = selectedFigure ? 5 : 2
            ..color = selectedFigure ? Colors.white : const Color(0xff162638),
        );
        if (selectedFigure) {
          canvas.drawRect(
            rect.inflate(3),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = AppTheme.accent,
          );
        }
        _text(canvas, '${figure.label}\n${team.code}', rect.center);
      }
    }
    final drag = preview;
    if (drag != null) {
      final pos = drag.position;
      final rect = Rect.fromLTWH(
        pos == null ? drag.point.x - cell / 2 : gutter + pos.column * cell,
        pos == null ? drag.point.y - cell / 2 : gutter + pos.row * cell,
        drag.figure.footprint.width * cell,
        drag.figure.footprint.height * cell,
      ).deflate(2);
      final color = drag.valid
          ? const Color(0xff69f0ae)
          : const Color(0xffff8a80);
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: .35));
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      _text(
        canvas,
        drag.valid ? '✓ ${drag.figure.label}' : '× ${drag.figure.label}',
        rect.center,
      );
    }
  }

  void _text(Canvas canvas, String value, Offset center) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: Color(0xff102030),
          fontFamily: 'sans-serif',
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
    text.dispose();
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) =>
      oldDelegate.dimensions != dimensions ||
      oldDelegate.selectedCell != selectedCell ||
      oldDelegate.showGrid != showGrid ||
      oldDelegate.showCoordinates != showCoordinates ||
      oldDelegate.session?.characters != session?.characters ||
      oldDelegate.session?.teams != session?.teams ||
      oldDelegate.session?.selectedCharacterId !=
          session?.selectedCharacterId ||
      oldDelegate.preview != preview;
}
