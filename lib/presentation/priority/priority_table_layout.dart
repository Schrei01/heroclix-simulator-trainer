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
  if (count == 3) {
    return wide
        ? [
            seat(0, 0, .5, 1, 1),
            seat(.5, .5, .5, .5, 3),
            seat(.5, 0, .5, .5, 3),
          ]
        : [
            seat(0, .5, 1, .5, 0),
            seat(.5, 0, .5, .5, 2),
            seat(0, 0, .5, .5, 2),
          ];
  }
  if (count == 4) {
    return [
      seat(0, .5, .5, .5, 0),
      seat(.5, .5, .5, .5, 0),
      seat(.5, 0, .5, .5, 2),
      seat(0, 0, .5, .5, 2),
    ];
  }
  if (wide) {
    return [
      for (var i = 0; i < 3; i++) seat(i / 3, .5, 1 / 3, .5, 0),
      for (var i = 0; i < count - 3; i++)
        seat(1 - (i + 1) / (count - 3), 0, 1 / (count - 3), .5, 2),
    ];
  }
  return [
    seat(0, 1 - 1 / (count - 3), .5, 1 / (count - 3), 1),
    for (var i = 0; i < 3; i++) seat(.5, 1 - (i + 1) / 3, .5, 1 / 3, 3),
    for (var i = 0; i < count - 4; i++)
      seat(0, i / (count - 3), .5, 1 / (count - 3), 1),
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
