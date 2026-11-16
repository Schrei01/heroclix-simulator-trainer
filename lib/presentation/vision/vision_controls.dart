import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/rules/line_of_sight.dart';
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
              'Perfil básico: figuras genéricas normales, sin poderes, en tablero plano. Este apoyo no sustituye una decisión oficial de torneo.',
            ),
            Text('Reglamento verificado: ${controller.rulesVersion}.'),
            Text(
              'Origen: ${controller.sight.origin?.describe(session) ?? 'sin elegir'}',
            ),
            Text(
              'Destino: ${controller.sight.destination?.describe(session) ?? 'sin elegir'}',
            ),
            const Text(
              'Indica si hay poderes, tamaños, fuente remota o reglas particulares que no están modelados. Con efectos especiales, el dictamen queda No evaluado.',
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
