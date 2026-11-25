import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/priority/priority.dart';

/// In-memory presentation adapter. All game decisions belong to PriorityEngine.
/// The revision check rejects stale callbacks; the short input latch protects
/// against a double tap even when automatic passes return priority immediately.
class PriorityController extends ValueNotifier<PriorityMatch?> {
  PriorityController({
    this.inputCooldown = const Duration(milliseconds: 350),
    this.elapsedClock,
  }) : super(null) {
    _stopwatch.start();
  }

  final Duration inputCooldown;
  final _engine = const PriorityEngine();
  final _stopwatch = Stopwatch();
  final Duration Function()? elapsedClock;
  Duration? _clockAnchor;
  Timer? _clockTicker;
  bool _foreground = true;
  Duration get _now => elapsedClock?.call() ?? _stopwatch.elapsed;
  final _inputTimers = <(PriorityOperation, String?), Timer>{};
  List<PriorityEvent> _events = const [];
  List<PriorityEvent> get events => _events;

  bool start(PriorityConfiguration configuration) {
    if (value != null) return false;
    final transition = _engine.apply(
      _engine.configure(configuration),
      const PriorityCommand.start(),
    );
    _events = transition.events;
    value = transition.match;
    _clockAnchor = _now;
    if (!_foreground) _pauseClock(PriorityPauseReason.background);
    _refreshTicker();
    return true;
  }

  bool can(PriorityCommand command, {bool includeInputCooldown = true}) {
    final match = value;
    return _foreground &&
        match != null &&
        (!includeInputCooldown ||
            !_inputTimers.containsKey((command.operation, command.playerId))) &&
        _engine.rejection(match, command) == null;
  }

  bool dispatch(PriorityCommand command, {required int expectedRevision}) {
    synchronizeClock();
    final match = value;
    if (match == null || match.revision != expectedRevision || !can(command)) {
      return false;
    }
    final transition = _engine.apply(match, command);
    _events = transition.events;
    // Score steppers intentionally accept every tap, unlike game actions.
    if (inputCooldown > Duration.zero &&
        command.operation != PriorityOperation.adjustVictoryPoints) {
      final key = (command.operation, command.playerId);
      _inputTimers[key] = Timer(inputCooldown, () {
        _inputTimers.remove(key);
        notifyListeners();
      });
    }
    value = transition.match;
    _refreshTicker();
    return true;
  }

  /// Charge real elapsed time once, regardless of how late a UI tick arrives.
  /// Domain clock updates preserve the command revision until time expires.
  void synchronizeClock() {
    final now = _now;
    final anchor = _clockAnchor;
    if (anchor != null && now < anchor) return;
    _clockAnchor = now;
    final match = value;
    if (match == null || anchor == null) return;
    final transition = _engine.advanceTime(match, now - anchor);
    if (transition.events.isNotEmpty) _events = transition.events;
    value = transition.match;
    _refreshTicker();
  }

  void setForeground(bool foreground) {
    final changed = _foreground != foreground;
    if (!foreground) {
      synchronizeClock();
      _pauseClock(PriorityPauseReason.background);
    }
    _foreground = foreground;
    _clockAnchor = _now;
    _refreshTicker();
    if (changed) notifyListeners();
  }

  void pauseForNavigation() {
    synchronizeClock();
    _pauseClock(PriorityPauseReason.background);
  }

  void prepareTimeCorrection() {
    synchronizeClock();
    _pauseClock(PriorityPauseReason.manual);
  }

  void _pauseClock(PriorityPauseReason reason) {
    final match = value;
    if (match == null ||
        !match.configuration.clockEnabled ||
        match.isPaused ||
        match.phase == PriorityPhase.finished) {
      return;
    }
    final transition = _engine.apply(
      match,
      PriorityCommand.pause(reason: reason),
    );
    _events = transition.events;
    value = transition.match;
    _refreshTicker();
  }

  void _refreshTicker() {
    final match = value;
    final running =
        _foreground &&
        match != null &&
        match.configuration.clockEnabled &&
        !match.isPaused &&
        match.phase != PriorityPhase.finished;
    if (!running) {
      _clockTicker?.cancel();
      _clockTicker = null;
    } else {
      _clockTicker ??= Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => synchronizeClock(),
      );
    }
  }

  /// Called only after the user confirms replacing the in-memory game.
  void reset() {
    _cancelInputTimers();
    _events = const [];
    _clockTicker?.cancel();
    _clockTicker = null;
    _clockAnchor = null;
    value = null;
  }

  @override
  void dispose() {
    _cancelInputTimers();
    _clockTicker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _cancelInputTimers() {
    for (final timer in _inputTimers.values) {
      timer.cancel();
    }
    _inputTimers.clear();
  }
}
