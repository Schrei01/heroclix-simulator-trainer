import 'dart:math';

part 'priority_engine.dart';
part 'priority_clock.dart';
part 'priority_snapshot.dart';

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
    bool clockEnabled = false,
    Duration initialTime = const Duration(minutes: 30),
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
    if (initialTime <= Duration.zero) {
      throw ArgumentError('El tiempo inicial debe ser mayor que cero.');
    }
    return PriorityConfiguration._(seats, first, clockEnabled, initialTime);
  }

  /// Randomness belongs to setup, never to a game transition. Inject a seeded
  /// Random when a reproducible starting-player draw is needed.
  factory PriorityConfiguration.randomStart({
    required Iterable<PriorityPlayerConfiguration> players,
    required Random random,
    bool clockEnabled = false,
    Duration initialTime = const Duration(minutes: 30),
  }) {
    final checked = PriorityConfiguration(
      players: players,
      clockEnabled: clockEnabled,
      initialTime: initialTime,
    );
    return PriorityConfiguration(
      players: checked.players,
      startingPlayerId:
          checked.players[random.nextInt(checked.players.length)].id,
      clockEnabled: clockEnabled,
      initialTime: initialTime,
    );
  }

  const PriorityConfiguration._(
    this.players,
    this.startingPlayerId,
    this.clockEnabled,
    this.initialTime,
  );
  final List<PriorityPlayerConfiguration> players;
  final String startingPlayerId;
  final bool clockEnabled;
  final Duration initialTime;
}

enum PriorityPauseReason { manual, background, timeExpired }

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
  adjustVictoryPoints,
  setVictoryPoints,
  setRemainingTime,
  eliminate,
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
  const PriorityCommand.pause({
    PriorityPauseReason reason = PriorityPauseReason.manual,
  }) : this._(PriorityOperation.pause, pauseReason: reason);
  const PriorityCommand.resume() : this._(PriorityOperation.resume);
  const PriorityCommand.finish() : this._(PriorityOperation.finish);
  const PriorityCommand.adjustVictoryPoints(String playerId, int delta)
    : this._(
        PriorityOperation.adjustVictoryPoints,
        playerId: playerId,
        points: delta,
      );
  const PriorityCommand.setVictoryPoints(String playerId, int points)
    : this._(
        PriorityOperation.setVictoryPoints,
        playerId: playerId,
        points: points,
      );
  const PriorityCommand.setRemainingTime(String playerId, Duration time)
    : this._(
        PriorityOperation.setRemainingTime,
        playerId: playerId,
        remainingTime: time,
      );
  const PriorityCommand.eliminate(String playerId)
    : this._(PriorityOperation.eliminate, playerId: playerId);

  const PriorityCommand._(
    this.operation, {
    this.playerId,
    this.additionalActions,
    this.points,
    this.remainingTime,
    this.pauseReason,
  });
  final PriorityOperation operation;
  final String? playerId;
  final int? additionalActions;
  final int? points;
  final Duration? remainingTime;
  final PriorityPauseReason? pauseReason;
}

final class PriorityPlayer {
  const PriorityPlayer._(
    this.configuration,
    this.additionalActions,
    this.consumedActions, {
    this.victoryPoints = 0,
    this.eliminated = false,
    this.remainingTime,
    this.spentTime = Duration.zero,
  });
  final PriorityPlayerConfiguration configuration;
  final int additionalActions, consumedActions;
  final int victoryPoints;
  final bool eliminated;
  final Duration? remainingTime;
  final Duration spentTime;
  String get id => configuration.id;
  String get name => configuration.name;
  int get baseActions => configuration.baseActions;
  int get totalActions => baseActions + additionalActions;
  int get availableActions =>
      eliminated ? 0 : max(0, totalActions - consumedActions);

  PriorityPlayer _copy({
    int? additionalActions,
    int? consumedActions,
    int? victoryPoints,
    bool? eliminated,
    Duration? remainingTime,
    Duration? spentTime,
  }) => PriorityPlayer._(
    configuration,
    additionalActions ?? this.additionalActions,
    consumedActions ?? this.consumedActions,
    victoryPoints: victoryPoints ?? this.victoryPoints,
    eliminated: eliminated ?? this.eliminated,
    remainingTime: remainingTime ?? this.remainingTime,
    spentTime: spentTime ?? this.spentTime,
  );
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
    required Iterable<String> roundPending,
    this.pauseReason,
    this.timedOutPlayerId,
  }) : players = List.unmodifiable(players),
       pendingResponders = List.unmodifiable(pendingResponders),
       roundPending = List.unmodifiable(roundPending);

  final PriorityConfiguration configuration;
  final List<PriorityPlayer> players;
  final PriorityPhase underlyingPhase;
  final bool isPaused;
  final PriorityPauseReason? pauseReason;
  final String? timedOutPlayerId;
  final String? activePlayerId, priorityPlayerId;

  /// Includes the current priority holder first, followed by later responders.
  final List<String> pendingResponders;

  /// Players still due a turn this round; active first while the game is live.
  final List<String> roundPending;
  final int turn, round, revision;
  PriorityPhase get phase => isPaused ? PriorityPhase.paused : underlyingPhase;
  bool get hasResponseWindow =>
      underlyingPhase == PriorityPhase.actionResponse ||
      underlyingPhase == PriorityPhase.freeResponse;

  PriorityPlayer player(String id) => players.firstWhere(
    (p) => p.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Jugador inexistente.'),
  );

  List<PriorityStanding> get standings {
    final sorted = players.toList()
      ..sort((a, b) {
        final points = b.victoryPoints.compareTo(a.victoryPoints);
        return points != 0
            ? points
            : players.indexOf(a).compareTo(players.indexOf(b));
      });
    var position = 1;
    return List.unmodifiable([
      for (var i = 0; i < sorted.length; i++)
        PriorityStanding._(
          i > 0 && sorted[i].victoryPoints == sorted[i - 1].victoryPoints
              ? position
              : position = i + 1,
          sorted[i],
        ),
    ]);
  }
}

final class PriorityStanding {
  const PriorityStanding._(this.position, this.player);
  final int position;
  final PriorityPlayer player;
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
  victoryPointsChanged,
  timeCorrected,
  timeExpired,
  eliminated,
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
  eliminatedPlayer,
  invalidPoints,
  invalidTime,
  timeExhausted,
}

final class PriorityException implements Exception {
  const PriorityException(this.code, this.message);
  final PriorityError code;
  final String message;
  @override
  String toString() => 'PriorityException(${code.name}): $message';
}
