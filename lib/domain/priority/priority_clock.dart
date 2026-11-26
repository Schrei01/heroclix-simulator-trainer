part of 'priority.dart';

PriorityTransition _advancePriorityClock(
  PriorityMatch match,
  Duration elapsed,
) {
  if (elapsed < Duration.zero) {
    throw ArgumentError('El tiempo transcurrido no puede ser negativo.');
  }
  if (!match.configuration.clockEnabled ||
      elapsed == Duration.zero ||
      match.isPaused ||
      match.phase == PriorityPhase.configuration ||
      match.phase == PriorityPhase.finished) {
    return PriorityTransition._(match, const []);
  }
  final draft = _PriorityDraft(match);
  final index = draft.players.indexWhere((p) => p.id == match.priorityPlayerId);
  final player = draft.players[index];
  final charged = elapsed < player.remainingTime!
      ? elapsed
      : player.remainingTime!;
  final spent = player.spentTime.inMicroseconds + charged.inMicroseconds;
  draft.players[index] = player._copy(
    remainingTime: player.remainingTime! - charged,
    spentTime: Duration(
      microseconds: spent < player.spentTime.inMicroseconds
          ? 0x7fffffffffffffff
          : spent,
    ),
  );
  draft.checkPriorityTime();
  return PriorityTransition._(
    draft.build(revision: draft.paused ? match.revision + 1 : match.revision),
    draft.events,
  );
}
