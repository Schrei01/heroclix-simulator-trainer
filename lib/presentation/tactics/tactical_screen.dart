import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../application/board/board_edit.dart';
import '../../application/tactics/diagnostic_summary.dart';
import '../../application/training/analysis_exercises.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/movement/movement.dart';
import '../../domain/tactics/tactical_diagnostic.dart';
import '../editor/board_canvas.dart';
import '../editor/editor_controller.dart';
import '../training/training_controller.dart';
import '../training/training_scope.dart';
import '../training/training_screen.dart';
import '../vision/vision_controls.dart' show visionLabel;
import '../vision/tactical_controls.dart' show targetLabel;
import 'position_analysis_controller.dart';
import 'tactical_map_painter.dart';
import 'diagnostic_png.dart';

class TacticalScreen extends StatefulWidget {
  const TacticalScreen({
    required this.editor,
    this.analysis,
    this.training,
    super.key,
  });
  final EditorController editor;
  final PositionAnalysisController? analysis;
  final TrainingController? training;
  @override
  State<TacticalScreen> createState() => _TacticalScreenState();
}

class _TacticalScreenState extends State<TacticalScreen> {
  late final PositionAnalysisController c;
  late final EditorController _board;
  bool _localBusy = false, _creating = false, _saving = false;
  int _creation = 0;
  String? _message, _target;
  TrainingController? get trainer =>
      widget.training ?? TrainingScope.maybeOf(context);
  @override
  void initState() {
    super.initState();
    c = widget.analysis ?? PositionAnalysisController(widget.editor);
    _board = EditorController()..loadScenario(c.original);
    c.addListener(_syncBoard);
  }

  void _syncBoard() {
    if (!BoardEdit.sameContent(_board.value, c.original)) {
      _board.loadScenario(c.original);
    }
  }

  @override
  void dispose() {
    _creation++;
    c.removeListener(_syncBoard);
    c.dispose();
    _board.dispose();
    super.dispose();
  }

  void _cell(CellCoordinate cell) {
    if (c.sourceId == null) {
      final f = c.original.characters.at(cell);
      if (f != null) c.chooseSource(f.id);
      return;
    }
    if (cell == c.current?.cell) {
      c.select(cell);
      return;
    }
    if (c.candidates.any((candidate) => candidate.cell == cell)) {
      c.select(cell);
      return;
    }
    if (!c.busy) unawaited(c.analyze(only: cell));
  }

  Future<void> _confirm() async {
    final selected = c.chosen;
    if (selected == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text('¿Mover a ${selected.cell.label}?'),
        content: Text(
          'Se aplicará la ruta verificada de ${selected.route!.cost} pasos con la ficha declarada. Deshacer estará disponible. No valida una acción ni un ataque.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('position-confirm-yes'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar movimiento'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final error = c.confirm();
      setState(
        () => _message =
            error ?? 'Posición aplicada; puedes deshacer desde el Editor.',
      );
    }
  }

  Future<void> _export(bool png) async {
    final files = widget.editor.files, current = c.current;
    if (files == null || current == null) return;
    final original = c.original,
        chosen = c.chosen,
        candidates = c.candidates,
        priority = c.priority;
    setState(() {
      _localBusy = true;
      _message = null;
    });
    try {
      final data = png
          ? await diagnosticPng(original, current, candidates, chosen, priority)
          : Uint8List.fromList(
              utf8.encode(
                diagnosticSummary(
                  current,
                  chosen,
                  priority,
                  evaluated: candidates.length,
                  requested: c.progress == null
                      ? candidates.length
                      : c.progress!.total - 1,
                  cancelled: c.cancelled,
                ),
              ),
            );
      if (!mounted || c.current != current) return;
      final saved = await files.saveFile(
        data,
        png ? 'heroclix_diagnostico.png' : 'heroclix_diagnostico.txt',
        png ? 'image/png' : 'text/plain',
      );
      if (mounted) {
        setState(
          () => _message = saved
              ? 'Diagnóstico exportado con etiquetas genéricas, sin nombres personales.'
              : 'Exportación cancelada.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _message = 'No se pudo exportar. $e');
    } finally {
      if (mounted) setState(() => _localBusy = false);
    }
  }

  Future<void> _exercise(bool routeQuestion) async {
    final t = trainer, selected = c.chosen, current = c.current;
    if (t == null ||
        !t.ready ||
        t.busy ||
        selected == null ||
        current == null ||
        c.busy) {
      return;
    }
    final original = c.original,
        sourceId = c.sourceId!,
        rulesVersion = c.context.rulesVersion,
        candidates = c.candidates,
        targetId = current.enemies.any((e) => e.id == _target)
            ? _target
            : current.enemies.firstOrNull?.id;
    final generation = ++_creation;
    setState(() {
      _localBusy = true;
      _creating = true;
      _saving = false;
      _message = null;
    });
    try {
      final exercise = await buildAnalysisExercise(
        AnalysisExerciseRequest(
          original,
          sourceId,
          rulesVersion,
          selected,
          current,
          candidates,
          targetId,
          routeQuestion,
        ),
      );
      if (!mounted || generation != _creation) return;
      if (c.current != current ||
          !BoardEdit.sameContent(original, widget.editor.value)) {
        throw StateError('El escenario cambió; vuelve a analizar.');
      }
      if (!t.ready || t.busy) {
        throw StateError('Espera a que termine el guardado del Entrenador.');
      }
      setState(() => _saving = true);
      await t.repository.add(exercise);
      t.generatedExerciseAdded();
      if (mounted && generation == _creation) {
        setState(
          () => _message = 'Ejercicio verificado y guardado en Entrenador.',
        );
      }
    } catch (e) {
      if (mounted && generation == _creation) {
        setState(() => _message = 'No se creó el ejercicio. $e');
      }
    } finally {
      if (mounted && generation == _creation) {
        setState(() {
          _localBusy = false;
          _creating = false;
          _saving = false;
        });
      }
    }
  }

  Widget _diagnostic(PositionDiagnostic d, {String? heading}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (heading != null)
        Text(heading, style: Theme.of(context).textTheme.titleMedium),
      for (final m in TacticalMetric.values)
        Text('${m.label}: ${d.metrics[m]!.text}'),
      Text(
        'Terreno: ${d.terrain.map((t) => switch (t.name) {
          'clear' => 'Despejado',
          'hindering' => 'Obstaculizado',
          _ => 'Bloqueado',
        }).join(', ')} · niveles ${d.levels.join(', ')}',
      ),
      for (final limit in d.limits) Text('No evaluado: $limit'),
    ],
  );
  Widget _candidate(TacticalCandidate p) {
    final d = p.position!,
        visible = d.metrics[TacticalMetric.visible]!,
        hindered = d.metrics[TacticalMetric.hindered]!,
        seen = d.metrics[TacticalMetric.seenBy]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${p.cell.label} · costo ${p.route!.cost} · ${d.complete ? 'métricas completas' : 'métricas incompletas'}',
            ),
            Text(
              'Desde aquí se ven ${visible.text} objetivos, ${hindered.text} con línea obstaculizada; ${seen.text} enemigos lo ven.',
            ),
            TextButton(
              key: ValueKey('position-select-${p.cell.label}'),
              onPressed: () => c.select(p.cell),
              child: const Text('Comparar esta posición'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final selected = c.chosen,
          position = selected?.position,
          training = trainer;
      final actor = c.original.characters.byId(c.sourceId ?? ''),
          progress = c.progress;
      final exerciseTarget =
          c.current?.enemies.any((e) => e.id == _target) == true
          ? _target
          : c.current?.enemies.firstOrNull?.id;
      final partial = c.candidates.where(
            (p) => p.status == CandidateStatus.legal && !p.position!.complete,
          ),
          pending = c.candidates.where(
            (p) => p.status != CandidateStatus.legal,
          );
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: math.max(
            56,
            MediaQuery.textScalerOf(context).scale(20) + 16,
          ),
          leading: IconButton(
            key: const ValueKey('position-back'),
            tooltip: 'Cerrar análisis sin mover',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text(
            'Analizar posición',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Comparaciones de métricas, no una jugada óptima ni una probabilidad de victoria. La escena permanece en su posición real hasta confirmar.',
                    ),
                    DropdownButtonFormField<String>(
                      key: ValueKey('position-source-${c.sourceId}'),
                      initialValue: c.sourceId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Figura activa',
                      ),
                      items: [
                        for (final f in c.original.characters.all)
                          DropdownMenuItem(
                            value: f.id,
                            child: Text(
                              '${f.label} · ${f.name} · ${f.position.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _localBusy ? null : c.chooseSource,
                    ),
                    if (actor != null)
                      Text(
                        'Ficha declarada: velocidad ${actor.speed}, alcance ${actor.range}, base ${actor.footprint.label}, tamaño ${actor.size.label}. IT: ${actor.abilities.isEmpty ? 'ninguna' : actor.abilities.map((a) => a.label).join(', ')}. IM: ${actor.movementAbilities.isEmpty ? 'ninguna' : actor.movementAbilities.map((a) => a.label).join(', ')}.',
                      ),
                    DropdownButtonFormField<TacticalPriority>(
                      key: const ValueKey('position-priority'),
                      initialValue: c.priority,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ordenar por métrica',
                      ),
                      items: [
                        for (final priority in TacticalPriority.values)
                          DropdownMenuItem(
                            value: priority,
                            child: Text(
                              priority.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) c.setPriority(v);
                      },
                    ),
                    const Text(
                      'Desempate por costo y coordenada, solo en esta página. Los datos parciales se muestran aparte y no se ordenan como propuestas categóricas.',
                    ),
                    CheckboxListTile(
                      key: const ValueKey('position-improvements'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Comparar sin mejoras soportadas del activo',
                      ),
                      value: c.compareImprovements,
                      onChanged: _localBusy
                          ? null
                          : (v) => c.setComparison(v ?? false),
                    ),
                    if (c.compareImprovements)
                      const Text(
                        'HIPÓTESIS: se desactivan solo las mejoras soportadas del activo. Otras fichas, tamaños y efectos sin soporte se conservan. Mapa y confirmar usan la ficha declarada.',
                      ),
                    CheckboxListTile(
                      key: const ValueKey('position-unknown'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Otro efecto táctico no modelado'),
                      value: c.unknownEffects,
                      onChanged: _localBusy
                          ? null
                          : (v) => c.setUnknown(v ?? false),
                    ),
                    Text(
                      'Página ${c.page + 1}/${c.pages}. Hasta 12 destinos y 32 enemigos por posición; los demás enemigos quedan No evaluados.',
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          key: const ValueKey('position-run'),
                          onPressed: c.busy || _localBusy || c.sourceId == null
                              ? null
                              : () => unawaited(c.analyze()),
                          child: const Text('Analizar página'),
                        ),
                        TextButton(
                          key: const ValueKey('position-prev'),
                          onPressed: !c.busy && !_localBusy && c.page > 0
                              ? () =>
                                    unawaited(c.analyze(pageIndex: c.page - 1))
                              : null,
                          child: const Text('Anterior'),
                        ),
                        TextButton(
                          key: const ValueKey('position-next'),
                          onPressed:
                              !c.busy && !_localBusy && c.page + 1 < c.pages
                              ? () =>
                                    unawaited(c.analyze(pageIndex: c.page + 1))
                              : null,
                          child: const Text('Siguiente'),
                        ),
                        if (c.busy)
                          TextButton(
                            key: const ValueKey('position-cancel'),
                            onPressed: c.cancel,
                            child: const Text('Cancelar cálculo'),
                          ),
                      ],
                    ),
                    if (c.busy) ...[
                      LinearProgressIndicator(
                        value: progress == null
                            ? null
                            : ((progress.position +
                                          (progress.enemies == 0
                                              ? 0
                                              : progress.enemy /
                                                    progress.enemies)) /
                                      progress.total)
                                  .clamp(0, 1),
                      ),
                      Text(
                        'Calculando posición ${(progress?.position ?? 0) + 1}/${progress?.total ?? 1} · enemigos ${progress?.enemy ?? 0}/${progress?.enemies ?? 0}',
                        key: const ValueKey('position-progress'),
                      ),
                    ],
                    if (c.cancelled)
                      Text(
                        'Cálculo cancelado. ${c.candidates.length} destinos terminados; los demás no se han evaluado.',
                        key: const ValueKey('position-cancelled'),
                      ),
                    if (c.error != null)
                      Text(c.error!, key: const ValueKey('position-error')),
                    SizedBox(
                      height: (MediaQuery.sizeOf(context).height * .43).clamp(
                        180,
                        440,
                      ),
                      child: AnimatedBuilder(
                        animation: _board,
                        builder: (context, _) => BoardCanvas(
                          controller: _board,
                          readOnly: true,
                          onCellTap: _cell,
                          overlayPainter: TacticalMapPainter(
                            candidates: c.candidates,
                            current: c.current?.cell ?? actor?.position,
                            selected: c.selected,
                            priority: c.priority,
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'Mapa: V visibles · T amenazas con línea y alcance · C costo · ? incertidumbre. Las casillas indican el ancla de la base. Color = métrica de orden, no legalidad de un ataque. Toca otra casilla para analizarla por separado.',
                    ),
                    if (c.current != null)
                      ExpansionTile(
                        key: const ValueKey('position-current'),
                        initiallyExpanded: true,
                        title: Text(
                          'Posición actual ${c.current!.cell.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [_diagnostic(c.current!)],
                      ),
                    if (c.alternateCurrent != null)
                      ExpansionTile(
                        key: const ValueKey('position-current-without'),
                        title: const Text(
                          'HIPÓTESIS en origen sin mejoras',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [_diagnostic(c.alternateCurrent!)],
                      ),
                    for (final candidate in c.ordered) _candidate(candidate),
                    if (partial.isNotEmpty)
                      ExpansionTile(
                        key: const ValueKey('position-partial'),
                        initiallyExpanded: true,
                        title: const Text(
                          'Rutas verificadas, métricas parciales',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [for (final p in partial) _candidate(p)],
                      ),
                    if (pending.isNotEmpty)
                      ExpansionTile(
                        key: const ValueKey('position-pending'),
                        title: const Text(
                          'Descartadas o No evaluadas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [
                          for (final p in pending)
                            Text(
                              '${p.cell.label}: ${p.status == CandidateStatus.invalid ? 'Inválida' : 'No evaluada'} · ${p.reason}',
                            ),
                        ],
                      ),
                    if (position != null && c.current != null) ...[
                      Text(
                        'Comparación con ${selected!.cell.label}',
                        key: const ValueKey('position-comparison'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      for (final metric in TacticalMetric.values)
                        Builder(
                          builder: (context) {
                            final difference = MetricDifference(
                              c.current!.metrics[metric]!,
                              position.metrics[metric]!,
                            );
                            return Text(
                              '${metric.label}: antes ${difference.before.text}; después ${difference.after.text}. '
                              '${difference.exact == null ? 'Diferencia indeterminada' : 'Cambio ${difference.exact! >= 0 ? '+' : ''}${difference.exact}'}',
                            );
                          },
                        ),
                      Text(
                        'Ruta de ${selected.route!.cost} pasos: ${selected.route!.route.map((c) => c.label).join(' / ')}',
                      ),
                      _diagnostic(position),
                      if (selected.alternate != null) ...[
                        _diagnostic(
                          selected.alternate!,
                          heading: 'HIPÓTESIS sin mejoras soportadas',
                        ),
                        Text(
                          'Esa misma ruta sin mejoras: ${movementLabel(selected.alternateMovement!.status)}. ${selected.alternateMovement!.reason}',
                        ),
                        if (c.alternateCurrent != null)
                          _diagnostic(
                            c.alternateCurrent!,
                            heading: 'Origen sin mejoras soportadas',
                          ),
                      ],
                      ExpansionTile(
                        key: const ValueKey('position-enemy-evidence'),
                        title: const Text(
                          'Evidencia por enemigo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [
                          for (final enemy in position.enemies)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Enemigo ${enemy.label}'),
                                  Text(
                                    'Activo hacia enemigo: ${visionLabel(enemy.outgoing.visibility)}. ${enemy.outgoing.reason}',
                                  ),
                                  Text(
                                    'Alcance/visión del mismo par: ${targetLabel(enemy.outgoing.combined)}. Distancia ${enemy.outgoing.distance ?? '?'}; ${enemy.outgoing.rangeFrom?.label ?? '?'} / ${enemy.outgoing.rangeTo?.label ?? '?'}. Visión sola: ${enemy.outgoing.from?.label ?? '?'} / ${enemy.outgoing.to?.label ?? '?'}.',
                                  ),
                                  Text(
                                    'Enemigo hacia activo: ${visionLabel(enemy.incoming.visibility)}; ${targetLabel(enemy.incoming.combined)}. ${enemy.incoming.reason}',
                                  ),
                                  Text(
                                    {
                                      ...enemy.outgoing.rules,
                                      ...enemy.incoming.rules,
                                    }.join(' · '),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      FilledButton(
                        key: const ValueKey('position-confirm'),
                        onPressed:
                            !c.busy && !_localBusy && selected.route!.canConfirm
                            ? _confirm
                            : null,
                        child: const Text(
                          'Confirmar movimiento con ficha declarada',
                        ),
                      ),
                      if (training != null) ...[
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'position-exercise-target-${c.sourceId}-$exerciseTarget',
                          ),
                          initialValue: exerciseTarget,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Objetivo del ejercicio',
                          ),
                          items: [
                            for (final enemy in c.current!.enemies)
                              DropdownMenuItem(
                                value: enemy.id,
                                child: Text('Figura ${enemy.label}'),
                              ),
                          ],
                          onChanged: _localBusy
                              ? null
                              : (v) => setState(() => _target = v),
                        ),
                        Wrap(
                          children: [
                            TextButton(
                              key: const ValueKey('position-exercise-route'),
                              onPressed:
                                  !_localBusy &&
                                      !c.busy &&
                                      training.ready &&
                                      !training.busy
                                  ? () => _exercise(true)
                                  : null,
                              child: const Text('Crear ejercicio de recorrido'),
                            ),
                            TextButton(
                              key: const ValueKey(
                                'position-exercise-visibility',
                              ),
                              onPressed:
                                  !_localBusy &&
                                      !c.busy &&
                                      training.ready &&
                                      !training.busy &&
                                      c.current!.enemies.isNotEmpty
                                  ? () => _exercise(false)
                                  : null,
                              child: const Text(
                                'Crear ejercicio de posición visible',
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          key: const ValueKey('position-open-trainer'),
                          onPressed: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TrainingScreen(controller: training),
                            ),
                          ),
                          child: const Text('Abrir Entrenador'),
                        ),
                      ],
                    ],
                    ExpansionTile(
                      key: const ValueKey('position-definitions'),
                      title: const Text(
                        'Qué comprueba cada indicador',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: [
                        for (final metric in TacticalMetric.values)
                          Text(
                            '${metric.label}: ${metric.scope} §${metric.rules}. ${TacticalMetric.excluded}',
                          ),
                        const Text(
                          'Alcance declarado, tamaños y bases del perfil implementado. Las propuestas incompletas no son afirmaciones de legalidad global.',
                        ),
                      ],
                    ),
                    if (_localBusy) ...[
                      const LinearProgressIndicator(),
                      Text(
                        _creating
                            ? (_saving
                                  ? 'Guardando ejercicio…'
                                  : 'Verificando ejercicio en segundo plano…')
                            : 'Preparando exportación…',
                      ),
                      if (_creating && !_saving)
                        TextButton(
                          key: const ValueKey('position-cancel-creation'),
                          onPressed: () {
                            _creation++;
                            setState(() {
                              _localBusy = false;
                              _creating = false;
                            });
                          },
                          child: const Text('Cancelar creación pendiente'),
                        ),
                    ],
                    if (_message != null)
                      Text(_message!, key: const ValueKey('position-message')),
                    Wrap(
                      children: [
                        TextButton(
                          key: const ValueKey('position-export-text'),
                          onPressed:
                              !c.busy &&
                                  !_localBusy &&
                                  c.current != null &&
                                  widget.editor.files != null
                              ? () => _export(false)
                              : null,
                          child: const Text('Exportar resumen'),
                        ),
                        TextButton(
                          key: const ValueKey('position-export-png'),
                          onPressed:
                              !c.busy &&
                                  !_localBusy &&
                                  c.current != null &&
                                  widget.editor.files != null
                              ? () => _export(true)
                              : null,
                          child: const Text('Exportar imagen'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
