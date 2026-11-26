import 'dart:math';

import '../../domain/priority/priority.dart';

enum PriorityLogKind { started, command, automatic, seats, undo, recovered }

final class PriorityLogEntry {
  PriorityLogEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.turn,
    required this.round,
    this.operation,
    this.playerId,
    this.otherPlayerId,
    this.undoOf,
    Iterable<PriorityEvent> events = const [],
  }) : events = List.unmodifiable(events);
  final int id, turn, round;
  final DateTime at;
  final PriorityLogKind kind;
  final PriorityOperation? operation;
  final String? playerId, otherPlayerId;
  final int? undoOf;
  final List<PriorityEvent> events;
  bool get undoable =>
      kind == PriorityLogKind.seats ||
      (kind == PriorityLogKind.command &&
          operation != PriorityOperation.pause &&
          operation != PriorityOperation.resume);
}

final class PriorityCheckpoint {
  PriorityCheckpoint(this.match, Iterable<String> seats, this.entryId)
    : seats = List.unmodifiable(seats);
  final PriorityMatch match;
  final List<String> seats;
  final int entryId;
}

final class PrioritySession {
  PrioritySession({
    required this.id,
    required this.createdAt,
    required this.modifiedAt,
    required this.match,
    required Iterable<String> seats,
    Iterable<PriorityLogEntry> history = const [],
    Iterable<PriorityCheckpoint> undo = const [],
  }) : seats = List.unmodifiable(seats),
       history = List.unmodifiable(history),
       undo = List.unmodifiable(undo);
  const PrioritySession._(
    this.id,
    this.createdAt,
    this.modifiedAt,
    this.match,
    this.seats,
    this.history,
    this.undo,
  );
  final String id;
  final DateTime createdAt, modifiedAt;
  final PriorityMatch match;
  final List<String> seats;
  final List<PriorityLogEntry> history;
  final List<PriorityCheckpoint> undo;
  Set<int> get undoneEntries => {
    for (final e in history)
      if (e.undoOf != null) e.undoOf!,
  };
  int count(String player, PriorityEventType type) {
    final undone = undoneEntries;
    return history
        .where((entry) => !undone.contains(entry.id))
        .expand((entry) => entry.events)
        .where((e) => e.playerId == player && e.type == type)
        .length;
  }

  PrioritySession copyWith({
    PriorityMatch? match,
    List<String>? seats,
    List<PriorityLogEntry>? history,
    List<PriorityCheckpoint>? undo,
    DateTime? modifiedAt,
  }) => PrioritySession._(
    id,
    createdAt,
    modifiedAt ?? this.modifiedAt,
    match ?? this.match,
    seats == null ? this.seats : List.unmodifiable(seats),
    history == null ? this.history : List.unmodifiable(history),
    undo == null ? this.undo : List.unmodifiable(undo),
  );
  PrioritySavedMatch get summary =>
      PrioritySavedMatch(id, createdAt, modifiedAt, match);

  static bool validId(String id) => RegExp(r'^s-[a-f0-9]{32}$').hasMatch(id);
  static String newId() {
    final random = Random.secure();
    return 's-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }
}

final class PrioritySavedMatch {
  const PrioritySavedMatch(
    this.id,
    this.createdAt,
    this.modifiedAt,
    this.match,
  );
  final String id;
  final DateTime createdAt, modifiedAt;
  final PriorityMatch match;
  bool get finished => match.underlyingPhase == PriorityPhase.finished;
}
