import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../application/board/board_edit.dart';
import '../../application/board/board_session.dart';
import '../../application/tactics/tactical_worker.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/rules/line_of_sight.dart';
import '../../domain/tactics/tactical_analysis_service.dart';
import '../../domain/tactics/tactical_diagnostic.dart';
import '../editor/editor_controller.dart';

final class _CachedPage {
  _CachedPage(
    this.current,
    this.alternate,
    Iterable<TacticalCandidate> candidates,
  ) : candidates = List.unmodifiable(candidates);
  final PositionDiagnostic current;
  final PositionDiagnostic? alternate;
  final List<TacticalCandidate> candidates;
}

final class PositionAnalysisController extends ChangeNotifier {
  PositionAnalysisController(this.editor) {
    _base = editor.value;
    _version = editor.rulesVersion;
    _special = editor.vision.specialEffects;
    sourceId = editor.value.selectedCharacterId;
    editor.addListener(_onEditor);
  }
  final EditorController editor;
  late BoardSession _base;
  late String _version;
  late bool _special;
  static const pageSize = 12;
  String? sourceId, error;
  bool busy = false,
      cancelled = false,
      compareImprovements = false,
      unknownEffects = false;
  int page = 0, cacheHits = 0, _generation = 0;
  bool _closed = false;
  TacticalPriority priority = TacticalPriority.seeMore;
  PositionDiagnostic? current, alternateCurrent;
  TacticalProgress? progress;
  List<TacticalCandidate> candidates = const [];
  CellCoordinate? selected;
  ReceivePort? _port;
  Isolate? _isolate;
  Completer<void>? _completion;
  final _cache = <Object, _CachedPage>{};
  List<CellCoordinate>? _pool;
  TacticalContext get context => TacticalContext(
    rulesVersion: editor.rulesVersion,
    unknownEffects: unknownEffects || editor.vision.specialEffects,
  );
  BoardSession get original => _base;
  VisionSnapshot get world => VisionSnapshot(
    dimensions: _base.dimensions,
    characters: _base.characters.all,
    terrain: _base.terrain,
    walls: _base.walls,
  );
  List<CellCoordinate> get pool => sourceId == null
      ? const []
      : _pool ??= const TacticalAnalysisService().pool(
          world,
          sourceId!,
          context,
        );
  int get pages => (pool.length / pageSize).ceil().clamp(1, 134);
  List<TacticalCandidate> get ordered =>
      const TacticalAnalysisService().ordered(candidates, priority);
  TacticalCandidate? get chosen =>
      candidates.where((c) => c.cell == selected).firstOrNull;
  void _changed() {
    if (!_closed) notifyListeners();
  }

  void _onEditor() {
    if (!BoardEdit.sameContent(_base, editor.value) ||
        _version != editor.rulesVersion ||
        _special != editor.vision.specialEffects) {
      _base = editor.value;
      _version = editor.rulesVersion;
      _special = editor.vision.specialEffects;
      if (_base.characters.byId(sourceId ?? '') == null) sourceId = null;
      _clear();
      error = 'El escenario o contexto cambió; vuelve a analizar.';
      _changed();
    }
  }

  void _stop() {
    _generation++;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _port?.close();
    _port = null;
    busy = false;
    if (_completion?.isCompleted == false) _completion!.complete();
  }

  void cancel() {
    _stop();
    cancelled = true;
    _changed();
  }

  void _clear() {
    _stop();
    current = null;
    alternateCurrent = null;
    candidates = const [];
    selected = null;
    progress = null;
    page = 0;
    cancelled = false;
    _cache.clear();
    _pool = null;
  }

  void chooseSource(String? id) {
    _clear();
    sourceId = id;
    error = null;
    _changed();
  }

  void setComparison(bool value) {
    _clear();
    compareImprovements = value;
    error = null;
    _changed();
  }

  void setUnknown(bool value) {
    _clear();
    unknownEffects = value;
    error = null;
    _changed();
  }

  void setPriority(TacticalPriority value) {
    priority = value;
    _changed();
  }

  void select(CellCoordinate cell) {
    selected = cell;
    _changed();
  }

  Future<void> analyze({int? pageIndex, CellCoordinate? only}) async {
    _stop();
    cancelled = false;
    error = null;
    selected = null;
    current = null;
    alternateCurrent = null;
    candidates = const [];
    final id = sourceId;
    if (id == null) {
      error = 'Elige una figura activa.';
      _changed();
      return;
    }
    if (pageIndex != null) page = pageIndex.clamp(0, pages - 1);
    final cells = only != null
        ? [only]
        : pool.skip(page * pageSize).take(pageSize).toList();
    final key = (
      id,
      context.key,
      compareImprovements,
      cells.map((c) => c.label).join(','),
    );
    final cached = _cache[key];
    if (cached != null) {
      cacheHits++;
      current = cached.current;
      alternateCurrent = cached.alternate;
      candidates = cached.candidates;
      _changed();
      return;
    }
    final generation = _generation;
    busy = true;
    progress = TacticalProgress(0, cells.length + 1, 0, 0);
    final port = ReceivePort();
    _port = port;
    final done = Completer<void>();
    _completion = done;
    _changed();
    port.listen((message) {
      if (generation != _generation || _closed) return;
      if (message is TacticalProgress) {
        progress = message;
        _changed();
      } else if (message is TacticalCurrent) {
        current = message.position;
        alternateCurrent = message.alternate;
        _changed();
      } else if (message is TacticalCandidate) {
        candidates = List.unmodifiable([...candidates, message]);
        if (only != null) selected = message.cell;
        _changed();
      } else if (message is TacticalCompleted) {
        if (current != null) {
          if (_cache.length >= 8) _cache.remove(_cache.keys.first);
          _cache[key] = _CachedPage(current!, alternateCurrent, candidates);
        }
        _stop();
        _changed();
      } else if (message is TacticalFailure) {
        error = message.message;
        _stop();
        _changed();
      } else if (message == null && busy) {
        error = 'El cálculo terminó antes de completar la página.';
        _stop();
        _changed();
      } else if (message is List) {
        error = 'El cálculo se interrumpió; vuelve a analizar.';
        _stop();
        _changed();
      }
    });
    try {
      final spawned = await Isolate.spawn(
        runTacticalJob,
        TacticalJob(
          port.sendPort,
          world,
          id,
          context,
          cells,
          compareImprovements,
        ),
        onError: port.sendPort,
        onExit: port.sendPort,
      );
      if (generation != _generation) {
        spawned.kill(priority: Isolate.immediate);
      } else {
        _isolate = spawned;
      }
    } catch (e) {
      if (generation == _generation) {
        error = 'No se pudo iniciar el cálculo. $e';
        _stop();
        _changed();
      }
    }
    return done.future;
  }

  String? confirm() {
    final candidate = chosen;
    if (busy ||
        candidate == null ||
        candidate.status != CandidateStatus.legal ||
        candidate.route == null) {
      return 'Selecciona una ruta verificada.';
    }
    if (!BoardEdit.sameContent(_base, editor.value) ||
        _version != editor.rulesVersion) {
      return 'El escenario cambió; vuelve a analizar.';
    }
    final fresh = const TacticalAnalysisService().movement.evaluate(
      world,
      sourceId!,
      candidate.route!.route,
      context: const TacticalAnalysisService().movementContext(context),
    );
    if (!fresh.canConfirm) return fresh.reason;
    return editor.moveCharacter(sourceId!, candidate.cell);
  }

  @override
  void dispose() {
    _closed = true;
    editor.removeListener(_onEditor);
    _stop();
    super.dispose();
  }
}
