import 'package:material_ui/material_ui.dart';

import '../../application/board/movement_analysis.dart';
import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/movement/movement.dart';

Color movementColor(MovementStatus? status) => switch (status) {
  MovementStatus.valid => const Color(0xff7dd9b2),
  MovementStatus.invalid => const Color(0xffff8585),
  _ => const Color(0xffffcb70),
};

final class MovementPainter extends CustomPainter {
  MovementPainter(this.analysis)
    : route = List.of(analysis.route),
      result = analysis.result;
  final MovementAnalysis analysis;
  final List<CellCoordinate> route;
  final RouteEvaluation? result;
  Offset center(CellCoordinate c) => Offset(
    BoardGeometry.gutter + (c.column + .5) * BoardGeometry.cellExtent,
    BoardGeometry.gutter + (c.row + .5) * BoardGeometry.cellExtent,
  );
  @override
  void paint(Canvas canvas, Size size) {
    if (route.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final color = movementColor(result?.status);
    final p = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(center(route.first).dx, center(route.first).dy);
    for (final c in route.skip(1)) {
      path.lineTo(center(c).dx, center(c).dy);
    }
    canvas.drawPath(path, p);
    final f = analysis.original?.characters.byId(analysis.sourceId ?? '');
    if (f != null) {
      for (final (anchor, label) in [
        (route.first, 'ORIGEN'),
        (route.last, 'ENSAYO'),
      ]) {
        final rect = Rect.fromLTWH(
          BoardGeometry.gutter + anchor.column * BoardGeometry.cellExtent + 5,
          BoardGeometry.gutter + anchor.row * BoardGeometry.cellExtent + 5,
          f.footprint.width * BoardGeometry.cellExtent - 10,
          f.footprint.height * BoardGeometry.cellExtent - 10,
        );
        canvas.drawRect(rect, Paint()..color = color.withValues(alpha: .12));
        canvas.drawRect(rect, p..strokeWidth = 2);
        final text = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'sans-serif',
              color: color,
              backgroundColor: const Color(0xff12202c),
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, rect.topLeft);
        text.dispose();
      }
    }
    for (var i = 0; i < route.length; i++) {
      final c = center(route[i]);
      canvas.drawCircle(c, 11, Paint()..color = const Color(0xff12202c));
      final text = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, c - Offset(text.width / 2, text.height / 2));
      text.dispose();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MovementPainter oldDelegate) => true;
}
