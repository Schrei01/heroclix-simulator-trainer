import 'dart:convert';

import '../board/board_session.dart';
import '../board/layer_codec.dart';
import '../../domain/board/board_dimensions.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/characters/character.dart';
import '../../domain/characters/character_repository.dart';
import '../../domain/characters/team.dart';
import 'scenario_document.dart';

final class ScenarioCodec {
  const ScenarioCodec();
  static const maxBytes = 2 * 1024 * 1024;
  Map<String, Object?> toMap(ScenarioDocument doc) {
    final state = doc.session, layers = const LayerCodec().encode(doc.session);
    final teams = state.teams.toList()..sort((a, b) => a.id.compareTo(b.id));
    final figures = state.characters.all.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return {
      'schemaVersion': ScenarioDocument.schemaVersion,
      'metadata': {
        'id': doc.id,
        'name': doc.name,
        'rulesVersion': doc.rulesVersion,
        'createdAt': doc.createdAt.toIso8601String(),
        'modifiedAt': doc.modifiedAt.toIso8601String(),
      },
      'board': {
        'rows': state.dimensions.rows,
        'columns': state.dimensions.columns,
      },
      'teams': [
        for (final team in teams)
          {
            'id': team.id,
            'code': team.code,
            'name': team.name,
            'color': team.color,
            'pattern': team.pattern.name,
          },
      ],
      'characters': [
        for (final figure in figures)
          {
            'id': figure.id,
            'label': figure.label,
            'name': figure.name,
            'teamId': figure.teamId,
            'position': figure.position.label,
            'footprint': {
              'width': figure.footprint.width,
              'height': figure.footprint.height,
            },
            'speed': figure.speed,
            'range': figure.range,
          },
      ],
      'terrain': layers['terrain'],
      'walls': layers['walls'],
      'counters': {
        'nextCharacter': state.nextCharacter,
        'nextTeam': state.nextTeam,
      },
    };
  }

  String encode(ScenarioDocument document) {
    final result = const JsonEncoder.withIndent('  ').convert(toMap(document));
    if (utf8.encode(result).length > maxBytes) {
      throw const FormatException('El escenario supera el límite de 2 MiB.');
    }
    return result;
  }

  static Object? parseBounded(String source, {int limit = maxBytes}) {
    if (source.length > limit || utf8.encode(source).length > limit) {
      throw const FormatException(
        'Archivo demasiado grande. Máximo 2 MiB por escenario.',
      );
    }
    var depth = 0, containers = 0;
    bool quoted = false, escaped = false;
    for (final unit in source.codeUnits) {
      if (quoted) {
        if (escaped) {
          escaped = false;
        } else if (unit == 92) {
          escaped = true;
        } else if (unit == 34) {
          quoted = false;
        }
      } else if (unit == 34) {
        quoted = true;
      } else if (unit == 123 || unit == 91) {
        depth++;
        containers++;
        if (depth > 16 || containers > 20000) {
          throw const FormatException('JSON demasiado anidado o complejo.');
        }
      } else if (unit == 125 || unit == 93) {
        depth--;
      }
    }
    return jsonDecode(source);
  }

  ScenarioDocument decode(String source) => fromMap(parseBounded(source));
  static Map<String, dynamic> object(Object? value, Set<String> keys) {
    if (value is! Map ||
        value.length != keys.length ||
        value.keys.any((key) => key is! String || !keys.contains(key))) {
      throw const FormatException('Campos desconocidos o incompletos.');
    }
    return Map<String, dynamic>.from(value);
  }

  static String text(Object? value, int max) {
    if (value is! String ||
        value.isEmpty ||
        value.length > max ||
        value.trim() != value) {
      throw const FormatException('Texto inválido o demasiado largo.');
    }
    return value;
  }

  static int integer(Object? value, int min, int max) {
    if (value is! int || value < min || value > max) {
      throw const FormatException('Número entero fuera de límites.');
    }
    return value;
  }

  ScenarioDocument fromMap(Object? source) {
    try {
      final root = object(source, {
        'schemaVersion',
        'metadata',
        'board',
        'teams',
        'characters',
        'terrain',
        'walls',
        'counters',
      });
      if (root['schemaVersion'] is! int ||
          root['schemaVersion'] != ScenarioDocument.schemaVersion) {
        throw const FormatException(
          'Versión de escenario no compatible. El archivo se conserva sin modificar.',
        );
      }
      final meta = object(root['metadata'], {
        'id',
        'name',
        'rulesVersion',
        'createdAt',
        'modifiedAt',
      });
      DateTime date(Object? value) {
        final string = text(value, 32), date = DateTime.tryParse(string);
        if (date == null || !date.isUtc || date.toIso8601String() != string) {
          throw const FormatException('Fecha UTC inválida.');
        }
        return date;
      }

      final board = object(root['board'], {'rows', 'columns'});
      final dimensions = BoardDimensions(
        rows: integer(board['rows'], 2, 40),
        columns: integer(board['columns'], 2, 40),
      );
      final rawTeams = root['teams'], rawFigures = root['characters'];
      if (rawTeams is! List ||
          rawTeams.isEmpty ||
          rawTeams.length > 32 ||
          rawFigures is! List ||
          rawFigures.length > dimensions.cellCount) {
        throw const FormatException('Cantidad de equipos o figuras inválida.');
      }
      final teams = <Team>[], teamIds = <String>{}, teamNames = <String>{};
      var maxTeam = 0, maxFigure = 0;
      for (final value in rawTeams) {
        final data = object(value, {'id', 'code', 'name', 'color', 'pattern'});
        final id = text(data['id'], 32),
            match = RegExp(r'^team-([1-9][0-9]{0,8})$').firstMatch(id);
        if (match == null || !teamIds.add(id)) {
          throw const FormatException('ID de equipo inválido o duplicado.');
        }
        final number = int.parse(match.group(1)!);
        if (number > maxTeam) maxTeam = number;
        final name = text(data['name'], 40),
            pattern = TeamPattern.values
                .where((p) => p.name == data['pattern'])
                .firstOrNull;
        if (data['code'] != 'T$number' ||
            pattern == null ||
            !teamNames.add(name.toLowerCase())) {
          throw const FormatException(
            'Código, nombre o patrón de equipo inválido.',
          );
        }
        teams.add(
          Team(
            id: id,
            code: data['code'] as String,
            name: name,
            color: integer(data['color'], 0xff000000, 0xffffffff),
            pattern: pattern,
          ),
        );
      }
      var characters = const CharacterRepository.empty();
      for (final value in rawFigures) {
        final data = object(value, {
          'id',
          'label',
          'name',
          'teamId',
          'position',
          'footprint',
          'speed',
          'range',
        });
        final id = text(data['id'], 32),
            match = RegExp(r'^figure-([1-9][0-9]{0,8})$').firstMatch(id);
        if (match == null) {
          throw const FormatException('ID de figura inválido.');
        }
        final number = int.parse(match.group(1)!);
        if (number > maxFigure) maxFigure = number;
        if (data['label'] != CellCoordinate.columnLabel(number - 1) ||
            !teamIds.contains(data['teamId'])) {
          throw const FormatException('Etiqueta o equipo de figura inválido.');
        }
        final footprint = object(data['footprint'], {'width', 'height'});
        final figure = Character(
          id: id,
          label: data['label'] as String,
          data: CharacterDraft(
            name: text(data['name'], 80),
            teamId: data['teamId'] as String,
            position: CellCoordinate.parse(text(data['position'], 12)),
            footprint: Footprint.rectangle(
              width: integer(footprint['width'], 1, 40),
              height: integer(footprint['height'], 1, 40),
            ),
            speed: integer(data['speed'], 0, 99),
            range: integer(data['range'], 0, 99),
          ),
        );
        characters = characters.add(figure, dimensions);
      }
      final layers = const LayerCodec().decode({
        'layerSchemaVersion': 1,
        'rows': dimensions.rows,
        'columns': dimensions.columns,
        'terrain': root['terrain'],
        'walls': root['walls'],
      }, dimensions);
      final counters = object(root['counters'], {'nextCharacter', 'nextTeam'});
      final session = BoardSession.restore(
        dimensions: dimensions,
        teams: teams,
        characters: characters,
        terrain: layers.terrain,
        walls: layers.walls,
        nextCharacter: integer(
          counters['nextCharacter'],
          maxFigure + 1,
          1000000000,
        ),
        nextTeam: integer(counters['nextTeam'], maxTeam + 1, 1000000000),
      );
      return ScenarioDocument(
        id: text(meta['id'], 34),
        name: text(meta['name'], 80),
        rulesVersion: text(meta['rulesVersion'], 40),
        createdAt: date(meta['createdAt']),
        modifiedAt: date(meta['modifiedAt']),
        session: session,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Escenario inválido: $error');
    } on PlacementException catch (error) {
      throw FormatException('Escenario inválido: ${error.message}');
    }
  }
}
