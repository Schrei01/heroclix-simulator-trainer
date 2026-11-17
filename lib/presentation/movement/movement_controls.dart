import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/movement/movement.dart';
import '../../domain/rules/target_analysis_service.dart' show RangeStatus;
import '../editor/editor_controller.dart';
import '../vision/vision_controls.dart' show visionLabel;
import 'movement_painter.dart';

Future<void> showMovementReport(
  BuildContext context,
  EditorController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => MovementDialog(controller: controller),
);

class MovementToolbar extends StatelessWidget {
  const MovementToolbar({required this.controller, super.key});
  final EditorController controller;
  @override
  Widget build(BuildContext context) {
    final m = controller.movement, r = m.result;
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            key: const ValueKey('movement-report'),
            onPressed: () => showMovementReport(context, controller),
            icon: Icon(Icons.route_outlined, color: movementColor(r?.status)),
            label: Text(
              r == null
                  ? 'Movimiento · elegir figura'
                  : '${r.cost}/${r.budget} · ${movementLabel(r.status)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('movement-back'),
          tooltip: 'Quitar último paso',
          onPressed: m.route.length > 1
              ? () => controller.updateMovement((m) => m.removeLast())
              : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          key: const ValueKey('movement-cancel'),
          tooltip: 'Cancelar ensayo sin mover',
          onPressed: () => controller.updateMovement((m) => m.clear()),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class MovementDialog extends StatefulWidget {
  const MovementDialog({required this.controller, super.key});
  final EditorController controller;
  @override
  State<MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<MovementDialog> {
  final _step = TextEditingController(), _destination = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _step.dispose();
    _destination.dispose();
    super.dispose();
  }

  void _coordinate(TextEditingController input, bool search) {
    try {
      final c = CellCoordinate.parse(input.text);
      widget.controller.updateMovement(
        (m) => search ? m.search(c) : m.append(c),
      );
      setState(() => _error = null);
    } on FormatException {
      setState(() => _error = 'Introduce una casilla como B3.');
    } on ArgumentError {
      setState(() => _error = 'Coordenada fuera de límites.');
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<BoardSession>(
    valueListenable: widget.controller,
    builder: (context, s, _) {
      final c = widget.controller, m = c.movement, r = m.result;
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: math.max(80, MediaQuery.sizeOf(context).height - 48),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ensayo de movimiento',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Text(
                  'La figura conserva su posición original. Toca casillas sucesivas del tablero; no se rellenan saltos. Confirmar aplica la ruta válida como una operación de historial.',
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('movement-source-${m.sourceId}'),
                  initialValue: m.sourceId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Figura que se mueve',
                  ),
                  items: [
                    for (final f in s.characters.all)
                      DropdownMenuItem(
                        value: f.id,
                        child: Text(
                          '${f.label} · ${f.name} · ${f.position.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) {
                    if (id != null) c.beginMovement(id);
                  },
                ),
                if (r != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    movementLabel(r.status),
                    key: const ValueKey('movement-result'),
                    style: TextStyle(
                      color: movementColor(r.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Recorridas ${r.cost} · velocidad declarada ${r.budget} · restante ${r.remaining}',
                  ),
                  Text(
                    'Distancia directa: ${_direct(m.route)}. La ruta consume sus pasos reales.',
                  ),
                  Text(r.reason, key: const ValueKey('movement-reason')),
                  Text('Ruta: ${m.route.map((c) => c.label).join(' / ')}'),
                  const Text(
                    'ENSAYO: origen y destino se comparan sin mover ni guardar. La velocidad no incorpora modificadores, dados ni acciones.',
                  ),
                  TextField(
                    key: const ValueKey('movement-step'),
                    controller: _step,
                    decoration: const InputDecoration(
                      labelText: 'Siguiente casilla (un paso)',
                    ),
                    onSubmitted: (_) => _coordinate(_step, false),
                  ),
                  TextButton(
                    key: const ValueKey('movement-add-step'),
                    onPressed: () => _coordinate(_step, false),
                    child: const Text('Añadir paso'),
                  ),
                  TextField(
                    key: const ValueKey('movement-destination'),
                    controller: _destination,
                    decoration: const InputDecoration(
                      labelText: 'Destino para buscar rutas',
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('movement-search'),
                    onPressed: () => _coordinate(_destination, true),
                    child: const Text('Buscar alternativas verificadas'),
                  ),
                  if (m.alternatives case final search?) ...[
                    Text(
                      search.reason,
                      key: const ValueKey('movement-search-result'),
                    ),
                    for (var i = 0; i < search.routes.length; i++)
                      TextButton(
                        key: ValueKey('movement-route-$i'),
                        onPressed: () =>
                            c.updateMovement((m) => m.choose(search.routes[i])),
                        child: Text(
                          '${search.routes[i].cost} pasos · ${search.routes[i].route.map((c) => c.label).join(' / ')}',
                        ),
                      ),
                  ],
                  CheckboxListTile(
                    key: const ValueKey('movement-special'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Otro efecto de movimiento no modelado'),
                    value: m.specialEffects,
                    onChanged: (v) =>
                        c.updateMovement((m) => m.setEffects(v ?? false)),
                  ),
                  ExpansionTile(
                    key: const ValueKey('movement-log'),
                    title: const Text(
                      'Pasos y reglas aplicadas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    children: [
                      for (final e in r.events)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${e.step}. ${e.cell.label} · ${e.citation}\n${e.reason}',
                          ),
                        ),
                    ],
                  ),
                  if (m.before != null && m.after != null)
                    ExpansionTile(
                      key: const ValueKey('movement-comparison'),
                      title: const Text(
                        'Visión y alcance antes / después',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: [
                        const Text(
                          'Se reutilizan los motores de visión y alcance de la ficha. No valida ataques.',
                        ),
                        for (final before in m.before!.targets)
                          Builder(
                            builder: (context) {
                              final after = m.after!.targets
                                  .where((t) => t.target.id == before.target.id)
                                  .first;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${before.target.label} · ${before.target.position.label}\n'
                                  '${visionLabel(before.vision.status)} / ${visionLabel(after.vision.status)}\n'
                                  'Distancia ${before.distance.squares ?? '?'} / ${after.distance.squares ?? '?'} · '
                                  'alcance ${_range(before.range)} / ${_range(after.range)}',
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  TextButton(
                    key: const ValueKey('movement-reset'),
                    onPressed: () => c.updateMovement((m) => m.reset()),
                    child: const Text('Volver al inicio del ensayo'),
                  ),
                  FilledButton(
                    key: const ValueKey('movement-confirm'),
                    onPressed: r.canConfirm
                        ? () {
                            final error = c.confirmMovement();
                            if (error == null) {
                              Navigator.pop(context);
                            } else {
                              setState(() => _error = error);
                            }
                          }
                        : null,
                    child: const Text('Confirmar movimiento'),
                  ),
                ],
                if (_error != null)
                  Text(_error!, key: const ValueKey('movement-error')),
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      key: const ValueKey('movement-cancel-dialog'),
                      onPressed: () {
                        c.updateMovement((m) => m.clear());
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar ensayo'),
                    ),
                    TextButton(
                      key: const ValueKey('movement-close'),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver al tablero'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  int _direct(List<CellCoordinate> route) => route.isEmpty
      ? 0
      : math.max(
          (route.last.column - route.first.column).abs(),
          (route.last.row - route.first.row).abs(),
        );
  String _range(RangeStatus r) => switch (r) {
    RangeStatus.within => 'dentro',
    RangeStatus.outside => 'fuera',
    RangeStatus.notEvaluated => 'no evaluado',
  };
}
