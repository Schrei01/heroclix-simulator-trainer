import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../application/priority/priority_repository.dart';
import '../../application/priority/priority_session.dart';
import '../../domain/priority/priority.dart';

/// UI adapter: game decisions stay in the engine; journals and saves wrap an
/// entire accepted operation, including its automatic consequences.
class PriorityController extends ValueNotifier<PriorityMatch?> {
  PriorityController({
    this.inputCooldown = const Duration(milliseconds: 350),
    this.elapsedClock,
    this.repository,
    DateTime Function()? wallClock,
  }) : wallClock = wallClock ?? DateTime.now,
       _ready = repository == null,
       super(null) {
    _stopwatch.start();
  }
  final Duration inputCooldown;
  final Duration Function()? elapsedClock;
  final DateTime Function() wallClock;
  final PriorityRepository? repository;
  final _engine = const PriorityEngine();
  final _snapshot = const PrioritySnapshotCodec();
  final _stopwatch = Stopwatch();
  final _inputTimers = <(PriorityOperation, String?), Timer>{};
  Duration? _clockAnchor;
  Timer? _clockTicker, _saveTimer;
  bool _foreground = true,
      _ready,
      _busy = false,
      _disposed = false,
      _dirty = false;
  Future<void>? _initializing, _writer;
  PrioritySession? _session, _pendingSave;
  List<PriorityEvent> _events = const [];
  List<String> _visualSeatOrder = const [];
  List<PrioritySavedMatch> _library = const [];
  final _memoryArchive = <String, PrioritySession>{};
  String? _storageError, _libraryError, _notice;

  PrioritySession? get session => _session;
  List<PriorityEvent> get events => _events;
  List<String> get visualSeatOrder => _visualSeatOrder;
  bool get ready => _ready;
  bool get busy => _busy;
  bool get saving => _writer != null || (_saveTimer?.isActive ?? false);
  bool get dirty => _dirty;
  String? get storageError => _storageError;
  String? get libraryError => _libraryError;
  bool get canUndo =>
      _ready &&
      !_busy &&
      _foreground &&
      !_disposed &&
      (_session?.undo.isNotEmpty ?? false);
  String? takeNotice() {
    final message = _notice;
    _notice = null;
    return message;
  }

  Duration get _now => elapsedClock?.call() ?? _stopwatch.elapsed;
  DateTime _at() {
    final now = wallClock().toUtc(), previous = _session?.modifiedAt;
    return previous != null && now.isBefore(previous) ? previous : now;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() {
    if (_ready || _disposed) return Future.value();
    return _initializing ??= _load();
  }

  Future<void> _load() async {
    try {
      final saved = await repository!.load();
      if (_disposed) return;
      _ready = true;
      _storageError = null;
      if (saved != null) {
        _adopt(_recovered(saved));
        _notice = _recoveryMessage(saved, backup: repository!.recoveredBackup);
        _scheduleSave();
      }
      await refreshLibrary();
    } catch (_) {
      if (!_disposed) {
        _ready = false;
        _storageError = 'No se pudo abrir Priority. Las partidas guardadas se conservan. Reintenta la lectura.';
      }
    } finally {
      _initializing = null;
      _notify();
    }
  }

  PrioritySession _recovered(PrioritySession saved) {
    final restored = _snapshot.restorePaused(
      saved.match,
      afterRevision: saved.match.revision,
    );
    var at = wallClock().toUtc();
    if (at.isBefore(saved.modifiedAt)) at = saved.modifiedAt;
    final entry = PriorityLogEntry(
      id: saved.history.length + 1,
      at: at,
      kind: PriorityLogKind.recovered,
      turn: restored.turn,
      round: restored.round,
      playerId: restored.priorityPlayerId ?? restored.activePlayerId,
    );
    return saved.copyWith(
      match: restored,
      modifiedAt: at,
      history: [...saved.history, entry],
    );
  }

  String _recoveryMessage(PrioritySession saved, {bool backup = false}) {
    final base = backup
        ? 'Se recuperó una copia anterior válida. Revisa la partida.'
        : 'Partida recuperada.';
    return saved.match.configuration.clockEnabled &&
            saved.match.phase != PriorityPhase.finished
        ? '$base Reanuda el reloj manualmente.'
        : base;
  }

  void _adopt(PrioritySession next) {
    _cancelInputTimers();
    _session = next;
    _visualSeatOrder = next.seats;
    _events = const [];
    _clockAnchor = _now;
    value = next.match;
    _refreshTicker();
  }

  bool start(PriorityConfiguration configuration) {
    if (!_ready || _busy || _disposed || value != null) {
      return false;
    }
    final transition = _engine.apply(
      _engine.configure(configuration),
      const PriorityCommand.start(),
    );
    _events = transition.events;
    _visualSeatOrder = List.unmodifiable(
      transition.match.players.map((p) => p.id),
    );
    final now = _at();
    var id = PrioritySession.newId();
    while (_memoryArchive.containsKey(id) ||
        _library.any((s) => s.id == id) ||
        id == PriorityRepository.backupId) {
      id = PrioritySession.newId();
    }
    _session = PrioritySession(
      id: id,
      createdAt: now,
      modifiedAt: now,
      match: transition.match,
      seats: _visualSeatOrder,
    );
    _append(
      transition.match,
      PriorityLogKind.started,
      events: transition.events,
      operation: PriorityOperation.start,
    );
    value = transition.match;
    _clockAnchor = _now;
    if (!_foreground) _pauseClock(PriorityPauseReason.background);
    _refreshTicker();
    return true;
  }

  bool can(PriorityCommand command, {bool includeInputCooldown = true}) =>
      !_disposed &&
      _ready &&
      !_busy &&
      _foreground &&
      value != null &&
      (!includeInputCooldown ||
          !_inputTimers.containsKey((command.operation, command.playerId))) &&
      _engine.rejection(value!, command) == null;

  bool dispatch(PriorityCommand command, {required int expectedRevision}) {
    synchronizeClock();
    final match = value;
    if (match == null || match.revision != expectedRevision || !can(command)) {
      return false;
    }
    final transition = _engine.apply(match, command);
    _events = transition.events;
    final undoable =
        command.operation != PriorityOperation.pause &&
        command.operation != PriorityOperation.resume;
    _append(
      transition.match,
      PriorityLogKind.command,
      before: undoable ? match : null,
      operation: command.operation,
      player: command.playerId,
      events: transition.events,
    );
    if (inputCooldown > Duration.zero &&
        command.operation != PriorityOperation.adjustVictoryPoints) {
      final key = (command.operation, command.playerId);
      _inputTimers[key] = Timer(inputCooldown, () {
        _inputTimers.remove(key);
        _notify();
      });
    }
    value = transition.match;
    _refreshTicker();
    return true;
  }

  void _append(
    PriorityMatch match,
    PriorityLogKind kind, {
    PriorityMatch? before,
    List<String>? seatsBefore,
    PriorityOperation? operation,
    String? player,
    String? other,
    int? undoOf,
    List<PriorityEvent> events = const [],
  }) {
    final old = _session!;
    final at = _at();
    final entry = PriorityLogEntry(
      id: old.history.length + 1,
      at: at,
      kind: kind,
      turn: match.turn,
      round: match.round,
      playerId: player ?? match.priorityPlayerId ?? match.activePlayerId,
      otherPlayerId: other,
      operation: operation,
      undoOf: undoOf,
      events: events,
    );
    _session = old.copyWith(
      match: match,
      modifiedAt: at,
      seats: _visualSeatOrder,
      history: [...old.history, entry],
      undo: before == null
          ? null
          : [
              ...old.undo,
              PriorityCheckpoint(before, seatsBefore ?? old.seats, entry.id),
            ],
    );
    _scheduleSave();
  }

  bool undo() {
    if (!canUndo) return false;
    synchronizeClock();
    final old = _session!, checkpoint = _session!.undo.last;
    final match = _snapshot.restorePaused(
      checkpoint.match,
      afterRevision: value!.revision,
    );
    _cancelInputTimers();
    _visualSeatOrder = checkpoint.seats;
    _session = old.copyWith(undo: old.undo.sublist(0, old.undo.length - 1));
    _append(match, PriorityLogKind.undo, undoOf: checkpoint.entryId);
    _events = const [];
    _clockAnchor = _now;
    value = match;
    _refreshTicker();
    return true;
  }

  bool swapVisualSeats(
    String source,
    String destination, {
    required PriorityConfiguration configuration,
  }) {
    if (!_ready ||
        _busy ||
        _disposed ||
        !_foreground ||
        !identical(value?.configuration, configuration)) {
      return false;
    }
    final from = _visualSeatOrder.indexOf(source),
        to = _visualSeatOrder.indexOf(destination);
    if (from < 0 || to < 0 || from == to) return false;
    synchronizeClock();
    final before = _visualSeatOrder;
    final seats = before.toList();
    seats[from] = destination;
    seats[to] = source;
    _visualSeatOrder = List.unmodifiable(seats);
    _append(
      value!,
      PriorityLogKind.seats,
      before: value,
      seatsBefore: before,
      player: source,
      other: destination,
    );
    _notify();
    return true;
  }

  void synchronizeClock() {
    if (_disposed) return;
    final now = _now, anchor = _clockAnchor;
    if (anchor != null && now < anchor) return;
    _clockAnchor = now;
    final match = value;
    if (match == null || anchor == null) return;
    final transition = _engine.advanceTime(match, now - anchor);
    if (!identical(transition.match, match)) {
      if (transition.events.isNotEmpty) {
        _events = transition.events;
        _append(
          transition.match,
          PriorityLogKind.automatic,
          events: transition.events,
        );
      } else {
        _session = _session!.copyWith(
          match: transition.match,
          modifiedAt: _at(),
        );
        _scheduleSave(immediate: false);
      }
      value = transition.match;
    }
    _refreshTicker();
  }

  void setForeground(bool foreground) {
    if (_disposed) return;
    final changed = _foreground != foreground;
    if (!foreground) {
      synchronizeClock();
      _pauseClock(PriorityPauseReason.background);
    }
    _foreground = foreground;
    _clockAnchor = _now;
    _refreshTicker();
    if (changed) _notify();
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
    _append(
      transition.match,
      PriorityLogKind.automatic,
      events: transition.events,
    );
    value = transition.match;
    _refreshTicker();
  }

  void _refreshTicker() {
    final match = value;
    final running =
        !_disposed &&
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

  void _scheduleSave({bool immediate = true}) {
    if (repository == null) {
      if (_session?.match.phase == PriorityPhase.finished) {
        _memoryArchive[_session!.id] = _session!;
      }
      return;
    }
    _dirty = true;
    if (immediate) {
      _saveTimer?.cancel();
      _saveTimer = null;
      _pendingSave = _session;
      _kickWriter();
    } else {
      _saveTimer ??= Timer(const Duration(seconds: 1), () {
        _saveTimer = null;
        _pendingSave = _session;
        _kickWriter();
      });
    }
  }

  void _kickWriter() {
    _writer ??= _writeLoop();
  }

  Future<void> _writeLoop() async {
    try {
      while (_pendingSave != null) {
        final saving = _pendingSave!;
        _pendingSave = null;
        try {
          await repository!.saveWorking(saving);
          _storageError = null;
          _dirty = !identical(_session, saving);
        } catch (_) {
          _dirty = true;
          _storageError = 'No se pudo guardar. La partida sigue en memoria. Reintenta antes de cambiar de partida.';
          break;
        }
      }
    } finally {
      _writer = null;
      _notify();
    }
  }

  Future<bool> flush() async {
    if (repository == null || _session == null) return _storageError == null;
    _saveTimer?.cancel();
    _saveTimer = null;
    _pendingSave = _session;
    _kickWriter();
    await _writer;
    return _storageError == null;
  }

  List<PrioritySavedMatch> get savedMatches {
    final map = <String, PrioritySavedMatch>{
      for (final s in _library) s.id: s,
      for (final s in _memoryArchive.values) s.id: s.summary,
      if (_session != null) _session!.id: _session!.summary,
    };
    return List.unmodifiable(
      map.values.toList()..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt)),
    );
  }

  Future<void> refreshLibrary() async {
    if (repository == null) return;
    try {
      _library = await repository!.list();
      _libraryError = repository!.unreadableIds.isEmpty
          ? null
          : 'Hay partidas que no se pudieron leer; sus archivos se conservan.';
    } catch (_) {
      _libraryError = 'No se pudo consultar la biblioteca. Reintenta.';
    }
    _notify();
  }

  Future<PrioritySession> readSaved(String id) async {
    if (_session?.id == id) return _session!;
    final memory = _memoryArchive[id];
    if (memory != null) return memory;
    if (repository == null) throw StateError('Partida no disponible.');
    return repository!.read(id);
  }

  Future<void> _archiveCurrent() async {
    if (_session == null) return;
    if (repository == null) {
      _memoryArchive[_session!.id] = _session!;
    } else {
      await repository!.archive(_session!);
    }
  }

  Future<bool> parkAndReset() async {
    if (!_ready || _busy || _disposed) return false;
    _busy = true;
    _notify();
    try {
      pauseForNavigation();
      if (!await flush()) return false;
      await _archiveCurrent();
      if (repository != null) await repository!.saveWorking(null);
      _resetCore();
      await refreshLibrary();
      return true;
    } catch (_) {
      _storageError = 'No se pudo guardar la partida actual. Se conserva abierta; reintenta.';
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<bool> openSaved(String id) async {
    if (!_ready || _busy || _disposed) return false;
    if (_session?.id == id) {
      pauseForNavigation();
      return true;
    }
    _busy = true;
    _notify();
    try {
      final saved = await readSaved(id);
      pauseForNavigation();
      if (!await flush()) return false;
      await _archiveCurrent();
      final next = _recovered(saved);
      if (repository != null) await repository!.saveWorking(next);
      _adopt(next);
      _dirty = false;
      _storageError = null;
      _notice = _recoveryMessage(next);
      await refreshLibrary();
      return true;
    } catch (_) {
      _storageError =
          'No se pudo abrir esa partida. La partida actual se conserva.';
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<bool> deleteSaved(String id) async {
    if (!_ready || _busy || _session?.id == id || _disposed) return false;
    _busy = true;
    _notify();
    try {
      if (repository == null) {
        _memoryArchive.remove(id);
      } else {
        await repository!.delete(id);
      }
      await refreshLibrary();
      return true;
    } catch (_) {
      _libraryError = 'No se pudo borrar la partida. Reintenta.';
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Tests without a repository may clear RAM directly. Production must first
  /// park the saved game, so a synchronous call cannot discard disk-backed data.
  void reset() {
    if (repository != null && _session != null) {
      throw StateError('Guarda la partida con parkAndReset.');
    }
    _resetCore();
  }

  void _resetCore() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _session = null;
    _pendingSave = null;
    _notice = null;
    _visualSeatOrder = const [];
    _cancelInputTimers();
    _events = const [];
    _clockTicker?.cancel();
    _clockTicker = null;
    _clockAnchor = null;
    _dirty = false;
    value = null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    pauseForNavigation();
    _saveTimer?.cancel();
    if (repository != null && _session != null) {
      _pendingSave = _session;
      _kickWriter();
    }
    _disposed = true;
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
