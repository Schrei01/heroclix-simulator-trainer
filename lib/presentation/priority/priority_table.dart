import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/priority/priority.dart';
import '../theme/app_theme.dart';
import 'priority_controller.dart';
import 'priority_input.dart';
import 'priority_table_layout.dart';
import 'priority_player_header.dart';

class PriorityTable extends StatelessWidget {
  const PriorityTable({required this.controller, super.key});
  final PriorityController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<PriorityMatch?>(
    valueListenable: controller,
    builder: (context, match, _) {
      if (match == null) return const SizedBox.shrink();
      return Semantics(
        label: 'Ronda ${match.round}, turno ${match.turn}.',
        child: LayoutBuilder(
          builder: (context, space) {
            final seats = priorityTableSeats(
              space.biggest,
              match.players.length,
              landscape:
                  MediaQuery.orientationOf(context) == Orientation.landscape,
            );
            return Stack(
              key: const ValueKey('priority-table'),
              children: [
                for (var i = 0; i < match.players.length; i++)
                  Positioned.fromRect(
                    rect: seats[i].bounds,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: RotatedBox(
                        key: ValueKey(
                          'priority-orientation-${match.players[i].id}',
                        ),
                        quarterTurns: seats[i].quarterTurns,
                        child: _PlayerPanel(
                          controller: controller,
                          match: match,
                          player: match.players[i],
                          seat: i,
                          quarterTurns: seats[i].quarterTurns,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    },
  );
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.controller,
    required this.match,
    required this.player,
    required this.seat,
    required this.quarterTurns,
  });
  final PriorityController controller;
  final PriorityMatch match;
  final PriorityPlayer player;
  final int seat, quarterTurns;

  @override
  Widget build(BuildContext context) {
    final active =
        !player.eliminated &&
        match.phase != PriorityPhase.finished &&
        match.activePlayerId == player.id;
    final priority = match.priorityPlayerId == player.id;
    final color = priorityPlayerColors[seat];
    final commands = active
        ? [
            PriorityCommand.action(player.id),
            PriorityCommand.free(player.id),
            PriorityCommand.endTurn(player.id),
          ]
        : [
            PriorityCommand.responseAction(player.id),
            PriorityCommand.responseFree(player.id),
            PriorityCommand.pass(player.id),
          ];
    final border = player.eliminated
        ? AppTheme.muted
        : priority
        ? const Color(0xFFFFD878)
        : active
        ? AppTheme.accent
        : color;
    return Semantics(
      key: priority ? ValueKey('priority-has-priority-${player.id}') : null,
      container: true,
      explicitChildNodes: true,
      liveRegion: priority,
      label: priority ? 'Con prioridad' : null,
      child: Material(
        key: ValueKey('priority-panel-${player.id}'),
        color: priority ? const Color(0xFF293B40) : AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: priority ? 3 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.max(0.0, constraints.maxWidth - 8);
            final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
            final columns = width >= 224 * scale
                ? 3
                : width >= 128 * scale
                ? 2
                : 1;
            final buttonWidth = (width - (columns - 1) * 4) / columns;
            final rows = (commands.length / columns).ceil();
            final buttonHeight = math.max(
              48.0,
              math.min(
                96.0,
                (constraints.maxHeight - (width >= 336 ? 48 : 96) - 4) / rows,
              ),
            );
            return SingleChildScrollView(
              key: ValueKey('priority-panel-scroll-${player.id}'),
              padding: const EdgeInsets.all(2),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PriorityPlayerHeader(
                      key: ValueKey('priority-header-${player.id}'),
                      controller: controller,
                      match: match,
                      player: player,
                      seat: seat,
                      color: color,
                      quarterTurns: quarterTurns,
                      editActions: () => showDialog<void>(
                        context: context,
                        builder: (_) => _ActionsDialog(
                          controller: controller,
                          playerId: player.id,
                          quarterTurns: quarterTurns,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        for (final command in commands)
                          SizedBox(
                            width: buttonWidth,
                            child: FilledButton(
                              key: ValueKey(
                                'priority-${command.operation.name}-${player.id}',
                              ),
                              onPressed: controller.can(command)
                                  ? () => controller.dispatch(
                                      command,
                                      expectedRevision: match.revision,
                                    )
                                  : null,
                              style: FilledButton.styleFrom(
                                minimumSize: Size(48, buttonHeight),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(fontSize: 12, height: 1.1),
                              ),
                              child: scale <= 1
                                  ? FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _buttonLabel(command.operation),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : Text(
                                      _buttonLabel(command.operation),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

String _buttonLabel(PriorityOperation operation) => switch (operation) {
  PriorityOperation.action => 'ACTION',
  PriorityOperation.free => 'FREE',
  PriorityOperation.endTurn => 'END TURN',
  PriorityOperation.responseAction => 'RESPONSE\nACTION',
  PriorityOperation.responseFree => 'RESPONSE\nFREE',
  PriorityOperation.pass => 'PASS',
  _ => throw ArgumentError.value(operation, 'operation'),
};

class _ActionsDialog extends StatefulWidget {
  const _ActionsDialog({
    required this.controller,
    required this.playerId,
    required this.quarterTurns,
  });
  final PriorityController controller;
  final String playerId;
  final int quarterTurns;
  @override
  State<_ActionsDialog> createState() => _ActionsDialogState();
}

class _ActionsDialogState extends State<_ActionsDialog> {
  final _form = GlobalKey<FormState>();
  late final _additional = TextEditingController(
    text:
        '${widget.controller.value!.player(widget.playerId).additionalActions}',
  );
  String? _error;

  @override
  void dispose() {
    _additional.dispose();
    super.dispose();
  }

  void _apply(PriorityMatch match) {
    if (!_form.currentState!.validate()) return;
    final command = PriorityCommand.setAdditionalActions(
      widget.playerId,
      int.parse(_additional.text.trim()),
    );
    if (widget.controller.dispatch(command, expectedRevision: match.revision)) {
      Navigator.pop(context);
    } else {
      setState(
        () => _error = 'No se pudo aplicar el cambio. Revisa el valor y el estado de la partida.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(12),
    child: RotatedBox(
      quarterTurns: widget.quarterTurns,
      child: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<PriorityMatch?>(
            valueListenable: widget.controller,
            builder: (context, match, _) {
              if (match == null) return const SizedBox.shrink();
              final player = match.player(widget.playerId);
              return Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones · ${player.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${player.baseActions} base · ${player.consumedActions} consumidas',
                    ),
                    Text(
                      '${player.availableActions} disponibles / ${player.totalActions} totales',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('priority-edit-additional'),
                      controller: _additional,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Acciones adicionales',
                      ),
                      validator: priorityIntegerError,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cambiar el total conserva las acciones ya consumidas.',
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          key: const ValueKey('priority-edit-apply'),
                          onPressed: () => _apply(match),
                          child: const Text('Aplicar'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
