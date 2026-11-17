import 'package:material_ui/material_ui.dart';

import '../../application/scenarios/scenario_repository.dart';
import '../../application/scenarios/scenario_document.dart';
import '../../application/training/personal_exercise.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/training/exercise.dart';
import 'training_controller.dart';

enum _PersonalKind {
  vision('Visión · opciones'),
  distance('Distancia · opciones'),
  range('Alcance y visión · opciones'),
  route('Trazar una ruta'),
  manual('Texto · evaluación manual');

  const _PersonalKind(this.label);
  final String label;
}

Future<void> showPersonalExercise(
  BuildContext context,
  TrainingController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => _PersonalExerciseDialog(controller: controller),
);

class _PersonalExerciseDialog extends StatefulWidget {
  const _PersonalExerciseDialog({required this.controller});
  final TrainingController controller;
  @override
  State<_PersonalExerciseDialog> createState() => _PersonalExerciseState();
}

class _PersonalExerciseState extends State<_PersonalExerciseDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _question = TextEditingController(),
      _hint = TextEditingController(),
      _explanation = TextEditingController(),
      _guide = TextEditingController(),
      _from = TextEditingController(text: 'A1'),
      _to = TextEditingController(text: 'D1'),
      _numbers = TextEditingController(text: '1,2,3,4,5'),
      _numberSolution = TextEditingController(text: '3'),
      _route = TextEditingController();
  final _labels = <String, TextEditingController>{
    'clear': TextEditingController(text: 'Despejada'),
    'hindered': TextEditingController(text: 'Obstaculizada'),
    'blocked': TextEditingController(text: 'Bloqueada'),
    'inRangeClear': TextEditingController(
      text: 'En alcance con visión despejada',
    ),
    'inRangeHindered': TextEditingController(
      text: 'En alcance con visión obstaculizada',
    ),
    'outOfRange': TextEditingController(text: 'Fuera de alcance'),
  };
  final _id = 'personal-${ScenarioDocument.newId().substring(2)}';
  List<LibraryItem> _items = const [];
  ScenarioDocument? _document;
  String? _selected, _source, _target, _error;
  String _solution = 'clear';
  bool _loading = true, _saving = false;
  _PersonalKind _kind = _PersonalKind.vision;
  SkillCategory _category = SkillCategory.vision;
  Difficulty _difficulty = Difficulty.basic;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = widget.controller.scenarios;
      if (repo == null) {
        throw StateError(
          'Guarda un escenario en la biblioteca del Editor para crear ejercicios.',
        );
      }
      final items = await repo.list();
      if (!mounted) return;
      setState(() => _items = items.where((i) => i.document != null).toList());
      if (_items.isNotEmpty) await _select(_items.first.id);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(String id) async {
    setState(() {
      _selected = id;
      _document = null;
      _loading = true;
      _error = null;
    });
    try {
      final doc = await widget.controller.scenarios!.open(id);
      if (!mounted || _selected != id) return;
      final figures = doc.session.characters.all.toList();
      setState(() {
        _document = doc;
        _source = figures.firstOrNull?.id;
        _target = figures.length > 1 ? figures[1].id : null;
        _from.text = figures.firstOrNull?.position.label ?? 'A1';
        _to.text = figures.length > 1 ? figures[1].position.label : 'B2';
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo leer el escenario. $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _optionIds => _kind == _PersonalKind.range
      ? ['inRangeClear', 'inRangeHindered', 'blocked', 'outOfRange']
      : ['clear', 'hindered', 'blocked'];
  Future<void> _save() async {
    if (!_form.currentState!.validate() || _document == null || _saving) return;
    try {
      final doc = _document!;
      if ([_PersonalKind.vision, _PersonalKind.range].contains(_kind) &&
          (_source == null || _target == null)) {
        throw const FormatException(
          'Selecciona dos figuras para visión/alcance. También puedes crear una pregunta de distancia o manual.',
        );
      }
      if (_kind == _PersonalKind.route && _source == null) {
        throw const FormatException(
          'Selecciona la figura que recorrerá la ruta.',
        );
      }
      final type = _kind == _PersonalKind.manual
          ? QuestionType.manual
          : _kind == _PersonalKind.route
          ? QuestionType.route
          : QuestionType.choice;
      final metric = switch (_kind) {
        _PersonalKind.vision => ExerciseMetric.vision,
        _PersonalKind.distance => ExerciseMetric.distance,
        _PersonalKind.range => ExerciseMetric.range,
        _PersonalKind.route => ExerciseMetric.movement,
        _PersonalKind.manual => ExerciseMetric.manual,
      };
      final options = _kind == _PersonalKind.distance
          ? _numbers.text.split(',').map((s) {
              final n = int.tryParse(s.trim());
              if (n == null || n < 0 || n > 39) {
                throw const FormatException(
                  'Opciones numéricas: 0–39, separadas por comas.',
                );
              }
              return ExerciseOption('$n', '$n');
            }).toList()
          : [_PersonalKind.vision, _PersonalKind.range].contains(_kind)
          ? [
              for (final id in _optionIds)
                ExerciseOption(id, _labels[id]!.text.trim()),
            ]
          : <ExerciseOption>[];
      final e = personalExercise(
        id: _id,
        title: _title.text,
        instruction: _question.text,
        scenario: doc,
        category: _category,
        difficulty: _difficulty,
        type: type,
        metric: metric,
        explanation: _explanation.text,
        sourceId: _kind == _PersonalKind.distance ? '' : _source ?? '',
        targetId: _kind == _PersonalKind.distance ? '' : _target ?? '',
        origin: _kind == _PersonalKind.distance
            ? CellCoordinate.parse(_from.text)
            : null,
        destination:
            [_PersonalKind.distance, _PersonalKind.route].contains(_kind)
            ? CellCoordinate.parse(_to.text)
            : null,
        options: options,
        expected: type == QuestionType.manual
            ? const []
            : [
                type == QuestionType.route
                    ? 'valid'
                    : _kind == _PersonalKind.distance
                    ? _numberSolution.text.trim()
                    : _solution,
              ],
        solutionRoute: type == QuestionType.route
            ? _route.text
                  .trim()
                  .split(RegExp(r'[\s,]+'))
                  .map(CellCoordinate.parse)
            : const [],
        hints: _hint.text.trim().isEmpty ? const [] : [_hint.text.trim()],
        manualGuide: _guide.text,
      );
      final proof = widget.controller.evaluator.check(e);
      if (!proof.eligible) {
        throw FormatException(
          '${proof.reason}${proof.actual.isEmpty ? '' : ' Motor: ${proof.actual.join(', ')}.'}',
        );
      }
      setState(() {
        _saving = true;
        _error = null;
      });
      final saved = await widget.controller.add(e);
      if (!mounted) return;
      if (saved) {
        Navigator.pop(context);
      } else {
        setState(() => _error = widget.controller.error);
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _question,
      _hint,
      _explanation,
      _guide,
      _from,
      _to,
      _numbers,
      _numberSolution,
      _route,
      ..._labels.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller, {
    int lines = 1,
    int max = 1000,
    bool required = false,
  }) => TextFormField(
    key: ValueKey(key),
    controller: controller,
    maxLines: lines,
    maxLength: max,
    decoration: InputDecoration(labelText: label),
    onChanged: (_) {
      if (key.startsWith('personal-option-')) setState(() {});
    },
    validator: (v) => (required && (v?.trim().isEmpty ?? true))
        ? 'Completa este campo.'
        : null,
  );
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crear ejercicio personal',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text(
                'Usa una copia de un escenario guardado; el Editor y el archivo original no cambian. Define la pregunta y su solución. El motor verifica las preguntas automáticas antes de guardarlas.',
              ),
              if (_loading || _saving) const LinearProgressIndicator(),
              if (!_loading && _items.isEmpty)
                const Text(
                  'La biblioteca no tiene escenarios disponibles. Guarda uno desde el Editor.',
                ),
              if (_items.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: const ValueKey('personal-scenario'),
                  initialValue: _selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Escenario guardado',
                  ),
                  items: [
                    for (final i in _items)
                      DropdownMenuItem(
                        value: i.id,
                        child: Text(
                          i.document!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (id) {
                          if (id != null) _select(id);
                        },
                ),
              DropdownButtonFormField<_PersonalKind>(
                key: const ValueKey('personal-kind'),
                initialValue: _kind,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de corrección',
                ),
                items: [
                  for (final k in _PersonalKind.values)
                    DropdownMenuItem(
                      value: k,
                      child: Text(
                        k.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() {
                        _kind = v!;
                        _solution = _kind == _PersonalKind.range
                            ? 'inRangeClear'
                            : 'clear';
                        _category = switch (_kind) {
                          _PersonalKind.distance ||
                          _PersonalKind.range => SkillCategory.distance,
                          _PersonalKind.route => SkillCategory.movement,
                          _ => SkillCategory.vision,
                        };
                      }),
              ),
              _field(
                'personal-title',
                'Título',
                _title,
                max: 80,
                required: true,
              ),
              _field(
                'personal-question',
                'Pregunta',
                _question,
                lines: 3,
                max: 2000,
                required: true,
              ),
              DropdownButtonFormField<SkillCategory>(
                key: ValueKey('personal-category-$_category'),
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  for (final v in SkillCategory.values)
                    DropdownMenuItem(
                      value: v,
                      child: Text(
                        v.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              DropdownButtonFormField<Difficulty>(
                initialValue: _difficulty,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Dificultad'),
                items: [
                  for (final v in Difficulty.values)
                    DropdownMenuItem(value: v, child: Text(v.label)),
                ],
                onChanged: (v) => setState(() => _difficulty = v!),
              ),
              if (_document != null) ...[
                Text('Edición del escenario: ${_document!.rulesVersion}'),
                if ([
                  _PersonalKind.vision,
                  _PersonalKind.range,
                  _PersonalKind.route,
                ].contains(_kind)) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('personal-source-$_source'),
                    initialValue: _source,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Figura de origen',
                    ),
                    items: [
                      for (final f in _document!.session.characters.all)
                        DropdownMenuItem(
                          value: f.id,
                          child: Text(
                            '${f.label} · ${f.position.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _source = v),
                  ),
                  if (_kind != _PersonalKind.route)
                    DropdownButtonFormField<String>(
                      key: ValueKey('personal-target-$_target'),
                      initialValue: _target,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Figura de destino',
                      ),
                      items: [
                        for (final f in _document!.session.characters.all)
                          DropdownMenuItem(
                            value: f.id,
                            child: Text(
                              '${f.label} · ${f.position.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _target = v),
                    ),
                ],
              ],
              if (_kind == _PersonalKind.distance) ...[
                _field(
                  'personal-from',
                  'Casilla origen',
                  _from,
                  max: 12,
                  required: true,
                ),
                _field(
                  'personal-to',
                  'Casilla destino',
                  _to,
                  max: 12,
                  required: true,
                ),
                _field(
                  'personal-numbers',
                  'Opciones numéricas separadas por comas',
                  _numbers,
                  max: 80,
                  required: true,
                ),
                _field(
                  'personal-number-solution',
                  'Solución numérica declarada',
                  _numberSolution,
                  max: 2,
                  required: true,
                ),
              ],
              if ([
                _PersonalKind.vision,
                _PersonalKind.range,
              ].contains(_kind)) ...[
                const Text(
                  'Etiquetas de opciones (puedes redactarlas con tus palabras):',
                ),
                for (final id in _optionIds)
                  _field(
                    'personal-option-$id',
                    'Texto de opción ${_optionIds.indexOf(id) + 1}',
                    _labels[id]!,
                    max: 240,
                    required: true,
                  ),
                DropdownButtonFormField<String>(
                  key: ValueKey('personal-solution-$_kind'),
                  initialValue: _solution,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Solución declarada',
                  ),
                  items: [
                    for (final id in _optionIds)
                      DropdownMenuItem(
                        value: id,
                        child: Text(
                          _labels[id]!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _solution = v!),
                ),
              ],
              if (_kind == _PersonalKind.route) ...[
                _field(
                  'personal-to',
                  'Destino de la ruta',
                  _to,
                  max: 12,
                  required: true,
                ),
                _field(
                  'personal-route',
                  'Ruta de verificación, incluido origen (A1 B1 C1)',
                  _route,
                  max: 1200,
                  lines: 2,
                  required: true,
                ),
                const Text(
                  'El alumno podrá acertar con otra ruta válida al mismo destino, dentro de velocidad.',
                ),
              ],
              _field(
                'personal-hint',
                'Pista opcional',
                _hint,
                max: 1000,
                lines: 2,
              ),
              if (_kind == _PersonalKind.manual)
                _field(
                  'personal-guide',
                  'Guía para revisión manual',
                  _guide,
                  max: 3000,
                  lines: 3,
                  required: true,
                )
              else
                _field(
                  'personal-explanation',
                  'Explicación redactada por ti',
                  _explanation,
                  max: 3000,
                  lines: 3,
                  required: true,
                ),
              if (_error != null)
                Text(_error!, key: const ValueKey('personal-error')),
              FilledButton(
                key: const ValueKey('personal-save'),
                onPressed: !_loading && !_saving && _document != null
                    ? _save
                    : null,
                child: const Text('Verificar y guardar ejercicio'),
              ),
              TextButton(
                key: const ValueKey('personal-cancel'),
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
