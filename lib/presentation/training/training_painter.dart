import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_viewport.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/training/exercise.dart';

/// Superposiciones de respuesta, sin consultar correctores ni dibujar soluciones.
final class TrainingPainter extends CustomPainter {
  const TrainingPainter(this.exercise, this.answer, this.outcome);
  final Exercise exercise;
  final Answer answer;
  final EvaluationOutcome? outcome;
  Rect rect(CellCoordinate c) => Rect.fromLTWH(
    BoardGeometry.gutter + c.column * BoardGeometry.cellExtent + 4,
    BoardGeometry.gutter + c.row * BoardGeometry.cellExtent + 4,
    BoardGeometry.cellExtent - 8,
    BoardGeometry.cellExtent - 8,
  );
  void _text(Canvas canvas, String value, Offset point, Color color) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 13,
          color: color,
          backgroundColor: const Color(0xff101c2b),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, point);
    text.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final source = exercise.world.characters
        .where((f) => f.id == exercise.sourceId)
        .firstOrNull;
    final dest = exercise.world.characters
        .where((f) => f.id == exercise.targetId)
        .firstOrNull;
    const neutral = Color(0xff9ddaf5);
    final color = outcome == EvaluationOutcome.correct
        ? const Color(0xff7dd9b2)
        : outcome == EvaluationOutcome.incorrect
        ? const Color(0xffff8585)
        : neutral;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;
    for (final c in exercise.candidates) {
      canvas.drawRect(
        rect(c),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = neutral.withValues(alpha: .5),
      );
    }
    final a = exercise.origin ?? source?.position,
        b = exercise.destination ?? dest?.position;
    if (a != null) _text(canvas, 'O', rect(a).topLeft, neutral);
    if (b != null) {
      _text(canvas, 'D', rect(b).topRight - const Offset(14, 0), neutral);
    }
    if (answer.kind == AnswerKind.route && answer.route.isNotEmpty) {
      final path = Path()
        ..moveTo(
          rect(answer.route.first).center.dx,
          rect(answer.route.first).center.dy,
        );
      for (final c in answer.route.skip(1)) {
        path.lineTo(rect(c).center.dx, rect(c).center.dy);
      }
      canvas.drawPath(path, p);
      for (var i = 0; i < answer.route.length; i++) {
        _text(canvas, '$i', rect(answer.route[i]).center, color);
      }
    } else if (answer.value.isNotEmpty && answer.kind == AnswerKind.cell) {
      final c = CellCoordinate.parse(answer.value);
      canvas.drawRect(rect(c), p);
      _text(canvas, 'R', rect(c).bottomLeft - const Offset(0, 16), color);
    } else if (answer.kind == AnswerKind.target) {
      final f = exercise.world.characters
          .where((f) => f.id == answer.value)
          .firstOrNull;
      if (f != null) {
        for (final c in f.occupiedCells) {
          canvas.drawRect(rect(c), p);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TrainingPainter oldDelegate) =>
      exercise != oldDelegate.exercise ||
      answer != oldDelegate.answer ||
      outcome != oldDelegate.outcome;
}
