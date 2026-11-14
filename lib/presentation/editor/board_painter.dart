import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_dimensions.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../theme/app_theme.dart';

/// Solo pinta la cuadrícula y la selección. Las capas futuras no existen aún.
final class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.dimensions,
    required this.selectedCell,
    required this.showGrid,
    required this.showCoordinates,
  });

  final BoardDimensions dimensions;
  final CellCoordinate? selectedCell;
  final bool showGrid;
  final bool showCoordinates;

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
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) =>
      oldDelegate.dimensions != dimensions ||
      oldDelegate.selectedCell != selectedCell ||
      oldDelegate.showGrid != showGrid ||
      oldDelegate.showCoordinates != showCoordinates;
}
