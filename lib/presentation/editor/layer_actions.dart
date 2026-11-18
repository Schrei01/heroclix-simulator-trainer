import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/terrain/terrain.dart';
import '../../domain/board/cell_coordinate.dart';
import 'editor_controller.dart';

String terrainName(TerrainType type) => switch (type) {
  TerrainType.clear => 'Despejado',
  TerrainType.hindering => 'Obstaculizado',
  TerrainType.blocking => 'Bloqueado',
  TerrainType.water => 'Agua',
};
String terrainMark(TerrainType type) => switch (type) {
  TerrainType.clear => 'D',
  TerrainType.hindering => 'H ···',
  TerrainType.blocking => 'B ///',
  TerrainType.water => 'A ≈',
};

Future<bool> confirmLayerAction(
  BuildContext context,
  String title,
  String message,
  String action,
  String key,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: ValueKey(key),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

String eraseName(EraseLayer layer) => switch (layer) {
  EraseLayer.all => 'Borrar todo',
  EraseLayer.figures => 'Borrar figura',
  EraseLayer.terrain => 'Borrar terreno',
  EraseLayer.elevation => 'Borrar elevación',
  EraseLayer.transitions => 'Borrar transición',
  EraseLayer.walls => 'Borrar muro',
};

bool hasDeletableContent(BoardSession state, CellCoordinate cell) =>
    state.characters.at(cell) != null ||
    state.terrain.at(cell).type != TerrainType.clear ||
    state.terrain.at(cell).level > 1 ||
    state.terrain.transitions.any(
      (e) => e.firstCell == cell || e.secondCell == cell,
    );

Future<void> deleteAtCell(
  BuildContext context,
  EditorController controller,
  CellCoordinate cell,
) async {
  final state = controller.value;
  final figure = state.characters.at(cell), terrain = state.terrain.at(cell);
  final transitions = state.terrain.transitions
      .where((e) => e.firstCell == cell || e.secondCell == cell)
      .toList();
  if (!hasDeletableContent(state, cell)) return;
  final name = figure != null
      ? 'el personaje ${figure.label}'
      : terrain.type != TerrainType.clear
      ? 'el terreno ${terrainName(terrain.type).toLowerCase()}'
      : terrain.level > 1
      ? 'la elevación E${terrain.level}'
      : 'las transiciones';
  if (!await confirmLayerAction(
    context,
    '¿Borrar $name?',
    'Casilla ${cell.label}. Solo se borra este elemento; puedes recuperarlo con Deshacer.',
    'Borrar',
    'confirm-delete-cell',
  )) {
    return;
  }
  if (!context.mounted) return;
  final error = controller.attempt((s) {
    if (figure != null) return s.deleteCharacter(figure.id);
    if (terrain.type != TerrainType.clear) {
      return s.paintTerrain([cell], TerrainType.clear);
    }
    if (terrain.level > 1) return s.paintElevation([cell], 1);
    for (final edge in transitions) {
      s = s.setTransition(edge, remove: true);
    }
    return s;
  });
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

Future<void> commitLayerDraft(
  BuildContext context,
  EditorController controller,
) async {
  final draft = controller.draft.value;
  if (draft == null) return;
  final erasingCells =
      draft.tool == EditorTool.erase &&
      (draft.eraseLayer == EraseLayer.all ||
          draft.eraseLayer == EraseLayer.terrain ||
          draft.eraseLayer == EraseLayer.elevation);
  if (draft.tool == EditorTool.terrain || erasingCells) {
    if (draft.cells.isEmpty) {
      controller.cancelDraft();
      return;
    }
  } else if (draft.tool == EditorTool.erase &&
      draft.eraseLayer == EraseLayer.figures) {
    if (draft.figureId == null) {
      controller.cancelDraft();
      return;
    }
    if (!await confirmLayerAction(
      context,
      '¿Eliminar figura?',
      'Solo se elimina la figura. Terreno, elevación y muros se conservan. Puedes recuperarla con Deshacer.',
      'Eliminar',
      'confirm-erase-figure',
    )) {
      controller.cancelDraft();
      return;
    }
  } else if (draft.edges.isEmpty) {
    controller.cancelDraft();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Toca cerca de un borde interno. Los bordes externos no admiten muros ni transiciones.',
          ),
        ),
      );
    }
    return;
  }
  if (!context.mounted || controller.draft.value != draft) return;
  final error = controller.attempt((session) {
    if (draft.tool == EditorTool.terrain) {
      if (draft.brush == TerrainBrush.elevated) {
        return session.raiseElevations(draft.cells);
      }
      return session.paintTerrain(draft.cells, draft.type);
    }
    if (draft.tool == EditorTool.erase) {
      switch (draft.eraseLayer) {
        case EraseLayer.all:
          return session.eraseCells(draft.cells);
        case EraseLayer.figures:
          return session.deleteCharacter(draft.figureId!);
        case EraseLayer.terrain:
          return session.paintTerrain(draft.cells, TerrainType.clear);
        case EraseLayer.elevation:
          return session.paintElevation(draft.cells, 1);
        case EraseLayer.transitions:
          for (final edge in draft.edges) {
            session = session.setTransition(edge, remove: true);
          }
          return session;
        case EraseLayer.walls:
          return session.editWalls(draft.edges, erase: true);
      }
    }
    return session.editWalls(draft.edges, erase: draft.eraseWalls);
  });
  controller.cancelDraft();
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

Future<void> clearLayer(
  BuildContext context,
  EditorController controller,
  String layer,
) async {
  final confirmed = await confirmLayerAction(
    context,
    '¿Limpiar solo $layer?',
    layer == 'terreno'
        ? 'Se limpian los tipos de terreno. Alturas, transiciones, figuras y muros se conservan. Puedes recuperar los tipos con Deshacer.'
        : 'Se elimina el contenido de esta capa y se conservan las otras. Puedes recuperarlo con Deshacer.',
    'Limpiar',
    'confirm-clear-layer',
  );
  if (!confirmed) return;
  controller.cancelDraft();
  controller.attempt(
    (session) => switch (layer) {
      'terreno' => session.clearTerrain(),
      'muros' => session.clearWalls(),
      'figuras' => session.clearCharacters(),
      _ => session,
    },
  );
}

Future<void> showLayerLegend(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    scrollable: true,
    title: const Text('Leyenda y capas'),
    content: const Text(
      'D · Despejado: terreno predeterminado.\nH ··· Obstaculizado: puntos verdes y letra H.\nB /// Bloqueado: rayas ámbar y letra B.\nA ≈ Agua: azul, ondas y letra A; se considera despejado salvo efectos específicos (§16.6).\n|| Muro: línea doble sobre borde interno.\n! Posición incompatible para estudio: figura sobre bloqueado.\n\n'
      'Terreno, elevación, muros y figuras son capas independientes. Despejado limpia solo el tipo de terreno y conserva la altura. Borrar empieza con Borrar todo por trazo y también permite elegir una capa. Retira la figura completa si toca su base; limpia el terreno, altura, muros y transiciones de las casillas recorridas. Dos toques en la misma casilla con Seleccionar preguntan si quieres borrar, en ese orden de prioridad: personaje, terreno y elevación.\n\n'
      'En Terrenos, Muros y Borrar, un dedo edita; dos dedos amplían y desplazan. Seleccionar permite pan con un dedo. Cancelar un gesto o añadir otro dedo descarta la edición en curso.\n\n'
      'Elevación: borde rojo y E2/E3… en casillas elevadas sin transición. Transición: triángulo blanco con su nivel en cada casilla conectada, formando un par sobre el borde.\n\n'
      'Los muros externos no se admiten. Consulta Visión o Movimiento para obtener un dictamen del perfil implementado.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  ),
);
