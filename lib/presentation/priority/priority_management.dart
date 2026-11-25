import 'package:material_ui/material_ui.dart';

import '../../domain/priority/priority.dart';
import 'priority_controller.dart';
import 'priority_input.dart';

Widget priorityRotatedDialog(int turns, Widget child) => Dialog(
  insetPadding: const EdgeInsets.all(12),
  child: RotatedBox(
    quarterTurns: turns,
    child: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  ),
);

Future<void> showPriorityStandings(
  BuildContext context,
  PriorityController controller,
) => showDialog<void>(
  context: context,
  builder: (context) => ValueListenableBuilder<PriorityMatch?>(
    valueListenable: controller,
    builder: (context, match, _) {
      if (match == null) return const SizedBox.shrink();
      return priorityRotatedDialog(
        0,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.phase == PriorityPhase.finished
                  ? 'Partida finalizada'
                  : 'Clasificación general',
              key: const ValueKey('priority-ranking-title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Ronda ${match.round} · Turno ${match.turn}'),
            if (match.phase == PriorityPhase.finished)
              Text(
                'Jugadores no eliminados: ${match.players.where((p) => !p.eliminated).length}',
              ),
            const Text(
              'Orden por puntos de victoria. Los empates comparten posición.',
            ),
            const SizedBox(height: 12),
            for (final standing in match.standings)
              Padding(
                key: ValueKey('priority-standing-${standing.player.id}'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${standing.position}. ${standing.player.name}: ${standing.player.victoryPoints} PV'
                  ' · ${standing.player.eliminated ? 'Eliminado' : 'No eliminado'}',
                ),
              ),
            TextButton(
              key: const ValueKey('priority-ranking-close'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    },
  ),
);

Future<void> showPriorityPlayer(
  BuildContext context,
  PriorityController controller,
  String playerId,
  int quarterTurns,
) => showDialog<void>(
  context: context,
  builder: (_) => _PlayerManagement(
    controller: controller,
    playerId: playerId,
    quarterTurns: quarterTurns,
  ),
);

enum _ScoreMode { add, subtract, correct }

class _PlayerManagement extends StatefulWidget {
  const _PlayerManagement({
    required this.controller,
    required this.playerId,
    required this.quarterTurns,
  });
  final PriorityController controller;
  final String playerId;
  final int quarterTurns;
  @override
  State<_PlayerManagement> createState() => _PlayerManagementState();
}

class _PlayerManagementState extends State<_PlayerManagement> {
  final _form = GlobalKey<FormState>();
  final _points = TextEditingController(text: '0');
  _ScoreMode _mode = _ScoreMode.add;
  String? _error;
  @override
  void dispose() {
    _points.dispose();
    super.dispose();
  }

  void _score(PriorityMatch match) {
    if (!_form.currentState!.validate()) return;
    final amount = int.parse(_points.text.trim());
    final command = switch (_mode) {
      _ScoreMode.add => PriorityCommand.adjustVictoryPoints(
        widget.playerId,
        amount,
      ),
      _ScoreMode.subtract => PriorityCommand.adjustVictoryPoints(
        widget.playerId,
        -amount,
      ),
      _ScoreMode.correct => PriorityCommand.setVictoryPoints(
        widget.playerId,
        amount,
      ),
    };
    if (widget.controller.dispatch(command, expectedRevision: match.revision)) {
      setState(() {
        _error = null;
        _points.text = '0';
        _mode = _ScoreMode.add;
      });
    } else {
      setState(
        () => _error = 'Revisa el valor: los puntos no pueden quedar negativos ni desbordarse.',
      );
    }
  }

  Future<void> _eliminate() async {
    final player = widget.controller.value!.player(widget.playerId);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => priorityRotatedDialog(
        widget.quarterTurns,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Eliminar a ${player.name}?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Dejará de recibir turnos y prioridad. Sus puntos se conservarán.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  key: const ValueKey('priority-eliminate-confirm'),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || yes != true) return;
    widget.controller.synchronizeClock();
    final match = widget.controller.value;
    if (match != null &&
        widget.controller.dispatch(
          PriorityCommand.eliminate(widget.playerId),
          expectedRevision: match.revision,
        )) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<PriorityMatch?>(
    valueListenable: widget.controller,
    builder: (context, match, _) {
      if (match == null) return const SizedBox.shrink();
      final player = match.player(widget.playerId);
      final editable = widget.controller.can(
        PriorityCommand.setVictoryPoints(player.id, player.victoryPoints),
        includeInputCooldown: false,
      );
      return priorityRotatedDialog(
        widget.quarterTurns,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player.name, style: Theme.of(context).textTheme.titleLarge),
            Text(player.eliminated ? 'ELIMINADO' : 'Jugador no eliminado'),
            Text(
              '${player.victoryPoints} PV',
              key: const ValueKey('priority-player-score'),
            ),
            const SizedBox(height: 12),
            if (editable)
              Form(
                key: _form,
                child: Column(
                  children: [
                    DropdownButtonFormField<_ScoreMode>(
                      key: ValueKey('priority-score-mode-${_mode.name}'),
                      initialValue: _mode,
                      isExpanded: true,
                      itemHeight: null,
                      decoration: const InputDecoration(
                        labelText: 'Puntos de victoria',
                      ),
                      items: [
                        for (final mode in _ScoreMode.values)
                          DropdownMenuItem(
                            value: mode,
                            child: Text(
                              switch (mode) {
                                _ScoreMode.add => 'Sumar puntos',
                                _ScoreMode.subtract => 'Restar puntos',
                                _ScoreMode.correct => 'Corregir total',
                              },
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          setState(() {
                            _mode = mode;
                            _points.text = mode == _ScoreMode.correct
                                ? '${player.victoryPoints}'
                                : '0';
                          });
                        }
                      },
                    ),
                    TextFormField(
                      key: const ValueKey('priority-score-input'),
                      controller: _points,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Puntos'),
                      validator: priorityIntegerError,
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    FilledButton(
                      key: const ValueKey('priority-score-apply'),
                      onPressed: () => _score(match),
                      child: const Text('Aplicar puntos'),
                    ),
                  ],
                ),
              ),
            if (match.configuration.clockEnabled) ...[
              const SizedBox(height: 12),
              Text(
                'Tiempo restante: ${priorityTimeLabel(player.remainingTime!)}',
              ),
              Text(
                'Tiempo consumido: ${priorityTimeLabel(player.spentTime, roundUp: false)}',
              ),
              if (!player.eliminated && match.phase != PriorityPhase.finished)
                OutlinedButton(
                  key: const ValueKey('priority-correct-time'),
                  onPressed: () {
                    widget.controller.prepareTimeCorrection();
                    showDialog<void>(
                      context: context,
                      builder: (_) => _TimeCorrection(
                        controller: widget.controller,
                        playerId: player.id,
                        quarterTurns: widget.quarterTurns,
                      ),
                    );
                  },
                  child: const Text('Corregir tiempo'),
                ),
            ],
            const SizedBox(height: 12),
            if (widget.controller.can(PriorityCommand.eliminate(player.id)))
              OutlinedButton(
                key: const ValueKey('priority-eliminate'),
                onPressed: _eliminate,
                child: const Text('Eliminar jugador'),
              ),
            TextButton(
              key: const ValueKey('priority-player-close'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    },
  );
}

class _TimeCorrection extends StatefulWidget {
  const _TimeCorrection({
    required this.controller,
    required this.playerId,
    required this.quarterTurns,
  });
  final PriorityController controller;
  final String playerId;
  final int quarterTurns;
  @override
  State<_TimeCorrection> createState() => _TimeCorrectionState();
}

class _TimeCorrectionState extends State<_TimeCorrection> {
  late final _minutes = TextEditingController(
    text:
        '${widget.controller.value!.player(widget.playerId).remainingTime!.inMinutes}',
  );
  late final _seconds = TextEditingController(
    text:
        '${widget.controller.value!.player(widget.playerId).remainingTime!.inSeconds % 60}',
  );
  String? _error;
  @override
  void dispose() {
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => priorityRotatedDialog(
    widget.quarterTurns,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Corregir tiempo', style: Theme.of(context).textTheme.titleLarge),
        const Text(
          'El reloj queda pausado. Confirma el tiempo restante y reanuda después.',
        ),
        TextField(
          key: const ValueKey('priority-time-minutes'),
          controller: _minutes,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minutos'),
        ),
        TextField(
          key: const ValueKey('priority-time-seconds'),
          controller: _seconds,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Segundos (0–59)'),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('priority-time-apply'),
              onPressed: () {
                final time = priorityDurationInput(
                  _minutes.text,
                  _seconds.text,
                  allowZero: true,
                );
                final match = widget.controller.value;
                if (time != null &&
                    match != null &&
                    widget.controller.dispatch(
                      PriorityCommand.setRemainingTime(widget.playerId, time),
                      expectedRevision: match.revision,
                    )) {
                  Navigator.pop(context);
                } else {
                  setState(
                    () => _error = 'Revisa el tiempo: no puede ser negativo; segundos de 0 a 59.',
                  );
                }
              },
              child: const Text('Confirmar tiempo'),
            ),
          ],
        ),
      ],
    ),
  );
}
