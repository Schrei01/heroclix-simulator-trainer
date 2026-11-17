import 'package:material_ui/material_ui.dart';

import '../../domain/board/cell_coordinate.dart';
import '../../domain/terrain/edge_wall.dart';
import '../scenarios/scenario_dialogs.dart';
import 'editor_controller.dart';

Future<void> showElevationDialog(
  BuildContext context,
  EditorController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => _ElevationDialog(controller),
);

class _ElevationDialog extends StatefulWidget {
  const _ElevationDialog(this.controller);
  final EditorController controller;
  @override
  State<_ElevationDialog> createState() => _ElevationDialogState();
}

class _ElevationDialogState extends State<_ElevationDialog> {
  late final from = TextEditingController(
    text: widget.controller.value.selectedCell?.label ?? 'A1',
  );
  late final to = TextEditingController(text: from.text);
  late final level = TextEditingController(
    text:
        '${widget.controller.value.terrain.at(CellCoordinate.parse(from.text)).level.clamp(2, 40)}',
  );
  String? error;
  @override
  void dispose() {
    from.dispose();
    to.dispose();
    level.dispose();
    super.dispose();
  }

  void apply({bool? removeTransition}) {
    try {
      final a = CellCoordinate.parse(from.text),
          b = CellCoordinate.parse(to.text);
      if (!widget.controller.value.dimensions.contains(a) ||
          !widget.controller.value.dimensions.contains(b)) {
        throw ArgumentError('Casilla fuera del tablero.');
      }
      String? message;
      if (removeTransition != null) {
        message = widget.controller.attempt(
          (s) =>
              s.setTransition(EdgeWall.between(a, b), remove: removeTransition),
        );
      } else {
        final height = int.tryParse(level.text.trim());
        if (height == null || height < 1 || height > 40) {
          throw ArgumentError('Nivel entero de 1 a 40.');
        }
        final cells = <CellCoordinate>[];
        for (
          var row = a.row < b.row ? a.row : b.row;
          row <= (a.row > b.row ? a.row : b.row);
          row++
        ) {
          for (
            var col = a.column < b.column ? a.column : b.column;
            col <= (a.column > b.column ? a.column : b.column);
            col++
          ) {
            cells.add(CellCoordinate(row: row, column: col));
          }
        }
        message = widget.controller.attempt(
          (s) => s.paintElevation(cells, height),
        );
      }
      if (message != null) {
        setState(() => error = message);
        return;
      }
      Navigator.pop(context);
    } on FormatException catch (e) {
      setState(() => error = e.message);
    } on ArgumentError catch (e) {
      setState(() => error = e.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => ScenarioFormDialog(
    title: 'Alturas y transiciones',
    children: [
      const Text(
        'Nivel 1: suelo. El rectángulo incluye ambas casillas. La altura no cambia el tipo de terreno. Los bordes se marcan automáticamente.',
      ),
      TextField(
        key: const ValueKey('elevation-from'),
        controller: from,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Desde (casilla)'),
      ),
      TextField(
        key: const ValueKey('elevation-to'),
        controller: to,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Hasta (casilla)'),
      ),
      TextField(
        key: const ValueKey('elevation-level'),
        controller: level,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Nivel (1–40)'),
      ),
      if (error != null) Text(error!, key: const ValueKey('elevation-error')),
      FilledButton(
        key: const ValueKey('elevation-apply'),
        onPressed: apply,
        child: const Text('Aplicar altura'),
      ),
      const Text(
        'Para una transición de altura elige dos casillas vecinas ortogonales, de distinto nivel y sin muro entre ellas. Cada casilla se marca con un triángulo que contiene su nivel; los dos triángulos quedan unidos por el borde. Editar alturas retira transiciones que ya no unen niveles distintos.',
      ),
      TextButton(
        key: const ValueKey('transition-add'),
        onPressed: () => apply(removeTransition: false),
        child: const Text('Añadir transición'),
      ),
      TextButton(
        key: const ValueKey('transition-remove'),
        onPressed: () => apply(removeTransition: true),
        child: const Text('Quitar transición'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
    ],
  );
}
