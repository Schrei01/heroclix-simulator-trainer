import '../board/cell_coordinate.dart';
import '../characters/character.dart';
import '../geometry/sight_geometry.dart';
import '../terrain/edge_wall.dart';
import '../terrain/terrain.dart';
import 'line_of_sight.dart';

/// Perfil básico documentado en MATRIZ_REGLAS_VISION.md. Una única entrada pública.
final class LineOfSightService implements VisionEvaluator {
  const LineOfSightService();
  @override
  VisionEvaluation evaluate(
    VisionSnapshot snapshot,
    VisionEndpoint origin,
    VisionEndpoint destination,
    VisionContext context,
  ) {
    final observations = <VisionObservation>[];
    GeometricTrace? trace;
    VisionEvaluation result(VisionStatus status) => VisionEvaluation(
      status: status,
      context: context,
      origin: origin,
      destination: destination,
      trace: trace,
      observations: observations,
    );
    void unsupported(
      String description,
      VisionRule rule, {
      Iterable<CellCoordinate> cells = const [],
      Iterable<String> figures = const [],
    }) {
      observations.add(
        VisionObservation(
          effect: VisionEffect.unsupported,
          description: description,
          rules: [VisionRule.limit, if (rule != VisionRule.limit) rule],
          cells: cells,
          figures: figures,
        ),
      );
    }

    if (!snapshot.dimensions.contains(origin.cell) ||
        !snapshot.dimensions.contains(destination.cell)) {
      unsupported('Origen o destino fuera del tablero.', VisionRule.limit);
      return result(VisionStatus.notEvaluated);
    }
    final occupants = <CellCoordinate, Character>{},
        identities = <String, Character>{};
    final sorted = snapshot.characters.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final figure in sorted) {
      if (identities.containsKey(figure.id)) {
        unsupported(
          'Identidad de figura duplicada: ${figure.id}.',
          VisionRule.limit,
        );
      }
      identities[figure.id] = figure;
      for (final cell in figure.occupiedCells) {
        if (!snapshot.dimensions.contains(cell)) {
          unsupported(
            'La figura ${figure.label} sale del tablero.',
            VisionRule.limit,
            figures: [figure.id],
          );
        } else if (occupants.containsKey(cell)) {
          unsupported(
            'Figuras superpuestas en ${cell.label}.',
            VisionRule.occupancy,
            cells: [cell],
          );
        } else {
          occupants[cell] = figure;
          if (snapshot.terrain.at(cell).type == TerrainType.blocking) {
            unsupported(
              'Posición de estudio incompatible: ${figure.label} ocupa bloqueado en ${cell.label}.',
              VisionRule.occupancy,
              cells: [cell],
              figures: [figure.id],
            );
          }
        }
      }
    }
    if (snapshot.terrain.cells.keys.any(
          (cell) => !snapshot.dimensions.contains(cell),
        ) ||
        snapshot.walls.edges.values.any(
          (edge) => !edge.isInternal(snapshot.dimensions),
        )) {
      unsupported('Hay terreno o muros fuera del tablero.', VisionRule.limit);
      return result(VisionStatus.notEvaluated);
    }
    trace = const SightGeometry().trace(
      snapshot.dimensions,
      SightPath(
        id: 'vision',
        origin: origin.cell,
        destination: destination.cell,
      ),
      walls: snapshot.walls,
    );
    observations.insert(
      0,
      VisionObservation(
        effect: VisionEffect.none,
        description:
            'Segmento entre centros ${origin.cell.label} y ${destination.cell.label}.',
        rules: [VisionRule.center],
        contributes: false,
      ),
    );
    Character? resolve(VisionEndpoint endpoint) {
      if (endpoint.figureId == null) return occupants[endpoint.cell];
      final figure = identities[endpoint.figureId];
      if (figure == null || !figure.occupiedCells.contains(endpoint.cell)) {
        unsupported(
          'La figura de un extremo fue eliminada o ya no ocupa la referencia ${endpoint.cell.label}.',
          VisionRule.limit,
          cells: [endpoint.cell],
        );
        return null;
      }
      return figure;
    }

    final source = resolve(origin), target = resolve(destination);
    if (source == null) {
      unsupported(
        'El origen debe estar ocupado por una figura del perfil básico.',
        VisionRule.limit,
        cells: [origin.cell],
      );
    }
    if (context.rulesVersion != VisionContext.supportedVersion) {
      unsupported(
        'Versión ${context.rulesVersion} sin soporte. Esta implementación verifica ${VisionContext.supportedVersion}.',
        VisionRule.limit,
      );
    }
    for (final feature in context.features) {
      unsupported(
        switch (feature) {
          VisionFeature.powersOrSizes =>
            'El caso declara poderes o tamaños que este perfil no evalúa.',
          VisionFeature.remoteSource =>
            'La fuente remota requiere excepciones aún no implementadas.',
          VisionFeature.specialMap =>
            'Las reglas particulares del mapa no están modeladas.',
        },
        switch (feature) {
          VisionFeature.powersOrSizes => VisionRule.powers,
          VisionFeature.remoteSource => VisionRule.hindering,
          VisionFeature.specialMap => VisionRule.specialMap,
        },
      );
    }
    final relevant = {
      for (final pass in trace.segments) pass.cell,
      for (final crossing in trace.crossings) ...crossing.cornerOnly,
    };
    for (final cell in relevant) {
      if (snapshot.terrain.at(cell).elevation != 0) {
        unsupported(
          'Elevación sin soporte en ${cell.label}. El perfil requiere un tablero plano sin alturas modeladas.',
          VisionRule.elevation,
          cells: [cell],
        );
      }
    }
    final involved = {
      for (final cell in relevant)
        if (occupants[cell] != null) occupants[cell]!.id,
    };
    for (final id in involved) {
      if (identities[id]!.footprint != Footprint.single) {
        unsupported(
          'La base múltiple de ${identities[id]!.label} requiere evaluación de referencias aún no implementada.',
          VisionRule.multiBase,
          figures: [id],
          cells: identities[id]!.occupiedCells,
        );
      }
    }
    final dx = (destination.cell.column - origin.cell.column).abs(),
        dy = (destination.cell.row - origin.cell.row).abs();
    if (dx != dy && trace.crossings.any((crossing) => crossing.isVertex)) {
      unsupported(
        'Paso por vértice con pendiente distinta de la diagonal perfecta: caso no resuelto por este perfil.',
        VisionRule.limit,
      );
    }
    if (origin.cell == destination.cell &&
        snapshot.terrain.at(origin.cell).type == TerrainType.hindering) {
      unsupported(
        'Línea a sí mismo sobre obstaculizado: clasificación no implementada; no se asume despejada.',
        VisionRule.self,
        cells: [origin.cell],
      );
    }
    if (observations.any(
      (observation) => observation.effect == VisionEffect.unsupported,
    )) {
      return result(VisionStatus.notEvaluated);
    }
    final sourceFigure = source!;
    VisionObservation inspectCell(
      CellCoordinate cell,
      int index, {
      bool side = false,
    }) {
      final terrain = snapshot.terrain.at(cell), figure = occupants[cell];
      final atSource = cell == origin.cell;
      final endpointFigure =
          figure != null &&
          (figure.id == sourceFigure.id || figure.id == target?.id);
      final blocksFigure = figure != null && !endpointFigure;
      final hinder = terrain.type == TerrainType.hindering && !atSource;
      final block = terrain.type == TerrainType.blocking || blocksFigure;
      final effect = block
          ? VisionEffect.blocking
          : hinder
          ? VisionEffect.hindering
          : VisionEffect.none;
      final reasons = <String>[
        if (terrain.type == TerrainType.blocking) 'terreno bloqueado',
        if (hinder) 'terreno obstaculizado',
        if (terrain.type == TerrainType.hindering && atSource)
          'obstaculizado de origen excluido',
        if (blocksFigure)
          'figura ${figure.label} (${figure.teamId == sourceFigure.teamId ? 'mismo equipo' : 'otro equipo'})',
        if (endpointFigure) 'figura de extremo excluida como obstáculo',
      ];
      return VisionObservation(
        effect: effect,
        eventIndex: index,
        contributes: !side,
        description:
            '${side ? 'Lado' : 'Casilla'} ${cell.label}: ${reasons.isEmpty ? 'sin restricción' : reasons.join('; ')}.',
        rules: [
          VisionRule.center,
          if (terrain.type == TerrainType.hindering) VisionRule.hindering,
          if (terrain.type == TerrainType.blocking) VisionRule.blocking,
          if (figure != null) VisionRule.character,
        ],
        cells: [cell],
        figures: [if (blocksFigure) figure.id],
      );
    }

    for (var index = 0; index < trace.events.length; index++) {
      final event = trace.events[index];
      if (event is CellPass) {
        observations.add(inspectCell(event.cell, index));
      } else if (event is GridCrossing && !event.isVertex) {
        final walls = event.contacts
            .where((contact) => contact.hasWall)
            .map((contact) => contact.edge)
            .toList();
        observations.add(
          VisionObservation(
            effect: walls.isEmpty ? VisionEffect.none : VisionEffect.blocking,
            description: walls.isEmpty
                ? 'Borde ${event.contacts.single.edge.id}: sin muro.'
                : 'La línea cruza el muro ${walls.single.id} en ${event.point}.',
            rules: [VisionRule.wall],
            eventIndex: index,
            edges: walls,
          ),
        );
      } else if (event is GridCrossing) {
        final sides = <VisionObservation>[];
        for (final cell in event.cornerOnly) {
          final cellObservation = inspectCell(cell, index, side: true);
          final walls = event.contacts
              .where(
                (contact) => contact.hasWall && _borders(contact.edge, cell),
              )
              .map((contact) => contact.edge)
              .toList();
          final effect = walls.isNotEmpty
              ? VisionEffect.blocking
              : cellObservation.effect;
          final side = VisionObservation(
            effect: effect,
            contributes: false,
            eventIndex: index,
            description:
                '${cellObservation.description}${walls.isEmpty ? '' : ' Muros de este lado: ${walls.map((edge) => edge.id).join(', ')}.'}',
            rules: [
              ...cellObservation.rules,
              VisionRule.corner,
              if (walls.isNotEmpty) VisionRule.wall,
            ],
            cells: [cell],
            edges: walls,
            figures: cellObservation.figures,
          );
          sides.add(side);
          observations.add(side);
        }
        final effect = sides
            .map((side) => side.effect)
            .reduce((a, b) => a.index < b.index ? a : b);
        final chosen = sides.where((side) => side.effect == effect);
        observations.add(
          VisionObservation(
            effect: effect,
            eventIndex: index,
            description:
                'Vértice ${event.point}: se usa el lado menos restrictivo (${chosen.expand((side) => side.cells).map((cell) => cell.label).join(' / ')}); ${switch (effect) {
                  VisionEffect.none => 'paso sin restricción',
                  VisionEffect.hindering => 'línea obstaculizada',
                  _ => 'ambos lados bloquean',
                }}.',
            rules: [VisionRule.corner],
            cells: chosen.expand((side) => side.cells),
            edges: chosen.expand((side) => side.edges),
            figures: chosen.expand((side) => side.figures),
          ),
        );
      }
    }
    if (origin.cell == destination.cell) {
      observations.add(
        VisionObservation(
          effect: VisionEffect.none,
          description: 'Línea a sí mismo en casilla despejada.',
          rules: [VisionRule.self],
          cells: [origin.cell],
        ),
      );
    }
    final worst = observations
        .where((item) => item.contributes)
        .map((item) => item.effect)
        .fold(VisionEffect.none, (a, b) => a.index > b.index ? a : b);
    return result(switch (worst) {
      VisionEffect.none => VisionStatus.clear,
      VisionEffect.hindering => VisionStatus.hindered,
      VisionEffect.blocking => VisionStatus.blocked,
      VisionEffect.unsupported => VisionStatus.notEvaluated,
    });
  }

  bool _borders(EdgeWall edge, CellCoordinate cell) =>
      edge.axis == EdgeAxis.vertical
      ? edge.row == cell.row &&
            (edge.column == cell.column || edge.column == cell.column + 1)
      : edge.column == cell.column &&
            (edge.row == cell.row || edge.row == cell.row + 1);
}
