import 'dart:convert';

import '../../domain/board/cell_coordinate.dart';
import '../../domain/characters/character_repository.dart';
import '../../domain/rules/line_of_sight.dart';
import '../../domain/training/exercise.dart';
import '../../domain/training/progress.dart';
import '../../domain/training/curated_exercises.dart';
import '../board/board_session.dart';
import '../scenarios/scenario_codec.dart';
import '../scenarios/scenario_document.dart';

final class TrainingData {
  TrainingData({
    Iterable<Exercise> personal = const [],
    Iterable<ExerciseProgress> progress = const [],
  }) : personal = List.unmodifiable(personal),
       progress = List.unmodifiable(progress);
  final List<Exercise> personal;
  final List<ExerciseProgress> progress;
}

final class TrainingCodec {
  const TrainingCodec();
  static const schemaVersion = 2, maxBytes = 2 * 1024 * 1024;
  static BoardSession session(Exercise e) {
    var figures = const CharacterRepository.empty();
    var next = 1;
    for (final f in e.world.characters) {
      figures = figures.add(f, e.world.dimensions);
      final n = int.parse(f.id.substring(7)) + 1;
      if (n > next) next = n;
    }
    var nextTeam = 1;
    for (final t in e.teams) {
      final n = int.parse(t.id.substring(5)) + 1;
      if (n > nextTeam) nextTeam = n;
    }
    return BoardSession.restore(
      dimensions: e.world.dimensions,
      teams: e.teams,
      characters: figures,
      terrain: e.world.terrain,
      walls: e.world.walls,
      nextCharacter: next,
      nextTeam: nextTeam,
    );
  }

  Map<String, Object?> exerciseMap(Exercise e) => {
    'id': e.id,
    'title': e.title,
    'instruction': e.instruction,
    'category': e.category.name,
    'difficulty': e.difficulty.name,
    'type': e.type.name,
    'metric': e.metric.name,
    'revision': e.revision,
    'rulesVersion': e.rules.value,
    'createdAt': e.createdAt.toIso8601String(),
    'sourceId': e.sourceId,
    'targetId': e.targetId,
    'origin': e.origin?.label,
    'destination': e.destination?.label,
    'options': [
      for (final o in e.options) {'id': o.id, 'label': o.label},
    ],
    'expected': e.expected.toList()..sort(),
    'candidates': e.candidates.map((c) => c.label).toList(),
    'solutionRoute': e.solutionRoute.map((c) => c.label).toList(),
    'explanation': e.explanation,
    'hints': e.hints,
    'references': e.references,
    'manualGuide': e.manualGuide,
    'scenario': const ScenarioCodec().toMap(
      ScenarioDocument(
        id: e.snapshotId,
        name: e.title,
        rulesVersion: e.rules.value,
        createdAt: e.createdAt,
        modifiedAt: e.createdAt,
        session: session(e),
      ),
    ),
  };
  Exercise exerciseFrom(Object? source) {
    final m = ScenarioCodec.object(source, {
      'id',
      'title',
      'instruction',
      'category',
      'difficulty',
      'type',
      'metric',
      'revision',
      'rulesVersion',
      'createdAt',
      'sourceId',
      'targetId',
      'origin',
      'destination',
      'options',
      'expected',
      'candidates',
      'solutionRoute',
      'explanation',
      'hints',
      'references',
      'manualGuide',
      'scenario',
    });
    final scenario = const ScenarioCodec().fromMap(m['scenario']);
    final version = _str(m['rulesVersion'], 40, false);
    if (scenario.rulesVersion != version) {
      throw const FormatException(
        'Edición del ejercicio y escenario distintas.',
      );
    }
    final options = _list(m['options'], 8).map((v) {
      final o = ScenarioCodec.object(v, {'id', 'label'});
      return ExerciseOption(
        _str(o['id'], 40, false),
        _str(o['label'], 240, false),
      );
    }).toList();
    final id = _str(m['id'], 80, false);
    if (!id.startsWith('personal-')) {
      throw const FormatException(
        'El banco curado no puede sobrescribirse desde progreso.',
      );
    }
    return Exercise(
      id: id,
      title: _str(m['title'], 80, false),
      instruction: _str(m['instruction'], 2000, false),
      category: _enum(SkillCategory.values, m['category']),
      difficulty: _enum(Difficulty.values, m['difficulty']),
      type: _enum(QuestionType.values, m['type']),
      metric: _enum(ExerciseMetric.values, m['metric']),
      revision: ScenarioCodec.integer(m['revision'], 1, 999),
      rules: RuleSetVersion(version),
      personal: true,
      createdAt: _date(m['createdAt']),
      sourceId: _str(m['sourceId'], 40),
      targetId: _str(m['targetId'], 40),
      origin: _cell(m['origin']),
      destination: _cell(m['destination']),
      options: options,
      expected: _strings(m['expected'], 32, 40),
      candidates: _strings(m['candidates'], 12, 12).map(CellCoordinate.parse),
      solutionRoute: _strings(
        m['solutionRoute'],
        101,
        12,
      ).map(CellCoordinate.parse),
      explanation: _str(m['explanation'], 3000),
      hints: _strings(m['hints'], 5, 1000),
      references: _strings(m['references'], 20, 160),
      manualGuide: _str(m['manualGuide'], 3000),
      snapshotId: scenario.id,
      teams: scenario.session.teams,
      world: VisionSnapshot(
        dimensions: scenario.session.dimensions,
        characters: scenario.session.characters.all,
        terrain: scenario.session.terrain,
        walls: scenario.session.walls,
      ),
    );
  }

  Map<String, Object?> answerMap(Answer a) => {
    'kind': a.kind.name,
    'value': a.value,
    'route': a.route.map((c) => c.label).toList(),
  };
  Answer answerFrom(Object? value) {
    final m = ScenarioCodec.object(value, {'kind', 'value', 'route'});
    return Answer(
      _enum(AnswerKind.values, m['kind']),
      value: _str(m['value'], 2000),
      route: _strings(m['route'], 102, 12).map(CellCoordinate.parse),
    );
  }

  Map<String, Object?> evaluationMap(Evaluation e) => {
    'outcome': e.outcome.name,
    'explanation': e.feedback.explanation,
    'solution': e.feedback.solution,
    'references': e.feedback.references,
    'evidence': e.feedback.evidence,
  };
  Evaluation evaluationFrom(Object? value) {
    final m = ScenarioCodec.object(value, {
      'outcome',
      'explanation',
      'solution',
      'references',
      'evidence',
    });
    final outcome = _enum(EvaluationOutcome.values, m['outcome']);
    if (![
      EvaluationOutcome.correct,
      EvaluationOutcome.incorrect,
      EvaluationOutcome.manual,
    ].contains(outcome)) {
      throw const FormatException('No se guardan respuestas sin evaluar.');
    }
    return Evaluation(
      outcome,
      Feedback(
        _str(m['explanation'], 6000),
        solution: _str(m['solution'], 3000),
        references: _strings(m['references'], 20, 160),
        evidence: _strings(m['evidence'], 240, 2000),
      ),
    );
  }

  Map<String, Object?> progressMap(ExerciseProgress p) => {
    'exerciseId': p.exerciseId,
    'revision': p.revision,
    'rulesVersion': p.rulesVersion,
    'category': p.category.name,
    'attempts': p.attempts,
    'correct': p.correct,
    'manualReviews': p.manualReviews,
    'lastAt': p.lastAt.toIso8601String(),
    'lastAttemptId': p.lastAttemptId,
    'answer': answerMap(p.lastAnswer),
    'evaluation': evaluationMap(p.lastEvaluation),
    'usedHint': p.usedHint,
  };
  Map<String, Object?> toMap(TrainingData data) => {
    'trainingSchemaVersion': schemaVersion,
    'bankVersion': curatedBankVersion,
    'personalExercises': data.personal.map(exerciseMap).toList(),
    'progress': (data.progress.toList()..sort((a, b) => a.key.compareTo(b.key)))
        .map(progressMap)
        .toList(),
  };
  String encode(TrainingData data) {
    final raw = jsonEncode(toMap(data));
    decode(raw);
    return raw;
  }

  TrainingData decode(String raw) {
    try {
      final root = ScenarioCodec.object(
        ScenarioCodec.parseBounded(raw, limit: maxBytes),
        {
          'trainingSchemaVersion',
          'bankVersion',
          'personalExercises',
          'progress',
        },
      );
      final version = root['trainingSchemaVersion'];
      if (version is! int ||
          (version != 1 && version != 2) ||
          root['bankVersion'] is! int ||
          (root['bankVersion'] as int) < 1 ||
          (root['bankVersion'] as int) > curatedBankVersion) {
        throw const FormatException(
          'Versión de entrenamiento desconocida; original conservado.',
        );
      }
      final personal = _list(
        root['personalExercises'],
        50,
      ).map(exerciseFrom).toList();
      if (personal.map((e) => e.id).toSet().length != personal.length) {
        throw const FormatException('Ejercicios duplicados.');
      }
      final progress = <ExerciseProgress>[];
      for (final value in _list(root['progress'], 5000)) {
        final m = ScenarioCodec.object(value, {
          'exerciseId',
          'rulesVersion',
          'category',
          'attempts',
          'correct',
          'manualReviews',
          'lastAt',
          'lastAttemptId',
          'answer',
          'evaluation',
          if (version == 2) ...['revision', 'usedHint'],
        });
        final attempts = ScenarioCodec.integer(m['attempts'], 1, 1000000000),
            manual = ScenarioCodec.integer(m['manualReviews'], 0, attempts),
            correct = ScenarioCodec.integer(m['correct'], 0, attempts - manual);
        if (version == 2 && m['usedHint'] is! bool) {
          throw const FormatException('Pista inválida.');
        }
        final id = _str(m['exerciseId'], 80, false);
        if (!RegExp(r'^(hc10-[a-z][0-9]{2}|personal-[a-f0-9]{32})$')
            .hasMatch(id)) {
          throw const FormatException('ID de progreso inválido.');
        }
        progress.add(
          ExerciseProgress(
            exerciseId: id,
            revision: version == 1
                ? 1
                : ScenarioCodec.integer(m['revision'], 1, 999),
            rulesVersion: _str(m['rulesVersion'], 40, false),
            category: _enum(SkillCategory.values, m['category']),
            attempts: attempts,
            correct: correct,
            manualReviews: manual,
            lastAt: _date(m['lastAt']),
            lastAttemptId: _str(m['lastAttemptId'], 80, false),
            lastAnswer: answerFrom(m['answer']),
            lastEvaluation: evaluationFrom(m['evaluation']),
            usedHint: version == 2 ? m['usedHint'] as bool : false,
          ),
        );
      }
      if (progress.map((p) => p.key).toSet().length != progress.length) {
        throw const FormatException('Progreso duplicado.');
      }
      return TrainingData(personal: personal, progress: progress);
    } on ArgumentError catch (e) {
      throw FormatException('Datos de entrenamiento inválidos: $e');
    }
  }

  List<dynamic> _list(Object? v, int max) {
    if (v is! List || v.length > max) {
      throw const FormatException('Lista demasiado grande o inválida.');
    }
    return v;
  }

  List<String> _strings(Object? v, int max, int length) =>
      _list(v, max).map((x) => _str(x, length)).toList();
  String _str(Object? v, int max, [bool empty = true]) {
    if (v is! String || v.length > max || (!empty && v.trim().isEmpty)) {
      throw const FormatException('Texto de entrenamiento inválido.');
    }
    return v;
  }

  T _enum<T extends Enum>(List<T> values, Object? v) {
    final found = values.where((e) => e.name == v).firstOrNull;
    if (found == null) {
      throw const FormatException('Valor de entrenamiento desconocido.');
    }
    return found;
  }

  DateTime _date(Object? v) {
    final raw = _str(v, 40, false), d = DateTime.tryParse(raw);
    if (d == null || !d.isUtc || d.toIso8601String() != raw) {
      throw const FormatException('Fecha de entrenamiento inválida.');
    }
    return d;
  }

  CellCoordinate? _cell(Object? v) =>
      v == null ? null : CellCoordinate.parse(_str(v, 12, false));
}
