part of 'priority.dart';

/// Pure deterministic state machine: no Flutter, IO, clocks or implicit random
/// draws. A rejected command throws and leaves the original snapshot untouched.
final class PriorityEngine {
  const PriorityEngine();

  PriorityMatch configure(PriorityConfiguration configuration) =>
      PriorityMatch._(
        configuration: configuration,
        players: [
          for (final p in configuration.players)
            PriorityPlayer._(p, p.additionalActions, 0),
        ],
        underlyingPhase: PriorityPhase.configuration,
        isPaused: false,
        activePlayerId: null,
        priorityPlayerId: null,
        pendingResponders: const [],
        turn: 0,
        round: 0,
        revision: 0,
      );

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
      return match.isPaused ? null : PriorityError.invalidPhase;
    }
    if (op == PriorityOperation.finish) {
      return match.underlyingPhase == PriorityPhase.configuration ||
              match.underlyingPhase == PriorityPhase.finished
          ? PriorityError.invalidPhase
          : null;
    }
    if (match.phase != PriorityPhase.activeTurn &&
        match.phase != PriorityPhase.actionResponse &&
        match.phase != PriorityPhase.freeResponse) {
      return PriorityError.invalidPhase;
    }
    if (op == PriorityOperation.pause) return null;
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
        draft.emit(PriorityEventType.turnEnded);
        for (var i = 0; i < draft.players.length; i++) {
          final p = draft.players[i];
          draft.players[i] = PriorityPlayer._(
            p.configuration,
            p.additionalActions,
            0,
          );
        }
        final index = draft.players.indexWhere((p) => p.id == draft.active);
        draft.active = draft.players[(index + 1) % draft.players.length].id;
        draft.turn++;
        draft.round = 1 + (draft.turn - 1) ~/ draft.players.length;
        draft
          ..emit(PriorityEventType.turnStarted)
          ..grantPriority(draft.active!);
      case PriorityOperation.setAdditionalActions:
        final index = draft.players.indexWhere((p) => p.id == command.playerId);
        final p = draft.players[index];
        draft.players[index] = PriorityPlayer._(
          p.configuration,
          command.additionalActions!,
          p.consumedActions,
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
          ..emit(PriorityEventType.paused, playerId: draft.priority);
      case PriorityOperation.resume:
        draft
          ..paused = false
          ..emit(PriorityEventType.resumed, playerId: draft.priority);
      case PriorityOperation.finish:
        draft
          ..emit(PriorityEventType.finished)
          ..phase = PriorityPhase.finished
          ..paused = false
          ..priority = null
          ..pending.clear();
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
      active = original.activePlayerId,
      priority = original.priorityPlayerId,
      pending = original.pendingResponders.toList(),
      turn = original.turn,
      round = original.round;

  final PriorityMatch original;
  final List<PriorityPlayer> players;
  final List<String> pending;
  final events = <PriorityEvent>[];
  PriorityPhase phase;
  bool paused;
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
  }

  void consume(String id) {
    final index = players.indexWhere((p) => p.id == id);
    final p = players[index];
    players[index] = PriorityPlayer._(
      p.configuration,
      p.additionalActions,
      p.consumedActions + 1,
    );
  }

  void openWindow(PriorityPhase responsePhase) {
    phase = responsePhase;
    final index = players.indexWhere((p) => p.id == active);
    pending.addAll([
      for (var offset = 1; offset < players.length; offset++)
        players[(index + offset) % players.length].id,
    ]);
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

  PriorityMatch build() => PriorityMatch._(
    configuration: original.configuration,
    players: players,
    underlyingPhase: phase,
    isPaused: paused,
    activePlayerId: active,
    priorityPlayerId: priority,
    pendingResponders: pending,
    turn: turn,
    round: round,
    revision: original.revision + 1,
  );
}
