import 'package:flutter/painting.dart';

/// Presentation geometry only. List index is the engine's seating order, never
/// the turn order sorted by active/priority status. RotatedBox also rotates hit
/// testing and semantics, unlike rotating text alone.
final class PrioritySeatLayout {
  const PrioritySeatLayout(this.bounds, this.quarterTurns);
  final Rect bounds;
  final int quarterTurns;
}

List<PrioritySeatLayout> priorityTableSeats(
  Size size,
  int count, {
  bool? landscape,
}) {
  if (count < 2 || count > 6) throw ArgumentError.value(count, 'count');
  final wide = landscape ?? size.width > size.height;
  PrioritySeatLayout seat(double x, double y, double w, double h, int turns) =>
      PrioritySeatLayout(
        Rect.fromLTWH(
          x * size.width,
          y * size.height,
          w * size.width,
          h * size.height,
        ),
        turns,
      );
  if (count == 2) {
    return wide
        ? [seat(0, 0, .5, 1, 1), seat(.5, 0, .5, 1, 3)]
        : [seat(0, .5, 1, .5, 0), seat(0, 0, 1, .5, 2)];
  }
  final near = (count + 1) ~/ 2;
  final far = count - near;
  if (wide) {
    return [
      for (var i = 0; i < near; i++) seat(i / near, .5, 1 / near, .5, 0),
      for (var i = 0; i < far; i++) seat(1 - (i + 1) / far, 0, 1 / far, .5, 2),
    ];
  }
  return [
    seat(0, 1 - 1 / far, .5, 1 / far, 1),
    for (var i = 0; i < near; i++)
      seat(.5, 1 - (i + 1) / near, .5, 1 / near, 3),
    for (var i = 0; i < far - 1; i++) seat(0, i / far, .5, 1 / far, 1),
  ];
}

const priorityPlayerColors = <Color>[
  Color(0xFF7FCBFF),
  Color(0xFFFFAA91),
  Color(0xFFB7E68A),
  Color(0xFFD9B0FF),
  Color(0xFFFFD878),
  Color(0xFF7DE0CF),
];
