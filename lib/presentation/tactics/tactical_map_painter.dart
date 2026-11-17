import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/tactics/tactical_diagnostic.dart';

final class TacticalMapPainter extends CustomPainter {
  TacticalMapPainter({
    required Iterable<TacticalCandidate> candidates,
    required this.current,
    required this.selected,
    required this.priority,
  }) : candidates = List.unmodifiable(candidates);
  final List<TacticalCandidate> candidates;
  final CellCoordinate? current, selected;
  final TacticalPriority priority;
  Rect _rect(CellCoordinate c) => Rect.fromLTWH(
    BoardGeometry.gutter + c.column * BoardGeometry.cellExtent + 3,
    BoardGeometry.gutter + c.row * BoardGeometry.cellExtent + 3,
    BoardGeometry.cellExtent - 6,
    BoardGeometry.cellExtent - 6,
  );
  void _text(Canvas canvas, String value, Offset at, {double size = 10}) {
    final t = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'sans-serif',
          fontSize: size,
          color: Colors.white,
          backgroundColor: const Color(0xff132637),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(canvas, at);
    t.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final c in candidates.where(
      (c) => c.status == CandidateStatus.legal,
    )) {
      final d = c.position!, r = _rect(c.cell);
      final score = switch (priority) {
        TacticalPriority.seeMore =>
          d.metrics[TacticalMetric.visible]!.known /
              (d.totalEnemies.clamp(1, 100000)),
        TacticalPriority.reduceExposure =>
          1 -
              d.metrics[TacticalMetric.seenBy]!.known /
                  (d.totalEnemies.clamp(1, 100000)),
        TacticalPriority.minimizeMovement => 1 / (c.route!.cost.clamp(1, 100)),
      };
      final color = d.complete
          ? Color.lerp(
              const Color(0xffd9837c),
              const Color(0xff7dd9b2),
              score.clamp(0, 1),
            )!
          : const Color(0xffffcb70);
      canvas.drawRect(r, Paint()..color = color.withValues(alpha: .27));
      canvas.drawRect(
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      String count(TacticalMetric m) =>
          '${d.metrics[m]!.known}${d.metrics[m]!.unknown > 0 ? '?' : ''}';
      _text(
        canvas,
        'V${count(TacticalMetric.visible)} T${count(TacticalMetric.threats)}',
        r.topLeft,
      );
      _text(canvas, 'C${c.route!.cost}', r.bottomLeft - const Offset(0, 13));
    }
    if (current != null) {
      _text(canvas, 'ORIGEN', _rect(current!).topLeft);
    }
    final candidate = candidates
        .where((c) => c.cell == selected && c.status == CandidateStatus.legal)
        .firstOrNull;
    if (candidate != null) {
      final p = Paint()
        ..color = const Color(0xffb5d8ff)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      final route = candidate.route!.route, path = Path();
      for (var i = 0; i < route.length; i++) {
        final center = _rect(route[i]).center;
        if (i == 0) {
          path.moveTo(center.dx, center.dy);
        } else {
          path.lineTo(center.dx, center.dy);
        }
      }
      canvas.drawPath(path, p);
      canvas.drawRect(_rect(candidate.cell).inflate(2), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TacticalMapPainter oldDelegate) => true;
}
