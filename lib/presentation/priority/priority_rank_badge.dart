import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class PriorityRankBadge extends StatelessWidget {
  const PriorityRankBadge({
    required this.playerId,
    required this.position,
    super.key,
  });
  final String playerId;
  final int position;

  static const gold = Color(0xFFFFD878);
  static const bronze = Color(0xFFCD8C52);

  @override
  Widget build(BuildContext context) {
    final color = position <= 2
        ? gold
        : position == 3
        ? bronze
        : AppTheme.accent;
    return Tooltip(
      message: 'Posición $position por puntos de victoria',
      child: Semantics(
        label: 'Posición $position por puntos de victoria',
        child: ExcludeSemantics(
          child: Container(
            key: ValueKey('priority-rank-badge-$playerId'),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .14),
              border: Border.all(color: color, width: 1.5),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$position',
                key: ValueKey('priority-rank-$playerId'),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
