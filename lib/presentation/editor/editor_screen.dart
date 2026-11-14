import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/board/board_dimensions.dart';
import '../theme/app_theme.dart';
import 'board_canvas.dart';
import 'board_size_dialog.dart';
import 'editor_controller.dart';

enum _ViewAction { grid, coordinates, clearSelection }

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
    if (dimensions != null) controller.changeDimensions(dimensions);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<BoardSession>(
    valueListenable: controller,
    builder: (context, session, _) {
      final scaler = MediaQuery.textScalerOf(context);
      return Scaffold(
        // Los formularios viven en diálogos: su teclado no desplaza la cámara
        // del tablero que permanece debajo.
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          toolbarHeight: math.max(56, scaler.scale(24) + 16),
          title: Text(
            'Editor · ${session.dimensions.rows} × ${session.dimensions.columns}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
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
                }
              },
              itemBuilder: (context) => [
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
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontal =
                        MediaQuery.orientationOf(context) ==
                        Orientation.landscape;
                    final canvas = Expanded(
                      child: BoardCanvas(controller: controller),
                    );
                    final tools = _ToolBar(vertical: horizontal);
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
    final message = selected == null
        ? 'Cuadrícula vacía · toca una casilla'
        : 'Seleccionada: ${selected.label}';
    final zoom = '${(session.camera.scale * 100).round()} %';
    return ColoredBox(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Tooltip(
                message: '$message · zoom $zoom',
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    key: const ValueKey('board-selection-status'),
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
  const _ToolBar({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final tools = <(String, String, IconData)>[
      ('select', 'Seleccionar', Icons.touch_app_outlined),
      ('characters', 'Personajes', Icons.person_outline),
      ('terrain', 'Terrenos', Icons.terrain_outlined),
      ('walls', 'Muros', Icons.view_column_outlined),
      ('vision', 'Visión', Icons.visibility_outlined),
      ('distance', 'Distancia', Icons.straighten_outlined),
      ('movement', 'Movimiento', Icons.route_outlined),
      ('erase', 'Borrar', Icons.backspace_outlined),
    ];
    final list = ListView(
      key: ValueKey(vertical ? 'tools-left' : 'tools-top'),
      scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
      padding: const EdgeInsets.all(8),
      children: [
        for (final (id, title, icon) in tools)
          SizedBox(
            width: 48,
            height: 48,
            child: Semantics(
              selected: id == 'select',
              child: IconButton(
                key: ValueKey('tool-$id'),
                tooltip: id == 'select' ? title : '$title · Próximamente',
                onPressed: id == 'select'
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Toca una casilla para seleccionarla; '
                              'tócala de nuevo para deseleccionar.',
                            ),
                          ),
                        );
                      }
                    : null,
                style: id == 'select'
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
    );
    return ColoredBox(
      color: AppTheme.surface,
      child: vertical
          ? SizedBox(width: 64, child: list)
          : SizedBox(height: 64, child: list),
    );
  }
}
