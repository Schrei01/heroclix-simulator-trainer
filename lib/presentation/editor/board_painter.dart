import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_dimensions.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../theme/app_theme.dart';
import '../../application/board/board_session.dart';
import '../../domain/characters/character.dart';
import '../../domain/characters/team.dart';
import '../../domain/terrain/terrain.dart';
import '../../domain/terrain/edge_wall.dart';
import '../../application/board/layer_draft.dart';

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
    this.layerPreview,
  });

  final BoardDimensions dimensions;
  final CellCoordinate? selectedCell;
  final bool showGrid;
  final bool showCoordinates;
  final BoardSession? session;
  final FigureDragPreview? preview;
  final LayerDraft? layerPreview;

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
    final terrain = session?.terrain;
    if (terrain != null) {
      for (final entry in terrain.cells.entries) {
        final type = entry.value.type;
        if (type == TerrainType.clear) continue;
        final rect = _cellRect(entry.key);
        final blocking = type == TerrainType.blocking;
        final water = type == TerrainType.water;
        canvas.drawRect(
          rect,
          Paint()
            ..color = blocking
                ? const Color(0xff524229)
                : water
                ? const Color(0xff193e60)
                : const Color(0xff25453c),
        );
        canvas.save();
        canvas.clipRect(rect.deflate(1));
        final pattern = Paint()
          ..color = blocking
              ? const Color(0xffe9bd6b)
              : water
              ? const Color(0xff79c9ff)
              : const Color(0xff87d8c0)
          ..strokeWidth = 1.5;
        if (blocking) {
          for (double x = rect.left - cell; x < rect.right; x += 12) {
            canvas.drawLine(
              Offset(x, rect.top),
              Offset(x + cell, rect.bottom),
              pattern,
            );
          }
        } else if (water) {
          final waves = Path();
          for (double y = rect.top + 16; y < rect.bottom; y += 16) {
            waves.moveTo(rect.left + 4, y);
            for (double x = rect.left + 4; x + 12 < rect.right; x += 12) {
              waves.quadraticBezierTo(x + 3, y - 4, x + 6, y);
              waves.quadraticBezierTo(x + 9, y + 4, x + 12, y);
            }
          }
          canvas.drawPath(waves, pattern..style = PaintingStyle.stroke);
        } else {
          for (double x = rect.left + 8; x < rect.right; x += 12) {
            for (double y = rect.top + 8; y < rect.bottom; y += 12) {
              canvas.drawCircle(Offset(x, y), 1.5, pattern);
            }
          }
        }
        canvas.restore();
        if (water) _waterBoundary(canvas, entry.key, rect, terrain);
        canvas.drawRect(
          Rect.fromLTWH(rect.left + 3, rect.top + 3, 14, 15),
          Paint()..color = AppTheme.background,
        );
        _text(
          canvas,
          blocking
              ? 'B'
              : water
              ? 'A'
              : 'H',
          Offset(rect.left + 10, rect.top + 10),
          fontSize: 11,
          color: Colors.white,
        );
      }
    }

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
        if (figure.abilities.isNotEmpty) {
          _text(
            canvas,
            'IT',
            rect.bottomLeft + const Offset(14, -10),
            fontSize: 10,
            color: Colors.white,
          );
        }
      }
    }
    if (state != null) {
      _elevations(canvas, state);
      _indoorBoundaries(canvas, state.terrain);
      for (final edge in state.walls.edges.values) {
        _wall(canvas, edge, const Color(0xfff5d28b));
      }
      for (final cell in state.studyConflicts) {
        final rect = _cellRect(cell);
        final center = Offset(rect.right - 9, rect.top + 10);
        canvas.drawCircle(center, 9, Paint()..color = const Color(0xffb71c1c));
        _text(canvas, '!', center, fontSize: 16, color: Colors.white);
      }
    }
    final draft = layerPreview;
    if (draft != null) {
      final incompatible =
          draft.tool == EditorTool.terrain &&
          draft.brush.type == TerrainType.blocking &&
          state != null &&
          state.blockingConflicts(draft.cells, draft.type).isNotEmpty;
      final color =
          incompatible || draft.tool == EditorTool.erase || draft.eraseWalls
          ? const Color(0xffff8a80)
          : draft.tool == EditorTool.terrain &&
                draft.brush == TerrainBrush.water
          ? const Color(0xff79c9ff)
          : draft.tool == EditorTool.terrain &&
                draft.brush == TerrainBrush.indoor
          ? const Color(0xffffde59)
          : const Color(0xff69f0ae);
      for (final cell in draft.cells) {
        final rect = _cellRect(cell).deflate(1);
        canvas.drawRect(rect, Paint()..color = color.withValues(alpha: .28));
        canvas.drawRect(
          rect,
          Paint()
            ..color = color
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
      if (draft.tool == EditorTool.terrain &&
          draft.brush == TerrainBrush.elevated &&
          state != null) {
        for (final cell in draft.cells) {
          final next = state.terrain.at(cell).level + 1;
          _text(
            canvas,
            next > 40 ? 'E40 máx.' : 'E$next',
            _cellRect(cell).center,
            fontSize: 16,
            color: Colors.white,
          );
        }
      }
      for (final edge in draft.edges) {
        _wall(canvas, edge, color);
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

  Rect _cellRect(CellCoordinate cell) => Rect.fromLTWH(
    BoardGeometry.gutter + cell.column * BoardGeometry.cellExtent,
    BoardGeometry.gutter + cell.row * BoardGeometry.cellExtent,
    BoardGeometry.cellExtent,
    BoardGeometry.cellExtent,
  );
  void _indoorBoundaries(Canvas canvas, TerrainLayer terrain) {
    final yellow = Paint()
      ..color = const Color(0xffffde59)
      ..strokeWidth = 3;
    if (terrain.environment == MapEnvironment.indoor) {
      canvas.drawRect(
        Rect.fromLTWH(
          BoardGeometry.gutter,
          BoardGeometry.gutter,
          dimensions.columns * BoardGeometry.cellExtent,
          dimensions.rows * BoardGeometry.cellExtent,
        ).deflate(3),
        yellow..style = PaintingStyle.stroke,
      );
      return;
    }
    bool inside(int col, int row) =>
        col >= 0 &&
        row >= 0 &&
        col < dimensions.columns &&
        row < dimensions.rows &&
        terrain.isIndoor(CellCoordinate(column: col, row: row));
    for (final cell in terrain.indoorCells) {
      final rect = _cellRect(cell).deflate(4);
      for (final (dx, dy, from, to) in [
        (-1, 0, rect.topLeft, rect.bottomLeft),
        (1, 0, rect.topRight, rect.bottomRight),
        (0, -1, rect.topLeft, rect.topRight),
        (0, 1, rect.bottomLeft, rect.bottomRight),
      ]) {
        if (!inside(cell.column + dx, cell.row + dy)) {
          canvas.drawLine(from, to, yellow);
        }
      }
      _text(
        canvas,
        'I',
        Offset(rect.right - 7, rect.top + 7),
        fontSize: 11,
        color: yellow.color,
      );
    }
  }

  void _waterBoundary(
    Canvas canvas,
    CellCoordinate cell,
    Rect rect,
    TerrainLayer terrain,
  ) {
    bool isWater(int column, int row) =>
        column >= 0 &&
        row >= 0 &&
        column < dimensions.columns &&
        row < dimensions.rows &&
        terrain.at(CellCoordinate(column: column, row: row)).type ==
            TerrainType.water;
    final border = Paint()
      ..color = const Color(0xff79c9ff)
      ..strokeWidth = 3;
    final inset = rect.deflate(1.5);
    for (final (dx, dy, from, to) in [
      (-1, 0, inset.topLeft, inset.bottomLeft),
      (1, 0, inset.topRight, inset.bottomRight),
      (0, -1, inset.topLeft, inset.topRight),
      (0, 1, inset.bottomLeft, inset.bottomRight),
    ]) {
      if (!isWater(cell.column + dx, cell.row + dy)) {
        canvas.drawLine(from, to, border);
      }
    }
  }

  void _elevations(Canvas canvas, BoardSession state) {
    const extent = BoardGeometry.cellExtent, gutter = BoardGeometry.gutter;
    final transitionCells = {
      for (final edge in state.terrain.transitions) ...[
        edge.firstCell,
        edge.secondCell,
      ],
    };
    for (var row = 0; row < dimensions.rows; row++) {
      for (var col = 0; col < dimensions.columns; col++) {
        final c = CellCoordinate(row: row, column: col);
        final level = state.terrain.at(c).level;
        final rect = _cellRect(c);
        final raising =
            layerPreview?.tool == EditorTool.terrain &&
            layerPreview?.brush == TerrainBrush.elevated &&
            layerPreview!.cells.contains(c);
        if (level > 1 && !transitionCells.contains(c) && !raising) {
          final badge = Rect.fromLTWH(
            rect.right - 31,
            rect.bottom - 19,
            30,
            18,
          );
          canvas.drawRect(badge, Paint()..color = AppTheme.background);
          _text(
            canvas,
            'E$level',
            badge.center,
            fontSize: 12,
            color: Colors.white,
          );
        }
        for (final n in [
          if (col + 1 < dimensions.columns)
            CellCoordinate(row: row, column: col + 1),
          if (row + 1 < dimensions.rows)
            CellCoordinate(row: row + 1, column: col),
        ]) {
          if (level != state.terrain.at(n).level) {
            final edge = EdgeWall.between(c, n);
            final start = Offset(
              gutter + edge.column * extent,
              gutter + edge.row * extent,
            );
            canvas.drawLine(
              start,
              start +
                  (edge.axis == EdgeAxis.vertical
                      ? const Offset(0, extent)
                      : const Offset(extent, 0)),
              Paint()
                ..color = const Color(0xffff7777)
                ..strokeWidth = 3,
            );
          }
        }
      }
    }
    for (final edge in state.terrain.transitions) {
      final vertical = edge.axis == EdgeAxis.vertical;
      final center = Offset(
        gutter + edge.column * extent + (vertical ? 0 : extent / 2),
        gutter + edge.row * extent + (vertical ? extent / 2 : 0),
      );
      const depth = 22.0, halfBase = 18.0;
      final tangent = vertical
          ? const Offset(0, halfBase)
          : const Offset(halfBase, 0);
      final normal = vertical ? const Offset(depth, 0) : const Offset(0, depth);
      void triangle(Offset tip, int level) {
        final shape = Path()
          ..moveTo((center - tangent).dx, (center - tangent).dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo((center + tangent).dx, (center + tangent).dy)
          ..close();
        canvas.drawPath(shape, Paint()..color = Colors.white);
        canvas.drawPath(
          shape,
          Paint()
            ..color = const Color(0xffff7777)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        _text(
          canvas,
          '$level',
          center + (tip - center) / 3,
          fontSize: 12,
          color: const Color(0xff101c2b),
        );
      }

      triangle(center - normal, state.terrain.at(edge.firstCell).level);
      triangle(center + normal, state.terrain.at(edge.secondCell).level);
    }
  }

  void _wall(Canvas canvas, EdgeWall edge, Color color) {
    final start = Offset(
      BoardGeometry.gutter + edge.column * BoardGeometry.cellExtent,
      BoardGeometry.gutter + edge.row * BoardGeometry.cellExtent,
    );
    final end =
        start +
        (edge.axis == EdgeAxis.vertical
            ? const Offset(0, BoardGeometry.cellExtent)
            : const Offset(BoardGeometry.cellExtent, 0));
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = const Color(0xff101c2b)
        ..strokeWidth = 9,
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 6,
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = const Color(0xff101c2b)
        ..strokeWidth = 2,
    );
  }

  void _text(
    Canvas canvas,
    String value,
    Offset center, {
    double fontSize = 20,
    Color color = const Color(0xff102030),
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontFamily: 'sans-serif',
          fontSize: fontSize,
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
      oldDelegate.preview != preview ||
      oldDelegate.session?.terrain != session?.terrain ||
      oldDelegate.session?.walls != session?.walls ||
      oldDelegate.layerPreview != layerPreview;
}
