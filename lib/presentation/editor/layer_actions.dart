import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/terrain/terrain.dart';
import 'editor_controller.dart';

String terrainName(TerrainType type) => switch (type) {
  TerrainType.clear => 'Despejado',
  TerrainType.hindering => 'Obstaculizado',
  TerrainType.blocking => 'Bloqueado',
};
String terrainMark(TerrainType type) => switch (type) {
  TerrainType.clear => 'D',
  TerrainType.hindering => 'H ···',
  TerrainType.blocking => 'B ///',
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

Future<void> commitLayerDraft(
  BuildContext context,
  EditorController controller,
) async {
  final draft = controller.draft.value;
  if (draft == null) return;
  bool allowStudy = false;
  if (draft.tool == EditorTool.terrain) {
    if (draft.cells.isEmpty) {
      controller.cancelDraft();
      return;
    }
    final conflicts = controller.value.blockingConflicts(
      draft.cells,
      draft.type,
    );
    if (conflicts.isNotEmpty) {
      allowStudy = await confirmLayerAction(
        context,
        'Figuras sobre bloqueado',
        'Casillas ocupadas que quedarían bloqueadas: ${conflicts.length} (${conflicts.take(6).map((cell) => cell.label).join(', ')}). '
            'Las figuras se conservarán. La posición se marcará con ! como incompatible para estudio, sin evaluar reglas.',
        'Conservar para estudio',
        'confirm-study-terrain',
      );
      if (!allowStudy) {
        controller.cancelDraft();
        return;
      }
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
      'Solo se elimina la figura. Terreno y muros se conservan. Deshacer llegará en una etapa posterior.',
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
            'Toca cerca de un borde interno. Los bordes externos no admiten muros.',
          ),
        ),
      );
    }
    return;
  }
  if (!context.mounted || controller.draft.value != draft) return;
  final error = controller.attempt((session) {
    if (draft.tool == EditorTool.terrain) {
      return session.paintTerrain(
        draft.cells,
        draft.type,
        allowStudy: allowStudy,
      );
    }
    if (draft.tool == EditorTool.erase &&
        draft.eraseLayer == EraseLayer.figures) {
      return session.deleteCharacter(draft.figureId!);
    }
    return session.editWalls(
      draft.edges,
      erase: draft.tool == EditorTool.erase || draft.eraseWalls,
    );
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
    'Se eliminará el contenido de esta capa. Las otras capas se conservarán. No hay deshacer en esta versión.',
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
      'D · Despejado: terreno predeterminado.\nH ··· Obstaculizado: puntos verdes y letra H.\nB /// Bloqueado: rayas ámbar y letra B.\n|| Muro: línea doble sobre borde interno.\n! Posición incompatible para estudio: figura sobre bloqueado.\n\n'
      'Terreno, muros y figuras son capas independientes. Pintar despejado cambia solo el terreno; Borrar elemento elimina un muro o una figura según la capa elegida.\n\n'
      'En Terrenos, Muros y Borrar, un dedo edita; dos dedos amplían y desplazan. Seleccionar permite pan con un dedo. Cancelar un gesto o añadir otro dedo descarta la edición en curso.\n\n'
      'Los muros externos no se admiten. No se evalúan visión, movimiento ni elevación.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  ),
);
