import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/priority/priority.dart';
import '../theme/app_theme.dart';
import 'priority_controller.dart';
import 'priority_input.dart';
import 'priority_management.dart';
import 'priority_skull_icon.dart';
import 'priority_theme.dart';
import 'priority_active_indicator.dart';
import 'priority_rank_badge.dart';
import 'priority_seat_drag.dart';

class PriorityPlayerHeader extends StatefulWidget {
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
  State<PriorityPlayerHeader> createState() => _PriorityPlayerHeaderState();
}

class _PriorityPlayerHeaderState extends State<PriorityPlayerHeader>
    with SingleTickerProviderStateMixin {
  int _delta = 0;
  late final _fade =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _delta = 0);
          }
        });
  late final _opacity = Tween<double>(
    begin: 1,
    end: 0,
  ).animate(CurvedAnimation(parent: _fade, curve: Curves.easeInCubic));

  void _adjust(int amount) {
    final controller = widget.controller;
    controller.synchronizeClock();
    final match = controller.value;
    if (match == null ||
        !controller.dispatch(
          PriorityCommand.adjustVictoryPoints(widget.player.id, amount),
          expectedRevision: match.revision,
        )) {
      return;
    }
    setState(
      () => _delta = _delta.sign == amount.sign ? _delta + amount : amount,
    );
    _fade.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant PriorityPlayerHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.player.eliminated && !oldWidget.player.eliminated) {
      _fade.stop();
      _delta = 0;
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final match = widget.match;
    final player = widget.player;
    final seat = widget.seat;
    final color = widget.color;
    final quarterTurns = widget.quarterTurns;
    final editActions = widget.editActions;
    final active =
        !player.eliminated &&
        match.phase != PriorityPhase.finished &&
        match.activePlayerId == player.id;
    final name = Semantics(
      button: true,
      label: 'Opciones de ${player.name}',
      hint: 'Mantén pulsado y arrastra para intercambiar asientos.',
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
              if (active)
                PriorityActiveIndicator(playerId: player.id, color: color)
              else
                Text(
                  player.eliminated
                      ? 'ELIMINADO'
                      : match.phase == PriorityPhase.finished
                      ? 'FINALIZADA'
                      : 'REACTIVO',
                  key: player.eliminated
                      ? ValueKey('priority-eliminated-${player.id}')
                      : null,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    color: AppTheme.muted,
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
      child: Semantics(
        label:
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
    final position = match.standings
        .firstWhere((s) => s.player.id == player.id)
        .position;
    final score = SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 24,
            child: Semantics(
              label: '${player.victoryPoints} puntos de victoria',
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${player.victoryPoints} PV',
                  key: ValueKey('priority-score-${player.id}'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          if (_delta != 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 12,
              child: FadeTransition(
                key: ValueKey('priority-score-feedback-${player.id}'),
                opacity: _opacity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_delta > 0 ? '+' : ''}$_delta',
                    key: ValueKey('priority-score-delta-${player.id}'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.bold,
                      color: _delta > 0 ? AppTheme.accent : Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    Widget scoreStep(int amount) => IconButton(
      key: ValueKey(
        'priority-score-${amount > 0 ? 'plus' : 'minus'}-${player.id}',
      ),
      tooltip: '${amount > 0 ? 'Sumar' : 'Restar'} 5 PV a ${player.name}',
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: PriorityTheme.shape,
      ),
      onPressed:
          controller.can(PriorityCommand.adjustVictoryPoints(player.id, amount))
          ? () => _adjust(amount)
          : null,
      icon: Icon(
        amount > 0 ? Icons.add : Icons.remove,
        semanticLabel:
            '${amount > 0 ? 'Sumar' : 'Restar'} 5 PV a ${player.name}',
      ),
    );
    final skull = IconButton(
      key: ValueKey('priority-skull-${player.id}'),
      tooltip: 'Eliminar a ${player.name}',
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: PriorityTheme.shape,
      ),
      onPressed: controller.can(PriorityCommand.eliminate(player.id))
          ? () => showPriorityElimination(
              context,
              controller,
              player.id,
              quarterTurns,
            )
          : null,
      icon: Semantics(
        label: 'Eliminar a ${player.name}',
        child: const PrioritySkullIcon(),
      ),
    );
    return LayoutBuilder(
      builder: (context, space) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(196, space.maxWidth),
          child: Column(
            children: [
              Row(
                children: [
                  PriorityRankBadge(playerId: player.id, position: position),
                  const SizedBox(width: 4),
                  Expanded(
                    child: PrioritySeatDragSource(
                      group: match.configuration,
                      playerId: player.id,
                      name: player.name,
                      color: color,
                      quarterTurns: quarterTurns,
                      child: name,
                    ),
                  ),
                  SizedBox(width: 56, child: counter),
                  skull,
                ],
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 208),
                  child: Row(
                    key: ValueKey('priority-score-row-${player.id}'),
                    children: [
                      scoreStep(-5),
                      Expanded(child: score),
                      scoreStep(5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
