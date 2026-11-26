import '../ports/local_document_store.dart';
import '../../domain/priority/priority.dart';
import 'priority_session.dart';
import 'priority_session_codec.dart';

final class PriorityRepository {
  PriorityRepository(this.store, {this.codec = const PrioritySessionCodec()});
  final LocalDocumentStore store;
  final PrioritySessionCodec codec;
  static const backupId = 's-00000000000000000000000000000000';
  Future<void> _tail = Future.value();
  String? _lastWorking;
  bool _loaded = false;
  bool recoveredBackup = false;
  List<String> unreadableIds = const [];
  Future<T> _queue<T>(Future<T> Function() run) {
    final result = _tail.then((_) => run());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<PrioritySession?> load() => _queue(() async {
    _loaded = false;
    recoveredBackup = false;
    try {
      final raw = await store.read('working');
      if (raw == null) {
        final backup = await store.read(backupId);
        if (backup != null) {
          final session = codec.decode(backup);
          _lastWorking = backup;
          _loaded = true;
          recoveredBackup = session != null;
          return session;
        }
      }
      final session = raw == null ? null : codec.decode(raw);
      _lastWorking = raw;
      _loaded = true;
      return session;
    } on PriorityVersionException {
      rethrow;
    } on FormatException {
      final raw = await store.read(backupId);
      if (raw == null) rethrow;
      final session = codec.decode(raw);
      if (session == null) rethrow;
      _lastWorking = raw;
      _loaded = true;
      recoveredBackup = true;
      return session;
    }
  });

  Future<void> saveWorking(PrioritySession? session) => _queue(() async {
    if (!_loaded) throw StateError('Carga Priority antes de guardar.');
    final raw = codec.encode(session);
    // Never copy a damaged primary over the last known valid backup.
    if (_lastWorking != null) await store.write(backupId, _lastWorking!);
    await store.write('working', raw);
    _lastWorking = raw;
    if (session?.match.underlyingPhase == PriorityPhase.finished) {
      await _archive(session!);
    }
  });

  Future<void> archive(PrioritySession session) =>
      _queue(() => _archive(session));
  Future<void> _archive(PrioritySession session) =>
      store.write(session.id, codec.encode(session));
  Future<PrioritySession> read(String id) => _queue(() async {
    if (id == backupId || !PrioritySession.validId(id)) {
      throw ArgumentError('Partida inválida.');
    }
    final raw = await store.read(id);
    final session = raw == null ? null : codec.decode(raw);
    if (session == null || session.id != id) {
      throw const FormatException('Partida no disponible.');
    }
    return session;
  });
  Future<List<PrioritySavedMatch>> list() => _queue(() async {
    final result = <PrioritySavedMatch>[], errors = <String>[];
    for (final id in await store.listIds()) {
      if (id == backupId) continue;
      try {
        final raw = await store.read(id);
        final summary = raw == null ? null : codec.summary(raw);
        if (summary == null || summary.id != id) throw const FormatException();
        result.add(summary);
      } catch (_) {
        errors.add(id);
      }
    }
    unreadableIds = List.unmodifiable(errors);
    return result..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  });
  Future<void> delete(String id) => _queue(() async {
    if (id == backupId || !PrioritySession.validId(id)) {
      throw ArgumentError('Partida inválida.');
    }
    await store.delete(id);
  });
}
