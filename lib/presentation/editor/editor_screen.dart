import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/board/board_dimensions.dart';
import '../../domain/terrain/terrain.dart';
import '../theme/app_theme.dart';
import 'board_canvas.dart';
import 'board_size_dialog.dart';
import 'editor_controller.dart';
import 'character_dialog.dart';
import 'layer_toolbar.dart';
import 'terrain_palette.dart';
import 'tool_hint.dart';
import 'layer_actions.dart';
import '../scenarios/scenario_actions.dart';
import 'sight_controls.dart';
import '../vision/vision_controls.dart';
import '../vision/vision_verdict_bar.dart';
import '../vision/tactical_controls.dart';
import '../movement/movement_controls.dart';
import '../tactics/tactical_screen.dart';

enum _ViewAction {
  grid,
  coordinates,
  clearSelection,
  legend,
  clearTerrain,
  clearWalls,
  clearFigures,
  newScenario,
  save,
  saveAs,
  library,
  importJson,
  exportJson,
  shareJson,
  exportPng,
  details,
  sight,
  visionVerdict,
}

class EditorScreen extends StatelessWidget {
  const EditorScreen({required this.controller, super.key});

  final EditorController controller;

  Future<void> _configureSize(BuildContext context) async {
    final dimensions = await showDialog<BoardDimensions>(
      context: context,
      builder: (context) => BoardSizeDialog(
        initial: controller.value.dimensions,
        selectedCell: controller.value.selectedCell,
      ),
    );
    if (dimensions != null) {
      final error = controller.attempt(
        (session) => session.changeDimensions(dimensions),
      );
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<void> _roster(BuildContext context) async {
    final id = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Figuras del escenario'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.value.characters.isEmpty)
                const Text(
                  'Usa Personajes y toca una casilla vacía para crear una figura.',
                ),
              for (final figure in controller.value.characters.all)
                ListTile(
                  key: ValueKey('roster-${figure.id}'),
                  title: Text('${figure.label} · ${figure.name}'),
                  subtitle: Text(
                    '${controller.value.teamById(figure.teamId).code} · ${controller.value.teamById(figure.teamId).name} · ${figure.position.label} · base ${figure.footprint.label}',
                  ),
                  onTap: () => Navigator.pop(context, figure.id),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (id != null && context.mounted) {
      controller.selectCharacter(id);
      await showCharacterDialog(
        context,
        controller,
        character: controller.value.characters.byId(id),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<BoardSession>(
    valueListenable: controller,
    builder: (context, session, _) {
      final scaler = MediaQuery.textScalerOf(context);
      final workspace = controller.workspace;
      final filesEnabled =
          workspace != null &&
          !workspace.loading &&
          !workspace.busy &&
          !controller.fileBusy;
      final actions = ScenarioActions(controller);
      return AbsorbPointer(
        absorbing: workspace?.loading == true || workspace?.switching == true,
        child: Scaffold(
          // Los formularios viven en diálogos: su teclado no desplaza la cámara
          // del tablero que permanece debajo.
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            toolbarHeight: math.max(
              56,
              scaler.scale(workspace == null ? 24 : 27) + 16,
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editor · ${session.dimensions.rows} × ${session.dimensions.columns}',
                  style: workspace == null
                      ? null
                      : const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (workspace != null)
                  Tooltip(
                    message: '${workspace.current.name} · ${workspace.status}',
                    child: Text(
                      workspace.current.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
            actions: [
              if (workspace != null)
                IconButton(
                  key: const ValueKey('scenario-library'),
                  tooltip: 'Biblioteca local',
                  onPressed: filesEnabled
                      ? () => actions.library(context)
                      : null,
                  icon: const Icon(Icons.folder_open_outlined),
                ),
              IconButton(
                key: const ValueKey('character-roster'),
                tooltip: 'Lista de figuras',
                onPressed: () => _roster(context),
                icon: const Icon(Icons.groups_outlined),
              ),
              IconButton(
                key: const ValueKey('board-size-button'),
                tooltip: 'Cambiar filas y columnas',
                onPressed: () => _configureSize(context),
                icon: const Icon(Icons.grid_4x4_outlined),
              ),
              PopupMenuButton<_ViewAction>(
                key: const ValueKey('board-view-options'),
                tooltip: 'Opciones del tablero',
                onSelected: (action) {
                  switch (action) {
                    case _ViewAction.grid:
                      controller.toggleGrid();
                    case _ViewAction.coordinates:
                      controller.toggleCoordinates();
                    case _ViewAction.clearSelection:
                      controller.clearSelection();
                    case _ViewAction.legend:
                      showLayerLegend(context);
                    case _ViewAction.clearTerrain:
                      clearLayer(context, controller, 'terreno');
                    case _ViewAction.clearWalls:
                      clearLayer(context, controller, 'muros');
                    case _ViewAction.clearFigures:
                      clearLayer(context, controller, 'figuras');
                    case _ViewAction.newScenario:
                      actions.create(context);
                    case _ViewAction.save:
                      actions.save(context);
                    case _ViewAction.saveAs:
                      actions.saveAs(context);
                    case _ViewAction.library:
                      actions.library(context);
                    case _ViewAction.importJson:
                      actions.importJson(context);
                    case _ViewAction.exportJson:
                      actions.exportJson(context, share: false);
                    case _ViewAction.shareJson:
                      actions.exportJson(context, share: true);
                    case _ViewAction.exportPng:
                      actions.exportPng(context);
                    case _ViewAction.details:
                      actions.details(context);
                    case _ViewAction.sight:
                      showSightInspector(context, controller);
                    case _ViewAction.visionVerdict:
                      showVisionReport(context, controller);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _ViewAction.visionVerdict,
                    child: Text('Dictamen de visión'),
                  ),
                  const PopupMenuItem(
                    value: _ViewAction.sight,
                    child: Text('Inspeccionar geometría'),
                  ),
                  if (workspace != null) ...[
                    PopupMenuItem(
                      key: const ValueKey('new-scenario'),
                      value: _ViewAction.newScenario,
                      enabled: filesEnabled,
                      child: const Text('Nuevo escenario'),
                    ),
                    PopupMenuItem(
                      key: const ValueKey('save-scenario'),
                      value: _ViewAction.save,
                      enabled: filesEnabled,
                      child: const Text('Guardar en biblioteca'),
                    ),
                    PopupMenuItem(
                      key: const ValueKey('save-as-scenario'),
                      value: _ViewAction.saveAs,
                      enabled: filesEnabled,
                      child: const Text('Guardar como'),
                    ),
                    PopupMenuItem(
                      value: _ViewAction.library,
                      enabled: filesEnabled,
                      child: const Text('Biblioteca local'),
                    ),
                    PopupMenuItem(
                      key: const ValueKey('import-scenario'),
                      value: _ViewAction.importJson,
                      enabled: filesEnabled && controller.files != null,
                      child: const Text('Importar JSON'),
                    ),
                    PopupMenuItem(
                      key: const ValueKey('export-json'),
                      value: _ViewAction.exportJson,
                      enabled: filesEnabled && controller.files != null,
                      child: const Text('Exportar JSON'),
                    ),
                    PopupMenuItem(
                      key: const ValueKey('share-json'),
                      value: _ViewAction.shareJson,
                      enabled: filesEnabled && controller.files != null,
                      child: const Text('Compartir JSON'),
                    ),
                    PopupMenuItem(
                      key: const ValueKey('export-png'),
                      value: _ViewAction.exportPng,
                      enabled: filesEnabled && controller.files != null,
                      child: const Text('Exportar / compartir PNG'),
                    ),
                    const PopupMenuItem(
                      value: _ViewAction.details,
                      child: Text('Información del escenario'),
                    ),
                    const PopupMenuDivider(),
                  ],
                  CheckedPopupMenuItem(
                    key: const ValueKey('grid-option'),
                    value: _ViewAction.grid,
                    checked: session.showGrid,
                    child: const Text('Mostrar cuadrícula'),
                  ),
                  CheckedPopupMenuItem(
                    key: const ValueKey('coordinates-option'),
                    value: _ViewAction.coordinates,
                    checked: session.showCoordinates,
                    child: const Text('Mostrar coordenadas'),
                  ),
                  PopupMenuItem(
                    key: const ValueKey('clear-selection-option'),
                    value: _ViewAction.clearSelection,
                    enabled: session.selectedCell != null,
                    child: const Text('Limpiar selección'),
                  ),
                  const PopupMenuItem(
                    value: _ViewAction.legend,
                    child: Text('Leyenda y capas'),
                  ),
                  const PopupMenuItem(
                    key: ValueKey('clear-terrain-option'),
                    value: _ViewAction.clearTerrain,
                    child: Text('Limpiar solo terreno'),
                  ),
                  const PopupMenuItem(
                    key: ValueKey('clear-walls-option'),
                    value: _ViewAction.clearWalls,
                    child: Text('Limpiar solo muros'),
                  ),
                  const PopupMenuItem(
                    key: ValueKey('clear-figures-option'),
                    value: _ViewAction.clearFigures,
                    child: Text('Limpiar solo figuras'),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            maintainBottomViewPadding: true,
            child: Column(
              children: [
                if (session.editsLayers || session.tool == EditorTool.terrain)
                  LayerToolbar(controller: controller),
                if (session.tool == EditorTool.movement)
                  MovementToolbar(controller: controller),
                if (session.tool == EditorTool.vision)
                  SightToolbar(controller: controller),
                if (session.tool == EditorTool.distance ||
                    session.tool == EditorTool.targets)
                  TacticalToolbar(controller: controller),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontal =
                          MediaQuery.orientationOf(context) ==
                              Orientation.landscape ||
                          constraints.maxHeight < 200;
                      final canvas = Expanded(
                        child: Column(
                          children: [
                            if (session.tool == EditorTool.vision)
                              VisionVerdictBar(controller: controller),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: BoardCanvas(controller: controller),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    bottom: 8,
                                    child: ToolHint(controller: controller),
                                  ),
                                ],
                              ),
                            ),
                            if (session.tool == EditorTool.terrain)
                              TerrainPalette(controller: controller),
                          ],
                        ),
                      );
                      final tools = _ToolBar(
                        vertical: horizontal,
                        controller: controller,
                      );
                      return horizontal
                          ? Row(children: [tools, canvas])
                          : Column(children: [tools, canvas]);
                    },
                  ),
                ),
                _CameraBar(controller: controller, session: session),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CameraBar extends StatelessWidget {
  const _CameraBar({required this.controller, required this.session});

  final EditorController controller;
  final BoardSession session;

  @override
  Widget build(BuildContext context) {
    final selected = session.selectedCell;
    final figure = session.selectedCharacter;
    final conflicts = session.studyConflicts;
    final study =
        figure != null && figure.occupiedCells.any(conflicts.contains);
    final selectionMessage = figure != null
        ? '${figure.label} · ${figure.name} · ${session.teamById(figure.teamId).code} · ${figure.position.label}${study ? ' · ! Estudio' : ''}'
        : selected == null
        ? (session.characters.isEmpty
              ? (session.terrain.isEmpty && session.walls.isEmpty
                    ? 'Cuadrícula vacía · toca una casilla'
                    : 'Terreno ${{...session.terrain.cells.keys, ...session.terrain.debrisCells}.length} · Muros ${session.walls.edges.length}')
              : '${session.characters.length} figuras · toca una casilla')
        : 'Seleccionada: ${selected.label}';
    final probe = controller.sight;
    final verdict =
        controller.vision.enabled && session.tool == EditorTool.vision
        ? controller.vision.result
        : null;
    final trace = verdict == null ? probe.trace : verdict.trace;
    final message = session.tool == EditorTool.movement
        ? 'Ensayo de movimiento · la figura permanece en origen hasta confirmar'
        : session.tool != EditorTool.vision
        ? selectionMessage
        : trace != null
        ? '${trace.path.origin.label} a ${trace.path.destination.label} · ${trace.segments.length} tramos · ${controller.vision.enabled ? 'Visión' : 'Solo geometría'}'
        : probe.error ??
              'Toca ${probe.chooseOrigin ? 'origen' : 'destino'} · casilla o figura. ${controller.vision.enabled ? 'Visión' : 'Solo geometría'}.';
    final zoom = '${(session.camera.scale * 100).round()} %';
    return ColoredBox(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (figure != null)
              IconButton(
                key: const ValueKey('edit-character'),
                tooltip: 'Ver o editar ficha ${figure.label}',
                onPressed: () =>
                    showCharacterDialog(context, controller, character: figure),
                icon: const Icon(Icons.edit_outlined),
              ),
            Expanded(
              child: Tooltip(
                message: '$message · zoom $zoom',
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    key: ValueKey(
                      session.tool == EditorTool.vision
                          ? 'sight-status'
                          : 'board-selection-status',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('zoom-out'),
              tooltip: 'Reducir · zoom $zoom',
              onPressed: () => controller.zoom(1 / 1.25),
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              key: const ValueKey('zoom-in'),
              tooltip: 'Ampliar · zoom $zoom',
              onPressed: () => controller.zoom(1.25),
              icon: const Icon(Icons.add),
            ),
            IconButton(
              key: const ValueKey('center-board'),
              tooltip: 'Centrar tablero conservando zoom',
              onPressed: controller.centerCamera,
              icon: const Icon(Icons.center_focus_strong_outlined),
            ),
            IconButton(
              key: const ValueKey('reset-camera'),
              tooltip: 'Ajustar tablero y restablecer zoom',
              onPressed: controller.resetCamera,
              icon: const Icon(Icons.fit_screen_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolBar extends StatelessWidget {
  const _ToolBar({required this.vertical, required this.controller});

  final bool vertical;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final tools = <(String, String, IconData)>[
      ('select', 'Seleccionar', Icons.touch_app_outlined),
      ('characters', 'Personajes', Icons.person_outline),
      ('terrain', 'Terrenos', Icons.terrain_outlined),
      ('walls', 'Muros', Icons.view_column_outlined),
      ('vision', 'Línea de visión · Geometría', Icons.visibility_outlined),
      ('distance', 'Medir distancia', Icons.straighten_outlined),
      ('targets', 'Mostrar objetivos', Icons.radar_outlined),
      ('movement', 'Movimiento', Icons.route_outlined),
      ('positionAnalysis', 'Analizar posición', Icons.analytics_outlined),
      ('erase', 'Borrar elemento', Icons.backspace_outlined),
    ];
    final list = SingleChildScrollView(
      key: ValueKey(vertical ? 'tools-left' : 'tools-top'),
      scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Flex(
        direction: vertical ? Axis.vertical : Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<MapEnvironment>(
            key: const ValueKey('map-environment'),
            tooltip:
                'Tipo de mapa: ${controller.value.terrain.environment.name}. Cambiar aplica a todo el mapa.',
            onSelected: (next) =>
                controller.attempt((s) => s.setEnvironment(next)),
            itemBuilder: (_) => [
              for (final type in MapEnvironment.values)
                CheckedPopupMenuItem(
                  key: ValueKey('map-environment-${type.name}'),
                  value: type,
                  checked: controller.value.terrain.environment == type,
                  child: Text(
                    type == MapEnvironment.indoor ? 'Indoor' : 'Outdoor',
                  ),
                ),
            ],
            child: SizedBox(
              width: vertical ? 48 : 104,
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (vertical)
                    Icon(
                      controller.value.terrain.environment ==
                              MapEnvironment.indoor
                          ? Icons.home_outlined
                          : Icons.park_outlined,
                    )
                  else
                    Flexible(
                      child: Text(
                        controller.value.terrain.environment ==
                                MapEnvironment.indoor
                            ? 'Indoor'
                            : 'Outdoor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              key: const ValueKey('undo-edit'),
              tooltip: 'Deshacer',
              onPressed: controller.history.canUndo ? controller.undo : null,
              icon: const Icon(Icons.undo),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              key: const ValueKey('redo-edit'),
              tooltip: 'Rehacer',
              onPressed: controller.history.canRedo ? controller.redo : null,
              icon: const Icon(Icons.redo),
            ),
          ),
          for (final (id, title, icon) in tools)
            SizedBox(
              width: 48,
              height: 48,
              child: Semantics(
                selected: id == controller.value.tool.name,
                child: IconButton(
                  key: ValueKey('tool-$id'),
                  tooltip: EditorTool.values.any((tool) => tool.name == id)
                      ? title
                      : '$title · Próximamente',
                  onPressed: EditorTool.values.any((tool) => tool.name == id)
                      ? () {
                          if (id == 'positionAnalysis') {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TacticalScreen(editor: controller),
                              ),
                            );
                            return;
                          }
                          controller.setTool(
                            EditorTool.values.firstWhere(
                              (tool) => tool.name == id,
                            ),
                          );
                          if (controller.value.editsLayers) return;
                          if (id == 'movement') return;
                          if (id == 'targets') {
                            showTargetList(context, controller);
                            return;
                          }
                          if (id == 'vision' || id == 'distance') return;
                        }
                      : null,
                  style: id == controller.value.tool.name
                      ? IconButton.styleFrom(
                          backgroundColor: AppTheme.accent.withValues(
                            alpha: 0.18,
                          ),
                          foregroundColor: AppTheme.accent,
                        )
                      : null,
                  icon: Icon(icon),
                ),
              ),
            ),
        ],
      ),
    );
    return ColoredBox(
      color: AppTheme.surface,
      child: vertical
          ? SizedBox(width: 64, child: list)
          : SizedBox(height: 64, child: list),
    );
  }
}
