import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_table_layout.dart';

import 'priority_screen_test.dart' show mount, press, key, selectCount;
import 'priority_seat_drag_test.dart' show dragSeat;
import 'support/priority_stage3_fixtures.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(800, 360)]) {
    for (var count = 2; count <= 6; count++) {
      test(
        '$count jugadores en $size: turnos y ambas respuestas recorren el reloj',
        () {
          final seats = priorityTableSeats(size, count);
          final center = Offset(size.width / 2, size.height / 2);
          double angle(String id) {
            final point =
                seats[int.parse(id.substring(1)) - 1].bounds.center - center;
            return math.atan2(point.dy, point.dx);
          }

          for (var first = 1; first <= count; first++) {
            var match = priorityGame(count, first: 'J$first', clock: false);
            final turnOrder = <String>[];
            for (var turn = 0; turn < count * 2; turn++) {
              final active = match.activePlayerId!;
              turnOrder.add(active);
              final free = turn.isOdd;
              match = priorityStep(
                match,
                free
                    ? PriorityCommand.free(active)
                    : PriorityCommand.action(active),
              );
              var previous = active;
              var totalAngle = 0.0;
              while (match.hasResponseWindow) {
                final next = match.priorityPlayerId!;
                final delta =
                    (angle(next) - angle(previous) + 2 * math.pi) %
                    (2 * math.pi);
                expect(delta, greaterThan(0));
                totalAngle += delta;
                previous = next;
                match = priorityStep(
                  match,
                  free
                      ? PriorityCommand.responseFree(next)
                      : PriorityCommand.responseAction(next),
                );
              }
              totalAngle +=
                  (angle(active) - angle(previous) + 2 * math.pi) %
                  (2 * math.pi);
              expect(totalAngle, closeTo(2 * math.pi, .0001));
              expect(match.priorityPlayerId, active);
              match = priorityStep(match, PriorityCommand.endTurn(active));
            }
            expect(turnOrder, [
              for (var n = 0; n < count * 2; n++)
                'J${(first - 1 + n) % count + 1}',
            ]);
            expect(match.round, 3);
          }
        },
      );
    }

    testWidgets(
      'tres en $size: dibujo, giros, configuración y circulación real',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPhysicalSize);
        final c = PriorityController(inputCooldown: Duration.zero);
        addTearDown(c.dispose);
        await mount(t, c);
        await selectCount(t, 3);
        // The setup preview must use the same positions and rotations as the table.
        final preview = [
          for (var i = 1; i <= 3; i++)
            t.getRect(key('priority-setup-view-J$i')),
        ];
        expect(preview[0].left, preview[2].left);
        expect(preview[0].top, preview[1].top);
        expect(preview[0].right, closeTo(preview[1].left, .01));
        expect(preview[2].top, closeTo(preview[0].bottom, .01));
        expect(preview[2].right, closeTo(preview[1].right, .01));
        for (var i = 1; i <= 3; i++) {
          final rotated = find.descendant(
            of: key('priority-setup-view-J$i'),
            matching: find.byType(RotatedBox),
          );
          expect(
            t.widget<RotatedBox>(rotated.first).quarterTurns,
            [1, 3, 0][i - 1],
          );
        }
        await press(t, 'priority-start');
        final table = t.getRect(key('priority-table'));
        final actual = [
          for (var i = 1; i <= 3; i++) t.getRect(key('priority-seat-view-J$i')),
        ];
        expect(actual, [
          Rect.fromLTWH(
            table.left,
            table.top,
            table.width / 2,
            table.height / 2,
          ),
          Rect.fromLTWH(
            table.center.dx,
            table.top,
            table.width / 2,
            table.height / 2,
          ),
          Rect.fromLTWH(
            table.left,
            table.center.dy,
            table.width,
            table.height / 2,
          ),
        ]);
        for (var i = 1; i <= 3; i++) {
          expect(
            t.widget<RotatedBox>(key('priority-orientation-J$i')).quarterTurns,
            [1, 3, 0][i - 1],
          );
        }
        await press(t, 'priority-action-J1');
        expect(c.value!.priorityPlayerId, 'J2');
        await press(t, 'priority-responseAction-J2');
        expect(c.value!.priorityPlayerId, 'J3');
        await press(t, 'priority-pass-J3');
        await press(t, 'priority-endTurn-J1');
        expect(c.value!.activePlayerId, 'J2');
        expect(c.value!.priorityPlayerId, 'J2');
        expect(c.value!.players.map((p) => p.availableActions), [3, 3, 3]);
        await dragSeat(t, 'J1', 'J3');
        expect(c.value!.turnOrder, ['J3', 'J2', 'J1']);
        expect(c.value!.configuration.startingPlayerId, 'J1');
        await press(t, 'priority-endTurn-J2');
        expect(c.value!.activePlayerId, 'J1');
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
