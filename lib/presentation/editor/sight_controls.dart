import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../application/board/sight_probe.dart';
import '../../domain/board/cell_coordinate.dart';
import '../../domain/characters/character.dart';
import '../../domain/geometry/sight_geometry.dart';
import '../scenarios/scenario_dialogs.dart';
import '../theme/app_theme.dart';
import 'editor_controller.dart';
import '../vision/vision_controls.dart';

Future<void> pickSightCell(
  BuildContext context,
  EditorController controller,
  CellCoordinate cell,
) async {
  final asOrigin = controller.sight.chooseOrigin;
  final figure = controller.value.characters.at(cell);
  ProbeEndpoint endpoint = ProbeEndpoint.cell(cell);
  if (figure != null) {
    var reference = cell;
    if (figure.footprint != Footprint.single &&
        (!controller.vision.enabled ||
            !controller.vision.automaticReferences)) {
      final chosen = await showDialog<CellCoordinate>(
        context: context,
        builder: (context) => _ReferenceDialog(figure, cell),
      );
      if (chosen == null || !context.mounted) return;
      reference = chosen;
    }
    endpoint = ProbeEndpoint.figure(
      figure.id,
      columnOffset: reference.column - figure.position.column,
      rowOffset: reference.row - figure.position.row,
    );
  }
  if (context.mounted) {
    controller.setSightEndpoint(endpoint, asOrigin: asOrigin);
  }
}

class _ReferenceDialog extends StatefulWidget {
  const _ReferenceDialog(this.figure, this.initial);
  final Character figure;
  final CellCoordinate initial;
  @override
  State<_ReferenceDialog> createState() => _ReferenceDialogState();
}

class _ReferenceDialogState extends State<_ReferenceDialog> {
  late CellCoordinate selected = widget.initial;
  @override
  Widget build(BuildContext context) => ScenarioFormDialog(
    title: 'Casilla de referencia · ${widget.figure.label}',
    children: [
      const Text(
        'Inspección de una referencia concreta. Para comparar la base completa activa Referencias automáticas en Dictamen de visión.',
      ),
      DropdownButtonFormField<CellCoordinate>(
        key: const ValueKey('sight-reference'),
        initialValue: selected,
        decoration: const InputDecoration(
          labelText: 'Referencia dentro de la base',
        ),
        items: [
          for (final cell in widget.figure.occupiedCells)
            DropdownMenuItem(value: cell, child: Text(cell.label)),
        ],
        onChanged: (value) => setState(() => selected = value!),
      ),
      Wrap(
        alignment: WrapAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('confirm-sight-reference'),
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('Usar referencia'),
          ),
        ],
      ),
    ],
  );
}

class SightToolbar extends StatelessWidget {
  const SightToolbar({required this.controller, super.key});
  final EditorController controller;
  @override
  Widget build(BuildContext context) {
    final probe = controller.sight;
    String short(ProbeEndpoint? endpoint) {
      if (endpoint == null) return 'sin elegir';
      try {
        if (controller.vision.enabled &&
            controller.vision.automaticReferences &&
            endpoint.figureId != null) {
          return controller.value.characters
                  .byId(endpoint.figureId!)
                  ?.position
                  .label ??
              'inválido';
        }
        return endpoint.resolve(controller.value).label;
      } on ArgumentError {
        return 'inválido';
      }
    }

    return ColoredBox(
      color: AppTheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children:
                <Widget>[
                      TextButton(
                        key: const ValueKey('sight-pick-origin'),
                        onPressed: () => controller.updateSight(
                          (p) => p.chooseOrigin = true,
                        ),
                        child: Text(
                          '${probe.chooseOrigin ? '* ' : ''}Origen ${short(probe.origin)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('sight-pick-destination'),
                        onPressed: () => controller.updateSight(
                          (p) => p.chooseOrigin = false,
                        ),
                        child: Text(
                          '${!probe.chooseOrigin ? '* ' : ''}Destino ${short(probe.destination)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('sight-endpoints'),
                        onPressed: () =>
                            showSightEndpoints(context, controller),
                        icon: const Icon(Icons.edit_location_alt_outlined),
                        label: const Text(
                          'Coordenadas / figuras',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('sight-inspect'),
                        onPressed: () =>
                            showSightInspector(context, controller),
                        icon: const Icon(Icons.manage_search),
                        label: const Text(
                          'Inspeccionar geometría',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('sight-verdict'),
                        onPressed: () => showVisionReport(context, controller),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text(
                          'Dictamen de visión',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('sight-swap'),
                        tooltip: 'Intercambiar origen y destino',
                        onPressed: () =>
                            controller.updateSight((p) => p.swap()),
                        icon: const Icon(Icons.swap_horiz),
                      ),
                      IconButton(
                        key: const ValueKey('sight-clear'),
                        tooltip: 'Limpiar trayectoria',
                        onPressed: () =>
                            controller.updateSight((p) => p.clear()),
                        icon: const Icon(Icons.clear),
                      ),
                    ]
                    .map(
                      (child) => ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: child,
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}

Future<void> showSightEndpoints(
  BuildContext context,
  EditorController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => _EndpointsDialog(controller),
);

class _EndpointsDialog extends StatefulWidget {
  const _EndpointsDialog(this.controller);
  final EditorController controller;
  @override
  State<_EndpointsDialog> createState() => _EndpointsDialogState();
}

class _EndpointsDialogState extends State<_EndpointsDialog> {
  final origin = GlobalKey<_EndpointFieldState>(),
      destination = GlobalKey<_EndpointFieldState>();
  String? error;
  void submit() {
    try {
      final a = origin.currentState!.endpoint(),
          b = destination.currentState!.endpoint();
      a.resolve(widget.controller.value);
      b.resolve(widget.controller.value);
      widget.controller.setSightEndpoint(a, asOrigin: true);
      widget.controller.setSightEndpoint(b, asOrigin: false);
      Navigator.pop(context);
    } on FormatException {
      setState(() => error = 'Usa coordenadas como A1 y D4.');
    } on ArgumentError catch (exception) {
      setState(() => error = exception.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => ScenarioFormDialog(
    title: 'Extremos de la trayectoria',
    children: [
      const Text(
        'Geometría centro a centro. Casilla fija o figura que seguirá su posición. No se evalúan reglas de visión ni ataques.',
      ),
      _EndpointField(
        key: origin,
        id: 'origin',
        title: 'Origen',
        session: widget.controller.value,
        initial: widget.controller.sight.origin,
      ),
      const SizedBox(height: 16),
      _EndpointField(
        key: destination,
        id: 'destination',
        title: 'Destino',
        session: widget.controller.value,
        initial: widget.controller.sight.destination,
      ),
      if (error != null)
        Text(
          error!,
          key: const ValueKey('sight-endpoint-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      Wrap(
        alignment: WrapAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('apply-sight-endpoints'),
            onPressed: submit,
            child: const Text('Trazar'),
          ),
        ],
      ),
    ],
  );
}

class _EndpointField extends StatefulWidget {
  const _EndpointField({
    super.key,
    required this.id,
    required this.title,
    required this.session,
    this.initial,
  });
  final String id, title;
  final BoardSession session;
  final ProbeEndpoint? initial;
  @override
  State<_EndpointField> createState() => _EndpointFieldState();
}

class _EndpointFieldState extends State<_EndpointField> {
  late final TextEditingController coordinate;
  late String source;
  int reference = 0;
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    source =
        initial?.figureId != null &&
            widget.session.characters.byId(initial!.figureId!) != null
        ? initial.figureId!
        : 'cell';
    String label = '';
    try {
      label = initial?.resolve(widget.session).label ?? '';
    } on ArgumentError {
      /* Se exige otra referencia válida. */
    }
    coordinate = TextEditingController(text: label);
    if (source != 'cell') {
      final figure = widget.session.characters.byId(source)!;
      reference =
          initial!.rowOffset * figure.footprint.width + initial.columnOffset;
      if (reference >= figure.occupiedCells.length) reference = 0;
    }
  }

  @override
  void dispose() {
    coordinate.dispose();
    super.dispose();
  }

  ProbeEndpoint endpoint() {
    if (source == 'cell') {
      return ProbeEndpoint.cell(CellCoordinate.parse(coordinate.text));
    }
    final figure = widget.session.characters.byId(source)!;
    return ProbeEndpoint.figure(
      source,
      columnOffset: reference % figure.footprint.width,
      rowOffset: reference ~/ figure.footprint.width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final figure = source == 'cell'
        ? null
        : widget.session.characters.byId(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        DropdownButtonFormField<String>(
          key: ValueKey('sight-source-${widget.id}'),
          initialValue: source,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Tipo de extremo'),
          items: [
            const DropdownMenuItem(value: 'cell', child: Text('Casilla fija')),
            for (final f in widget.session.characters.all)
              DropdownMenuItem(
                value: f.id,
                child: Text(
                  '${f.label} · ${f.name} · ${f.position.label}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() {
            source = value!;
            reference = 0;
          }),
        ),
        if (figure == null)
          TextField(
            key: ValueKey('sight-cell-${widget.id}'),
            controller: coordinate,
            maxLength: 5,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Coordenada (A1…AN40)',
            ),
          ),
        if (figure != null)
          DropdownButtonFormField<int>(
            key: ValueKey('sight-ref-${widget.id}-$source'),
            initialValue: reference,
            decoration: const InputDecoration(
              labelText: 'Casilla de referencia',
            ),
            items: [
              for (var i = 0; i < figure.occupiedCells.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(figure.occupiedCells.elementAt(i).label),
                ),
            ],
            onChanged: (value) => setState(() => reference = value!),
          ),
        if (figure != null && figure.footprint != Footprint.single)
          const Text(
            'Se usa una sola referencia de esta base. Evaluación completa en Prompt 08.',
          ),
      ],
    );
  }
}

Future<void> showSightInspector(
  BuildContext context,
  EditorController controller,
) => showDialog<void>(
  context: context,
  builder: (context) => ValueListenableBuilder<BoardSession>(
    valueListenable: controller,
    builder: (context, session, _) {
      final p = controller.sight, trace = controller.sight.trace;
      return ScenarioFormDialog(
        title: 'Inspección geométrica',
        children: [
          const Text(
            'Sin dictamen reglamentario. x hacia la derecha, y hacia abajo; (0, 0) es la esquina superior izquierda. t recorre el segmento de 0 a 1.',
          ),
          Text('Origen: ${p.origin?.describe(session) ?? 'sin elegir'}'),
          Text('Destino: ${p.destination?.describe(session) ?? 'sin elegir'}'),
          if (p.error != null)
            Text(p.error!, key: const ValueKey('sight-invalid')),
          const Text(
            'Una base 2×2 usa solo la casilla de referencia elegida. Su evaluación completa corresponde al Prompt 08.',
          ),
          CheckboxListTile(
            key: const ValueKey('sight-show-line'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Segmento y extremos O / D'),
            value: p.showLine,
            onChanged: (value) =>
                controller.updateSight((p) => p.showLine = value!),
          ),
          CheckboxListTile(
            key: const ValueKey('sight-show-cells'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Casillas: interior y contacto solo en esquina'),
            value: p.showCells,
            onChanged: (value) =>
                controller.updateSight((p) => p.showCells = value!),
          ),
          CheckboxListTile(
            key: const ValueKey('sight-show-contacts'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Cruces de borde y vértices; muros tocados'),
            value: p.showContacts,
            onChanged: (value) =>
                controller.updateSight((p) => p.showContacts = value!),
          ),
          const Text(
            'Azul: interior/borde (círculo). Lila: vértice (rombo) y esquinas laterales sin relleno. Resalte de muro: contacto geométrico, sin resolver su efecto.',
          ),
          if (trace == null && p.error == null)
            const Text(
              'Elige origen y destino en el tablero o en Coordenadas / figuras.',
            ),
          if (trace != null) ...[
            Text(
              '${trace.segments.length} tramos interiores · ${trace.crossings.length} contactos',
              key: const ValueKey('sight-summary'),
            ),
            if (trace.isDegenerate)
              const Text(
                'Misma casilla: segmento de longitud cero, sin cruces de borde.',
              ),
            for (var i = 0; i < trace.events.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  '${i + 1}. ${describeTraceEvent(trace.events[i], session)}',
                  key: ValueKey('sight-event-$i'),
                ),
              ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  ),
);

String describeTraceEvent(TraceEvent event, BoardSession session) {
  final location = 't=${event.t} · ${event.point}';
  return switch (event) {
    TraceStart() => 'Inicio · $location',
    TraceEnd() => 'Fin · $location',
    CellPass() =>
      'Interior ${event.cell.label} · t=${event.t} a ${event.until} · ${event.point} a ${event.exit}${session.characters.at(event.cell) == null ? '' : ' · figura ${session.characters.at(event.cell)!.label}'}',
    GridCrossing() =>
      '${event.isVertex ? 'Vértice' : 'Cruce de borde'} · $location\n${event.contacts.map((c) => '${c.edge.id}: ${c.hasWall ? 'muro' : 'borde sin muro'} (${c.kind == ContactKind.edgeInterior ? 'interior del borde' : 'extremo del borde'})').join('\n')}${event.cornerOnly.isEmpty ? '' : '\nSolo esquina: ${event.cornerOnly.map((cell) => cell.label).join(', ')}'}',
  };
}
