import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../theme/app_theme.dart';
import 'editor_controller.dart';

String brushName(TerrainBrush brush) => switch (brush) {
  TerrainBrush.blocking => 'Bloqueado',
  TerrainBrush.hindering => 'Obstaculizado',
  TerrainBrush.water => 'Agua',
  TerrainBrush.indoor => 'Indoor',
  TerrainBrush.elevated => 'Elevado',
  TerrainBrush.transition => 'Transición',
  TerrainBrush.clear => 'Despejado',
};

/// Fuera del receptor de gestos: elegir un pincel nunca modifica el tablero.
class TerrainPalette extends StatelessWidget {
  const TerrainPalette({required this.controller, super.key});
  final EditorController controller;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labels =
          constraints.maxWidth >= 560 &&
          MediaQuery.textScalerOf(context).scale(12) <= 15.6;
      final width = ((constraints.maxWidth - 16) / TerrainBrush.values.length)
          .clamp(48.0, 110.0);
      return Padding(
        key: const ValueKey('terrain-palette'),
        padding: const EdgeInsets.all(4),
        child: Center(
          heightFactor: 1,
          child: Material(
            color: AppTheme.surface,
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final brush in TerrainBrush.values)
                    _button(context, brush, labels, width),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _button(
    BuildContext context,
    TerrainBrush brush,
    bool labels,
    double width,
  ) {
    final selected = controller.value.terrainBrush == brush;
    void choose() {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      controller.configureLayers(brush: brush);
    }

    return Semantics(
      label: brushName(brush),
      button: true,
      selected: selected,
      onTap: choose,
      child: ExcludeSemantics(
        child: Tooltip(
          message: brush == TerrainBrush.elevated
              ? 'Terreno elevado: traza para subir un nivel por casilla (E2, E3…)'
              : brush == TerrainBrush.transition
              ? 'Transición: toca dos casillas vecinas de distinto nivel'
              : brushName(brush),
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
              key: ValueKey('terrain-${brush.name}'),
              onTap: choose,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: width,
                height: labels ? 64 : 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(switch (brush) {
                          TerrainBrush.blocking => Icons.block,
                          TerrainBrush.hindering => Icons.grain,
                          TerrainBrush.water => Icons.water_drop_outlined,
                          TerrainBrush.indoor => Icons.home_outlined,
                          TerrainBrush.elevated => Icons.layers_outlined,
                          TerrainBrush.transition => Icons.change_history,
                          TerrainBrush.clear => Icons.crop_square,
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
                        brushName(brush),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
