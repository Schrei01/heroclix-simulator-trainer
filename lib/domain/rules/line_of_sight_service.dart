import '../board/cell_coordinate.dart';
import '../characters/character.dart';
import '../characters/vision_ability.dart';
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
        snapshot.terrain.transitions.any(
          (e) =>
              !e.isInternal(snapshot.dimensions) || snapshot.walls.contains(e),
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
    final abilities =
        context.laboratoryAbilities ?? source?.abilities ?? <VisionAbility>{};
    if (target?.abilities.contains(VisionAbility.other) == true) {
      unsupported(
        'El destino declara otra excepción sin modelar.',
        VisionRule.powers,
        figures: [target!.id],
      );
    }
    bool ignores(VisionAbility a) => abilities.contains(a);
    for (final a in abilities.where((a) => !a.supported)) {
      unsupported('Capacidad sin soporte: ${a.label}.', abilityRule(a));
    }
    for (final f in [source, target].whereType<Character>()) {
      if (f.size != FigureSize.normal) {
        unsupported(
          'El tamaño ${f.size.label} de ${f.label} requiere excepciones no implementadas.',
          VisionRule.size,
          figures: [f.id],
        );
      }
    }
    if (context.laboratoryAbilities != null) {
      observations.add(
        VisionObservation(
          effect: VisionEffect.none,
          contributes: false,
          description: 'HIPÓTESIS de laboratorio: se sustituyen temporalmente las capacidades del origen; la ficha no cambia.',
          rules: [VisionRule.limit],
        ),
      );
    }
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
    final involved = {
      for (final cell in relevant)
        if (occupants[cell] != null) occupants[cell]!.id,
    };
    for (final id in involved) {
      final figure = identities[id]!;
      if (!figure.footprint.isSupported) {
        unsupported(
          'La base ${figure.footprint.label} de ${figure.label} no es un formato implementado.',
          VisionRule.multiBase,
          figures: [id],
          cells: identities[id]!.occupiedCells,
        );
      }
      if (figure.size != FigureSize.giant &&
          figure.size != FigureSize.colossal &&
          figure.occupiedCells
                  .map((c) => snapshot.terrain.at(c).level)
                  .toSet()
                  .length >
              1) {
        unsupported(
          'La base normal de ${figure.label} ocupa niveles distintos.',
          VisionRule.baseElevation,
          figures: [id],
          cells: figure.occupiedCells,
        );
      }
    }
    if (origin.cell == destination.cell &&
        snapshot.terrain.at(origin.cell).type == TerrainType.hindering &&
        !ignores(VisionAbility.hindering)) {
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
    final sourceLevel = snapshot.terrain.at(origin.cell).level;
    final targetLevel = snapshot.terrain.at(destination.cell).level;
    final different = sourceLevel != targetLevel;
    final low = sourceLevel < targetLevel ? sourceLevel : targetLevel;
    observations.add(
      VisionObservation(
        effect: VisionEffect.none,
        contributes: false,
        description:
            'Elevaciones: origen $sourceLevel, destino $targetLevel. ${different ? 'Se evalúa entre niveles distintos; solo el H de destino obstaculiza.' : 'Se evalúa en el mismo nivel.'}',
        rules: [VisionRule.elevation, if (different) VisionRule.rim],
      ),
    );
    List<EdgeWall> activeWalls(GridCrossing event, {CellCoordinate? side}) {
      final active = <EdgeWall>[];
      for (final contact in event.contacts) {
        if (!contact.hasWall ||
            (side != null && !_borders(contact.edge, side))) {
          continue;
        }
        final edge = contact.edge;
        final first = snapshot.terrain.at(edge.firstCell).level,
            second = snapshot.terrain.at(edge.secondCell).level;
        final bottom = first < second ? first : second,
            top = first > second ? first : second;
        final applicable = different
            ? bottom <= low && top >= low
            : top >= sourceLevel;
        if (applicable && !ignores(VisionAbility.blocking)) {
          active.add(edge);
        } else {
          observations.add(
            VisionObservation(
              effect: VisionEffect.none,
              contributes: false,
              description:
                  'Muro ${edge.id}: ${applicable ? 'se ignora por IT Bloqueado' : 'fuera del nivel relevante'}; ocupa niveles $bottom a $top.',
              rules: [
                VisionRule.wallElevation,
                if (applicable) VisionRule.improvedBlocking,
              ],
              edges: [edge],
            ),
          );
        }
      }
      return active;
    }

    VisionObservation inspectCell(
      CellCoordinate cell,
      int index, {
      bool side = false,
    }) {
      final terrain = snapshot.terrain.at(cell), figure = occupants[cell];
      final atSource = cell == origin.cell;
      final atTarget = cell == destination.cell;
      final level = terrain.level;
      final endpointFigure =
          figure != null &&
          (figure.id == sourceFigure.id || figure.id == target?.id);
      final figureRelevant = different
          ? figure?.size == FigureSize.giant ||
                figure?.size == FigureSize.colossal
          : level >= sourceLevel && figure?.size != FigureSize.tiny;
      final rawFigure = figure != null && !endpointFigure && figureRelevant;
      final blocksFigure = rawFigure && !ignores(VisionAbility.characters);
      final rawHinder =
          terrain.type == TerrainType.hindering &&
          !atSource &&
          (different ? atTarget : level >= sourceLevel);
      final hinder = rawHinder && !ignores(VisionAbility.hindering);
      final rawBlocking =
          terrain.type == TerrainType.blocking &&
          (different ? level == low : level >= sourceLevel);
      final terrainBlocks = rawBlocking && !ignores(VisionAbility.blocking);
      final rawElevation = different
          ? !atSource && !atTarget && level > low
          : level > sourceLevel;
      final elevationBlocks = rawElevation && !ignores(VisionAbility.elevated);
      final block = terrainBlocks || blocksFigure || elevationBlocks;
      final effect = block
          ? VisionEffect.blocking
          : hinder
          ? VisionEffect.hindering
          : VisionEffect.none;
      final reasons = <String>[
        'nivel $level',
        if (snapshot.terrain.isIndoor(cell))
          'Indoor: el límite amarillo no es un muro',
        if (elevationBlocks) 'terreno elevado bloquea',
        if (rawElevation && !elevationBlocks)
          'elevación ignorada por IT Elevación',
        if (terrainBlocks) 'terreno bloqueado',
        if (rawBlocking && !terrainBlocks)
          'bloqueado ignorado por IT Bloqueado',
        if (rawHinder && !hinder) 'obstaculizado ignorado por IT Obstaculizado',
        if (hinder) 'terreno obstaculizado',
        if (snapshot.terrain.debrisCells.contains(cell))
          'escombros (debris): obstaculizado',
        if (terrain.type == TerrainType.water) 'agua: se considera despejado',
        if (terrain.type == TerrainType.hindering && atSource)
          'obstaculizado de origen excluido',
        if (blocksFigure)
          'figura ${figure.label} (${figure.teamId == sourceFigure.teamId ? 'mismo equipo' : 'otro equipo'})',
        if (endpointFigure) 'figura de extremo excluida como obstáculo',
        if (rawFigure && !blocksFigure) 'figura ignorada por IT Personajes',
        if (figure != null && !endpointFigure && !figureRelevant)
          'figura fuera de la restricción de altura/tamaño de esta línea',
      ];
      return VisionObservation(
        effect: effect,
        eventIndex: index,
        contributes: !side,
        description:
            '${side ? 'Lado' : 'Casilla'} ${cell.label}: ${reasons.isEmpty ? 'sin restricción' : reasons.join('; ')}.',
        rules: [
          VisionRule.center,
          if (snapshot.terrain.isIndoor(cell)) VisionRule.environment,
          VisionRule.elevation,
          if (rawElevation && !elevationBlocks) VisionRule.improvedElevated,
          if (rawBlocking && !terrainBlocks) VisionRule.improvedBlocking,
          if (rawHinder && !hinder) VisionRule.improvedHindering,
          if (rawFigure && !blocksFigure) VisionRule.improvedCharacters,
          if (terrain.type == TerrainType.hindering) VisionRule.hindering,
          if (snapshot.terrain.debrisCells.contains(cell)) VisionRule.debris,
          if (terrain.type == TerrainType.blocking) VisionRule.blocking,
          if (terrain.type == TerrainType.water) VisionRule.water,
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
        final walls = activeWalls(event);
        observations.add(
          VisionObservation(
            effect: walls.isEmpty ? VisionEffect.none : VisionEffect.blocking,
            description: walls.isEmpty
                ? 'Borde ${event.contacts.single.edge.id}: ${event.contacts.any((c) => c.hasWall) ? 'el muro no impide esta línea; ver exclusión registrada' : 'sin muro'}.'
                : 'La línea cruza el muro ${walls.single.id} en ${event.point}.',
            rules: [VisionRule.wall],
            eventIndex: index,
            edges: walls,
          ),
        );
      } else if (event is GridCrossing) {
        // §16.8b se aplica al paso exacto por una intersección. La pendiente
        // global no cambia las dos casillas laterales ni sus muros incidentes.
        final sides = <VisionObservation>[];
        for (final cell in event.cornerOnly) {
          final cellObservation = inspectCell(cell, index, side: true);
          final walls = activeWalls(event, side: cell);
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
