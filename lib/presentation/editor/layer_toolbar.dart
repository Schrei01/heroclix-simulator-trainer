import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../application/board/layer_draft.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/terrain/editing_geometry.dart';
import '../../domain/terrain/edge_wall.dart';
import '../theme/app_theme.dart';
import 'editor_controller.dart';
import 'layer_actions.dart';
import 'elevation_controls.dart';

class LayerToolbar extends StatelessWidget {
  const LayerToolbar({required this.controller, super.key});
  final EditorController controller;
  Widget _choice(String text, {IconData? icon, bool compact = false}) => compact
      ? SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon ?? Icons.layers_outlined),
        )
      : Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
              Text(text),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        );
  @override
  Widget build(BuildContext context) {
    final state = controller.value;
    final compact =
        MediaQuery.sizeOf(context).height < 400 &&
        MediaQuery.textScalerOf(context).scale(20) > 32;
    return ColoredBox(
      color: AppTheme.surface,
      child: SizedBox(
        width: double.infinity,
        height: compact ? 48 : MediaQuery.textScalerOf(context).scale(20) + 32,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (state.tool == EditorTool.terrain &&
                  state.terrainBrush.type != null) ...[
                PopupMenuButton<bool>(
                  key: const ValueKey('terrain-brush'),
                  tooltip: 'Trazo o rectángulo',
                  onSelected: (rectangle) =>
                      controller.configureLayers(rectangle: rectangle),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: false,
                      child: Text('Trazo por arrastre'),
                    ),
                    const PopupMenuItem(
                      value: true,
                      child: Text('Rellenar rectángulo'),
                    ),
                  ],
                  child: _choice(
                    state.rectangleBrush ? 'Rectángulo' : 'Trazo',
                    compact: compact,
                    icon: state.rectangleBrush
                        ? Icons.crop_square_outlined
                        : Icons.edit_outlined,
                  ),
                ),
              ],
              if (state.tool == EditorTool.walls)
                PopupMenuButton<bool>(
                  key: const ValueKey('wall-action'),
                  tooltip: 'Acción de muro',
                  onSelected: (erase) =>
                      controller.configureLayers(removeWalls: erase),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: false,
                      child: Text('Añadir muro'),
                    ),
                    const PopupMenuItem(
                      value: true,
                      child: Text('Borrar muro'),
                    ),
                  ],
                  child: _choice(
                    state.eraseWalls ? 'Borrar muro' : 'Añadir muro',
                    compact: compact,
                    icon: Icons.view_column_outlined,
                  ),
                ),
              if (state.tool == EditorTool.erase)
                PopupMenuButton<EraseLayer>(
                  key: const ValueKey('erase-layer'),
                  tooltip: 'Capa de Borrar elemento',
                  onSelected: (layer) =>
                      controller.configureLayers(erase: layer),
                  itemBuilder: (_) => [
                    for (final layer in EraseLayer.values)
                      PopupMenuItem(
                        value: layer,
                        child: Text(eraseName(layer)),
                      ),
                  ],
                  child: _choice(
                    eraseName(state.eraseLayer),
                    compact: compact,
                    icon: Icons.backspace_outlined,
                  ),
                ),
              if (compact)
                IconButton(
                  key: const ValueKey('edit-coordinates'),
                  tooltip: 'Editar por coordenadas',
                  onPressed: () => _coordinates(context),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                )
              else
                TextButton.icon(
                  key: const ValueKey('edit-coordinates'),
                  onPressed: () => _coordinates(context),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Coordenadas'),
                ),
              if (compact)
                IconButton(
                  tooltip: 'Leyenda',
                  onPressed: () => showLayerLegend(context),
                  icon: const Icon(Icons.info_outline),
                )
              else
                TextButton.icon(
                  onPressed: () => showLayerLegend(context),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Leyenda'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _coordinates(BuildContext context) async {
    final initial = controller.value;
    if (initial.tool == EditorTool.terrain &&
        initial.terrainBrush == TerrainBrush.elevated) {
      await showElevationDialog(context, controller);
      return;
    }
    final result = await showDialog<(CellCoordinate, CellCoordinate)>(
      context: context,
      builder: (_) => _CoordinatesDialog(controller: controller),
    );
    if (result == null || !context.mounted) return;
    final state = controller.value;
    final (a, b) = result;
    if (state.tool == EditorTool.terrain &&
        state.terrainBrush == TerrainBrush.transition) {
      final error = controller.attempt(
        (s) => s.setTransition(EdgeWall.between(a, b), remove: false),
      );
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    controller.draft.value = LayerDraft(
      tool: state.tool,
      type: state.terrainType,
      brush: state.terrainBrush,
      rectangle: state.tool == EditorTool.terrain,
      eraseWalls: state.eraseWalls,
      eraseLayer: state.eraseLayer,
      cells:
          state.tool == EditorTool.terrain ||
              (state.tool == EditorTool.erase &&
                  (state.eraseLayer == EraseLayer.all ||
                      state.eraseLayer == EraseLayer.terrain ||
                      state.eraseLayer == EraseLayer.elevation))
          ? const EditingGeometry().rectangle(a, b)
          : [],
      edges:
          state.tool == EditorTool.walls ||
              (state.tool == EditorTool.erase &&
                  (state.eraseLayer == EraseLayer.walls ||
                      state.eraseLayer == EraseLayer.transitions))
          ? [EdgeWall.between(a, b)]
          : [],
      figureId:
          state.tool == EditorTool.erase &&
              state.eraseLayer == EraseLayer.figures
          ? state.characters.at(a)?.id
          : null,
      pending: state.tool == EditorTool.terrain,
    );
    if (state.tool != EditorTool.terrain) {
      await commitLayerDraft(context, controller);
    }
  }
}

class _CoordinatesDialog extends StatefulWidget {
  const _CoordinatesDialog({required this.controller});
  final EditorController controller;
  @override
  State<_CoordinatesDialog> createState() => _CoordinatesDialogState();
}

class _CoordinatesDialogState extends State<_CoordinatesDialog> {
  final _form = GlobalKey<FormState>();
  final _start = TextEditingController(), _end = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  String? _validate(String? text) {
    try {
      final cell = CellCoordinate.parse(text ?? '');
      return widget.controller.value.dimensions.contains(cell)
          ? null
          : 'Fuera del tablero.';
    } on FormatException {
      return 'Usa una coordenada como A1.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.value;
    final wall =
        state.tool == EditorTool.walls ||
        (state.tool == EditorTool.erase &&
            (state.eraseLayer == EraseLayer.walls ||
                state.eraseLayer == EraseLayer.transitions)) ||
        (state.tool == EditorTool.terrain &&
            state.terrainBrush == TerrainBrush.transition);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Editar por coordenadas',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  wall
                      ? 'Indica dos casillas vecinas que compartan el borde interno.'
                      : state.tool == EditorTool.terrain
                      ? 'Inicio y fin del rectángulo. Fin vacío pinta una casilla. Se mostrará vista previa.'
                      : 'Indica la casilla que quieres borrar de la capa elegida.',
                ),
                TextFormField(
                  key: const ValueKey('layer-start'),
                  controller: _start,
                  decoration: const InputDecoration(labelText: 'Inicio'),
                  validator: _validate,
                ),
                if (state.tool != EditorTool.erase || wall)
                  TextFormField(
                    key: const ValueKey('layer-end'),
                    controller: _end,
                    decoration: InputDecoration(
                      labelText: wall ? 'Casilla vecina' : 'Fin (opcional)',
                    ),
                    validator: (value) =>
                        !wall && (value?.trim().isEmpty ?? true)
                        ? null
                        : _validate(value),
                  ),
                if (_error != null) Text(_error!),
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      key: const ValueKey('preview-coordinates'),
                      onPressed: () {
                        if (!_form.currentState!.validate()) return;
                        final a = CellCoordinate.parse(_start.text),
                            b = _end.text.trim().isEmpty
                                ? a
                                : CellCoordinate.parse(_end.text);
                        if (wall) {
                          try {
                            EdgeWall.between(a, b);
                          } on ArgumentError {
                            setState(
                              () => _error = 'Selecciona dos casillas vecinas ortogonales.',
                            );
                            return;
                          }
                        }
                        Navigator.pop(context, (a, b));
                      },
                      child: Text(
                        state.tool == EditorTool.terrain
                            ? 'Ver previa'
                            : 'Aplicar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
