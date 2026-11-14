import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_dimensions.dart';
import '../../domain/board/cell_coordinate.dart';

class BoardSizeDialog extends StatefulWidget {
  const BoardSizeDialog({
    required this.initial,
    required this.selectedCell,
    super.key,
  });

  final BoardDimensions initial;
  final CellCoordinate? selectedCell;

  @override
  State<BoardSizeDialog> createState() => _BoardSizeDialogState();
}

class _BoardSizeDialogState extends State<BoardSizeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rows;
  late final TextEditingController _columns;

  @override
  void initState() {
    super.initState();
    _rows = TextEditingController(text: '${widget.initial.rows}');
    _columns = TextEditingController(text: '${widget.initial.columns}');
  }

  @override
  void dispose() {
    _rows.dispose();
    _columns.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Introduce un valor.';
    final number = int.tryParse(value.trim());
    if (number == null) return 'Introduce un número entero.';
    if (number < BoardDimensions.minimum || number > BoardDimensions.maximum) {
      return 'El valor debe estar entre 2 y 40.';
    }
    return null;
  }

  Future<void> _apply() async {
    if (!_formKey.currentState!.validate()) return;
    final dimensions = BoardDimensions(
      rows: int.parse(_rows.text.trim()),
      columns: int.parse(_columns.text.trim()),
    );
    if (dimensions != widget.initial && widget.selectedCell != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('¿Cambiar el tamaño?'),
          content: SingleChildScrollView(
            child: Text(
              'Se perderá la selección ${widget.selectedCell!.label} y se '
              'ajustará la cámara. No se puede deshacer en esta versión.',
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('cancel-resize'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('confirm-resize'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (mounted) Navigator.pop(context, dimensions);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Tamaño del tablero'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filas y columnas independientes, de 2 a 40. '
              'La vista se ajustará al aplicar un tamaño nuevo.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('board-rows'),
              controller: _rows,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Filas',
                border: OutlineInputBorder(),
              ),
              validator: _validate,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('board-columns'),
              controller: _columns,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Columnas',
                border: OutlineInputBorder(),
              ),
              validator: _validate,
              onFieldSubmitted: (_) => _apply(),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const ValueKey('apply-board-size'),
        onPressed: _apply,
        child: const Text('Aplicar'),
      ),
    ],
  );
}
