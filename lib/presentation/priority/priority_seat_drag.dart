import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class PrioritySeatDragData {
  const PrioritySeatDragData(this.group, this.playerId);
  final Object group;
  final String playerId;
}

class PrioritySeatDragSource extends StatelessWidget {
  const PrioritySeatDragSource({
    required this.group,
    required this.playerId,
    required this.name,
    required this.color,
    required this.quarterTurns,
    required this.child,
    super.key,
  });
  final Object group;
  final String playerId, name;
  final Color color;
  final int quarterTurns;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      LongPressDraggable<PrioritySeatDragData>(
        key: ValueKey('priority-drag-$playerId'),
        data: PrioritySeatDragData(group, playerId),
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: FractionalTranslation(
          translation: const Offset(-.5, -1.1),
          child: RotatedBox(
            quarterTurns: quarterTurns,
            child: Material(
              elevation: 8,
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: color, width: 2),
              ),
              child: SizedBox(
                width: 156,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: child,
      );
}

class PrioritySeatDropZone extends StatelessWidget {
  const PrioritySeatDropZone({
    required this.group,
    required this.playerId,
    required this.onSwap,
    required this.child,
    super.key,
  });
  final Object group;
  final String playerId;
  final void Function(String source, String destination) onSwap;
  final Widget child;

  @override
  Widget build(BuildContext context) => DragTarget<PrioritySeatDragData>(
    key: ValueKey('priority-drop-$playerId'),
    onWillAcceptWithDetails: (details) =>
        identical(details.data.group, group) &&
        details.data.playerId != playerId,
    onAcceptWithDetails: (details) => onSwap(details.data.playerId, playerId),
    builder: (context, candidates, rejected) => Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (candidates.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: ValueKey('priority-drop-highlight-$playerId'),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent, width: 3),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
