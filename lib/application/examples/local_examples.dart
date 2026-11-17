import '../../domain/training/curated_exercises.dart';
import '../../domain/training/exercise.dart';
import '../training/training_codec.dart';
import '../scenarios/scenario_document.dart';

/// Escenas originales derivadas de los contratos verificados del banco curado.
final class LocalExample {
  const LocalExample(this.id, this.title, this.lesson, this.exerciseId);
  final String id, title, lesson, exerciseId;
  Exercise get exercise =>
      curatedExercises.singleWhere((e) => e.id == exerciseId);
  ScenarioDocument copy() => ScenarioDocument.fresh(
    name: title,
    rulesVersion: exercise.rules.value,
    session: TrainingCodec.session(exercise),
  );
}

const localExamples = [
  LocalExample(
    'vision',
    'Visión básica · terreno H',
    'De A1 a D1 se atraviesa H en B1: la visión es obstaculizada y sigue siendo visible. Consulta el dictamen y mide el alcance.',
    'hc10-v02',
  ),
  LocalExample(
    'diagonal',
    'Diagonal y vértice · A1–D6',
    'B4 está bloqueado y C3 libre. El contacto puntual por el vértice permite el lado menos restrictivo. La línea es despejada.',
    'hc10-t04',
  ),
  LocalExample(
    'wall',
    'Muro entre casillas',
    'El muro de A1/B1 bloquea la línea. Un muro pertenece a un borde; no es una casilla de terreno bloqueado.',
    'hc10-t01',
  ),
  LocalExample(
    'elevation',
    'Elevación intermedia',
    'Una casilla más alta intermedia bloquea esta línea entre figuras al mismo nivel inferior. Consulta niveles y evidencia.',
    'hc10-e01',
  ),
  LocalExample(
    'movement',
    'Movimiento y rodeo',
    'A1–A2–B3–C2–C1 evita los muros y cuesta cuatro pasos. Ensaya la ruta con velocidad 4; confirmar es una acción separada.',
    'hc10-m02',
  ),
];
