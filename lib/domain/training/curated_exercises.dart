import '../board/board_dimensions.dart';
import '../board/cell_coordinate.dart';
import '../characters/character.dart';
import '../characters/vision_ability.dart';
import '../rules/line_of_sight.dart';
import '../terrain/edge_wall.dart';
import '../terrain/terrain.dart';
import 'exercise.dart';

const curatedBankVersion = 1;
final List<Exercise> curatedExercises = List.unmodifiable(_bank());
CellCoordinate tc(String label) => CellCoordinate.parse(label);
EdgeWall tw(String a, String b) => EdgeWall.between(tc(a), tc(b));
VisionSnapshot trainingWorld({
  String source = 'A1',
  String? target = 'D1',
  String? extra,
  int rows = 4,
  int columns = 4,
  int speed = 6,
  int range = 4,
  Map<String, TerrainType> terrain = const {},
  Map<String, int> levels = const {},
  List<EdgeWall> walls = const [],
  List<VisionAbility> abilities = const [],
}) {
  final dimensions = BoardDimensions(rows: rows, columns: columns);
  var layer = const TerrainLayer.empty();
  for (final label in {...terrain.keys, ...levels.keys}) {
    layer = layer.put(
      tc(label),
      CellTerrain(
        type: terrain[label] ?? TerrainType.clear,
        elevation: levels[label] ?? 0,
      ),
      dimensions,
    );
  }
  Character figure(int n, String at, String team) => Character(
    id: 'figure-$n',
    label: CellCoordinate.columnLabel(n - 1),
    data: CharacterDraft(
      name: 'Figura $n',
      teamId: team,
      position: tc(at),
      speed: speed,
      range: range,
      abilities: n == 1 ? abilities : const [],
    ),
  );
  return VisionSnapshot(
    dimensions: dimensions,
    terrain: layer,
    walls: const WallLayer.empty().edit(walls, dimensions, erase: false),
    characters: [
      figure(1, source, 'team-1'),
      if (target != null) figure(2, target, 'team-2'),
      if (extra != null) figure(3, extra, 'team-2'),
    ],
  );
}

const _visionOptions = [
  ExerciseOption('clear', 'Despejada'),
  ExerciseOption('hindered', 'Obstaculizada'),
  ExerciseOption('blocked', 'Bloqueada'),
];
const _rangeOptions = [
  ExerciseOption('inRangeClear', 'En alcance con visión despejada'),
  ExerciseOption('inRangeHindered', 'En alcance con visión obstaculizada'),
  ExerciseOption('blocked', 'Visión bloqueada'),
  ExerciseOption('outOfRange', 'Fuera de alcance'),
];

List<Exercise> _bank() {
  Exercise vision(
    String id,
    String title,
    VisionSnapshot world,
    String expected,
    String explanation,
    List<String> refs, {
    SkillCategory category = SkillCategory.vision,
    Difficulty difficulty = Difficulty.basic,
  }) => Exercise(
    id: id,
    title: title,
    instruction: '¿Cómo es la línea de visión de A hacia B?',
    category: category,
    difficulty: difficulty,
    type: QuestionType.choice,
    metric: ExerciseMetric.vision,
    world: world,
    options: _visionOptions,
    expected: [expected],
    explanation: explanation,
    references: refs,
    hints: ['Revisa las casillas y los bordes que atraviesa el segmento.'],
  );
  Exercise reason(
    String id,
    String title,
    VisionSnapshot world,
    String expected,
    String text,
    List<ExerciseOption> options,
    List<String> refs, {
    SkillCategory category = SkillCategory.terrain,
    Difficulty difficulty = Difficulty.intermediate,
  }) => Exercise(
    id: id,
    title: title,
    instruction:
        'Elige la regla que explica la restricción de visión entre A y B.',
    category: category,
    difficulty: difficulty,
    type: QuestionType.justification,
    metric: ExerciseMetric.reason,
    world: world,
    options: options,
    expected: [expected],
    explanation: text,
    references: refs,
    hints: [
      'Distingue las causas activas de las mejoras que ignoran otro obstáculo.',
    ],
  );
  Exercise route(
    String id,
    String title,
    VisionSnapshot world,
    String end,
    String solution,
    String text,
    Difficulty difficulty,
    List<String> refs,
  ) => Exercise(
    id: id,
    title: title,
    instruction:
        'Traza una ruta válida de A hasta $end sin exceder su velocidad. Toca casillas vecinas en orden.',
    category: SkillCategory.movement,
    difficulty: difficulty,
    type: QuestionType.route,
    metric: ExerciseMetric.movement,
    world: world,
    destination: tc(end),
    expected: ['valid'],
    solutionRoute: solution.split(' ').map(tc),
    explanation: text,
    references: refs,
    hints: [
      'Cada paso debe ser vecino. La distancia directa no garantiza una ruta legal.',
    ],
  );
  Exercise cell(
    String id,
    String title,
    VisionSnapshot world,
    List<String> candidates,
    List<String> expected,
    String text, {
    bool position = false,
    Difficulty difficulty = Difficulty.intermediate,
  }) => Exercise(
    id: id,
    title: title,
    instruction: position
        ? 'Entre ${candidates.join(', ')}, toca una casilla alcanzable en un paso que deje a B en alcance y con visión despejada.'
        : 'Entre ${candidates.join(', ')}, toca una casilla en la que A pueda terminar un movimiento de un paso.',
    category: position ? SkillCategory.position : SkillCategory.movement,
    difficulty: difficulty,
    type: QuestionType.cell,
    metric: position ? ExerciseMetric.position : ExerciseMetric.movement,
    world: world,
    candidates: candidates.map(tc),
    expected: expected,
    explanation: text,
    references: position
        ? ['10.2', '11.3b', '11.5']
        : ['10.2', '13.2', '16.2a', '16.3a'],
    hints: ['Solo se comparan las casillas indicadas; revisa paso y destino.'],
  );
  Exercise target(
    String id,
    String title,
    VisionSnapshot world,
    List<String> expected, {
    SkillCategory category = SkillCategory.vision,
  }) => Exercise(
    id: id,
    title: title,
    instruction: 'Toca una figura del otro equipo visible desde A. Una línea obstaculizada también permite verla; aquí no se pregunta por alcance.',
    category: category,
    difficulty: Difficulty.intermediate,
    type: QuestionType.target,
    metric: ExerciseMetric.vision,
    world: world,
    expected: expected,
    explanation: 'Se comparan los dictámenes de visión de cada figura del otro equipo. Obstaculizada sigue siendo visible; bloqueada no.',
    references: ['11.4', '16.2b', '16.3b', '16.4b'],
    hints: [
      'Compara cada destino por separado, sin usar alcance como criterio.',
    ],
  );
  return [
    vision(
      'hc10-v01',
      'Un pasillo libre',
      trainingWorld(),
      'clear',
      'No hay restricciones relevantes entre las dos figuras.',
      ['11.4'],
    ),
    vision(
      'hc10-v02',
      'Visión entre obstáculos verdes',
      trainingWorld(terrain: {'B1': TerrainType.hindering}),
      'hindered',
      'La línea atraviesa H: sigue siendo visible, pero obstaculizada.',
      ['16.2b'],
    ),
    vision(
      'hc10-v03',
      'Una figura intermedia',
      trainingWorld(extra: 'B1'),
      'blocked',
      'La figura intermedia normal ocupa una casilla atravesada y bloquea la visión.',
      ['11.4c'],
    ),
    target(
      'hc10-v04',
      'Dos destinos, dos líneas',
      trainingWorld(extra: 'D4', walls: [tw('B1', 'C1')]),
      ['figure-3'],
    ),
    reason(
      'hc10-t01',
      'Identificar un muro',
      trainingWorld(walls: [tw('A1', 'B1')]),
      'V06',
      'Un muro cruzado bloquea la visión. No es una casilla completa de B ni terreno H.',
      const [
        ExerciseOption('V06', 'El segmento cruza un muro'),
        ExerciseOption('V05', 'Cruza una casilla de bloqueado'),
        ExerciseOption('V04', 'Cruza obstaculizado'),
      ],
      ['16.4b'],
    ),
    reason(
      'hc10-t02',
      'Explicar la visión obstaculizada',
      trainingWorld(terrain: {'C1': TerrainType.hindering}),
      'V04',
      'H obstaculiza la línea, pero no la bloquea.',
      const [
        ExerciseOption('V04', 'Terreno obstaculizado atravesado'),
        ExerciseOption('V06', 'Muro cruzado'),
        ExerciseOption('V03', 'Figura intermedia'),
      ],
      ['16.2b'],
    ),
    vision(
      'hc10-t03',
      'Bloqueado en el recorrido',
      trainingWorld(terrain: {'B1': TerrainType.blocking}),
      'blocked',
      'El segmento atraviesa el interior de B; no puede elegir otra ruta de movimiento para esta línea.',
      ['16.3b'],
      category: SkillCategory.terrain,
    ),
    vision(
      'hc10-t04',
      'Vértice en A1–D6',
      trainingWorld(
        rows: 6,
        target: 'D6',
        terrain: {'B4': TerrainType.blocking},
      ),
      'clear',
      'En el vértice se usa el lado menos restrictivo. B4 está bloqueado, pero C3 deja pasar; no se curva el segmento.',
      ['16.8b'],
      category: SkillCategory.terrain,
      difficulty: Difficulty.advanced,
    ),
    Exercise(
      id: 'hc10-d01',
      title: 'Contar una distancia oblicua',
      instruction:
          '¿Cuántas casillas separan A1 de D6? No es una ruta de movimiento.',
      category: SkillCategory.distance,
      difficulty: Difficulty.basic,
      type: QuestionType.choice,
      metric: ExerciseMetric.distance,
      world: trainingWorld(rows: 6, target: 'D6'),
      options: const [
        ExerciseOption('4', '4'),
        ExerciseOption('5', '5'),
        ExerciseOption('6', '6'),
      ],
      expected: ['5'],
      explanation:
          'El servicio cuenta en ocho direcciones desde cero en el origen.',
      references: ['11.3a'],
      hints: ['Compara el cambio de filas y columnas.'],
    ),
    Exercise(
      id: 'hc10-d02',
      title: 'Dos columnas',
      instruction: '¿Cuál es la distancia entre B2 y D2?',
      category: SkillCategory.distance,
      difficulty: Difficulty.basic,
      type: QuestionType.choice,
      metric: ExerciseMetric.distance,
      world: trainingWorld(source: 'B2', target: 'D2'),
      options: const [
        ExerciseOption('1', '1'),
        ExerciseOption('2', '2'),
        ExerciseOption('3', '3'),
      ],
      expected: ['2'],
      explanation: 'Hay dos pasos de casilla entre ambos extremos; el origen cuenta cero.',
      references: ['11.3a'],
      hints: ['No cuentes el origen como uno.'],
    ),
    Exercise(
      id: 'hc10-d03',
      title: 'Ver no basta para alcanzar',
      instruction:
          'A tiene alcance 2. ¿Cómo queda B en la consulta de objetivos?',
      category: SkillCategory.distance,
      difficulty: Difficulty.intermediate,
      type: QuestionType.choice,
      metric: ExerciseMetric.range,
      world: trainingWorld(range: 2),
      options: _rangeOptions,
      expected: ['outOfRange'],
      explanation: 'La distancia es 3 y el alcance declarado 2. Una línea despejada no amplía alcance.',
      references: ['11.3b', '11.5'],
      hints: ['Evalúa alcance y visión como dimensiones separadas.'],
    ),
    Exercise(
      id: 'hc10-d04',
      title: 'En alcance con H',
      instruction:
          'A tiene alcance 3. ¿Cómo queda B en la consulta de objetivos?',
      category: SkillCategory.distance,
      difficulty: Difficulty.intermediate,
      type: QuestionType.choice,
      metric: ExerciseMetric.range,
      world: trainingWorld(range: 3, terrain: {'B1': TerrainType.hindering}),
      options: _rangeOptions,
      expected: ['inRangeHindered'],
      explanation: 'La distancia 3 cabe exactamente en alcance 3; H conserva la visión obstaculizada.',
      references: ['11.3b', '16.2b'],
      hints: ['Estar en alcance no elimina el terreno.'],
    ),
    route(
      'hc10-m01',
      'Usar la velocidad exacta',
      trainingWorld(target: null, speed: 3),
      'D1',
      'A1 B1 C1 D1',
      'Tres pasos legales caben exactamente en velocidad 3. Se aceptan otras rutas verificables que lleguen dentro del presupuesto.',
      Difficulty.basic,
      ['10.2'],
    ),
    route(
      'hc10-m02',
      'El rodeo entre muros',
      trainingWorld(
        target: null,
        speed: 4,
        walls: [tw('A1', 'B1'), tw('A2', 'B2')],
      ),
      'C1',
      'A1 A2 B3 C2 C1',
      'La distancia directa no evita los muros. El rodeo verificado cuesta cuatro pasos.',
      Difficulty.advanced,
      ['10.2', '16.4a', '16.8a'],
    ),
    cell(
      'hc10-m03',
      'Un destino libre',
      trainingWorld(
        target: null,
        speed: 1,
        terrain: {'B1': TerrainType.blocking, 'B2': TerrainType.blocking},
      ),
      ['B1', 'A2', 'B2'],
      ['A2'],
      'El destino debe estar libre de B y dentro del presupuesto.',
      difficulty: Difficulty.basic,
    ),
    cell(
      'hc10-m04',
      'Mover por obstaculizado',
      trainingWorld(
        target: null,
        speed: 1,
        terrain: {
          'B1': TerrainType.hindering,
          'A2': TerrainType.blocking,
          'B2': TerrainType.blocking,
        },
      ),
      ['B1', 'A2', 'B2'],
      ['B1'],
      'En esta edición H no añade costo al movimiento ni obliga a terminar antes de entrar.',
    ),
    vision(
      'hc10-e01',
      'Una colina más alta',
      trainingWorld(levels: {'A1': 2, 'D1': 2, 'B1': 3}),
      'blocked',
      'Entre extremos del mismo nivel, la elevación intermedia superior bloquea.',
      ['16.5c'],
      category: SkillCategory.elevation,
      difficulty: Difficulty.intermediate,
    ),
    vision(
      'hc10-e02',
      'Desde el borde elevado',
      trainingWorld(levels: {'A1': 2}),
      'clear',
      'La casilla elevada de origen no se convierte en un obstáculo intermedio; el resto del perfil permite la línea.',
      ['16.5c', '16.5d'],
      category: SkillCategory.elevation,
      difficulty: Difficulty.intermediate,
    ),
    vision(
      'hc10-e03',
      'Mejora de visión contra H',
      trainingWorld(
        terrain: {'B1': TerrainType.hindering},
        abilities: [VisionAbility.hindering],
      ),
      'clear',
      'IT Obstaculizado ignora ese componente de visión; no es una mejora universal.',
      ['27.6b'],
      category: SkillCategory.elevation,
    ),
    reason(
      'hc10-e04',
      'Ignorar B no ignora figuras',
      trainingWorld(
        extra: 'C1',
        terrain: {'B1': TerrainType.blocking},
        abilities: [VisionAbility.blocking],
      ),
      'V03',
      'IT Bloqueado ignora B, pero la figura intermedia sigue bloqueando.',
      const [
        ExerciseOption('V03', 'Figura intermedia que sigue activa'),
        ExerciseOption('I03', 'La mejora contra B crea el bloqueo'),
        ExerciseOption('V06', 'Un muro cruzado'),
      ],
      ['11.4c', '27.6c'],
      category: SkillCategory.elevation,
      difficulty: Difficulty.advanced,
    ),
    cell(
      'hc10-p01',
      'Un paso para cambiar la línea',
      trainingWorld(range: 2, walls: [tw('B1', 'C1')]),
      ['B1', 'B2', 'A2'],
      ['B2'],
      'Desde B2 el paso es legal y B queda a distancia 2, en alcance y con visión despejada. Se reutilizan ambos motores.',
      position: true,
      difficulty: Difficulty.advanced,
    ),
    cell(
      'hc10-p02',
      'Acercarse en diagonal',
      trainingWorld(
        target: 'D4',
        range: 2,
        terrain: {'B2': TerrainType.hindering},
      ),
      ['B1', 'B2', 'A2'],
      ['B2'],
      'B2 acerca el destino a distancia 2; H en el origen de la futura línea no obstaculiza esa línea hacia otro destino.',
      position: true,
    ),
    target(
      'hc10-p03',
      'Visible no significa despejada',
      trainingWorld(
        extra: 'D4',
        terrain: {'D1': TerrainType.hindering, 'C3': TerrainType.blocking},
      ),
      ['figure-2'],
      category: SkillCategory.position,
    ),
    cell(
      'hc10-p04',
      'Casilla libre y alcance',
      trainingWorld(
        target: 'D3',
        range: 2,
        terrain: {'B1': TerrainType.blocking},
      ),
      ['B1', 'B2', 'A2'],
      ['B2'],
      'El paso diagonal usa el lado libre. Desde B2 el destino queda en alcance y despejado; no se compara daño ni valor táctico general.',
      position: true,
      difficulty: Difficulty.advanced,
    ),
  ];
}
