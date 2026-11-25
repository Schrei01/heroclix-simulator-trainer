import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../domain/priority/priority.dart';
import 'priority_controller.dart';
import 'priority_input.dart';
import 'priority_management.dart';
import 'priority_table.dart';
import 'priority_table_layout.dart';
import 'priority_theme.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFinished());
  }

  void _checkFinished() {
    if (!mounted) return;
    final match = widget.controller.value;
    _syncExpiryNotice(match);
    if (match == null) _resultsShown = false;
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
      final seats = priorityTableSeats(
        MediaQuery.sizeOf(context),
        current.players.length,
        landscape: MediaQuery.orientationOf(context) == Orientation.landscape,
      );
      final index = current.players.indexWhere((p) => p.id == id);
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
          content: const Text('Se descartará la partida Priority actual.'),
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
    if (confirmed == true && mounted) widget.controller.reset();
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
                  key: const ValueKey('priority-standings'),
                  tooltip: 'Clasificación general',
                  icon: const Icon(Icons.leaderboard_outlined),
                  onPressed: () =>
                      showPriorityStandings(context, widget.controller),
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
              ],
              if (match != null)
                IconButton(
                  key: const ValueKey('priority-new-game'),
                  onPressed: _newGame,
                  tooltip: 'Nueva partida',
                  icon: const Icon(Icons.add_circle_outline),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: match == null
                ? _setup()
                : PriorityTable(controller: widget.controller),
          ),
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
                'Ordena los asientos en sentido antihorario. '
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
              SizedBox(
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
                                rect: seats[i].bounds,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: RotatedBox(
                                    quarterTurns: seats[i].quarterTurns,
                                    child: ColoredBox(
                                      color: priorityPlayerColors[i].withValues(
                                        alpha: .18,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            color: priorityPlayerColors[i],
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
                'Puedes volver al inicio y regresar a esta partida mientras la app siga abierta.',
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
