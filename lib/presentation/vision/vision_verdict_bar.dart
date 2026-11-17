import 'package:material_ui/material_ui.dart';

import '../editor/editor_controller.dart';
import '../theme/app_theme.dart';
import 'vision_controls.dart';

/// El dictamen existente, visible al completar la línea; sin reglas duplicadas.
class VisionVerdictBar extends StatelessWidget {
  const VisionVerdictBar({required this.controller, super.key});
  final EditorController controller;
  @override
  Widget build(BuildContext context) {
    final result = controller.vision.result;
    if (result == null) return const SizedBox.shrink();
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 24;
    final label = visionLabel(result.status),
        color = visionColor(result.status);
    final endpoints = result.origin != null && result.destination != null
        ? ' · ${result.origin!.cell.label} a ${result.destination!.cell.label}'
        : '';
    final description =
        'Visión: $label$endpoints. ${result.explanation} Edición ${result.context.rulesVersion}. Toca para ver el dictamen y sus referencias.';
    void details() => showVisionReport(context, controller);
    return Semantics(
      key: const ValueKey('vision-map-verdict'),
      label: description,
      liveRegion: true,
      button: true,
      onTap: details,
      child: ExcludeSemantics(
        child: Tooltip(
          message: description,
          child: Material(
            color: AppTheme.surface,
            child: InkWell(
              onTap: details,
              child: SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(visionIcon(result.status), color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          largeText ? label : 'Visión: $label$endpoints',
                          key: const ValueKey('vision-map-result'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: largeText ? 12 : 14,
                            height: 1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.info_outline, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
