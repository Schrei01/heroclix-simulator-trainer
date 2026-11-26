import 'dart:math';

part 'priority_engine.dart';

/// The list order in [PriorityConfiguration] is the physical anticlockwise
/// seating order. IDs identify players; names need not be unique.
final class PriorityPlayerConfiguration {
  PriorityPlayerConfiguration({
    required String id,
    required String name,
    required this.buildPoints,
    this.additionalActions = 0,
  }) : id = id.trim(),
       name = name.trim() {
    if (this.id.isEmpty || this.name.isEmpty) {
      throw ArgumentError('El identificador y el nombre son obligatorios.');
    }
    if (buildPoints < 0 || additionalActions < 0) {
      throw ArgumentError(
        'Los puntos y las acciones adicionales no son negativos.',
      );
    }
    if (totalActions < baseActions) {
      throw ArgumentError('El total de acciones excede el rango de enteros.');
    }
  }

  final String id, name;
  final int buildPoints, additionalActions;
  int get baseActions => max(1, buildPoints ~/ 100);
  int get totalActions => baseActions + additionalActions;
}

final class PriorityConfiguration {
  factory PriorityConfiguration({
    required Iterable<PriorityPlayerConfiguration> players,
    String? startingPlayerId,
  }) {
    final seats = List<PriorityPlayerConfiguration>.unmodifiable(players);
    if (seats.length < 2 || seats.length > 6) {
      throw ArgumentError('Priority requiere entre 2 y 6 jugadores.');
    }
    if (seats.map((p) => p.id).toSet().length != seats.length) {
      throw ArgumentError('Los identificadores de jugador deben ser únicos.');
    }
    final first = startingPlayerId ?? seats.first.id;
    if (!seats.any((p) => p.id == first)) {
      throw ArgumentError.value(
        first,
        'startingPlayerId',
        'Jugador inexistente.',
      );
    }
    return PriorityConfiguration._(seats, first);
  }

  /// Randomness belongs to setup, never to a game transition. Inject a seeded
  /// Random when a reproducible starting-player draw is needed.
  factory PriorityConfiguration.randomStart({
    required Iterable<PriorityPlayerConfiguration> players,
    required Random random,
  }) {
    final checked = PriorityConfiguration(players: players);
    return PriorityConfiguration(
      players: checked.players,
      startingPlayerId:
          checked.players[random.nextInt(checked.players.length)].id,
    );
  }

  const PriorityConfiguration._(this.players, this.startingPlayerId);
  final List<PriorityPlayerConfiguration> players;
  final String startingPlayerId;
}

enum PriorityPhase {
  configuration,
  activeTurn,
  actionResponse,
  freeResponse,
  paused,
  finished,
}

enum PriorityOperation {
  start,
  action,
  free,
  responseAction,
  responseFree,
  pass,
  endTurn,
  setAdditionalActions,
  pause,
  resume,
  finish,
}

/// Explicit commands keep invalid UI button states from bypassing engine rules.
final class PriorityCommand {
  const PriorityCommand.start() : this._(PriorityOperation.start);
  const PriorityCommand.action(String playerId)
    : this._(PriorityOperation.action, playerId: playerId);
  const PriorityCommand.free(String playerId)
    : this._(PriorityOperation.free, playerId: playerId);
  const PriorityCommand.responseAction(String playerId)
    : this._(PriorityOperation.responseAction, playerId: playerId);
  const PriorityCommand.responseFree(String playerId)
    : this._(PriorityOperation.responseFree, playerId: playerId);
  const PriorityCommand.pass(String playerId)
    : this._(PriorityOperation.pass, playerId: playerId);
  const PriorityCommand.endTurn(String playerId)
    : this._(PriorityOperation.endTurn, playerId: playerId);
  const PriorityCommand.setAdditionalActions(String playerId, int value)
    : this._(
        PriorityOperation.setAdditionalActions,
        playerId: playerId,
        additionalActions: value,
      );
  const PriorityCommand.pause() : this._(PriorityOperation.pause);
  const PriorityCommand.resume() : this._(PriorityOperation.resume);
  const PriorityCommand.finish() : this._(PriorityOperation.finish);

  const PriorityCommand._(
    this.operation, {
    this.playerId,
    this.additionalActions,
  });
  final PriorityOperation operation;
  final String? playerId;
  final int? additionalActions;
}

final class PriorityPlayer {
  const PriorityPlayer._(
    this.configuration,
    this.additionalActions,
    this.consumedActions,
  );
  final PriorityPlayerConfiguration configuration;
  final int additionalActions, consumedActions;
  String get id => configuration.id;
  String get name => configuration.name;
  int get baseActions => configuration.baseActions;
  int get totalActions => baseActions + additionalActions;
  int get availableActions => max(0, totalActions - consumedActions);
}

/// Immutable snapshot. Only the engine can construct a match, so pending
/// responders, phase and priority cannot be edited independently.
final class PriorityMatch {
  PriorityMatch._({
    required this.configuration,
    required Iterable<PriorityPlayer> players,
    required this.underlyingPhase,
    required this.isPaused,
    required this.activePlayerId,
    required this.priorityPlayerId,
    required Iterable<String> pendingResponders,
    required this.turn,
    required this.round,
    required this.revision,
  }) : players = List.unmodifiable(players),
       pendingResponders = List.unmodifiable(pendingResponders);

  final PriorityConfiguration configuration;
  final List<PriorityPlayer> players;
  final PriorityPhase underlyingPhase;
  final bool isPaused;
  final String? activePlayerId, priorityPlayerId;

  /// Includes the current priority holder first, followed by later responders.
  final List<String> pendingResponders;
  final int turn, round, revision;
  PriorityPhase get phase => isPaused ? PriorityPhase.paused : underlyingPhase;
  bool get hasResponseWindow =>
      underlyingPhase == PriorityPhase.actionResponse ||
      underlyingPhase == PriorityPhase.freeResponse;

  PriorityPlayer player(String id) => players.firstWhere(
    (p) => p.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Jugador inexistente.'),
  );
}

enum PriorityEventType {
  started,
  turnStarted,
  turnEnded,
  priorityChanged,
  action,
  free,
  responseAction,
  responseFree,
  voluntaryPass,
  automaticPass,
  additionalActionsChanged,
  paused,
  resumed,
  finished,
}

/// Operation events, without timestamps or a stored history. Future consumers
/// can record them; an automatic pass never grants priority to a skipped player.
final class PriorityEvent {
  const PriorityEvent._(
    this.type,
    this.playerId,
    this.turn,
    this.round, {
    this.previousValue,
    this.value,
  });
  final PriorityEventType type;
  final String playerId;
  final int turn, round;
  final int? previousValue, value;
}

final class PriorityTransition {
  PriorityTransition._(this.match, Iterable<PriorityEvent> events)
    : events = List.unmodifiable(events);
  final PriorityMatch match;
  final List<PriorityEvent> events;
}

enum PriorityError {
  invalidPhase,
  unknownPlayer,
  notPriorityHolder,
  notActivePlayer,
  noActions,
  invalidAdditionalActions,
}

final class PriorityException implements Exception {
  const PriorityException(this.code, this.message);
  final PriorityError code;
  final String message;
  @override
  String toString() => 'PriorityException(${code.name}): $message';
}
