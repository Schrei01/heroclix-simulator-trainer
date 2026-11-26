import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';

const priorityEngine = PriorityEngine();

PriorityConfiguration priorityConfig(
  int count, {
  bool clock = true,
  Duration time = const Duration(minutes: 30),
  String? first,
}) => PriorityConfiguration(
  players: [
    for (var i = 1; i <= count; i++)
      PriorityPlayerConfiguration(
        id: 'J$i',
        name: 'Jugador $i',
        buildPoints: 300,
      ),
  ],
  startingPlayerId: first,
  clockEnabled: clock,
  initialTime: time,
);

PriorityMatch priorityGame(
  int count, {
  bool clock = true,
  Duration time = const Duration(minutes: 30),
  String? first,
}) => priorityEngine
    .apply(
      priorityEngine.configure(
        priorityConfig(count, clock: clock, time: time, first: first),
      ),
      const PriorityCommand.start(),
    )
    .match;

PriorityMatch priorityStep(PriorityMatch match, PriorityCommand command) =>
    priorityEngine.apply(match, command).match;

class PriorityFakeClock {
  Duration now = Duration.zero;
  Duration read() => now;
  void advance(Duration elapsed) {
    now += elapsed;
  }
}
