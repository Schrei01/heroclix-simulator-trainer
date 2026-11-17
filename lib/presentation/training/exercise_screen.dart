import 'dart:math' as math;
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../application/training/training_codec.dart';
import '../../application/scenarios/scenario_document.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/training/exercise.dart';
import '../editor/board_canvas.dart';
import '../editor/editor_controller.dart';
import 'training_controller.dart';
import 'training_painter.dart';
import 'training_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({
    required this.controller,
    required this.exercises,
    required this.index,
    super.key,
  });
  final TrainingController controller;
  final List<Exercise> exercises;
  final int index;
  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  Exercise get exercise => widget.exercises[widget.index];
  late final EditorController _board;
  late Answer _answer;
  String _token = ScenarioDocument.newId();
  int _hints = 0;
  Evaluation? _feedback;
  bool _submitted = false;
  final _text = TextEditingController();
  final _feedbackAnchor = GlobalKey();
  @override
  void initState() {
    super.initState();
    _board = EditorController()..loadScenario(TrainingCodec.session(exercise));
    _newAnswer();
  }

  void _newAnswer() {
    final kind = switch (exercise.type) {
      QuestionType.choice || QuestionType.justification => AnswerKind.choice,
      QuestionType.target => AnswerKind.target,
      QuestionType.cell => AnswerKind.cell,
      QuestionType.route => AnswerKind.route,
      QuestionType.manual => AnswerKind.text,
    };
    final source = exercise.world.characters
        .where((f) => f.id == exercise.sourceId)
        .firstOrNull;
    _answer = Answer(
      kind,
      route: kind == AnswerKind.route && source != null
          ? [source.position]
          : const [],
    );
  }

  @override
  void dispose() {
    _board.dispose();
    _text.dispose();
    super.dispose();
  }

  void _cell(CellCoordinate cell) {
    if (_submitted || widget.controller.busy) return;
    final e = exercise;
    setState(() {
      _feedback = null;
      if (e.type == QuestionType.cell) {
        _answer = Answer(AnswerKind.cell, value: cell.label);
      }
      if (e.type == QuestionType.target) {
        final f = e.world.characters
            .where((f) => f.occupiedCells.contains(cell))
            .firstOrNull;
        _answer = Answer(AnswerKind.target, value: f?.id ?? '');
      }
      if (e.type == QuestionType.route &&
          _answer.route.length < 102 &&
          (_answer.route.isEmpty || _answer.route.last != cell)) {
        _answer = Answer(AnswerKind.route, route: [..._answer.route, cell]);
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final result = await widget.controller.submit(
      exercise,
      _answer,
      _token,
      usedHint: _hints > 0,
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _feedback = result;
        _submitted = result.recordable;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _feedback == null) {
          return;
        }
        final target = _feedbackAnchor.currentContext;
        if (target != null) {
          unawaited(
            Scrollable.ensureVisible(
              target,
              alignment: .2,
              duration: const Duration(milliseconds: 180),
            ),
          );
        }
      });
    }
  }

  void _repeat() {
    setState(() {
      _token = ScenarioDocument.newId();
      _feedback = null;
      _submitted = false;
      _hints = 0;
      _text.clear();
      _newAnswer();
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final e = exercise,
          c = widget.controller,
          proof = c.check(e),
          f = _feedback;
      final source = e.world.characters
          .where((f) => f.id == e.sourceId)
          .firstOrNull;
      final dest = e.world.characters
          .where((f) => f.id == e.targetId)
          .firstOrNull;
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: math.max(
            56,
            MediaQuery.textScalerOf(context).scale(20) + 16,
          ),
          title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            key: const ValueKey('training-back'),
            tooltip: 'Volver al banco',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${e.category.label} · ${e.difficulty.label} · edición ${e.rules.value}',
                    ),
                    Text(
                      e.instruction,
                      key: const ValueKey('training-instruction'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Origen: ${e.origin?.label ?? source?.position.label ?? 'sin figura'} · destino: ${e.destination?.label ?? dest?.position.label ?? 'según respuesta'}',
                    ),
                    if (source != null)
                      Text(
                        '${source.label}: velocidad ${source.speed} · alcance ${source.range}',
                      ),
                    SizedBox(
                      height: (MediaQuery.sizeOf(context).height * .42).clamp(
                        180,
                        420,
                      ),
                      child: AnimatedBuilder(
                        animation: _board,
                        builder: (context, _) => BoardCanvas(
                          controller: _board,
                          readOnly: true,
                          onCellTap: _cell,
                          overlayPainter: TrainingPainter(
                            e,
                            _answer,
                            f?.outcome,
                          ),
                        ),
                      ),
                    ),
                    ExpansionTile(
                      title: const Text(
                        'Fichas y datos del escenario',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: [
                        for (final figure in e.world.characters)
                          Text(
                            '${figure.label}: ${figure.name} · ${figure.position.label} · '
                            '${e.teams.where((t) => t.id == figure.teamId).first.name} · base ${figure.footprint.label} · ${figure.size.label}\n'
                            'IT: ${figure.abilities.isEmpty ? 'ninguna' : figure.abilities.map((a) => a.label).join(', ')} · '
                            'IM: ${figure.movementAbilities.isEmpty ? 'ninguna' : figure.movementAbilities.map((a) => a.label).join(', ')}',
                          ),
                      ],
                    ),
                    if ([
                      QuestionType.choice,
                      QuestionType.justification,
                    ].contains(e.type))
                      for (final option in e.options)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Semantics(
                            selected: _answer.value == option.id,
                            child: OutlinedButton(
                              key: ValueKey('training-option-${option.id}'),
                              style: _answer.value == option.id
                                  ? OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xff244b60),
                                    )
                                  : null,
                              onPressed: !_submitted && !c.busy
                                  ? () => setState(() {
                                      _answer = Answer(
                                        AnswerKind.choice,
                                        value: option.id,
                                      );
                                      _feedback = null;
                                    })
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(option.label),
                              ),
                            ),
                          ),
                        ),
                    if (e.type == QuestionType.target ||
                        e.type == QuestionType.cell)
                      Text(
                        'Respuesta seleccionada: ${_answer.value.isEmpty
                            ? 'ninguna'
                            : e.type == QuestionType.cell
                            ? _answer.value
                            : e.world.characters.where((f) => f.id == _answer.value).firstOrNull?.label ?? 'ninguna'}',
                        key: const ValueKey('training-selection'),
                      ),
                    if (e.type == QuestionType.route) ...[
                      Text(
                        'Tu ruta: ${_answer.route.map((c) => c.label).join(' / ')}',
                        key: const ValueKey('training-route'),
                      ),
                      TextButton(
                        key: const ValueKey('training-route-back'),
                        onPressed:
                            !_submitted && !c.busy && _answer.route.length > 1
                            ? () => setState(() {
                                _answer = Answer(
                                  AnswerKind.route,
                                  route: _answer.route.take(
                                    _answer.route.length - 1,
                                  ),
                                );
                                _feedback = null;
                              })
                            : null,
                        child: const Text('Quitar último paso'),
                      ),
                    ],
                    if (e.type == QuestionType.manual) ...[
                      const Text(
                        'Evaluación manual. Tu texto no recibe acierto automático ni entra en el porcentaje de aciertos.',
                      ),
                      TextField(
                        key: const ValueKey('training-text'),
                        controller: _text,
                        enabled: !c.busy,
                        readOnly: _submitted,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'Tu razonamiento',
                        ),
                        onChanged: (v) => setState(
                          () => _answer = Answer(
                            AnswerKind.text,
                            value: v.trim(),
                          ),
                        ),
                      ),
                    ],
                    if (_hints > 0)
                      for (final hint in e.hints.take(_hints))
                        Text(
                          'Pista: $hint',
                          key: ValueKey(
                            'training-hint-${e.hints.indexOf(hint)}',
                          ),
                        ),
                    if (e.hints.isNotEmpty)
                      TextButton(
                        key: const ValueKey('training-hint'),
                        onPressed: !c.busy && _hints < e.hints.length
                            ? () => setState(() => _hints++)
                            : null,
                        child: Text('Pista ($_hints/${e.hints.length})'),
                      ),
                    if (!proof.eligible)
                      Text('Autocorrección inhabilitada: ${proof.reason}'),
                    if (c.error != null)
                      Text(
                        c.error!,
                        key: const ValueKey('training-submit-error'),
                      ),
                    if (c.busy) const LinearProgressIndicator(),
                    FilledButton(
                      key: const ValueKey('training-check'),
                      onPressed:
                          !_submitted &&
                              c.ready &&
                              !c.busy &&
                              proof.eligible &&
                              !_answer.empty
                          ? _submit
                          : null,
                      child: Text(
                        e.type == QuestionType.manual
                            ? 'Registrar revisión manual'
                            : 'Comprobar respuesta',
                      ),
                    ),
                    if (f != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        key: _feedbackAnchor,
                        padding: EdgeInsets.zero,
                        child: Text(
                          outcomeLabel(f.outcome),
                          key: const ValueKey('training-feedback'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(f.feedback.explanation),
                      if (_submitted)
                        Text(
                          'Solución / guía: ${f.feedback.solution}',
                          key: const ValueKey('training-solution'),
                        ),
                      if (f.feedback.references.isNotEmpty)
                        Text(
                          'Referencias: ${f.feedback.references.map((r) => '§$r').join(' · ')}',
                        ),
                      if (f.feedback.evidence.isNotEmpty)
                        ExpansionTile(
                          key: const ValueKey('training-evidence'),
                          title: const Text(
                            'Ver explicación del motor',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          children: [
                            for (final line in f.feedback.evidence)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(line),
                              ),
                          ],
                        ),
                      if (_submitted) ...[
                        TextButton(
                          key: const ValueKey('training-repeat'),
                          onPressed: _repeat,
                          child: const Text('Repetir ejercicio'),
                        ),
                        FilledButton(
                          key: const ValueKey('training-next'),
                          onPressed: () {
                            if (widget.index + 1 < widget.exercises.length) {
                              Navigator.pushReplacement<void, void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExerciseScreen(
                                    controller: c,
                                    exercises: widget.exercises,
                                    index: widget.index + 1,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            widget.index + 1 < widget.exercises.length
                                ? 'Continuar'
                                : 'Volver al banco',
                          ),
                        ),
                      ],
                    ],
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
