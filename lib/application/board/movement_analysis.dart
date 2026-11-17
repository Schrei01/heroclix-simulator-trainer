import '../../domain/board/cell_coordinate.dart';
import '../../domain/movement/movement.dart';
import '../../domain/movement/movement_rules_service.dart';
import '../../domain/movement/route_planner.dart';
import '../../domain/rules/line_of_sight.dart';
import '../../domain/rules/target_analysis_service.dart';
import 'board_edit.dart';
import 'board_session.dart';

/// Ensayo transitorio: nunca escribe ni modifica la sesión original.
final class MovementAnalysis {
  BoardSession? original;
  String? sourceId;
  List<CellCoordinate> route = const [];
  RouteEvaluation? result;
  RouteSearch? alternatives;
  TargetReport? before, after;
  bool specialEffects = false;
  MovementContext context = const MovementContext();
  static const rules = MovementRulesService();
  VisionSnapshot snapshot(BoardSession s) => VisionSnapshot(
    dimensions: s.dimensions,
    characters: s.characters.all,
    terrain: s.terrain,
    walls: s.walls,
  );
  void clear() {
    original = null;
    sourceId = null;
    route = const [];
    result = null;
    alternatives = null;
    before = null;
    after = null;
    specialEffects = false;
  }

  void sync(BoardSession s) {
    if (original != null && !BoardEdit.sameContent(original!, s)) clear();
  }

  void begin(BoardSession s, String id, String version) {
    clear();
    final f = s.characters.byId(id);
    if (f == null) return;
    original = s;
    sourceId = id;
    route = [f.position];
    context = MovementContext(rulesVersion: version);
    _evaluate();
  }

  void append(CellCoordinate c) {
    if (original == null ||
        route.isEmpty ||
        route.last == c ||
        route.length >= 102) {
      return;
    }
    route = [...route, c];
    alternatives = null;
    _evaluate();
  }

  void removeLast() {
    if (route.length <= 1) return;
    route = route.sublist(0, route.length - 1);
    alternatives = null;
    _evaluate();
  }

  void reset() {
    if (original == null || sourceId == null) return;
    route = [original!.characters.byId(sourceId!)!.position];
    alternatives = null;
    _evaluate();
  }

  void setEffects(bool value) {
    specialEffects = value;
    context = MovementContext(
      rulesVersion: context.rulesVersion,
      specialEffects: value,
    );
    _evaluate();
  }

  void search(CellCoordinate destination) {
    if (original == null || sourceId == null) return;
    alternatives = const RoutePlanner().search(
      snapshot(original!),
      sourceId!,
      destination,
      context: context,
    );
  }

  void choose(RouteEvaluation evaluation) {
    route = List.of(evaluation.route);
    _evaluate();
  }

  void _evaluate() {
    if (original == null || sourceId == null) return;
    final w = snapshot(original!);
    result = rules.evaluate(w, sourceId!, route, context: context);
    before = null;
    after = null;
    if (result!.status != MovementStatus.valid) return;
    final future = VisionSnapshot(
      dimensions: w.dimensions,
      terrain: w.terrain,
      walls: w.walls,
      characters: w.characters.map(
        (f) => f.id == sourceId ? f.revised(f.data.at(route.last)) : f,
      ),
    );
    const targets = TargetAnalysisService();
    final visionContext = VisionContext(rulesVersion: context.rulesVersion);
    before = targets.evaluate(w, sourceId!, visionContext);
    after = targets.evaluate(future, sourceId!, visionContext);
  }
}
