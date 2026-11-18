import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/application/board/board_session.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/domain/board/board_dimensions.dart';
import 'package:heroclix_simulator_trainer/domain/board/cell_coordinate.dart';
import 'package:heroclix_simulator_trainer/domain/characters/character.dart';
import 'package:heroclix_simulator_trainer/domain/characters/team.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/edge_wall.dart';
import 'package:heroclix_simulator_trainer/domain/terrain/terrain.dart';

CellCoordinate cell(String text) => CellCoordinate.parse(text);
CharacterDraft character(
  String at, {
  String team = 'team-1',
  Footprint base = Footprint.single,
  String name = 'Figura',
}) => CharacterDraft(
  name: name,
  teamId: team,
  position: cell(at),
  footprint: base,
);
ScenarioDocument sampleDocument() {
  var state = BoardSession.initial()
      .changeDimensions(BoardDimensions(rows: 8, columns: 12))
      .addTeam(name: 'Aliados', color: 0xff81c784, pattern: TeamPattern.dots)
      .createCharacter(character('B2', base: Footprint.square2))
      .createCharacter(character('F7'))
      .createCharacter(
        character('A8', team: 'team-3', name: 'Figura { [ " literal'),
      );
  state = state
      .deleteCharacter('figure-2')
      .paintTerrain([cell('D4')], TerrainType.hindering)
      .editWalls([EdgeWall.between(cell('A1'), cell('B1'))], erase: false);
  state = state.replaceLayers(
    terrain: state.terrain
        .paint([cell('C3')], TerrainType.blocking, state.dimensions)
        .put(
          cell('D4'),
          CellTerrain(type: TerrainType.hindering, elevation: 3),
          state.dimensions,
        ),
    walls: state.walls,
    characters: state.characters,
  );
  return ScenarioDocument(
    id: 's-${'a' * 32}',
    name: 'Mi escenario',
    rulesVersion: '2026-07-01',
    createdAt: DateTime.utc(2026, 11, 14),
    modifiedAt: DateTime.utc(2026, 11, 14, 1),
    session: state,
  );
}

void main() {
  const codec = ScenarioCodec();
  test(
    'JSON legible versionado, ida/vuelta completa, determinista y sin cámara',
    () {
      final document = sampleDocument(), json = codec.encode(sampleDocument());
      final decoded = codec.decode(json);
      expect(json, contains('"schemaVersion": 4'));
      expect(json, contains('\n  "metadata"'));
      expect(codec.encode(decoded), json);
      expect(decoded.session.dimensions.rows, 8);
      expect(decoded.session.dimensions.columns, 12);
      expect(decoded.session.studyConflicts, {cell('C3')});
      expect(decoded.session.terrain.at(cell('D4')).elevation, 3);
      expect(
        decoded.session.characters.byId('figure-1')!.footprint,
        Footprint.square2,
      );
      expect(decoded.session.nextCharacter, 4);
      expect(decoded.session.teams.last.name, isNotEmpty);
      expect(decoded.session.selectedCell, isNull);
      expect(decoded.session.viewport, isNull);
      expect(codec.encode(document.copyAs('Copia')), isNot(json));
      expect(document.copyAs('Copia').id, isNot(document.id));
    },
  );
  test(
    'cada validación corrupta se rechaza sin modificar el documento original',
    () {
      final original = sampleDocument(), text = codec.encode(sampleDocument());
      Map<String, dynamic> fresh() => jsonDecode(text) as Map<String, dynamic>;
      final mutations = <void Function(Map<String, dynamic>)>[
        (m) => m['schemaVersion'] = 999,
        (m) => m['schemaVersion'] = 1.0,
        (m) => m['extra'] = true,
        (m) => m['metadata']['id'] = '../../archivo',
        (m) => m['metadata']['name'] = ' ',
        (m) => m['metadata']['name'] = 'x' * 81,
        (m) => m['metadata']['rulesVersion'] = 'x' * 41,
        (m) => m['metadata']['createdAt'] = '2026-13-99T00:00:00.000Z',
        (m) => m['metadata']['modifiedAt'] = '2020-01-01T00:00:00.000Z',
        (m) => m['board']['rows'] = 41,
        (m) => m['board']['columns'] = 0,
        (m) => m['board']['rows'] = 4.0,
        (m) => m['teams'].add(m['teams'][0]),
        (m) => m['teams'][0]['color'] = 0,
        (m) => m['teams'][0]['pattern'] = 'inventado',
        (m) => m['teams'][0]['code'] = 'T99',
        (m) => m['characters'].add(m['characters'][0]),
        (m) => m['characters'][1]['position'] = 'B2',
        (m) => m['characters'][0]['teamId'] = 'team-99',
        (m) => m['characters'][0]['id'] = '../figure-1',
        (m) => m['characters'][0]['label'] = 'Z',
        (m) => m['characters'][0]['position'] = 'AN40',
        (m) => m['characters'][0]['footprint']['width'] = 40,
        (m) => m['characters'][0]['speed'] = -1,
        (m) => m['characters'][0]['range'] = 100,
        (m) => m['counters']['nextCharacter'] = 1,
        (m) => m['counters']['nextTeam'] = 1,
        (m) => m['counters']['nextCharacter'] = 100000000000,
        (m) => m['walls'].add(m['walls'][0]),
        (m) => m['walls'][0]['id'] = 'h:0:0',
        (m) => m['terrain'].add(m['terrain'][0]),
        (m) => m['terrain'][0]['elevation'] = 100,
      ];
      for (final mutate in mutations) {
        final map = fresh();
        mutate(map);
        expect(() => codec.decode(jsonEncode(map)), throwsFormatException);
      }
      expect(codec.encode(original), text);
    },
  );
  test(
    'tamaño, profundidad, tipos y complejidad limitados antes de interpretar',
    () {
      for (final text in [
        'x' * (ScenarioCodec.maxBytes + 1),
        '${'[' * 20}0${']' * 20}',
        '{',
        'null',
        '[]',
        '[${List.filled(20001, '[]').join(',')}]',
      ]) {
        expect(() => codec.decode(text), throwsFormatException);
      }
    },
  );
  test(
    'mapa máximo de 1600 figuras y 3120 muros cabe y se restaura bajo límites',
    () {
      var state = BoardSession.initial().changeDimensions(
        BoardDimensions(rows: 40, columns: 40),
      );
      final cells = <CellCoordinate>[], walls = <EdgeWall>[];
      for (var row = 0; row < 40; row++) {
        for (var col = 0; col < 40; col++) {
          final at = CellCoordinate(column: col, row: row);
          cells.add(at);
          state = state.createCharacter(
            CharacterDraft(name: '界' * 80, teamId: 'team-1', position: at),
          );
          if (col < 39) {
            walls.add(
              EdgeWall.between(at, CellCoordinate(column: col + 1, row: row)),
            );
          }
          if (row < 39) {
            walls.add(
              EdgeWall.between(at, CellCoordinate(column: col, row: row + 1)),
            );
          }
        }
      }
      state = state
          .paintTerrain(cells, TerrainType.hindering)
          .editWalls(walls, erase: false);
      final text = codec.encode(ScenarioDocument.fresh(session: state));
      expect(
        utf8.encode(text).length,
        lessThanOrEqualTo(ScenarioCodec.maxBytes),
      );
      final decoded = codec.decode(text);
      expect(decoded.session.characters.length, 1600);
      expect(decoded.session.walls.edges.length, 3120);
      expect(codec.encode(decoded), text);
    },
  );
}
