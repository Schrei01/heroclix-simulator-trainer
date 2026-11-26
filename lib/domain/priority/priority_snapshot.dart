part of 'priority.dart';

/// Versioned persistence boundary. No IO, UI or implicit clock is used here.
final class PrioritySnapshotCodec {
  const PrioritySnapshotCodec();

  Map<String, Object?> configuration(PriorityConfiguration c) => {
    'players': [
      for (final p in c.players)
        {
          'id': p.id,
          'name': p.name,
          'points': p.buildPoints,
          'additional': p.additionalActions,
        },
    ],
    'first': c.startingPlayerId,
    'clock': c.clockEnabled,
    'initialMicros': c.initialTime.inMicroseconds,
  };

  PriorityConfiguration readConfiguration(Object? raw) {
    final m = object(raw);
    final players = array(m['players']);
    if (players.length < 2 || players.length > 6) invalid();
    try {
      return PriorityConfiguration(
        players: [
          for (final rawPlayer in players) _configurationPlayer(rawPlayer),
        ],
        startingPlayerId: string(m['first']),
        clockEnabled: boolean(m['clock']),
        initialTime: Duration(
          microseconds: integer(m['initialMicros'], min: 1),
        ),
      );
    } on ArgumentError {
      invalid();
    }
  }

  PriorityPlayerConfiguration _configurationPlayer(Object? raw) {
    final p = object(raw);
    return PriorityPlayerConfiguration(
      id: string(p['id']),
      name: string(p['name']),
      buildPoints: integer(p['points']),
      additionalActions: integer(p['additional']),
    );
  }

  Map<String, Object?> state(PriorityMatch m) => {
    'players': [
      for (final p in m.players)
        {
          'id': p.id,
          'additional': p.additionalActions,
          'consumed': p.consumedActions,
          'pv': p.victoryPoints,
          'eliminated': p.eliminated,
          'remaining': p.remainingTime?.inMicroseconds,
          'spent': p.spentTime.inMicroseconds,
        },
    ],
    'order': m.turnOrder,
    'phase': m.underlyingPhase.name,
    'paused': m.isPaused,
    'pauseReason': m.pauseReason?.name,
    'timedOut': m.timedOutPlayerId,
    'active': m.activePlayerId,
    'priority': m.priorityPlayerId,
    'pending': m.pendingResponders,
    'roundPending': m.roundPending,
    'turn': m.turn,
    'round': m.round,
    'revision': m.revision,
  };

  PriorityMatch readState(Object? raw, PriorityConfiguration c) {
    final m = object(raw), rows = array(object(raw)['players']);
    if (rows.length != c.players.length) invalid();
    final players = <PriorityPlayer>[];
    for (var i = 0; i < rows.length; i++) {
      final p = object(rows[i]), config = c.players[i];
      if (p['id'] != config.id) invalid();
      final additional = integer(p['additional']);
      if (config.baseActions + additional < config.baseActions) invalid();
      if ((p['remaining'] == null) == c.clockEnabled) invalid();
      players.add(
        PriorityPlayer._(
          config,
          additional,
          integer(p['consumed']),
          victoryPoints: integer(p['pv']),
          eliminated: boolean(p['eliminated']),
          remainingTime: c.clockEnabled
              ? Duration(microseconds: integer(p['remaining']))
              : null,
          spentTime: Duration(microseconds: integer(p['spent'])),
        ),
      );
    }
    final phase = enumeration(PriorityPhase.values, m['phase']);
    if (phase == PriorityPhase.paused) invalid();
    final active = nullableString(m['active']),
        priority = nullableString(m['priority']);
    final pending = strings(m['pending']),
        roundPending = strings(m['roundPending']);
    final paused = boolean(m['paused']);
    final reason = m['pauseReason'] == null
        ? null
        : enumeration(PriorityPauseReason.values, m['pauseReason']);
    final timedOut = nullableString(m['timedOut']);
    final turn = integer(m['turn']), round = integer(m['round']);
    final revision = integer(m['revision'], max: 0x1fffffffffffff);
    final ids = players.map((p) => p.id).toSet();
    final order = strings(m['order']);
    bool validIds(List<String> list) =>
        list.toSet().length == list.length && list.every(ids.contains);
    if (order.length != players.length ||
        !validIds(order) ||
        !validIds(pending) ||
        !validIds(roundPending) ||
        (active != null && !ids.contains(active)) ||
        (priority != null && !ids.contains(priority)) ||
        (timedOut != null && !ids.contains(timedOut)) ||
        paused != (reason != null)) {
      invalid();
    }
    if (phase == PriorityPhase.configuration) {
      if (turn != 0 ||
          round != 0 ||
          revision != 0 ||
          active != null ||
          priority != null ||
          pending.isNotEmpty ||
          roundPending.isNotEmpty ||
          paused ||
          timedOut != null ||
          players.any(
            (p) =>
                p.eliminated ||
                p.consumedActions != 0 ||
                p.victoryPoints != 0 ||
                p.additionalActions != p.configuration.additionalActions ||
                p.spentTime != Duration.zero ||
                (c.clockEnabled && p.remainingTime != c.initialTime),
          )) {
        invalid();
      }
    } else {
      if (turn < 1 ||
          round < 1 ||
          round > turn ||
          active == null ||
          players.every((p) => p.eliminated)) {
        invalid();
      }
      if (phase == PriorityPhase.finished) {
        if (priority != null ||
            pending.isNotEmpty ||
            paused ||
            timedOut != null) {
          invalid();
        }
      } else {
        final alive = players
            .where((p) => !p.eliminated)
            .map((p) => p.id)
            .toList();
        if (alive.length < 2 ||
            !alive.contains(active) ||
            !alive.contains(priority) ||
            roundPending.isEmpty ||
            roundPending.first != active ||
            !roundPending.every(alive.contains) ||
            !pending.every(alive.contains)) {
          invalid();
        }
        final start = order.indexOf(priority!);
        final activeIndex = order.indexOf(active);
        final roundOrder = [
          for (var n = 0; n < order.length; n++)
            order[(activeIndex + n) % order.length],
        ].where(roundPending.contains).toList();
        if (!_same(roundPending, roundOrder)) invalid();
        final responderOrder = [
          for (var n = 0; n < order.length; n++)
            order[(start + n) % order.length],
        ].where(pending.contains).toList();
        if (phase == PriorityPhase.activeTurn) {
          if (priority != active || pending.isNotEmpty) invalid();
        } else {
          if (pending.isEmpty ||
              pending.first != priority ||
              pending.contains(active) ||
              !_same(pending, responderOrder)) {
            invalid();
          }
          if (phase == PriorityPhase.actionResponse &&
              players.firstWhere((p) => p.id == priority).availableActions ==
                  0) {
            invalid();
          }
        }
      }
    }
    if (timedOut != null && (!c.clockEnabled || !paused)) invalid();
    if (!c.clockEnabled && players.any((p) => p.spentTime != Duration.zero)) {
      invalid();
    }
    return PriorityMatch._(
      configuration: c,
      players: players,
      underlyingPhase: phase,
      isPaused: paused,
      pauseReason: reason,
      timedOutPlayerId: timedOut,
      activePlayerId: active,
      priorityPlayerId: priority,
      pendingResponders: pending,
      roundPending: roundPending,
      turnOrder: order,
      turn: turn,
      round: round,
      revision: revision,
    );
  }

  /// A restored state cannot restart a chess clock. Revision never goes backwards.
  PriorityMatch restorePaused(
    PriorityMatch snapshot, {
    required int afterRevision,
  }) {
    final draft = _PriorityDraft(snapshot);
    if (snapshot.configuration.clockEnabled &&
        snapshot.phase != PriorityPhase.finished &&
        snapshot.underlyingPhase != PriorityPhase.configuration) {
      draft.paused = true;
      draft.pauseReason ??= PriorityPauseReason.manual;
    }
    final revision = max(snapshot.revision, afterRevision) + 1;
    if (revision > 0x1fffffffffffff) invalid();
    return draft.build(revision: revision);
  }

  Map<String, Object?> event(PriorityEvent e) => {
    'type': e.type.name,
    'player': e.playerId,
    'turn': e.turn,
    'round': e.round,
    'previous': e.previousValue,
    'value': e.value,
  };
  PriorityEvent readEvent(Object? raw, PriorityConfiguration c) {
    final m = object(raw), id = string(object(raw)['player']);
    if (!c.players.any((p) => p.id == id)) invalid();
    final type = enumeration(PriorityEventType.values, m['type']);
    final previous = m['previous'] == null ? null : integer(m['previous']);
    final value = m['value'] == null ? null : integer(m['value']);
    if (type == PriorityEventType.additionalActionsChanged &&
        previous != null &&
        value != null) {
      final base = c.players.firstWhere((p) => p.id == id).baseActions;
      if (base + previous < base || base + value < base) invalid();
    }
    if ([
          PriorityEventType.additionalActionsChanged,
          PriorityEventType.victoryPointsChanged,
          PriorityEventType.timeCorrected,
        ].contains(type) &&
        (previous == null || value == null)) {
      invalid();
    }
    return PriorityEvent._(
      type,
      id,
      integer(m['turn'], min: 1),
      integer(m['round'], min: 1),
      previousValue: previous,
      value: value,
    );
  }

  static bool _same(List<String> a, List<String> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);
  static Never invalid() =>
      throw const FormatException('Estado de Priority inválido.');
  static Map<String, dynamic> object(Object? raw) {
    if (raw is! Map<String, dynamic>) invalid();
    return raw;
  }

  static List<dynamic> array(Object? raw) {
    if (raw is! List || raw.length > 100000) invalid();
    return raw;
  }

  static int integer(Object? raw, {int min = 0, int max = 0x7fffffffffffffff}) {
    if (raw is! int || raw < min || raw > max) invalid();
    return raw;
  }

  static String string(Object? raw) {
    if (raw is! String || raw.isEmpty) invalid();
    return raw;
  }

  static String? nullableString(Object? raw) =>
      raw == null ? null : string(raw);
  static bool boolean(Object? raw) {
    if (raw is! bool) invalid();
    return raw;
  }

  static List<String> strings(Object? raw) =>
      List.unmodifiable(array(raw).map(string));
  static T enumeration<T extends Enum>(List<T> values, Object? raw) =>
      values.where((e) => e.name == raw).firstOrNull ?? (invalid());
}
