import '../../domain/board/board_dimensions.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/terrain/terrain.dart';
import '../../domain/terrain/edge_wall.dart';
import 'board_session.dart';

/// Fragmento de capas versionado, sin archivos ni importación/exportación en UI.
/// El documento completo del escenario se definirá en 04.
final class LayerCodec {
  const LayerCodec();
  Map<String, Object?> encode(BoardSession session) {
    final terrain = session.terrain.cells.entries.toList()
      ..sort((a, b) {
        final row = a.key.row.compareTo(b.key.row);
        return row != 0 ? row : a.key.column.compareTo(b.key.column);
      });
    final walls = session.walls.edges.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return {
      'layerSchemaVersion': 4,
      'debrisCells': (session.terrain.debrisCells.map((c) => c.label).toList()
        ..sort()),
      'environment': session.terrain.environment.name,
      'indoorCells': (session.terrain.indoorCells.map((c) => c.label).toList()
        ..sort()),
      'rows': session.dimensions.rows,
      'columns': session.dimensions.columns,
      'terrain': [
        for (final entry in terrain)
          {
            'cell': entry.key.label,
            'type': entry.value.type.name,
            'elevation': entry.value.elevation,
          },
      ],
      'walls': [
        for (final edge in walls)
          {
            'id': edge.id,
            'axis': edge.axis.name,
            'column': edge.column,
            'row': edge.row,
          },
      ],
      'transitions': [
        for (final edge
            in session.terrain.transitions.toList()
              ..sort((a, b) => a.id.compareTo(b.id)))
          {'axis': edge.axis.name, 'column': edge.column, 'row': edge.row},
      ],
    };
  }

  ({TerrainLayer terrain, WallLayer walls}) decode(
    Object? input,
    BoardDimensions dimensions,
  ) {
    Map<Object?, Object?> object(Object? value, Set<String> keys) {
      if (value is! Map ||
          value.length != keys.length ||
          value.keys.any((key) => !keys.contains(key))) {
        throw const FormatException('Objeto de capa desconocido o incompleto.');
      }
      return Map<Object?, Object?>.from(value);
    }

    final version = input is Map ? input['layerSchemaVersion'] : null;
    final root = object(input, {
      'layerSchemaVersion',
      'rows',
      'columns',
      'terrain',
      'walls',
      if (version == 2 || version == 3 || version == 4) 'transitions',
      if (version == 3 || version == 4) ...{'environment', 'indoorCells'},
      if (version == 4) 'debrisCells',
    });
    if ((version != 1 && version != 2 && version != 3 && version != 4) ||
        root['layerSchemaVersion'] is! int ||
        root['rows'] is! int ||
        root['columns'] is! int ||
        root['rows'] != dimensions.rows ||
        root['columns'] != dimensions.columns) {
      throw const FormatException(
        'Versión o dimensiones de capas incompatibles.',
      );
    }
    final cells = root['terrain'], edges = root['walls'];
    if (cells is! List ||
        edges is! List ||
        cells.length > dimensions.cellCount ||
        edges.length > 2 * dimensions.cellCount) {
      throw const FormatException(
        'Listas de capas inválidas o demasiado grandes.',
      );
    }
    var terrain = const TerrainLayer.empty();
    final seenCells = <CellCoordinate>{};
    final seenEdges = <String>{};
    final walls = <EdgeWall>[];
    try {
      for (final value in cells) {
        final map = object(value, {'cell', 'type', 'elevation'});
        if (map['cell'] is! String || map['elevation'] is! int) {
          throw const FormatException('Casilla o elevación inválida.');
        }
        final cell = CellCoordinate.parse(map['cell'] as String);
        final type = TerrainType.values
            .where((type) => type.name == map['type'])
            .firstOrNull;
        if (type == null || !seenCells.add(cell)) {
          throw const FormatException('Terreno desconocido o duplicado.');
        }
        final data = CellTerrain(
          type: type,
          elevation: map['elevation'] as int,
        );
        if (data == CellTerrain.clear) {
          throw const FormatException(
            'El terreno predeterminado se omite del fragmento.',
          );
        }
        terrain = terrain.put(cell, data, dimensions);
      }
      for (final value in edges) {
        final map = object(value, {'id', 'axis', 'column', 'row'});
        if (map['column'] is! int || map['row'] is! int) {
          throw const FormatException('Coordenadas de muro inválidas.');
        }
        final axis = EdgeAxis.values
            .where((axis) => axis.name == map['axis'])
            .firstOrNull;
        if (axis == null) {
          throw const FormatException('Eje de muro desconocido.');
        }
        final edge = EdgeWall(
          axis: axis,
          column: map['column'] as int,
          row: map['row'] as int,
        );
        if (edge.id != map['id'] || !seenEdges.add(edge.id)) {
          throw const FormatException('ID de muro no canónico o duplicado.');
        }
        walls.add(edge);
      }
      final wallLayer = const WallLayer.empty().edit(
        walls,
        dimensions,
        erase: false,
      );
      final transitions = version != 1
          ? root['transitions']
          : const <Object?>[];
      if (transitions is! List ||
          transitions.length > dimensions.cellCount * 2) {
        throw const FormatException('Transiciones inválidas.');
      }
      final seenTransitions = <String>{};
      for (final raw in transitions) {
        final data = object(raw, {'axis', 'column', 'row'});
        final axis = EdgeAxis.values
            .where((a) => a.name == data['axis'])
            .firstOrNull;
        if (axis == null || data['column'] is! int || data['row'] is! int) {
          throw const FormatException('Transición inválida.');
        }
        final edge = EdgeWall(
          axis: axis,
          column: data['column'] as int,
          row: data['row'] as int,
        );
        if (!seenTransitions.add(edge.id) || wallLayer.contains(edge)) {
          throw const FormatException('Transición duplicada o sobre un muro.');
        }
        terrain = terrain.setTransition(edge, dimensions, remove: false);
      }
      if (version == 3 || version == 4) {
        final environment = MapEnvironment.values
            .where((v) => v.name == root['environment'])
            .firstOrNull;
        final inside = root['indoorCells'];
        if (environment == null ||
            inside is! List ||
            inside.length > dimensions.cellCount ||
            inside.any((c) => c is! String) ||
            inside.toSet().length != inside.length ||
            (environment == MapEnvironment.indoor && inside.isNotEmpty)) {
          throw const FormatException(
            'Tipo de mapa o casillas Indoor inválidos.',
          );
        }
        final parsed = inside
            .map((c) => CellCoordinate.parse(c as String))
            .toList();
        if (parsed.map((c) => c.label).toSet().length != parsed.length ||
            List.generate(
              parsed.length,
              (i) => parsed[i].label == inside[i],
            ).any((v) => !v)) {
          throw const FormatException(
            'Casillas Indoor no canónicas o duplicadas.',
          );
        }
        terrain = terrain
            .setEnvironment(environment)
            .paintIndoor(parsed, dimensions);
      }
      if (version == 4) {
        final raw = root['debrisCells'];
        if (raw is! List ||
            raw.length > dimensions.cellCount ||
            raw.any((c) => c is! String)) {
          throw const FormatException('Escombros inválidos.');
        }
        final parsed = raw
            .map((c) => CellCoordinate.parse(c as String))
            .toList();
        if (parsed.toSet().length != raw.length ||
            List.generate(
              raw.length,
              (i) => parsed[i].label != raw[i],
            ).any((v) => v)) {
          throw const FormatException('Escombros duplicados o no canónicos.');
        }
        terrain = terrain.withDebris(parsed, dimensions);
      }
      return (terrain: terrain, walls: wallLayer);
    } on ArgumentError catch (error) {
      throw FormatException('Capa inválida: $error');
    }
  }
}
