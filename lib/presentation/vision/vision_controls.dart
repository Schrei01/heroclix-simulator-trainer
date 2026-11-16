import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/rules/line_of_sight.dart';
import '../../domain/characters/vision_ability.dart';
import '../editor/editor_controller.dart';
import '../scenarios/scenario_dialogs.dart';

String visionLabel(VisionStatus status) => switch (status) {
  VisionStatus.clear => 'DESPEJADA',
  VisionStatus.hindered => 'OBSTACULIZADA',
  VisionStatus.blocked => 'BLOQUEADA',
  VisionStatus.notEvaluated => 'NO EVALUADA',
};
Color visionColor(VisionStatus status) => switch (status) {
  VisionStatus.clear => const Color(0xff81d69b),
  VisionStatus.hindered => const Color(0xffffcb70),
  VisionStatus.blocked => const Color(0xffff8e8e),
  VisionStatus.notEvaluated => const Color(0xffb7c1cb),
};
IconData visionIcon(VisionStatus status) => switch (status) {
  VisionStatus.clear => Icons.check_circle_outline,
  VisionStatus.hindered => Icons.tonality,
  VisionStatus.blocked => Icons.block,
  VisionStatus.notEvaluated => Icons.help_outline,
};

Future<void> showVisionReport(
  BuildContext context,
  EditorController controller,
) {
  controller.updateVision((vision) => vision.enabled = true);
  return showDialog<void>(
    context: context,
    builder: (context) => ValueListenableBuilder<BoardSession>(
      valueListenable: controller,
      builder: (context, session, _) {
        final analysis = controller.vision, result = analysis.result;
        final status = result?.status ?? VisionStatus.notEvaluated;
        final source =
            session.characters.byId(
              controller.sight.origin?.figureId ??
                  controller.tactical.sourceId ??
                  '',
            ) ??
            (result?.origin == null
                ? null
                : session.characters.at(result!.origin!.cell));
        return ScenarioFormDialog(
          title: 'Dictamen de visión',
          children: [
            Row(
              children: [
                Icon(visionIcon(status), color: visionColor(status)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visionLabel(status),
                    key: const ValueKey('vision-result'),
                    style: TextStyle(
                      color: visionColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              result?.explanation ??
                  'Elige una figura de origen y una figura o casilla objetivo.',
            ),
            Text(
              result?.canSee == true
                  ? 'Puede trazar la línea de visión bajo este perfil.'
                  : result?.canSee == false
                  ? 'La línea de visión no puede trazarse bajo este perfil.'
                  : 'No se ha determinado si puede trazar la línea de visión.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo línea de visión. No comprueba alcance, acciones ni legalidad completa de un ataque.',
            ),
            const Text(
              'Perfil verificado: elevaciones, bases reconocidas y mejoras de visión tipadas. Este apoyo no sustituye una decisión oficial de torneo.',
            ),
            Text('Reglamento verificado: ${controller.rulesVersion}.'),
            Text(
              'Origen: ${controller.sight.origin?.describe(session) ?? 'sin elegir'}',
            ),
            Text(
              'Destino: ${controller.sight.destination?.describe(session) ?? 'sin elegir'}',
            ),
            if (result?.origin != null && result?.destination != null)
              Text(
                'Par evaluado: ${result!.origin!.cell.label} / ${result.destination!.cell.label}',
              ),
            Text(
              'Capacidades de ficha del origen: ${source == null || source.abilities.isEmpty ? 'ninguna' : source.abilities.map((a) => a.label).join(', ')}',
            ),
            CheckboxListTile(
              key: const ValueKey('vision-auto-references'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Referencias automáticas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: analysis.automaticReferences,
              onChanged: session.tool == EditorTool.targets
                  ? null
                  : (v) => controller.updateVision(
                      (a) => a.automaticReferences = v!,
                    ),
            ),
            const Text(
              'En Visión, busca pares permitidos de base; al desactivar usa la referencia manual. Objetivos siempre compara alcance y visión desde el mismo par.',
            ),
            CheckboxListTile(
              key: const ValueKey('vision-laboratory'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Laboratorio de capacidades',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: analysis.laboratoryAbilities != null,
              onChanged: (v) => controller.updateVision(
                (a) =>
                    a.laboratoryAbilities = v! ? {...?source?.abilities} : null,
              ),
            ),
            if (analysis.laboratoryAbilities != null) ...[
              const Text(
                'HIPÓTESIS TEMPORAL: sustituye las capacidades de la ficha solo para comparar. No se guarda ni modifica el personaje.',
              ),
              for (final ability in VisionAbility.values.where(
                (a) => a.supported,
              ))
                CheckboxListTile(
                  key: ValueKey('lab-${ability.name}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'IT ${ability.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: analysis.laboratoryAbilities!.contains(ability),
                  onChanged: (checked) => controller.updateVision((a) {
                    final next = {...a.laboratoryAbilities!};
                    if (checked!) {
                      next.add(ability);
                    } else {
                      next.remove(ability);
                    }
                    a.laboratoryAbilities = next;
                  }),
                ),
            ],
            const Text(
              'Marca Efectos especiales solo si hay otras condiciones no modeladas. Las capacidades declaradas de la ficha se aplican automáticamente. Lo que no tiene soporte queda No evaluado.',
            ),
            CheckboxListTile(
              key: const ValueKey('vision-special-effects'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Efectos especiales',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: analysis.specialEffects,
              onChanged: (value) =>
                  controller.updateVision((v) => v.specialEffects = value!),
            ),
            CheckboxListTile(
              key: const ValueKey('vision-show-causes'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Resaltar causas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: analysis.showCauses,
              onChanged: (value) =>
                  controller.updateVision((v) => v.showCauses = value!),
            ),
            if (result != null) ...[
              if (result.references.length > 1)
                ExpansionTile(
                  key: const ValueKey('vision-reference-pairs'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Pares de referencia (${result.references.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  children: [
                    for (final ref in result.references)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${ref.origin.label} / ${ref.destination.label}: ${visionLabel(ref.status)} · D ${ref.distance ?? '?'}',
                        ),
                      ),
                  ],
                ),
              Text(
                'Registro: ${result.trace?.events.length ?? 0} eventos geométricos · ${result.observations.length} comprobaciones',
                key: const ValueKey('vision-log-summary'),
              ),
              ExpansionTile(
                key: const ValueKey('vision-log'),
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Registro y referencias',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                children: [
                  for (
                    var index = 0;
                    index < result.observations.length;
                    index++
                  )
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${index + 1}. ${result.observations[index].description}\n${result.observations[index].rules.map((rule) => rule.citation).join(' · ')}${result.observations[index].eventIndex == null ? '' : '\nEvento ${result.observations[index].eventIndex! + 1}'}${result.status != VisionStatus.clear && result.decisive.contains(result.observations[index]) ? '\nDetermina este dictamen.' : ''}',
                          key: ValueKey('vision-observation-$index'),
                        ),
                      ),
                    ),
                ],
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
}
