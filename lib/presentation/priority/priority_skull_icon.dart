import 'package:material_ui/material_ui.dart';

/// Vector icon so the skull has the same appearance on every Android version.
class PrioritySkullIcon extends StatelessWidget {
  const PrioritySkullIcon({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(22, 22),
    painter: _SkullPainter(IconTheme.of(context).color ?? Colors.white),
  );
}

class _SkullPainter extends CustomPainter {
  const _SkullPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final skull = Path()
      ..addOval(const Rect.fromLTWH(3, 1, 18, 17))
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 12, 10, 11),
          const Radius.circular(2),
        ),
      );
    final holes = Path()
      ..addOval(const Rect.fromLTWH(6, 8, 5, 5))
      ..addOval(const Rect.fromLTWH(13, 8, 5, 5))
      ..moveTo(12, 13)
      ..lineTo(10, 16)
      ..lineTo(14, 16)
      ..close()
      ..addRect(const Rect.fromLTWH(9, 19, 1.5, 4))
      ..addRect(const Rect.fromLTWH(13.5, 19, 1.5, 4));
    canvas.drawPath(
      Path.combine(PathOperation.difference, skull, holes),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SkullPainter oldDelegate) => color != oldDelegate.color;
}
