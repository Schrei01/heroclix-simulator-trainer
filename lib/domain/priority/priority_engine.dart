part of 'priority.dart';

/// Pure deterministic state machine: no Flutter, IO or implicit time/random
/// sources. A rejected command leaves the original snapshot untouched.
final class PriorityEngine {
  const PriorityEngine();

  PriorityMatch configure(PriorityConfiguration configuration) =>
      PriorityMatch._(
        configuration: configuration,
        players: [
          for (final p in configuration.players)
            PriorityPlayer._(
              p,
              p.additionalActions,
              0,
              remainingTime: configuration.clockEnabled
                  ? configuration.initialTime
                  : null,
            ),
        ],
        underlyingPhase: PriorityPhase.configuration,
        isPaused: false,
        activePlayerId: null,
        priorityPlayerId: null,
        pendingResponders: const [],
        turn: 0,
        round: 0,
        revision: 0,
        roundPending: const [],
        turnOrder: configuration.players.map((p) => p.id),
      );

  /// Move seats without replacing the active player or interrupting their responder.
  /// Already completed responses stay completed; the remaining queue follows the
  /// new clockwise order starting at its current priority holder.
  PriorityTransition reseat(PriorityMatch match, Iterable<String> seats) {
    final order = seats.toList();
    if (order.length != match.players.length ||
        order.toSet().length != order.length ||
        !order.every((id) => match.players.any((p) => p.id == id))) {
      throw ArgumentError(
        'Los asientos deben contener a cada jugador una sola vez.',
      );
    }
    if (match.underlyingPhase == PriorityPhase.configuration) {
      throw const PriorityException(
        PriorityError.invalidPhase,
        'Configura los asientos antes de empezar.',
      );
    }
    if (Iterable<int>.generate(order.length)
        .every((i) => order[i] == match.turnOrder[i])) {
      return PriorityTransition._(match, const []);
    }
    final draft = _PriorityDraft(match);
    draft.order
      ..clear()
      ..addAll(order);
    if (draft.pending.isNotEmpty) {
      final remaining = draft.pending.toSet();
      final reordered = draft
          .seatingFrom(draft.priority!)
          .where(remaining.contains)
          .toList();
      draft.pending
        ..clear()
        ..addAll(reordered);
    }
    if (match.phase != PriorityPhase.finished) {
      draft.alignRound();
    }
    return PriorityTransition._(draft.build(), const []);
  }

  /// Explicit elapsed duration from an external monotonic source. Regular clock
  /// updates do not change the command revision or create per-tick events.
  PriorityTransition advanceTime(PriorityMatch match, Duration elapsed) =>
      _advancePriorityClock(match, elapsed);

  /// Allows a future UI to use the same validation as [apply].
  PriorityError? rejection(PriorityMatch match, PriorityCommand command) {
    final op = command.operation;
    if (command.playerId != null &&
        !match.players.any((p) => p.id == command.playerId)) {
      return PriorityError.unknownPlayer;
    }
    if (op == PriorityOperation.start) {
      return match.phase == PriorityPhase.configuration
          ? null
          : PriorityError.invalidPhase;
    }
    if (op == PriorityOperation.resume) {
      if (!match.isPaused) return PriorityError.invalidPhase;
      return match.configuration.clockEnabled &&
              match.player(match.priorityPlayerId!).remainingTime ==
                  Duration.zero
          ? PriorityError.timeExhausted
          : null;
    }
    if (op == PriorityOperation.finish) {
      return match.underlyingPhase == PriorityPhase.configuration ||
              match.underlyingPhase == PriorityPhase.finished
          ? PriorityError.invalidPhase
          : null;
    }
    if (op == PriorityOperation.adjustVictoryPoints ||
        op == PriorityOperation.setVictoryPoints ||
        op == PriorityOperation.eliminate ||
        op == PriorityOperation.setRemainingTime) {
      if (match.underlyingPhase == PriorityPhase.configuration) {
        return PriorityError.invalidPhase;
      }
      final player = match.player(command.playerId!);
      if (op == PriorityOperation.adjustVictoryPoints ||
          op == PriorityOperation.setVictoryPoints) {
        final number = command.points!;
        final result = op == PriorityOperation.setVictoryPoints
            ? number
            : player.victoryPoints + number;
        return result < 0 ||
                (op == PriorityOperation.adjustVictoryPoints &&
                    number > 0 &&
                    result < player.victoryPoints)
            ? PriorityError.invalidPoints
            : null;
      }
      if (match.underlyingPhase == PriorityPhase.finished) {
        return PriorityError.invalidPhase;
      }
      if (player.eliminated) return PriorityError.eliminatedPlayer;
      if (op == PriorityOperation.setRemainingTime) {
        return !match.configuration.clockEnabled ||
                command.remainingTime! < Duration.zero
            ? PriorityError.invalidTime
            : null;
      }
      return null;
    }
    if (match.phase != PriorityPhase.activeTurn &&
        match.phase != PriorityPhase.actionResponse &&
        match.phase != PriorityPhase.freeResponse) {
      return PriorityError.invalidPhase;
    }
    if (op == PriorityOperation.pause) {
      return command.pauseReason == PriorityPauseReason.timeExpired
          ? PriorityError.invalidPhase
          : null;
    }
    if (command.playerId != null &&
        match.player(command.playerId!).eliminated) {
      return PriorityError.eliminatedPlayer;
    }
    if (op == PriorityOperation.setAdditionalActions) {
      final base = match.player(command.playerId!).baseActions;
      final additional = command.additionalActions!;
      return additional < 0 || base + additional < base
          ? PriorityError.invalidAdditionalActions
          : null;
    }
    final requiredPhase = switch (op) {
      PriorityOperation.action ||
      PriorityOperation.free ||
      PriorityOperation.endTurn => PriorityPhase.activeTurn,
      PriorityOperation.responseAction => PriorityPhase.actionResponse,
      PriorityOperation.responseFree => PriorityPhase.freeResponse,
      _ => null,
    };
    if ((requiredPhase != null && match.phase != requiredPhase) ||
        (op == PriorityOperation.pass && !match.hasResponseWindow)) {
      return PriorityError.invalidPhase;
    }
    if (command.playerId != match.priorityPlayerId) {
      return PriorityError.notPriorityHolder;
    }
    if (requiredPhase == PriorityPhase.activeTurn &&
        command.playerId != match.activePlayerId) {
      return PriorityError.notActivePlayer;
    }
    if ((op == PriorityOperation.action ||
            op == PriorityOperation.responseAction) &&
        match.player(command.playerId!).availableActions == 0) {
      return PriorityError.noActions;
    }
    return null;
  }

  PriorityTransition apply(PriorityMatch match, PriorityCommand command) {
    final error = rejection(match, command);
    if (error != null) {
      throw PriorityException(error, switch (error) {
        PriorityError.invalidPhase =>
          'La fase actual no permite esta operación.',
        PriorityError.unknownPlayer => 'El jugador no pertenece a la partida.',
        PriorityError.notPriorityHolder => 'El jugador no tiene la prioridad.',
        PriorityError.notActivePlayer =>
          'La operación requiere al jugador activo.',
        PriorityError.noActions => 'El jugador no tiene acciones disponibles.',
        PriorityError.invalidAdditionalActions => 'Las acciones adicionales deben ser no negativas y su total no debe desbordarse.',
        PriorityError.eliminatedPlayer => 'El jugador está eliminado.',
        PriorityError.invalidPoints =>
          'La puntuación debe ser no negativa y no debe desbordarse.',
        PriorityError.invalidTime => 'El cronómetro debe estar habilitado y el tiempo no puede ser negativo.',
        PriorityError.timeExhausted =>
          'Corrige el tiempo agotado o elimina al jugador antes de reanudar.',
      });
    }
    final draft = _PriorityDraft(match);
    switch (command.operation) {
      case PriorityOperation.start:
        draft
          ..phase = PriorityPhase.activeTurn
          ..active = match.configuration.startingPlayerId
          ..turn = 1
          ..round = 1
          ..roundPending.addAll(draft.seatingFrom(draft.active!))
          ..emit(PriorityEventType.started)
          ..emit(PriorityEventType.turnStarted)
          ..grantPriority(draft.active!);
      case PriorityOperation.action:
        draft
          ..consume(command.playerId!)
          ..emit(PriorityEventType.action, playerId: command.playerId)
          ..openWindow(PriorityPhase.actionResponse);
      case PriorityOperation.free:
        draft
          ..emit(PriorityEventType.free, playerId: command.playerId)
          ..openWindow(PriorityPhase.freeResponse);
      case PriorityOperation.responseAction:
        draft
          ..consume(command.playerId!)
          ..emit(PriorityEventType.responseAction, playerId: command.playerId)
          ..pending.removeAt(0)
          ..advanceResponse();
      case PriorityOperation.responseFree:
        draft
          ..emit(PriorityEventType.responseFree, playerId: command.playerId)
          ..pending.removeAt(0)
          ..advanceResponse();
      case PriorityOperation.pass:
        draft
          ..emit(PriorityEventType.voluntaryPass, playerId: command.playerId)
          ..pending.removeAt(0)
          ..advanceResponse();
      case PriorityOperation.endTurn:
        draft.endTurn();
      case PriorityOperation.setAdditionalActions:
        final index = draft.players.indexWhere((p) => p.id == command.playerId);
        final p = draft.players[index];
        draft.players[index] = p._copy(
          additionalActions: command.additionalActions!,
        );
        draft.emit(
          PriorityEventType.additionalActionsChanged,
          playerId: p.id,
          previousValue: p.additionalActions,
          value: command.additionalActions,
        );
        if (draft.phase == PriorityPhase.actionResponse) {
          draft.advanceResponse();
        }
      case PriorityOperation.pause:
        draft
          ..paused = true
          ..pauseReason = command.pauseReason
          ..emit(PriorityEventType.paused, playerId: draft.priority);
      case PriorityOperation.resume:
        draft
          ..paused = false
          ..pauseReason = null
          ..timedOut = null
          ..emit(PriorityEventType.resumed, playerId: draft.priority);
      case PriorityOperation.finish:
        draft.finish();
      case PriorityOperation.adjustVictoryPoints:
      case PriorityOperation.setVictoryPoints:
        final index = draft.players.indexWhere((p) => p.id == command.playerId);
        final player = draft.players[index];
        final points = command.operation == PriorityOperation.setVictoryPoints
            ? command.points!
            : player.victoryPoints + command.points!;
        draft.players[index] = player._copy(victoryPoints: points);
        draft.emit(
          PriorityEventType.victoryPointsChanged,
          playerId: player.id,
          previousValue: player.victoryPoints,
          value: points,
        );
      case PriorityOperation.setRemainingTime:
        final index = draft.players.indexWhere((p) => p.id == command.playerId);
        final player = draft.players[index];
        draft.players[index] = player._copy(
          remainingTime: command.remainingTime,
        );
        draft.emit(
          PriorityEventType.timeCorrected,
          playerId: player.id,
          previousValue: player.remainingTime!.inMicroseconds,
          value: command.remainingTime!.inMicroseconds,
        );
        draft
          ..paused = true
          ..pauseReason = PriorityPauseReason.manual;
        if (command.remainingTime == Duration.zero &&
            player.id == draft.priority) {
          draft.timedOut = player.id;
          draft.pauseReason = PriorityPauseReason.timeExpired;
          if (player.remainingTime != Duration.zero) {
            draft.emit(PriorityEventType.timeExpired, playerId: player.id);
          }
        }
        draft.emit(PriorityEventType.paused, playerId: draft.priority);
      case PriorityOperation.eliminate:
        draft.eliminate(command.playerId!);
    }
    return PriorityTransition._(draft.build(), draft.events);
  }
}

/// Mutable only during one validated synchronous operation; never published.
final class _PriorityDraft {
  _PriorityDraft(this.original)
    : players = original.players.toList(),
      phase = original.underlyingPhase,
      paused = original.isPaused,
      pauseReason = original.pauseReason,
      timedOut = original.timedOutPlayerId,
      active = original.activePlayerId,
      priority = original.priorityPlayerId,
      pending = original.pendingResponders.toList(),
      roundPending = original.roundPending.toList(),
      order = original.turnOrder.toList(),
      turn = original.turn,
      round = original.round;

  final PriorityMatch original;
  final List<PriorityPlayer> players;
  final List<String> pending;
  final List<String> roundPending;
  final List<String> order;
  final events = <PriorityEvent>[];
  PriorityPhase phase;
  bool paused;
  PriorityPauseReason? pauseReason;
  String? timedOut;
  String? active, priority;
  int turn, round;

  void emit(
    PriorityEventType type, {
    String? playerId,
    int? previousValue,
    int? value,
  }) => events.add(
    PriorityEvent._(
      type,
      playerId ?? active!,
      turn,
      round,
      previousValue: previousValue,
      value: value,
    ),
  );

  void grantPriority(String id) {
    if (priority == id) return;
    priority = id;
    emit(PriorityEventType.priorityChanged, playerId: id);
    checkPriorityTime();
  }

  void consume(String id) {
    final index = players.indexWhere((p) => p.id == id);
    final p = players[index];
    players[index] = p._copy(consumedActions: p.consumedActions + 1);
  }

  void openWindow(PriorityPhase responsePhase) {
    phase = responsePhase;
    pending.addAll([...seatingFrom(active!).skip(1)]);
    advanceResponse();
  }

  void advanceResponse() {
    // Skip only when their opportunity arrives, so a future responder can
    // recover additional actions before receiving priority.
    while (phase == PriorityPhase.actionResponse &&
        pending.isNotEmpty &&
        players.firstWhere((p) => p.id == pending.first).availableActions ==
            0) {
      emit(PriorityEventType.automaticPass, playerId: pending.removeAt(0));
    }
    if (pending.isEmpty) {
      phase = PriorityPhase.activeTurn;
      grantPriority(active!);
    } else {
      grantPriority(pending.first);
    }
  }

  Iterable<String> seatingFrom(String first) sync* {
    final index = order.indexOf(first);
    for (var offset = 0; offset < order.length; offset++) {
      final p = players.firstWhere(
        (p) => p.id == order[(index + offset) % order.length],
      );
      if (!p.eliminated) yield p.id;
    }
  }

  void alignRound() {
    final remaining = roundPending.toSet()..add(active!);
    final sorted = seatingFrom(active!).where(remaining.contains).toList();
    roundPending
      ..clear()
      ..addAll(sorted);
  }

  void endTurn() {
    emit(PriorityEventType.turnEnded);
    final previous = active!;
    pending.clear();
    phase = PriorityPhase.activeTurn;
    roundPending.remove(previous);
    for (var i = 0; i < players.length; i++) {
      if (!players[i].eliminated) {
        players[i] = players[i]._copy(consumedActions: 0);
      }
    }
    // If the previous active was just eliminated, seatingFrom omits it already.
    active = seatingFrom(previous).firstWhere((id) => id != previous);
    turn++;
    if (roundPending.isEmpty) {
      round++;
      roundPending.addAll(seatingFrom(active!));
    } else {
      // Reseating may put a player who already acted before a still-due player.
      // Keep the physical next seat and remember everyone still due this round.
      alignRound();
    }
    emit(PriorityEventType.turnStarted);
    grantPriority(active!);
  }

  void eliminate(String id) {
    final index = players.indexWhere((p) => p.id == id);
    players[index] = players[index]._copy(eliminated: true);
    if (timedOut == id) timedOut = null;
    pending.remove(id);
    roundPending.remove(id);
    emit(PriorityEventType.eliminated, playerId: id);
    if (players.where((p) => !p.eliminated).length == 1) {
      finish();
    } else if (id == active) {
      endTurn();
    } else if (phase == PriorityPhase.actionResponse ||
        phase == PriorityPhase.freeResponse) {
      advanceResponse();
    }
  }

  void finish() {
    emit(PriorityEventType.finished);
    phase = PriorityPhase.finished;
    paused = false;
    pauseReason = null;
    timedOut = null;
    priority = null;
    pending.clear();
  }

  void checkPriorityTime() {
    if (!original.configuration.clockEnabled || paused || priority == null) {
      return;
    }
    if (players.firstWhere((p) => p.id == priority).remainingTime ==
        Duration.zero) {
      paused = true;
      pauseReason = PriorityPauseReason.timeExpired;
      timedOut = priority;
      emit(PriorityEventType.timeExpired, playerId: priority);
      emit(PriorityEventType.paused, playerId: priority);
    }
  }

  PriorityMatch build({int? revision}) => PriorityMatch._(
    configuration: original.configuration,
    players: players,
    underlyingPhase: phase,
    isPaused: paused,
    pauseReason: pauseReason,
    timedOutPlayerId: timedOut,
    activePlayerId: active,
    priorityPlayerId: priority,
    pendingResponders: pending,
    roundPending: roundPending,
    turnOrder: order,
    turn: turn,
    round: round,
    revision: revision ?? original.revision + 1,
  );
}
