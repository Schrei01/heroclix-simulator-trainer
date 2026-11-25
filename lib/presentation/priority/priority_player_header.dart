import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/priority/priority.dart';
import '../theme/app_theme.dart';
import 'priority_controller.dart';
import 'priority_input.dart';
import 'priority_management.dart';

class PriorityPlayerHeader extends StatelessWidget {
  const PriorityPlayerHeader({
    required this.controller,
    required this.match,
    required this.player,
    required this.seat,
    required this.color,
    required this.quarterTurns,
    required this.editActions,
    super.key,
  });
  final PriorityController controller;
  final PriorityMatch match;
  final PriorityPlayer player;
  final int seat, quarterTurns;
  final Color color;
  final VoidCallback editActions;

  @override
  Widget build(BuildContext context) {
    final active =
        !player.eliminated &&
        match.phase != PriorityPhase.finished &&
        match.activePlayerId == player.id;
    final priority = match.priorityPlayerId == player.id;
    final name = Semantics(
      button: true,
      label: 'Opciones de ${player.name}',
      child: InkWell(
        key: ValueKey('priority-player-menu-${player.id}'),
        onTap: () =>
            showPriorityPlayer(context, controller, player.id, quarterTurns),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${seat + 1}. ${player.name}',
                      key: ValueKey('priority-player-name-${player.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        height: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.more_vert, size: 14),
                ],
              ),
              Text(
                player.eliminated
                    ? 'ELIMINADO'
                    : match.phase == PriorityPhase.finished
                    ? 'FINALIZADA'
                    : active
                    ? 'ACTIVO'
                    : 'REACTIVO',
                key: player.eliminated
                    ? ValueKey('priority-eliminated-${player.id}')
                    : active
                    ? ValueKey('priority-active-${player.id}')
                    : null,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  color: active ? AppTheme.accent : AppTheme.muted,
                ),
              ),
              if (priority)
                Text(
                  'PRIORIDAD',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  key: ValueKey('priority-has-priority-${player.id}'),
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    color: Color(0xFFFFD878),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final counter = TextButton(
      key: ValueKey('priority-count-${player.id}'),
      onPressed:
          controller.can(
            PriorityCommand.setAdditionalActions(
              player.id,
              player.additionalActions,
            ),
          )
          ? editActions
          : null,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 2),
      ),
      child: Tooltip(
        message:
            'Editar acciones de ${player.name}. ${player.availableActions} disponibles '
            'de ${player.totalActions}. ${player.victoryPoints} puntos de victoria. Toca el nombre para más opciones.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${player.availableActions} / ${player.totalActions}',
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${player.victoryPoints} PV',
                key: ValueKey('priority-score-${player.id}'),
                style: const TextStyle(fontSize: 11, height: 1.1),
              ),
            ),
            if (match.configuration.clockEnabled)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  priorityTimeLabel(player.remainingTime!),
                  key: ValueKey('priority-clock-${player.id}'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    color: player.remainingTime == Duration.zero
                        ? Colors.redAccent
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, space) => space.maxWidth < 108
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [name, counter],
            )
          : Row(
              children: [
                Expanded(child: name),
                SizedBox(
                  width: math.min(88, math.max(48, space.maxWidth * .45)),
                  child: counter,
                ),
              ],
            ),
    );
  }
}
