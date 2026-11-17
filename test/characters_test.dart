import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_viewport.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character_repository.dart';
import 'package:heroclix_simulator_trainer/domain/characters/team.dart';

CharacterDraft draft(
  String cell, {
  String name = 'Iguales',
  String team = 'team-1',
  Footprint footprint = Footprint.single,
  int speed = 6,
  int range = 4,
}) => CharacterDraft(
  name: name,
  teamId: team,
  position: CellCoordinate.parse(cell),
  footprint: footprint,
  speed: speed,
  range: range,
);

void main() {
  test(
    'alta, edición y borrado conservan identidad y liberan todas las casillas',
    () {
      final before = BoardSession.initial().changeDimensions(
        BoardDimensions(rows: 4, columns: 4),
      );
      var state = before
          .createCharacter(draft('A1'))
          .createCharacter(draft('C1', team: 'team-2'));
      final a = state.characters.all.first;
      final b = state.characters.all.last;
      expect(a.name, b.name);
      expect(a.id, isNot(b.id));
      expect(a.label, 'A');
      expect(b.label, 'B');
      state = state.editCharacter(
        a.id,
        draft('A2', name: 'Editada', team: 'team-2', speed: 0, range: 99),
      );
      final edited = state.characters.byId(a.id)!;
      expect(edited.label, a.label);
      expect(edited.name, 'Editada');
      expect(edited.teamId, 'team-2');
      expect(edited.speed, 0);
      expect(edited.range, 99);
      expect(state.characters.at(CellCoordinate.parse('A1')), isNull);
      expect(before.characters.isEmpty, isTrue);
      state = state.deleteCharacter(a.id);
      expect(state.characters.at(CellCoordinate.parse('A2')), isNull);
      state = state.createCharacter(draft('A2'));
      expect(state.selectedCharacter!.label, 'C');
      expect(state.selectedCharacter!.id, isNot(a.id));
    },
  );
  test('duplicar asigna nueva identidad y preserva los datos del original', () {
    var state = BoardSession.initial()
        .changeDimensions(BoardDimensions(rows: 4, columns: 4))
        .createCharacter(draft('A1', footprint: Footprint.square2));
    final original = state.selectedCharacter!;
    state = state.duplicateCharacter(original.id, CellCoordinate.parse('C3'));
    expect(state.characters.length, 2);
    expect(state.selectedCharacter!.id, isNot(original.id));
    expect(state.selectedCharacter!.label, 'B');
    expect(state.selectedCharacter!.footprint, original.footprint);
    expect(state.characters.byId(original.id), same(original));
    expect(
      () => state.duplicateCharacter(original.id, CellCoordinate.parse('B2')),
      throwsA(isA<PlacementException>()),
    );
  });
  test('movimiento atómico rechaza colisión y fuera, éxito libera origen', () {
    final state = BoardSession.initial()
        .changeDimensions(BoardDimensions(rows: 4, columns: 4))
        .createCharacter(draft('A1'))
        .createCharacter(draft('B1'));
    final a = state.characters.all.first;
    for (final target in ['B1', 'E1', 'A5']) {
      expect(
        () => state.moveCharacter(a.id, CellCoordinate.parse(target)),
        throwsA(isA<PlacementException>()),
      );
      expect(state.characters.byId(a.id), same(a));
      expect(state.characters.at(CellCoordinate.parse('A1')), same(a));
    }
    final moved = state.moveCharacter(a.id, CellCoordinate.parse('C2'));
    expect(moved.characters.at(CellCoordinate.parse('A1')), isNull);
    expect(moved.characters.at(CellCoordinate.parse('C2'))!.id, a.id);
  });
  test(
    'base 2×2 valida sus cuatro celdas, bordes y movimiento sobre sí misma',
    () {
      final state = BoardSession.initial()
          .changeDimensions(BoardDimensions(rows: 4, columns: 4))
          .createCharacter(draft('A1', footprint: Footprint.square2));
      final a = state.selectedCharacter!;
      expect(a.occupiedCells.map((cell) => cell.label), [
        'A1',
        'B1',
        'A2',
        'B2',
      ]);
      for (final cell in ['A1', 'B1', 'A2', 'B2']) {
        expect(
          () => state.createCharacter(draft(cell)),
          throwsA(isA<PlacementException>()),
        );
      }
      for (final cell in ['D3', 'C4', 'D4']) {
        expect(
          () => BoardSession.initial()
              .changeDimensions(BoardDimensions(rows: 4, columns: 4))
              .createCharacter(draft(cell, footprint: Footprint.square2)),
          throwsA(isA<PlacementException>()),
        );
      }
      final moved = state.moveCharacter(a.id, CellCoordinate.parse('B2'));
      expect(moved.characters.at(CellCoordinate.parse('A1')), isNull);
      expect(moved.characters.at(CellCoordinate.parse('C3'))!.id, a.id);
      expect(moved.deleteCharacter(a.id).characters.isEmpty, isTrue);
    },
  );
  test('editar base rechazada y reducir tablero nunca pierde figuras', () {
    final state = BoardSession.initial()
        .changeDimensions(BoardDimensions(rows: 4, columns: 4))
        .createCharacter(draft('C3'))
        .createCharacter(draft('D4'));
    final a = state.characters.all.first;
    expect(
      () =>
          state.editCharacter(a.id, draft('C3', footprint: Footprint.square2)),
      throwsA(isA<PlacementException>()),
    );
    expect(
      () => state.changeDimensions(BoardDimensions(rows: 3, columns: 3)),
      throwsA(isA<PlacementException>()),
    );
    final grown = state.changeDimensions(BoardDimensions(rows: 8, columns: 12));
    expect(grown.characters, same(state.characters));
    expect(state.characters.length, 2);
    expect(state.characters.byId(a.id), same(a));
  });
  test(
    'equipos tienen código y patrón, nuevos equipos elegibles y validados',
    () {
      var state = BoardSession.initial().changeDimensions(
        BoardDimensions(rows: 4, columns: 4),
      );
      expect(state.teams.map((team) => team.code), ['T1', 'T2']);
      expect(state.teams[0].pattern, isNot(state.teams[1].pattern));
      state = state.addTeam(
        name: 'Verde',
        color: 0xff81c784,
        pattern: TeamPattern.dots,
      );
      final team = state.teams.last;
      state = state.createCharacter(draft('A1', team: team.id));
      expect(state.selectedCharacter!.teamId, team.id);
      expect(team.code, 'T3');
      expect(() => state.teams.add(Team.blue), throwsUnsupportedError);
      expect(
        () => state.addTeam(
          name: ' verde ',
          color: 0xff81c784,
          pattern: TeamPattern.solid,
        ),
        throwsA(isA<PlacementException>()),
      );
      expect(
        () => state.createCharacter(draft('B1', team: 'missing')),
        throwsA(isA<PlacementException>()),
      );
      expect(
        () => Team(
          id: '',
          code: 'X',
          name: 'X',
          color: 0xff81c784,
          pattern: TeamPattern.solid,
        ),
        throwsArgumentError,
      );
    },
  );
  test('nombre, velocidad y alcance validados, huellas extensibles', () {
    expect(() => draft('A1', name: '  '), throwsArgumentError);
    for (final number in [-1, 100]) {
      expect(() => draft('A1', speed: number), throwsRangeError);
      expect(() => draft('A1', range: number), throwsRangeError);
    }
    final footprint = Footprint.rectangle(width: 3, height: 1);
    expect(footprint.cellsAt(CellCoordinate.parse('A1')).length, 3);
    expect(() => Footprint.rectangle(width: 0, height: 1), throwsRangeError);
  });
  test(
    'selección por celda ocupada, zoom, pan y orientación conservan mundo',
    () {
      var state = BoardSession.initial()
          .changeDimensions(BoardDimensions(rows: 4, columns: 4))
          .resizeViewport(ViewportSize(400, 800))
          .createCharacter(draft('B2', footprint: Footprint.square2));
      final repository = state.characters;
      final figure = state.selectedCharacter!;
      state = state.toggleCell(CellCoordinate.parse('C3'));
      expect(state.selectedCharacterId, figure.id);
      state = state
          .zoom(2)
          .withCamera(BoardCamera(scale: 2, offsetX: -100, offsetY: 30))
          .resizeViewport(ViewportSize(800, 400));
      expect(state.characters, same(repository));
      expect(state.selectedCharacterId, figure.id);
      expect(state.selectedCharacter!.position.label, 'B2');
      state = state.toggleCell(CellCoordinate.parse('A1'));
      expect(state.selectedCharacterId, isNull);
      expect(state.selectedCell!.label, 'A1');
    },
  );
  test('busca sitio para duplicar y detecta tablero lleno sin mutar', () {
    var state = BoardSession.initial().changeDimensions(
      BoardDimensions(rows: 4, columns: 4),
    );
    for (final cell in ['A1', 'C1', 'A3', 'C3']) {
      state = state.createCharacter(draft(cell, footprint: Footprint.square2));
    }
    expect(state.firstFreeCell(Footprint.single), isNull);
    expect(state.firstFreeCell(Footprint.square2), isNull);
    expect(
      state.characters
          .validatePlacement(
            dimensions: state.dimensions,
            position: null,
            footprint: Footprint.single,
          )
          .isValid,
      isFalse,
    );
  });
}
