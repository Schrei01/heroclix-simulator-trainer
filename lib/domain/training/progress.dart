import 'exercise.dart';

final class ExerciseProgress {
  const ExerciseProgress({
    required this.exerciseId,
    required this.revision,
    required this.rulesVersion,
    required this.category,
    required this.attempts,
    required this.correct,
    required this.manualReviews,
    required this.lastAt,
    required this.lastAttemptId,
    required this.lastAnswer,
    required this.lastEvaluation,
    required this.usedHint,
  });
  final String exerciseId, rulesVersion, lastAttemptId;
  final int revision, attempts, correct, manualReviews;
  final SkillCategory category;
  final DateTime lastAt;
  final Answer lastAnswer;
  final Evaluation lastEvaluation;
  final bool usedHint;
  String get key => '$exerciseId@$revision@$rulesVersion';
  bool get completed => correct > 0;
}

final class CategoryProgress {
  CategoryProgress(Iterable<ExerciseProgress> items) {
    final completedIds = <String>{};
    for (final p in items) {
      attempts += p.attempts;
      correct += p.correct;
      manualReviews += p.manualReviews;
      if (p.completed) completedIds.add(p.exerciseId);
      if (lastAt == null || p.lastAt.isAfter(lastAt!)) lastAt = p.lastAt;
    }
    completed = completedIds.length;
  }
  int attempts = 0, correct = 0, manualReviews = 0, completed = 0;
  DateTime? lastAt;
  int get autoAttempts => attempts - manualReviews;
  double? get percentage =>
      autoAttempts == 0 ? null : correct * 100 / autoAttempts;
}
