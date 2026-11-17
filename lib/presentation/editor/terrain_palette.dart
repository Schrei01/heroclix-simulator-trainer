import 'package:material_ui/material_ui.dart';

import '../../domain/terrain/terrain.dart';
import '../theme/app_theme.dart';
import 'editor_controller.dart';
import 'layer_actions.dart';

/// Fuera del receptor de gestos del tablero: elegir un tipo nunca pinta casillas.
class TerrainPalette extends StatelessWidget {
  const TerrainPalette({required this.controller, super.key});
  final EditorController controller;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labels =
          constraints.maxWidth >= 354 &&
          MediaQuery.textScalerOf(context).scale(12) <= 15.6;
      return Padding(
        key: const ValueKey('terrain-palette'),
        padding: const EdgeInsets.all(8),
        child: Center(
          heightFactor: 1,
          child: Material(
            color: AppTheme.surface,
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final type in [
                    TerrainType.blocking,
                    TerrainType.hindering,
                    TerrainType.clear,
                  ])
                    _button(context, type, labels),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _button(BuildContext context, TerrainType type, bool labels) {
    final selected = controller.value.terrainType == type;
    void choose() => controller.configureLayers(type: type);
    return Semantics(
      label: terrainName(type),
      button: true,
      selected: selected,
      onTap: choose,
      child: ExcludeSemantics(
        child: Tooltip(
          message: terrainName(type),
          child: Material(
            color: selected ? const Color(0xff284b4c) : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected ? AppTheme.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              key: ValueKey('terrain-${type.name}'),
              onTap: choose,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: labels ? 110 : 56,
                height: labels ? 64 : 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(switch (type) {
                          TerrainType.blocking => Icons.block,
                          TerrainType.hindering => Icons.grain,
                          TerrainType.clear => Icons.crop_square,
                        }, color: selected ? AppTheme.accent : AppTheme.muted),
                        if (selected)
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: AppTheme.accent,
                          ),
                      ],
                    ),
                    if (labels) ...[
                      const SizedBox(height: 2),
                      Text(
                        terrainName(type),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
