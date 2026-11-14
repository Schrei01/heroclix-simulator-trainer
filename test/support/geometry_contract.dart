// Contratos ejecutables con Dart puro o desde flutter test, sin dependencia UI.
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/geometry/exact_fraction.dart';
import 'package:heroclix_simulator_trainer/domain/geometry/sight_geometry.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

CellCoordinate cell(String label) => CellCoordinate.parse(label);
GeometricTrace path(
  String a,
  String b, {
  int rows = 4,
  int columns = 4,
  WallLayer walls = const WallLayer.empty(),
}) => const SightGeometry().trace(
  BoardDimensions(rows: rows, columns: columns),
  SightPath(id: 'test', origin: cell(a), destination: cell(b)),
  walls: walls,
);
List<String> labels(GeometricTrace trace) =>
    trace.segments.map((segment) => segment.cell.label).toList();
void same(Object? a, Object? b) =>
    check(a.toString() == b.toString(), '$a != $b');
void rejects(void Function() action) {
  try {
    action();
  } on ArgumentError {
    return;
  }
  throw StateError('Se esperaba ArgumentError');
}

Map<String, void Function()> geometryCases() => {
  'racionales normalizados y aritmética exacta': () {
    same(ExactFraction(2, -4), ExactFraction(-1, 2));
    check(ExactFraction(2, 4) == ExactFraction(1, 2), 'igualdad racional');
    check(
      {ExactFraction(2, 4), ExactFraction(1, 2)}.length == 1,
      'hash racional',
    );
    same(ExactFraction(1, 3) + ExactFraction(1, 6), ExactFraction(1, 2));
    same(ExactFraction(1, 3) - ExactFraction(5, 6), ExactFraction(-1, 2));
    same(ExactFraction(-2, 3) * ExactFraction(9, 4), ExactFraction(-3, 2));
    same(ExactFraction(3, 5) / ExactFraction(-9, 10), ExactFraction(-2, 3));
    same(ExactFraction(-1, 2).floor, -1);
    same(ExactFraction(-4, 2).floor, -2);
    check(
      ExactFraction(7, 13).compareTo(ExactFraction(8, 13)) < 0,
      'orden exacto',
    );
    rejects(() => ExactFraction(1, 0));
  },
  'horizontal 1×N sin introducir otras filas': () {
    final trace = path('A1', 'H1', rows: 3, columns: 8);
    same(labels(trace), ['A1', 'B1', 'C1', 'D1', 'E1', 'F1', 'G1', 'H1']);
    same(trace.crossings.length, 7);
    for (final crossing in trace.crossings) {
      check(
        !crossing.isVertex && crossing.contacts.length == 1,
        'cruce ordinario',
      );
      same(crossing.point.y, ExactFraction(1, 2));
      same(crossing.contacts.single.edge.axis, EdgeAxis.vertical);
    }
    same(trace.crossings.first.t, ExactFraction(1, 14));
  },
  'vertical N×1 sin introducir otras columnas': () {
    final trace = path('B1', 'B9', rows: 9, columns: 4);
    same(labels(trace), [for (var y = 1; y <= 9; y++) 'B$y']);
    same(trace.crossings.length, 8);
    for (final crossing in trace.crossings) {
      check(!crossing.isVertex, 'vertical sin vértice');
      same(crossing.point.x, ExactFraction(3, 2));
      same(crossing.contacts.single.edge.axis, EdgeAxis.horizontal);
    }
  },
  'diagonal principal distingue interior de solo esquina': () {
    final trace = path('A1', 'D4');
    same(labels(trace), ['A1', 'B2', 'C3', 'D4']);
    same(trace.crossings.map((event) => event.t).toList(), [
      ExactFraction(1, 6),
      ExactFraction(1, 2),
      ExactFraction(5, 6),
    ]);
    check(
      trace.crossings.every(
        (event) => event.isVertex && event.contacts.length == 4,
      ),
      'cuatro contactos terminales por vértice',
    );
    same(trace.crossings.first.cornerOnly.map((cell) => cell.label).toList(), [
      'A2',
      'B1',
    ]);
  },
  'diagonal secundaria con pendiente negativa': () {
    final trace = path('D1', 'A4');
    same(labels(trace), ['D1', 'C2', 'B3', 'A4']);
    same(
      trace.crossings.first.point,
      LogicalPoint(ExactFraction(3), ExactFraction(1)),
    );
    same(
      trace.crossings.last.point,
      LogicalPoint(ExactFraction(1), ExactFraction(3)),
    );
  },
  'pendiente 1:2 y 2:3 en mapas rectangulares': () {
    // Pendiente = delta de fila / delta de columna; también su recíproca.
    final half = path('A1', 'E3', rows: 3, columns: 7);
    same(labels(half), ['A1', 'B1', 'B2', 'C2', 'D2', 'D3', 'E3']);
    check(
      half.crossings.every((event) => !event.isVertex),
      'pendiente 1/2 sin vértices',
    );
    final steep = path('A1', 'C5', rows: 7, columns: 3);
    same(labels(steep), ['A1', 'A2', 'B2', 'B3', 'B4', 'C4', 'C5']);
    check(
      steep.crossings.every((event) => !event.isVertex),
      'pendiente 2 sin vértices',
    );
    final shallow = path('A1', 'D3', rows: 5, columns: 8);
    same(labels(shallow), ['A1', 'B1', 'B2', 'C2', 'C3', 'D3']);
    same(
      shallow.crossings.first.point,
      LogicalPoint(ExactFraction(1), ExactFraction(5, 6)),
    );
  },
  'vértices múltiples fuera de diagonal de 45 grados': () {
    final trace = path('A1', 'D10', rows: 10, columns: 4);
    same(
      trace.crossings
          .where((crossing) => crossing.isVertex)
          .map((crossing) => crossing.point)
          .toList(),
      [
        LogicalPoint(ExactFraction(1), ExactFraction(2)),
        LogicalPoint(ExactFraction(2), ExactFraction(5)),
        LogicalPoint(ExactFraction(3), ExactFraction(8)),
      ],
    );
    same(trace.segments.length, 10);
    final reciprocal = path('A1', 'J4', rows: 4, columns: 10);
    same(
      reciprocal.crossings
          .where((crossing) => crossing.isVertex)
          .map((crossing) => crossing.point)
          .toList(),
      [
        LogicalPoint(ExactFraction(2), ExactFraction(1)),
        LogicalPoint(ExactFraction(5), ExactFraction(2)),
        LogicalPoint(ExactFraction(8), ExactFraction(3)),
      ],
    );
  },
  'muro cruzado por interior frente a contacto terminal en vértice': () {
    final dims = BoardDimensions.initial;
    final edge = EdgeWall.between(cell('A1'), cell('B1'));
    final walls = const WallLayer.empty().edit([edge], dims, erase: false);
    final cross = path('A1', 'C1', walls: walls).crossings.first;
    check(
      cross.contacts.single.hasWall &&
          cross.contacts.single.kind == ContactKind.edgeInterior,
      'muro cruzado interior',
    );
    final corner = path('A1', 'C3', walls: walls).crossings.first;
    final contact = corner.contacts.singleWhere((contact) => contact.hasWall);
    same(contact.edge.id, edge.id);
    same(contact.kind, ContactKind.vertexEndpoint);
    check(
      corner.contacts.every(
        (contact) => contact.kind == ContactKind.vertexEndpoint,
      ),
      'no inventar cruces interiores en esquina',
    );
  },
  'simetría exhaustiva y orden exacto A→B / B→A en 4×4': () {
    final dimensions = BoardDimensions.initial;
    final walls = const WallLayer.empty().edit(
      [
        for (var x = 1; x < 4; x++)
          for (var y = 0; y < 4; y++)
            EdgeWall(axis: EdgeAxis.vertical, column: x, row: y),
        for (var y = 1; y < 4; y++)
          for (var x = 0; x < 4; x++)
            EdgeWall(axis: EdgeAxis.horizontal, column: x, row: y),
      ],
      dimensions,
      erase: false,
    );
    for (var ay = 0; ay < 4; ay++) {
      for (var ax = 0; ax < 4; ax++) {
        for (var by = 0; by < 4; by++) {
          for (var bx = 0; bx < 4; bx++) {
            final a = CellCoordinate(column: ax, row: ay),
                b = CellCoordinate(column: bx, row: by);
            final forward = path(a.label, b.label, walls: walls),
                reverse = path(b.label, a.label, walls: walls);
            same(labels(forward), labels(reverse).reversed.toList());
            final f = forward.crossings.toList(),
                r = reverse.crossings.toList().reversed.toList();
            same(f.length, r.length);
            for (var i = 0; i < f.length; i++) {
              same(f[i].point, r[i].point);
              check(f[i].t == ExactFraction.one - r[i].t, 'parámetro inverso');
              same(
                f[i].contacts
                    .map((c) => '${c.edge.id}:${c.kind}:${c.hasWall}')
                    .toList(),
                r[i].contacts
                    .map((c) => '${c.edge.id}:${c.kind}:${c.hasWall}')
                    .toList(),
              );
              same(
                (f[i].cornerOnly.map((c) => c.label).toList()..sort()),
                (r[i].cornerOnly.map((c) => c.label).toList()..sort()),
              );
            }
            for (var i = 1; i < forward.events.length; i++) {
              check(
                forward.events[i - 1].t.compareTo(forward.events[i].t) <= 0,
                'eventos ordenados',
              );
            }
          }
        }
      }
    }
  },
  'oráculo independiente recorta interiores en 6×9 para todos los pares': () {
    // Recorte de cada caja abierta: no utiliza los cortes por líneas del motor.
    const rows = 6, columns = 9;
    for (var ay = 0; ay < rows; ay++) {
      for (var ax = 0; ax < columns; ax++) {
        for (var by = 0; by < rows; by++) {
          for (var bx = 0; bx < columns; bx++) {
            final trace = path(
              CellCoordinate(column: ax, row: ay).label,
              CellCoordinate(column: bx, row: by).label,
              rows: rows,
              columns: columns,
            );
            final expected = <String>{};
            for (var y = 0; y < rows; y++) {
              for (var x = 0; x < columns; x++) {
                var low = ExactFraction.zero,
                    high = ExactFraction.one,
                    possible = true;
                for (final (start, delta, min, max) in [
                  (2 * ax + 1, 2 * (bx - ax), 2 * x, 2 * x + 2),
                  (2 * ay + 1, 2 * (by - ay), 2 * y, 2 * y + 2),
                ]) {
                  if (delta == 0) {
                    if (start <= min || start >= max) possible = false;
                    continue;
                  }
                  var entry = ExactFraction(min - start, delta),
                      exit = ExactFraction(max - start, delta);
                  if (entry.compareTo(exit) > 0) {
                    final swap = entry;
                    entry = exit;
                    exit = swap;
                  }
                  if (entry.compareTo(low) > 0) low = entry;
                  if (exit.compareTo(high) < 0) high = exit;
                }
                if (possible && low.compareTo(high) < 0) {
                  expected.add(CellCoordinate(column: x, row: y).label);
                }
              }
            }
            same((labels(trace)..sort()), (expected.toList()..sort()));
            final segments = trace.segments.toList();
            check(
              segments.first.t == ExactFraction.zero &&
                  segments.last.until == ExactFraction.one,
              'cobertura completa',
            );
            for (var i = 1; i < segments.length; i++) {
              check(
                segments[i - 1].until == segments[i].t &&
                    segments[i - 1].exit == segments[i].point,
                'sin huecos',
              );
            }
          }
        }
      }
    }
  },
  'casilla idéntica y coordenadas inválidas explícitas': () {
    final trace = path('B2', 'B2');
    check(
      trace.isDegenerate && trace.events.length == 3 && trace.crossings.isEmpty,
      'punto fijo',
    );
    same(labels(trace), ['B2']);
    same(trace.segments.single.point, trace.segments.single.exit);
    rejects(() => path('E1', 'A1'));
    rejects(() => path('A1', 'A5'));
    rejects(() => path('A1', 'AO40', rows: 40, columns: 40));
    final wrongWalls = const WallLayer.empty().edit(
      [EdgeWall.between(cell('E1'), cell('F1'))],
      BoardDimensions(rows: 4, columns: 8),
      erase: false,
    );
    rejects(() => path('A1', 'B2', walls: wrongWalls));
  },
  '40×40 completo y máximo de eventos acotado': () {
    final diagonal = path('A1', 'AN40', rows: 40, columns: 40);
    same(diagonal.segments.length, 40);
    same(diagonal.crossings.length, 39);
    check(
      diagonal.crossings.every((crossing) => crossing.isVertex),
      'diagonal grande exacta',
    );
    final general = path('A1', 'AN39', rows: 40, columns: 40);
    same(general.segments.length, 78);
    check(general.events.length <= 159, 'cota por filas y columnas');
  },
  'candidatas explícitas independientes sin evaluación de bases': () {
    const geometry = SightGeometry();
    final requests = [
      SightPath(id: 'one', origin: cell('A1'), destination: cell('D4')),
      SightPath(id: 'two', origin: cell('B1'), destination: cell('D4')),
    ];
    final results = geometry.traceCandidates(BoardDimensions.initial, requests);
    same(results.map((r) => r.path.id).toList(), ['one', 'two']);
    same(labels(results.first), labels(path('A1', 'D4')));
    rejects(
      () => geometry.traceCandidates(BoardDimensions.initial, [
        requests.first,
        requests.first,
      ]),
    );
    rejects(
      () => geometry.traceCandidates(BoardDimensions.initial, [
        for (var i = 0; i < 17; i++)
          SightPath(id: '$i', origin: cell('A1'), destination: cell('B2')),
      ]),
    );
  },
};
