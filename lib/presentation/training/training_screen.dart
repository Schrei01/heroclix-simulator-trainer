import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/training/exercise.dart';
import '../../domain/training/progress.dart';
import 'training_controller.dart';
import 'exercise_screen.dart';
import 'personal_exercise_dialog.dart';

String outcomeLabel(EvaluationOutcome o) => switch (o) {
  EvaluationOutcome.correct => 'Acierto',
  EvaluationOutcome.incorrect => 'Respuesta incorrecta',
  EvaluationOutcome.manual => 'Revisión manual',
  EvaluationOutcome.notEvaluated => 'No evaluada',
  EvaluationOutcome.incomplete => 'Respuesta incompleta',
};
String trainingDate(DateTime d) {
  final v = d.toLocal();
  String n(int x) => '$x'.padLeft(2, '0');
  return '${n(v.day)}/${n(v.month)}/${v.year} ${n(v.hour)}:${n(v.minute)}';
}

Future<void> showStoredAttempt(
  BuildContext context,
  ExerciseProgress p,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    scrollable: true,
    title: Text('Último intento · ${outcomeLabel(p.lastEvaluation.outcome)}'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edición ${p.rulesVersion} · ${trainingDate(p.lastAt)}${p.usedHint ? ' · con pista' : ''}',
        ),
        const Text(
          'Revisión guardada. Abrirla no recalifica ni suma intentos.',
        ),
        Text(
          'Respuesta: ${p.lastAnswer.route.isEmpty ? p.lastAnswer.value : p.lastAnswer.route.map((c) => c.label).join(' / ')}',
        ),
        Text(p.lastEvaluation.feedback.explanation),
        Text('Guía guardada: ${p.lastEvaluation.feedback.solution}'),
        Text(
          p.lastEvaluation.feedback.references.map((r) => '§$r').join(' · '),
        ),
      ],
    ),
    actions: [
      TextButton(
        key: const ValueKey('training-review-close'),
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  ),
);

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({required this.controller, super.key});
  final TrainingController controller;
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  SkillCategory? _category;
  Difficulty? _difficulty;
  bool _mistakes = false;
  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('¿Reiniciar estadísticas?'),
        content: const Text(
          'Se borrarán los intentos, aciertos y revisiones locales de todas las ediciones. Tus ejercicios personales se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('training-reset-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.controller.reset();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller,
          exercises = c.exercises
              .where(
                (e) =>
                    (_category == null || e.category == _category) &&
                    (_difficulty == null || e.difficulty == _difficulty) &&
                    (!_mistakes || c.isMistake(e)),
              )
              .toList();
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: math.max(
            56,
            MediaQuery.textScalerOf(context).scale(20) + 16,
          ),
          title: const Text(
            'Entrenador',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              key: const ValueKey('training-new'),
              tooltip: 'Crear ejercicio personal',
              onPressed: c.ready && !c.busy
                  ? () => showPersonalExercise(context, c)
                  : null,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              key: const ValueKey('training-reset'),
              tooltip: 'Reiniciar estadísticas',
              onPressed: c.ready && !c.busy ? _reset : null,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Practica y comprueba tu razonamiento',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Text(
                      '24 ejercicios curados y tus ejercicios personales. La dificultad cambia la complejidad del escenario, no las reglas.',
                    ),
                    Text(
                      'Corrector: edición ${c.evaluator.activeVersion.value}. Progreso local, sin cuentas.',
                    ),
                    if (c.loading) const LinearProgressIndicator(),
                    if (c.error != null) ...[
                      Text(c.error!, key: const ValueKey('training-error')),
                      TextButton(
                        key: const ValueKey('training-retry'),
                        onPressed: c.busy
                            ? null
                            : () => c.initialize(reload: true),
                        child: const Text('Volver a leer progreso'),
                      ),
                    ],
                    ExpansionTile(
                      key: const ValueKey('training-progress'),
                      title: const Text(
                        'Progreso por categoría',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: [
                        for (final category in SkillCategory.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Builder(
                              builder: (context) {
                                final stats = c.stats(category);
                                return Text(
                                  '${category.label}\nIntentos ${stats.attempts} · aciertos ${stats.correct} · '
                                  '${stats.percentage == null ? 'sin porcentaje automático' : '${stats.percentage!.toStringAsFixed(1)} %'}\n'
                                  'Completados ${stats.completed} · revisiones manuales ${stats.manualReviews}\n'
                                  'Último intento: ${stats.lastAt == null ? 'ninguno' : trainingDate(stats.lastAt!)}',
                                  key: ValueKey(
                                    'training-stats-${category.name}',
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    DropdownButtonFormField<SkillCategory?>(
                      key: const ValueKey('training-category'),
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todas'),
                        ),
                        for (final category in SkillCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Text(
                              category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _category = v),
                    ),
                    DropdownButtonFormField<Difficulty?>(
                      key: const ValueKey('training-difficulty'),
                      initialValue: _difficulty,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Dificultad',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todas'),
                        ),
                        for (final d in Difficulty.values)
                          DropdownMenuItem(value: d, child: Text(d.label)),
                      ],
                      onChanged: (v) => setState(() => _difficulty = v),
                    ),
                    SwitchListTile(
                      key: const ValueKey('training-mistakes'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Practicar errores'),
                      subtitle: const Text(
                        'Último intento incorrecto y autocorrección disponible en esta edición.',
                      ),
                      value: _mistakes,
                      onChanged: (v) => setState(() => _mistakes = v),
                    ),
                    if (exercises.isEmpty)
                      const Text(
                        'No hay ejercicios que cumplan estos filtros.',
                      ),
                    for (var i = 0; i < exercises.length; i++)
                      Builder(
                        builder: (context) {
                          final e = exercises[i],
                              proof = c.check(e),
                              p = c.progress(e),
                              last = c.last(e);
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    e.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    '${e.category.label} · ${e.difficulty.label} · ${e.type.label}${e.personal ? ' · Personal' : ''}',
                                  ),
                                  if (p != null)
                                    Text(
                                      'Intentos ${p.attempts} · aciertos ${p.correct}${p.completed ? ' · Completado' : ''}',
                                    ),
                                  if (!proof.eligible)
                                    Text(
                                      'Autocorrección inhabilitada: ${proof.reason}',
                                    ),
                                  Wrap(
                                    alignment: WrapAlignment.end,
                                    children: [
                                      if (last != null)
                                        TextButton(
                                          key: ValueKey(
                                            'training-review-${e.id}',
                                          ),
                                          onPressed: () =>
                                              showStoredAttempt(context, last),
                                          child: const Text(
                                            'Revisar último intento',
                                          ),
                                        ),
                                      FilledButton(
                                        key: ValueKey('training-start-${e.id}'),
                                        onPressed:
                                            c.ready && !c.busy && proof.eligible
                                            ? () => Navigator.push<void>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ExerciseScreen(
                                                        controller: c,
                                                        exercises: exercises,
                                                        index: i,
                                                      ),
                                                ),
                                              )
                                            : null,
                                        child: const Text('Iniciar ejercicio'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
