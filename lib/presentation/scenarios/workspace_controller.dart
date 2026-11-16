import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../application/board/board_session.dart';
import '../../application/scenarios/scenario_document.dart';
import '../../application/scenarios/scenario_repository.dart';

/// Serializa I/O; las revisiones impiden marcar como guardada una edición posterior.
final class WorkspaceController extends ChangeNotifier {
  WorkspaceController({
    required this.repository,
    required this.readSession,
    required this.loadSession,
  }) : current = ScenarioDocument.fresh(session: readSession());
  final ScenarioRepository repository;
  final BoardSession Function() readSession;
  final void Function(BoardSession) loadSession;
  ScenarioDocument current;
  bool dirty = true,
      saved = false,
      loading = true,
      busy = false,
      switching = false;
  bool _disposed = false, _scheduled = false, _recoveryBlocked = false;
  int _revision = 0, _autosavedRevision = -1;
  String? error;
  String? autosaveError;
  DateTime? autosavedAt;
  Future<void> _tail = Future.value();
  bool get recoveryBlocked => _recoveryBlocked;
  bool get autosaveCurrent =>
      !_recoveryBlocked &&
      _autosavedRevision == _revision &&
      autosaveError == null;
  String get status => loading
      ? 'Recuperando sesión…'
      : error != null || autosaveError != null
      ? 'No se pudo guardar o leer: ${autosaveError ?? error}'
      : _autosavedRevision < _revision
      ? 'Autoguardado pendiente…'
      : dirty || !saved
      ? 'Autoguardado · sin guardar en biblioteca'
      : 'Guardado en biblioteca · autoguardado al día';
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  String _message(Object exception) => exception is FormatException
      ? exception.message.toString()
      : exception is FileSystemException
      ? 'No se pudo acceder al almacenamiento local. Revisa el espacio disponible y vuelve a intentar.'
      : exception.toString();
  Future<T> _queued<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<bool> _run(
    Future<void> Function() operation, {
    bool switchDocument = false,
  }) => _queued(() async {
    if (_disposed) return false;
    busy = true;
    switching = switchDocument;
    error = null;
    _changed();
    try {
      await operation();
      return true;
    } on Exception catch (exception) {
      error = _message(exception);
      return false;
    } finally {
      busy = false;
      switching = false;
      _changed();
    }
  });
  Future<void> initialize() => _queued(() async {
    loading = true;
    error = null;
    _changed();
    try {
      final working = await repository.readWorking();
      if (_disposed) return;
      if (working != null) {
        current = working.document;
        dirty = working.dirty;
        saved = working.saved;
        if (saved) {
          try {
            await repository.open(current.id);
          } on Exception {
            saved = false;
            dirty = true;
          }
        }
        loadSession(current.session);
        if (saved != working.saved || dirty != working.dirty) {
          await repository.saveWorking(WorkingScenario(current, dirty, saved));
        }
      } else {
        await repository.saveWorking(WorkingScenario(current, dirty, saved));
      }
      _autosavedRevision = _revision;
      autosavedAt = DateTime.now();
      _recoveryBlocked = false;
      autosaveError = null;
    } on Exception catch (exception) {
      error = _message(exception);
      autosaveError = error;
      _recoveryBlocked = true;
    } finally {
      loading = false;
      _changed();
    }
  });
  void edited(BoardSession session) {
    current = current.revised(session: session);
    dirty = true;
    _revision++;
    _changed();
    if (_recoveryBlocked || _scheduled || _disposed) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (!_disposed) unawaited(flush());
    });
  }

  Future<void> _writeWorking() async {
    final revision = _revision, document = current;
    await repository.saveWorking(WorkingScenario(document, dirty, saved));
    if (current.id == document.id) {
      _autosavedRevision = revision;
      autosavedAt = DateTime.now();
      autosaveError = null;
    }
  }

  Future<bool> flush() => _queued(() async {
    if (_disposed || loading || _recoveryBlocked) return false;
    if (_autosavedRevision == _revision && error == null) return true;
    try {
      await _writeWorking();
      error = null;
      return true;
    } on Exception catch (exception) {
      error = _message(exception);
      autosaveError = error;
      return false;
    } finally {
      _changed();
    }
  });
  Future<bool> retry() async {
    // No se sustituye una sesión editada por una recuperación tardía.
    if (_recoveryBlocked && _revision == 0) {
      await initialize();
      return !_recoveryBlocked;
    }
    if (_recoveryBlocked) {
      error = 'La sesión fue editada. Guarda una copia o crea/abre otro escenario para sustituir el autoguardado dañado.';
      _changed();
      return false;
    }
    return flush();
  }

  Future<bool> save({String? name, String? rulesVersion}) => _run(() async {
    final revision = _revision;
    final document = name == null && rulesVersion == null
        ? current
        : current.revised(name: name, rulesVersion: rulesVersion);
    await repository.save(document);
    if (_revision == revision) {
      current = document;
      dirty = false;
    }
    saved = true;
    if (_recoveryBlocked) await repository.archiveWorking();
    await _writeWorking();
    _recoveryBlocked = false;
  });
  Future<void> _replace(
    ScenarioDocument document, {
    required bool isSaved,
    required bool isDirty,
  }) async {
    if (_recoveryBlocked) await repository.archiveWorking();
    await repository.saveWorking(WorkingScenario(document, isDirty, isSaved));
    if (_disposed) return;
    current = document;
    saved = isSaved;
    dirty = isDirty;
    _revision++;
    _autosavedRevision = _revision;
    autosavedAt = DateTime.now();
    _recoveryBlocked = false;
    autosaveError = null;
    loadSession(document.session);
  }

  Future<bool> create(String name, String rulesVersion) => _run(
    () => _replace(
      ScenarioDocument.fresh(name: name, rulesVersion: rulesVersion),
      isSaved: false,
      isDirty: true,
    ),
    switchDocument: true,
  );
  Future<bool> open(String id) => _run(() async {
    final document = await repository.open(id);
    await _replace(document, isSaved: true, isDirty: false);
  }, switchDocument: true);
  Future<bool> saveAs(String name, String rulesVersion) => _run(() async {
    final document = ScenarioDocument.fresh(
      name: name,
      rulesVersion: rulesVersion,
      session: readSession(),
    );
    await repository.save(document);
    await _replace(document, isSaved: true, isDirty: false);
  }, switchDocument: true);
  Future<bool> importDocument(ScenarioDocument imported) => _run(() async {
    final document = imported.copyAs(imported.name);
    await repository.save(document);
    await _replace(document, isSaved: true, isDirty: false);
  }, switchDocument: true);
  Future<List<LibraryItem>> library() => _queued(() async {
    try {
      final result = await repository.list();
      error = null;
      _changed();
      return result;
    } on Exception catch (exception) {
      error = _message(exception);
      _changed();
      rethrow;
    }
  });
  Future<bool> rename(String id, String name, String rulesVersion) =>
      _run(() async {
        final document = (await repository.open(id))
            .revised(name: name, rulesVersion: rulesVersion);
        await repository.save(document);
        if (current.id == id) {
          current = current.revised(name: name, rulesVersion: rulesVersion);
          await _writeWorking();
        }
      });
  Future<bool> duplicate(String id, String name, {String? rulesVersion}) =>
      _run(() async {
        final document = await repository.open(id);
        await repository.save(
          ScenarioDocument.fresh(
            name: name,
            rulesVersion: rulesVersion ?? document.rulesVersion,
            session: document.session,
          ),
        );
      });
  Future<bool> delete(String id) => _run(() async {
    await repository.delete(id);
    if (current.id == id) {
      saved = false;
      dirty = true;
      _revision++;
      await _writeWorking();
    }
  });
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
