import 'dart:math';
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../domain/priority/priority.dart';
import 'priority_controller.dart';
import 'priority_input.dart';
import 'priority_management.dart';
import 'priority_table.dart';
import 'priority_table_layout.dart';
import 'priority_theme.dart';
import 'priority_seat_drag.dart';
import 'priority_history.dart';

enum _PriorityMenu { history, undo, saved, finish, standings, newGame }

class PriorityScreen extends StatefulWidget {
  const PriorityScreen({required this.controller, super.key});
  final PriorityController controller;

  @override
  State<PriorityScreen> createState() => _PriorityScreenState();
}

class _PriorityScreenState extends State<PriorityScreen> {
  final _form = GlobalKey<FormState>();
  final _players = [for (var i = 1; i <= 6; i++) _SeatDraft(i)];
  int _count = 2;
  String _first = 'J1';
  String? _error;
  bool _clockEnabled = false;
  final _minutes = TextEditingController(text: '30');
  final _points = TextEditingController(text: '300');
  bool _resultsShown = false;
  String? _notifiedExpired;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _expiryNotice;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkFinished);
    unawaited(widget.controller.initialize());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFinished());
  }

  void _checkFinished() {
    if (!mounted) return;
    final match = widget.controller.value;
    _syncExpiryNotice(match);
    if (match?.phase != PriorityPhase.finished) _resultsShown = false;
    final notice = widget.controller.takeNotice();
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                notice,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
    if (match?.phase == PriorityPhase.finished && !_resultsShown) {
      _resultsShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
          showPriorityStandings(context, widget.controller);
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  void _closeExpiryNotice() {
    final notice = _expiryNotice;
    _expiryNotice = null;
    notice?.close();
  }

  void _syncExpiryNotice(PriorityMatch? match) {
    final id =
        match != null &&
            match.isPaused &&
            match.configuration.clockEnabled &&
            match.priorityPlayerId != null &&
            match.player(match.priorityPlayerId!).remainingTime == Duration.zero
        ? match.priorityPlayerId
        : null;
    if (id == null) {
      _notifiedExpired = null;
      _closeExpiryNotice();
      return;
    }
    if (_notifiedExpired == id) return;
    _notifiedExpired = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(ModalRoute.of(context)?.isActive ?? true)) return;
      final current = widget.controller.value;
      if (current == null ||
          current.priorityPlayerId != id ||
          !current.isPaused ||
          current.player(id).remainingTime != Duration.zero) {
        return;
      }
      _expiryNotice = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          persist: false,
          shape: PriorityTheme.shape,
          content: Text(
            'Tiempo agotado: ${current.player(id).name}',
            key: const ValueKey('priority-time-expired'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () {
              _closeExpiryNotice();
              final latest = widget.controller.value;
              if (latest == null) return;
              final seats = priorityTableSeats(
                MediaQuery.sizeOf(context),
                latest.players.length,
                landscape:
                    MediaQuery.orientationOf(context) == Orientation.landscape,
              );
              final index = widget.controller.visualSeatOrder.indexOf(id);
              showPriorityPlayer(
                context,
                widget.controller,
                id,
                seats[index].quarterTurns,
              );
            },
          ),
        ),
      );
      final notice = _expiryNotice;
      notice?.closed.then((_) {
        if (identical(_expiryNotice, notice)) _expiryNotice = null;
      });
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkFinished);
    widget.controller.pauseForNavigation();
    unawaited(widget.controller.flush());
    _minutes.dispose();
    _points.dispose();
    for (final player in _players) {
      player.dispose();
    }
    super.dispose();
  }

  PriorityConfiguration? _configuration({bool draw = false}) {
    if (!_form.currentState!.validate()) {
      setState(() => _error = 'Revisa los campos marcados antes de continuar.');
      return null;
    }
    try {
      final points = int.tryParse(_points.text.trim()) ?? -1;
      final players = [
        for (final p in _players.take(_count)) p.configuration(points),
      ];
      final time = _clockEnabled
          ? priorityDurationInput(_minutes.text, '0')
          : const Duration(minutes: 30);
      if (time == null) {
        setState(
          () =>
              _error = 'Escribe una cantidad válida de minutos mayor que cero.',
        );
        return null;
      }
      return draw
          ? PriorityConfiguration.randomStart(
              players: players,
              random: Random(),
              clockEnabled: _clockEnabled,
              initialTime: time,
            )
          : PriorityConfiguration(
              players: players,
              startingPlayerId: _first,
              clockEnabled: _clockEnabled,
              initialTime: time,
            );
    } on ArgumentError catch (error) {
      setState(() => _error = '${error.message}');
      return null;
    }
  }

  void _start() {
    final configuration = _configuration();
    if (configuration == null) return;
    FocusScope.of(context).unfocus();
    widget.controller.start(configuration);
  }

  void _draw() {
    final configuration = _configuration(draw: true);
    if (configuration != null) {
      setState(() {
        _first = configuration.startingPlayerId;
        _error = null;
      });
    }
  }

  Future<void> _newGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PriorityTheme(
        child: AlertDialog(
          title: const Text('¿Configurar una nueva partida?'),
          content: const Text(
            'La partida actual quedará guardada para retomarla después.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('priority-reset-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Nueva partida'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) await widget.controller.parkAndReset();
  }

  Future<void> _more(_PriorityMenu choice) async {
    switch (choice) {
      case _PriorityMenu.standings:
        await showPriorityStandings(context, widget.controller);
      case _PriorityMenu.newGame:
        await _newGame();
      case _PriorityMenu.history:
        await openPriorityHistory(context, controller: widget.controller);
      case _PriorityMenu.undo:
        if (widget.controller.undo()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Operación deshecha. Los relojes quedan pausados.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
      case _PriorityMenu.saved:
        await openPriorityLibrary(context, widget.controller);
      case _PriorityMenu.finish:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => priorityRotatedDialog(
            0,
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Finalizar la partida?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Se detendrán los relojes y se guardará el resumen de resultados.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      key: const ValueKey('priority-finish-confirm'),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Finalizar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        if (confirmed == true && mounted) {
          widget.controller.synchronizeClock();
          final current = widget.controller.value;
          if (current != null) {
            widget.controller.dispatch(
              const PriorityCommand.finish(),
              expectedRevision: current.revision,
            );
          }
        }
    }
  }

  Widget _body(PriorityMatch? match) {
    final controller = widget.controller;
    if (!controller.ready) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: controller.storageError == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.storageError!),
                    FilledButton(
                      key: const ValueKey('priority-retry-load'),
                      onPressed: controller.initialize,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, limits) => Column(
        children: [
          if (controller.storageError != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: limits.maxHeight * .4),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      controller.storageError!,
                      key: const ValueKey('priority-storage-error'),
                    ),
                    TextButton(
                      key: const ValueKey('priority-retry-save'),
                      onPressed: controller.flush,
                      child: const Text('Reintentar guardado'),
                    ),
                  ],
                ),
              ),
            ),
          if (controller.busy) const LinearProgressIndicator(),
          Expanded(
            child: match == null
                ? _setup()
                : PriorityTable(controller: controller),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PriorityTheme(
    child: ValueListenableBuilder<PriorityMatch?>(
      valueListenable: widget.controller,
      builder: (context, match, _) => PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            _closeExpiryNotice();
            widget.controller.pauseForNavigation();
          }
        },
        child: Scaffold(
          // Only the form uses the page keyboard. Modal editors manage their own
          // insets; keep the table stable behind them instead of shrinking panels.
          resizeToAvoidBottomInset: match == null,
          appBar: AppBar(
            title: const Text('Priority'),
            actions: [
              if (match != null) ...[
                IconButton(
                  key: const ValueKey('priority-toolbar-undo'),
                  tooltip: 'Deshacer última operación',
                  color: const Color(0xFF69DB8C),
                  disabledColor: const Color(0xFF69DB8C).withValues(alpha: .35),
                  icon: const Icon(Icons.undo_rounded),
                  onPressed: widget.controller.canUndo
                      ? () => _more(_PriorityMenu.undo)
                      : null,
                ),
                if (match.isPaused ||
                    (match.configuration.clockEnabled &&
                        match.phase != PriorityPhase.finished))
                  IconButton(
                    key: const ValueKey('priority-pause-resume'),
                    tooltip: match.isPaused ? 'Reanudar' : 'Pausar',
                    icon: Icon(match.isPaused ? Icons.play_arrow : Icons.pause),
                    onPressed:
                        widget.controller.can(
                          match.isPaused
                              ? const PriorityCommand.resume()
                              : const PriorityCommand.pause(),
                        )
                        ? () => widget.controller.dispatch(
                            match.isPaused
                                ? const PriorityCommand.resume()
                                : const PriorityCommand.pause(),
                            expectedRevision: match.revision,
                          )
                        : null,
                  ),
                IconButton(
                  key: const ValueKey('priority-toolbar-finish'),
                  tooltip: 'Finalizar partida',
                  color: const Color(0xFFFF7070),
                  disabledColor: const Color(0xFFFF7070).withValues(alpha: .35),
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed:
                      widget.controller.can(const PriorityCommand.finish())
                      ? () => _more(_PriorityMenu.finish)
                      : null,
                ),
              ],
              PopupMenuButton<_PriorityMenu>(
                key: const ValueKey('priority-more'),
                tooltip: 'Más opciones',
                onSelected: _more,
                itemBuilder: (context) => [
                  if (match != null) ...[
                    const PopupMenuItem(
                      value: _PriorityMenu.standings,
                      key: ValueKey('priority-standings'),
                      child: Text('Clasificación general'),
                    ),
                    PopupMenuItem(
                      value: _PriorityMenu.newGame,
                      key: const ValueKey('priority-new-game'),
                      enabled: !widget.controller.busy,
                      child: const Text('Nueva partida'),
                    ),
                    const PopupMenuItem(
                      value: _PriorityMenu.history,
                      key: ValueKey('priority-menu-history'),
                      child: Text('Historial'),
                    ),
                    PopupMenuItem(
                      value: _PriorityMenu.undo,
                      enabled: widget.controller.canUndo,
                      key: const ValueKey('priority-menu-undo'),
                      child: const Text('Deshacer'),
                    ),
                    if (match.phase != PriorityPhase.finished)
                      PopupMenuItem(
                        value: _PriorityMenu.finish,
                        enabled: !widget.controller.busy,
                        key: const ValueKey('priority-menu-finish'),
                        child: const Text('Finalizar partida'),
                      ),
                  ],
                  PopupMenuItem(
                    value: _PriorityMenu.saved,
                    enabled: widget.controller.ready && !widget.controller.busy,
                    key: const ValueKey('priority-menu-saved'),
                    child: const Text('Partidas guardadas'),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(top: false, child: _body(match)),
        ),
      ),
    ),
  );

  Widget _setup() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          key: const ValueKey('priority-setup'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Prepara la mesa',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ordena los asientos en sentido horario. '
                'Los números y colores te ayudarán a ubicar a cada jugador.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: const ValueKey('priority-player-count'),
                initialValue: _count,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(labelText: 'Jugadores'),
                items: [
                  for (var n = 2; n <= 6; n++)
                    DropdownMenuItem(
                      value: n,
                      child: Text(
                        '$n jugadores',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (count) {
                  if (count == null) return;
                  setState(() {
                    _count = count;
                    if (!_players.take(_count).any((p) => p.id == _first)) {
                      _first = _players.first.id;
                    }
                    _error = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              _number(
                _points,
                'Puntos de construcción para todos',
                'priority-build-points',
              ),
              SwitchListTile(
                key: const ValueKey('priority-clock-enabled'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Cronómetros individuales'),
                subtitle: const Text(
                  'Solo descuenta quien tiene la prioridad.',
                ),
                value: _clockEnabled,
                onChanged: (enabled) => setState(() {
                  _clockEnabled = enabled;
                  _error = null;
                }),
              ),
              if (_clockEnabled) ...[
                _number(
                  _minutes,
                  'Tiempo inicial: minutos',
                  'priority-clock-minutes',
                ),
                const Text(
                  'Al volver de segundo plano, reanuda manualmente el reloj.',
                ),
              ],
              for (var i = 0; i < _count; i++) _seatEditor(i),
              const SizedBox(height: 16),
              const Text('Turnos y prioridad siguen este orden:'),
              Text(
                '${_players.take(_count).map((p) => p.displayName).join(' → ')} → ${_players.first.displayName}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Ubicación de los asientos con el teléfono en la mesa:',
              ),
              const Text(
                'Mantén pulsado un asiento y arrástralo sobre otro para intercambiarlos. '
                'El jugador inicial se conserva y el orden horario sigue las posiciones.',
              ),
              SizedBox(
                key: const ValueKey('priority-setup-seats'),
                height: 180,
                child: Center(
                  child: AspectRatio(
                    aspectRatio:
                        MediaQuery.orientationOf(context) ==
                            Orientation.portrait
                        ? .75
                        : 1.8,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final seats = priorityTableSeats(
                          constraints.biggest,
                          _count,
                        );
                        return Stack(
                          children: [
                            for (var i = 0; i < _count; i++)
                              Positioned.fromRect(
                                key: ValueKey(
                                  'priority-setup-view-${_players[i].id}',
                                ),
                                rect: seats[i].bounds,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: RotatedBox(
                                    quarterTurns: seats[i].quarterTurns,
                                    child: PrioritySeatDropZone(
                                      group: _form,
                                      playerId: _players[i].id,
                                      onSwap: _swapSetupSeats,
                                      child: PrioritySeatDragSource(
                                        group: _form,
                                        playerId: _players[i].id,
                                        name: _players[i].displayName,
                                        color: priorityPlayerColors[i],
                                        quarterTurns: seats[i].quarterTurns,
                                        child: ColoredBox(
                                          color: priorityPlayerColors[i]
                                              .withValues(alpha: .18),
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: 64,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${i + 1}. ${_players[i].displayName}',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            priorityPlayerColors[i],
                                                      ),
                                                    ),
                                                    if (_players[i].id ==
                                                        _first)
                                                      const Text(
                                                        'INICIA',
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFFFFD878,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('priority-initial-$_first-$_count'),
                initialValue: _first,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(labelText: 'Jugador inicial'),
                items: [
                  for (var i = 0; i < _count; i++)
                    DropdownMenuItem(
                      value: _players[i].id,
                      child: Text(
                        '${i + 1}. ${_players[i].displayName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id != null) setState(() => _first = id);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('priority-draw'),
                onPressed: _draw,
                icon: const Icon(Icons.casino_outlined),
                label: const Text('Sortear jugador inicial'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Al finalizar cualquier turno se recuperan las acciones de todos. '
                'La partida se guarda en este dispositivo para retomarla después.',
              ),
              const SizedBox(height: 8),
              const Text(
                'En la mesa, usa −/+ para cambiar 5 PV y la calavera para eliminar. '
                'Toca un nombre para más opciones. '
                'El contador de acciones permite cambiar sus adicionales.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    key: const ValueKey('priority-setup-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('priority-start'),
                onPressed: _start,
                icon: const Icon(Icons.play_arrow),
                label: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Listo'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _swapSetupSeats(String source, String destination) {
    if (widget.controller.value != null) return;
    final selected = _players.take(_count).toList();
    final from = selected.indexWhere((p) => p.id == source);
    final to = selected.indexWhere((p) => p.id == destination);
    if (from < 0 || to < 0 || from == to) return;
    setState(() {
      final moving = _players[from];
      _players[from] = _players[to];
      _players[to] = moving;
      _error = null;
    });
  }

  Widget _seatEditor(int index) {
    final draft = _players[index];
    PriorityPlayerConfiguration? preview;
    try {
      preview = draft.configuration(int.tryParse(_points.text.trim()) ?? -1);
    } on ArgumentError {
      /* Invalid form input. */
    }
    void move(int offset) => setState(() {
      final other = _players[index + offset];
      _players[index + offset] = draft;
      _players[index] = other;
    });
    return Card(
      key: ValueKey('priority-seat-${draft.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: priorityPlayerColors[index],
                  foregroundColor: Colors.black,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Asiento ${index + 1}')),
                IconButton(
                  key: ValueKey('priority-up-${draft.id}'),
                  onPressed: index > 0 ? () => move(-1) : null,
                  tooltip: 'Mover al asiento anterior',
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  key: ValueKey('priority-down-${draft.id}'),
                  onPressed: index < _count - 1 ? () => move(1) : null,
                  tooltip: 'Mover al asiento siguiente',
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
            TextFormField(
              key: ValueKey('priority-name-${draft.id}'),
              controller: draft.name,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe un nombre.'
                  : null,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 8),
            _number(
              draft.additional,
              'Acciones adicionales',
              'priority-additional-${draft.id}',
            ),
            const SizedBox(height: 8),
            Text(
              preview == null
                  ? 'Revisa los datos del jugador.'
                  : '${preview.baseActions} base + ${preview.additionalActions} adicionales = ${preview.totalActions} acciones',
            ),
          ],
        ),
      ),
    );
  }

  Widget _number(TextEditingController controller, String label, String key) =>
      TextFormField(
        key: ValueKey(key),
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) => priorityIntegerError(value),
        onChanged: (_) => setState(() => _error = null),
      );
}

final class _SeatDraft {
  _SeatDraft(int number)
    : id = 'J$number',
      name = TextEditingController(text: 'Jugador $number');
  final String id;
  final TextEditingController name;
  final additional = TextEditingController(text: '0');
  String get displayName => name.text.trim().isEmpty ? id : name.text.trim();
  PriorityPlayerConfiguration configuration(int points) =>
      PriorityPlayerConfiguration(
        id: id,
        name: name.text,
        buildPoints: points,
        additionalActions: int.tryParse(additional.text.trim()) ?? -1,
      );
  void dispose() {
    name.dispose();
    additional.dispose();
  }
}
