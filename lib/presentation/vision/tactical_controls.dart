import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/characters/character.dart';
import '../../domain/rules/distance_service.dart';
import '../../domain/rules/target_analysis_service.dart';
import '../editor/editor_controller.dart';
import '../editor/sight_controls.dart';
import '../scenarios/scenario_dialogs.dart';
import 'vision_controls.dart';

String targetLabel(TargetStatus status) => switch (status) {
  TargetStatus.inRangeClear => 'En alcance · visión despejada',
  TargetStatus.inRangeHindered => 'En alcance · visión obstaculizada',
  TargetStatus.blocked => 'Visión bloqueada',
  TargetStatus.outOfRange => 'Fuera de alcance',
  TargetStatus.notEvaluated => 'No evaluado',
};
String rangeLabel(RangeStatus status) => switch (status) {
  RangeStatus.within => 'Dentro del alcance declarado',
  RangeStatus.outside => 'Fuera del alcance declarado',
  RangeStatus.notEvaluated => 'Alcance no evaluado',
};
const _attackLimit =
    'Análisis preliminar. Visible y en alcance no significa ataque legal. No comprueba acciones, poderes, adyacencia ni número de objetivos.';

Color targetColor(TargetStatus status) => switch (status) {
  TargetStatus.inRangeClear => const Color(0xff81d69b),
  TargetStatus.inRangeHindered => const Color(0xffffcb70),
  TargetStatus.blocked => const Color(0xffff8e8e),
  TargetStatus.outOfRange => const Color(0xffa7b7d0),
  TargetStatus.notEvaluated => const Color(0xffb7c1cb),
};
IconData targetIcon(TargetStatus status) => switch (status) {
  TargetStatus.inRangeClear => Icons.check_circle_outline,
  TargetStatus.inRangeHindered => Icons.tonality,
  TargetStatus.blocked => Icons.block,
  TargetStatus.outOfRange => Icons.straighten_outlined,
  TargetStatus.notEvaluated => Icons.help_outline,
};

class TacticalToolbar extends StatelessWidget {
  const TacticalToolbar({required this.controller, super.key});
  final EditorController controller;
  @override
  Widget build(BuildContext context) {
    final measuring = controller.value.tool == EditorTool.distance;
    final tactical = controller.tactical;
    final selected = tactical.selected;
    final distance = tactical.measurement;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            [
                  if (measuring) ...[
                    TextButton(
                      key: const ValueKey('distance-origin'),
                      onPressed: () =>
                          controller.updateSight((p) => p.chooseOrigin = true),
                      child: Text(
                        '${controller.sight.chooseOrigin ? '* ' : ''}Origen',
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('distance-destination'),
                      onPressed: () =>
                          controller.updateSight((p) => p.chooseOrigin = false),
                      child: Text(
                        '${!controller.sight.chooseOrigin ? '* ' : ''}Destino',
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('distance-coordinates'),
                      onPressed: () => showSightEndpoints(context, controller),
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: const Text(
                        'Coordenadas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('distance-summary'),
                      onPressed: () => showDistanceReport(context, controller),
                      child: Text(
                        distance?.squares == null
                            ? 'Distancia · elegir dos casillas'
                            : 'Distancia: ${distance!.squares} casillas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    TextButton.icon(
                      key: const ValueKey('show-targets'),
                      onPressed: () => showTargetList(context, controller),
                      icon: const Icon(Icons.radar_outlined),
                      label: const Text(
                        'Mostrar objetivos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selected != null)
                      TextButton(
                        key: const ValueKey('selected-target-summary'),
                        onPressed: () => showTargetReport(context, controller),
                        child: Text(
                          '${selected.target.label} · D ${selected.distance.squares ?? '?'} / A ${selected.declaredRange} · ${targetLabel(selected.status)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (selected == null)
                      const Text(
                        'Elige origen y un objetivo de la lista',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ]
                .map(
                  (child) => ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width - 32,
                    ),
                    child: child,
                  ),
                )
                .toList(),
      ),
    );
  }
}

Future<void> showDistanceReport(
  BuildContext context,
  EditorController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => ValueListenableBuilder<BoardSession>(
    valueListenable: controller,
    builder: (context, session, _) {
      final m = controller.tactical.measurement;
      return ScenarioFormDialog(
        title: 'Medir distancia',
        children: [
          Text(
            m?.squares == null
                ? m?.reason ?? 'Elige dos casillas en el tablero.'
                : '${m!.squares} casillas',
            key: const ValueKey('distance-result'),
          ),
          Text(
            'Origen: ${controller.sight.origin?.describe(session) ?? 'sin elegir'}',
          ),
          Text(
            'Destino: ${controller.sight.destination?.describe(session) ?? 'sin elegir'}',
          ),
          const Text(
            'Conteo de casillas, incluidas diagonales; cero en origen. El terreno no cambia esta cuenta. No es una ruta de movimiento.',
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            key: const ValueKey('distance-deltas'),
            title: const Text('Mostrar diferencias de filas y columnas'),
            value: controller.tactical.showDeltas,
            onChanged: (v) =>
                controller.updateTactical((t) => t.showDeltas = v!),
          ),
          if (controller.tactical.showDeltas && m?.squares != null)
            Text('Diferencia de filas: ${m!.rows} · columnas: ${m.columns}'),
          Text(TacticalRule.distance.citation),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  ),
);

Future<void> _editRange(
  BuildContext context,
  EditorController controller,
  Character source,
) async {
  final value = await showDialog<int>(
    context: context,
    builder: (context) => _RangeDialog(initial: source.range),
  );
  if (value == null) return;
  final latest = controller.value.characters.byId(source.id);
  if (latest == null) return;
  final error = controller.saveCharacter(
    CharacterDraft(
      name: latest.name,
      teamId: latest.teamId,
      position: latest.position,
      footprint: latest.footprint,
      speed: latest.speed,
      range: value,
      abilities: latest.abilities,
      size: latest.size,
      movementAbilities: latest.movementAbilities,
    ),
    id: latest.id,
    allowStudy: latest.occupiedCells.any(
      controller.value.studyConflicts.contains,
    ),
  );
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

class _RangeDialog extends StatefulWidget {
  const _RangeDialog({required this.initial});
  final int initial;
  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  late final input = TextEditingController(text: widget.initial.toString());
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  String? error;
  @override
  Widget build(BuildContext context) => ScenarioFormDialog(
    title: 'Alcance declarado',
    children: [
      TextField(
        key: const ValueKey('range-input'),
        controller: input,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Alcance (0–99)',
          errorText: error,
        ),
      ),
      const Text(
        'Se compara este valor anotado. No se aplican modificadores ni poderes.',
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const ValueKey('range-save'),
        onPressed: () {
          final value = int.tryParse(input.text.trim());
          if (value == null || value < 0 || value > 99) {
            setState(() => error = 'Introduce un entero de 0 a 99.');
            return;
          }
          Navigator.pop(context, value);
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}

Future<void> showTargetList(BuildContext context, EditorController controller) {
  controller.enableTargets();
  return showDialog<void>(
    context: context,
    builder: (_) => ValueListenableBuilder<BoardSession>(
      valueListenable: controller,
      builder: (context, session, _) {
        final t = controller.tactical;
        final source = session.characters.byId(t.sourceId ?? '');
        return ScenarioFormDialog(
          title: 'Objetivos · análisis preliminar',
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('target-source-${source?.id}'),
              initialValue: source?.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Figura de origen'),
              items: [
                for (final f in session.characters.all)
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
                if (id != null) controller.setTargetSource(id);
              },
            ),
            DropdownButtonFormField<TargetFilter>(
              key: const ValueKey('target-filter'),
              initialValue: t.filter,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Mostrar figuras'),
              items: const [
                DropdownMenuItem(
                  value: TargetFilter.enemies,
                  child: Text('Enemigas'),
                ),
                DropdownMenuItem(
                  value: TargetFilter.allies,
                  child: Text('Aliadas'),
                ),
                DropdownMenuItem(value: TargetFilter.all, child: Text('Todas')),
              ],
              onChanged: (v) => controller.updateTactical((t) => t.filter = v!),
            ),
            if (source != null)
              TextButton.icon(
                key: const ValueKey('target-edit-range'),
                onPressed: () => _editRange(context, controller, source),
                icon: const Icon(Icons.edit_outlined),
                label: Text('Editar alcance: ${source.range}'),
              ),
            const Text(_attackLimit),
            if (source == null)
              const Text(
                'Selecciona una figura de origen. También puedes tocarla en el tablero antes de abrir objetivos.',
              ),
            if (t.report?.error != null) Text(t.report!.error!),
            if (source != null && t.visible.isEmpty)
              const Text('Sin otras figuras para este filtro.'),
            for (final item in t.visible)
              ListTile(
                key: ValueKey('target-${item.target.id}'),
                selected: item.target.id == t.selectedTargetId,
                leading: Icon(
                  targetIcon(item.status),
                  color: targetColor(item.status),
                ),
                title: Text(
                  '${item.target.label} · ${item.target.name} · ${item.target.position.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Distancia ${item.distance.squares ?? '?'} · alcance ${item.declaredRange}\n${targetLabel(item.status)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  controller.selectTarget(item.target.id);
                  Navigator.pop(context);
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> showTargetReport(
  BuildContext context,
  EditorController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => ValueListenableBuilder<BoardSession>(
    valueListenable: controller,
    builder: (context, session, _) {
      final item = controller.tactical.selected;
      return ScenarioFormDialog(
        title: 'Análisis del objetivo',
        children: [
          if (item == null)
            const Text('El origen u objetivo ya no está disponible.'),
          if (item != null) ...[
            Text(
              targetLabel(item.status),
              key: const ValueKey('target-result'),
            ),
            Text('Origen ${item.source.label} · destino ${item.target.label}'),
            Text(
              'Distancia: ${item.distance.squares ?? 'No evaluada'} · alcance declarado: ${item.declaredRange}',
            ),
            Text(
              'Referencias elegidas: ${item.vision.origin?.cell.label ?? '?'} / ${item.vision.destination?.cell.label ?? '?'} · ${item.vision.references.length} pares consultados.',
            ),
            if (item.vision.context.laboratoryAbilities != null)
              const Text(
                'HIPÓTESIS de laboratorio; no modifica la ficha guardada.',
              ),
            Text(rangeLabel(item.range)),
            Text('Visión: ${visionLabel(item.vision.status)}'),
            Text(item.vision.explanation),
            const Text(_attackLimit),
            const Text('Comprobado:'),
            for (final text in item.evaluated) Text(text),
            const Text('Pendiente / fuera de cobertura:'),
            for (final text in item.pending) Text(text),
            const Text('Referencias:'),
            for (final rule in item.rules) Text(rule.citation),
            TextButton(
              key: const ValueKey('target-vision-log'),
              onPressed: () => showVisionReport(context, controller),
              child: const Text('Ver registro de visión'),
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
