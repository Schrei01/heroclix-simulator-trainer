import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/priority/priority.dart';

/// In-memory presentation adapter. All game decisions belong to PriorityEngine.
/// The revision check rejects stale callbacks; the short input latch protects
/// against a double tap even when automatic passes return priority immediately.
class PriorityController extends ValueNotifier<PriorityMatch?> {
  PriorityController({this.inputCooldown = const Duration(milliseconds: 350)})
    : super(null);

  final Duration inputCooldown;
  final _engine = const PriorityEngine();
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
    return true;
  }

  bool can(PriorityCommand command) {
    final match = value;
    return match != null &&
        !_inputTimers.containsKey((command.operation, command.playerId)) &&
        _engine.rejection(match, command) == null;
  }

  bool dispatch(PriorityCommand command, {required int expectedRevision}) {
    final match = value;
    if (match == null || match.revision != expectedRevision || !can(command)) {
      return false;
    }
    final transition = _engine.apply(match, command);
    _events = transition.events;
    if (inputCooldown > Duration.zero) {
      final key = (command.operation, command.playerId);
      _inputTimers[key] = Timer(inputCooldown, () {
        _inputTimers.remove(key);
        notifyListeners();
      });
    }
    value = transition.match;
    return true;
  }

  /// Called only after the user confirms replacing the in-memory game.
  void reset() {
    _cancelInputTimers();
    _events = const [];
    value = null;
  }

  @override
  void dispose() {
    _cancelInputTimers();
    super.dispose();
  }

  void _cancelInputTimers() {
    for (final timer in _inputTimers.values) {
      timer.cancel();
    }
    _inputTimers.clear();
  }
}
