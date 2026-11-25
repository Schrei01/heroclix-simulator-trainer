import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_table_layout.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(360, 800),
    const Size(800, 360),
    const Size(320, 320),
    const Size(1024, 768),
  ]) {
    for (var count = 2; count <= 6; count++) {
      test(
        '$count asientos en $size: cubren mesa, sin solaparse, orden antihorario',
        () {
          final seats = priorityTableSeats(size, count);
          expect(seats.length, count);
          var area = 0.0;
          var totalAngle = 0.0;
          final center = Offset(size.width / 2, size.height / 2);
          double angle(int index) => math.atan2(
            center.dy - seats[index].bounds.center.dy,
            seats[index].bounds.center.dx - center.dx,
          );
          for (var i = 0; i < count; i++) {
            final rect = seats[i].bounds;
            expect(rect.width, greaterThan(0));
            expect(rect.height, greaterThan(0));
            expect(rect.left, greaterThanOrEqualTo(-.0001));
            expect(rect.top, greaterThanOrEqualTo(-.0001));
            expect(rect.right, lessThanOrEqualTo(size.width + .0001));
            expect(rect.bottom, lessThanOrEqualTo(size.height + .0001));
            expect(seats[i].quarterTurns, inInclusiveRange(0, 3));
            area += rect.width * rect.height;
            final delta =
                (angle((i + 1) % count) - angle(i) + 2 * math.pi) %
                (2 * math.pi);
            expect(delta, greaterThan(0));
            totalAngle += delta;
            for (var j = i + 1; j < count; j++) {
              final overlap = rect.intersect(seats[j].bounds);
              expect(
                overlap.isEmpty || overlap.width * overlap.height < .0001,
                isTrue,
              );
            }
          }
          expect(area, closeTo(size.width * size.height, .0001));
          expect(totalAngle, closeTo(2 * math.pi, .0001));
          if (count == 2) {
            expect((seats[1].quarterTurns - seats[0].quarterTurns).abs(), 2);
          }
        },
      );
    }
  }
  test('rechaza cantidades fuera del formato', () {
    for (final count in [0, 1, 7]) {
      expect(
        () => priorityTableSeats(const Size(360, 800), count),
        throwsArgumentError,
      );
    }
  });
}
