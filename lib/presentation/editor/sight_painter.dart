import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_viewport.dart';
import '../../domain/geometry/sight_geometry.dart';
import '../../domain/terrain/edge_wall.dart';
import '../../domain/rules/line_of_sight.dart';
import '../vision/vision_controls.dart' show visionColor;

/// Solo proyecta resultados exactos del motor; no vuelve a calcular contactos.
final class SightPainter extends CustomPainter {
  const SightPainter(
    this.trace, {
    required this.line,
    required this.cells,
    required this.contacts,
    this.evaluation,
    this.showCauses = true,
    this.annotation,
    this.highlightTarget = false,
  });
  final GeometricTrace? trace;
  final bool line, cells, contacts;
  final VisionEvaluation? evaluation;
  final bool showCauses;
  final String? annotation;
  final bool highlightTarget;
  static const pathColor = Color(0xffb3d5ff);
  static const vertexColor = Color(0xffdbb8ff);
  Offset _point(LogicalPoint point) => Offset(
    BoardGeometry.gutter + point.x.toDouble() * BoardGeometry.cellExtent,
    BoardGeometry.gutter + point.y.toDouble() * BoardGeometry.cellExtent,
  );
  @override
  void paint(Canvas canvas, Size size) {
    final result = trace;
    if (result == null) return;
    const extent = BoardGeometry.cellExtent, gutter = BoardGeometry.gutter;
    if (cells) {
      for (final segment in result.segments) {
        final cell = segment.cell;
        final rect = Rect.fromLTWH(
          gutter + cell.column * extent,
          gutter + cell.row * extent,
          extent,
          extent,
        ).deflate(3);
        canvas.drawRect(
          rect,
          Paint()..color = pathColor.withValues(alpha: .10),
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = pathColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      for (final crossing in result.crossings.where(
        (crossing) => crossing.isVertex,
      )) {
        for (final cell in crossing.cornerOnly) {
          final rect = Rect.fromLTWH(
            gutter + cell.column * extent,
            gutter + cell.row * extent,
            extent,
            extent,
          ).deflate(7);
          // Cuatro marcas de esquina: contacto puntual, sin relleno de interior.
          final paint = Paint()
            ..color = vertexColor
            ..strokeWidth = 2;
          for (final corner in [
            rect.topLeft,
            rect.topRight,
            rect.bottomLeft,
            rect.bottomRight,
          ]) {
            final dx = corner.dx == rect.left ? 6.0 : -6.0;
            final dy = corner.dy == rect.top ? 6.0 : -6.0;
            canvas.drawLine(corner, corner + Offset(dx, 0), paint);
            canvas.drawLine(corner, corner + Offset(0, dy), paint);
          }
        }
      }
    }
    if (contacts) {
      for (final crossing in result.crossings) {
        final color = crossing.isVertex ? vertexColor : pathColor;
        for (final contact in crossing.contacts.where(
          (contact) => contact.hasWall,
        )) {
          final edge = contact.edge;
          final start = Offset(
            gutter + edge.column * extent,
            gutter + edge.row * extent,
          );
          final finish =
              start +
              (edge.axis == EdgeAxis.vertical
                  ? const Offset(0, extent)
                  : const Offset(extent, 0));
          canvas.drawLine(
            start,
            finish,
            Paint()
              ..color = color
              ..strokeWidth = 6,
          );
        }
      }
    }
    if (line) {
      final tint = evaluation == null
          ? pathColor
          : visionColor(evaluation!.status);
      final start = _point(result.events.first.point),
          end = _point(result.events.last.point);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xdd101c2c)
          ..strokeWidth = 6,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = tint
          ..strokeWidth = 3,
      );
      canvas.drawCircle(start, 7, Paint()..color = tint);
      canvas.drawCircle(start, 3, Paint()..color = const Color(0xff102030));
      canvas.drawRect(
        Rect.fromCenter(center: end, width: 10, height: 10),
        Paint()
          ..color = tint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _label(canvas, 'O', start + const Offset(-15, -16));
      _label(canvas, 'D', end + const Offset(15, 16));
      if (annotation != null) {
        _label(canvas, annotation!, (start + end) / 2 + const Offset(0, -16));
      }
      if (highlightTarget) {
        canvas.drawRect(
          Rect.fromCenter(center: end, width: extent - 8, height: extent - 8),
          Paint()
            ..color = tint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
    }
    if (contacts) {
      for (final crossing in result.crossings) {
        final p = _point(crossing.point);
        if (crossing.isVertex) {
          final diamond = Path()
            ..moveTo(p.dx, p.dy - 6)
            ..lineTo(p.dx + 6, p.dy)
            ..lineTo(p.dx, p.dy + 6)
            ..lineTo(p.dx - 6, p.dy)
            ..close();
          canvas.drawPath(diamond, Paint()..color = vertexColor);
        } else {
          canvas.drawCircle(p, 4, Paint()..color = pathColor);
        }
      }
    }
    final verdict = evaluation;
    if (showCauses && verdict != null && verdict.status != VisionStatus.clear) {
      final tint = visionColor(verdict.status);
      final cells = {for (final item in verdict.decisive) ...item.cells};
      final edges = {for (final item in verdict.decisive) ...item.edges};
      for (final cell in cells) {
        final rect = Rect.fromLTWH(
          gutter + cell.column * extent,
          gutter + cell.row * extent,
          extent,
          extent,
        ).deflate(5);
        canvas.drawRect(
          rect,
          Paint()
            ..color = tint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        _label(canvas, '!', rect.topRight + const Offset(-5, 8));
      }
      for (final edge in edges) {
        final a = Offset(
          gutter + edge.column * extent,
          gutter + edge.row * extent,
        );
        canvas.drawLine(
          a,
          a +
              (edge.axis == EdgeAxis.vertical
                  ? const Offset(0, extent)
                  : const Offset(extent, 0)),
          Paint()
            ..color = tint
            ..strokeWidth = 7,
        );
      }
    }
  }

  void _label(Canvas canvas, String value, Offset point) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'sans-serif',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
      center: point,
      width: text.width + 6,
      height: text.height + 2,
    );
    canvas.drawRect(rect, Paint()..color = const Color(0xff102030));
    text.paint(canvas, rect.topLeft + const Offset(3, 1));
    text.dispose();
  }

  @override
  bool shouldRepaint(SightPainter oldDelegate) =>
      oldDelegate.trace != trace ||
      oldDelegate.line != line ||
      oldDelegate.cells != cells ||
      oldDelegate.contacts != contacts ||
      oldDelegate.evaluation != evaluation ||
      oldDelegate.showCauses != showCauses ||
      oldDelegate.annotation != annotation ||
      oldDelegate.highlightTarget != highlightTarget;
}
