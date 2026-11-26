import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../application/priority/priority_session.dart';
import '../../domain/priority/priority.dart';
import 'priority_controller.dart';
import 'priority_input.dart';
import 'priority_theme.dart';

String priorityDateLabel(DateTime at) {
  final d = at.toLocal();
  String p(int n) => '$n'.padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
}

String priorityOperationLabel(PriorityOperation? operation) =>
    switch (operation) {
      PriorityOperation.action => 'ACTION',
      PriorityOperation.free => 'FREE',
      PriorityOperation.responseAction => 'RESPONSE ACTION',
      PriorityOperation.responseFree => 'RESPONSE FREE',
      PriorityOperation.pass => 'PASS',
      PriorityOperation.endTurn => 'END TURN',
      PriorityOperation.setAdditionalActions => 'Cambiar acciones totales',
      PriorityOperation.adjustVictoryPoints ||
      PriorityOperation.setVictoryPoints => 'Cambiar puntos de victoria',
      PriorityOperation.setRemainingTime => 'Corregir tiempo',
      PriorityOperation.pause => 'Pausar',
      PriorityOperation.resume => 'Reanudar',
      PriorityOperation.eliminate => 'Eliminar jugador',
      PriorityOperation.finish => 'Finalizar partida',
      _ => 'Inicio',
    };

String _name(PrioritySession s, String? id) =>
    id == null ? '' : s.match.player(id).name;
String _eventLabel(PrioritySession session, PriorityEvent e) {
  final who = _name(session, e.playerId);
  final text = switch (e.type) {
    PriorityEventType.started => 'Inicio de partida',
    PriorityEventType.turnStarted => 'Inicio de turno',
    PriorityEventType.turnEnded => 'Fin de turno',
    PriorityEventType.priorityChanged => 'Recibe prioridad',
    PriorityEventType.action => 'ACTION',
    PriorityEventType.free => 'FREE',
    PriorityEventType.responseAction => 'RESPONSE ACTION',
    PriorityEventType.responseFree => 'RESPONSE FREE',
    PriorityEventType.voluntaryPass => 'PASS voluntario',
    PriorityEventType.automaticPass => 'PASS automático',
    PriorityEventType.additionalActionsChanged =>
      'Acciones totales: ${session.match.player(e.playerId).baseActions + e.previousValue!} → ${session.match.player(e.playerId).baseActions + e.value!}',
    PriorityEventType.victoryPointsChanged =>
      'PV: ${e.previousValue} → ${e.value}',
    PriorityEventType.timeCorrected =>
      'Tiempo: ${priorityTimeLabel(Duration(microseconds: e.previousValue!))} → ${priorityTimeLabel(Duration(microseconds: e.value!))}',
    PriorityEventType.paused => 'Reloj pausado',
    PriorityEventType.resumed => 'Reanudación',
    PriorityEventType.timeExpired => 'Tiempo agotado',
    PriorityEventType.eliminated => 'Eliminado',
    PriorityEventType.finished => 'Partida finalizada',
  };
  return '$who · $text · R${e.round} / T${e.turn}';
}

Future<void> openPriorityHistory(
  BuildContext context, {
  PriorityController? controller,
  PrioritySession? session,
}) async {
  controller?.pauseForNavigation();
  if (controller != null) unawaited(controller.flush());
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          PriorityHistoryScreen(controller: controller, session: session),
    ),
  );
}

class PriorityHistoryScreen extends StatelessWidget {
  const PriorityHistoryScreen({this.controller, this.session, super.key});
  final PriorityController? controller;
  final PrioritySession? session;
  @override
  Widget build(BuildContext context) => PriorityTheme(
    child: controller == null
        ? _view(context, session)
        : ValueListenableBuilder<PriorityMatch?>(
            valueListenable: controller!,
            builder: (context, _, _) => _view(context, controller!.session),
          ),
  );
  Widget _view(BuildContext context, PrioritySession? data) {
    final undone = data?.undoneEntries ?? <int>{};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial', key: ValueKey('priority-history-title')),
        actions: [
          if (controller != null)
            IconButton(
              key: const ValueKey('priority-history-undo'),
              tooltip: 'Deshacer última operación',
              onPressed: controller!.canUndo ? controller!.undo : null,
              icon: const Icon(Icons.undo),
            ),
        ],
      ),
      body: data == null
          ? const Center(child: Text('No hay partida abierta.'))
          : ListView.builder(
              key: const ValueKey('priority-history-list'),
              padding: const EdgeInsets.all(12),
              itemCount: data.history.length + (controller == null ? 0 : 1),
              itemBuilder: (context, rawIndex) {
                if (controller != null && rawIndex == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Deshacer restaura la operación completa. Los relojes quedan pausados.',
                    ),
                  );
                }
                final index = rawIndex - (controller == null ? 0 : 1);
                final e = data.history[index];
                final title = switch (e.kind) {
                  PriorityLogKind.started => 'Partida iniciada',
                  PriorityLogKind.command => priorityOperationLabel(
                    e.operation,
                  ),
                  PriorityLogKind.automatic => 'Acontecimiento automático',
                  PriorityLogKind.seats =>
                    'Asientos: ${_name(data, e.playerId)} ↔ ${_name(data, e.otherPlayerId)}',
                  PriorityLogKind.undo => 'Deshacer operación #${e.undoOf}',
                  PriorityLogKind.recovered =>
                    data.match.configuration.clockEnabled
                        ? 'Partida recuperada · relojes pausados'
                        : 'Partida recuperada',
                };
                return Card(
                  key: ValueKey('priority-history-entry-${e.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${e.id} · ${priorityDateLabel(e.at)} · R${e.round} / T${e.turn}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: undone.contains(e.id)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (undone.contains(e.id)) const Text('Deshecho'),
                        for (final event in e.events)
                          Text(_eventLabel(data, event)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PriorityStatistics extends StatelessWidget {
  const PriorityStatistics({required this.session, super.key});
  final PrioritySession session;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Resumen de operaciones',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const Text('Los registros deshechos no cuentan en este resumen.'),
      for (final p in session.match.players)
        Padding(
          key: ValueKey('priority-result-stats-${p.id}'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'ACTION ${session.count(p.id, PriorityEventType.action)} · FREE ${session.count(p.id, PriorityEventType.free)}',
              ),
              Text(
                'RESPONSE ACTION ${session.count(p.id, PriorityEventType.responseAction)} · RESPONSE FREE ${session.count(p.id, PriorityEventType.responseFree)}',
              ),
              Text(
                'PASS voluntario ${session.count(p.id, PriorityEventType.voluntaryPass)} · automático ${session.count(p.id, PriorityEventType.automaticPass)}',
              ),
              if (session.match.configuration.clockEnabled)
                Text(
                  'Tiempo consumido: ${priorityTimeLabel(p.spentTime, roundUp: false)}',
                ),
            ],
          ),
        ),
    ],
  );
}

class PrioritySavedResultsScreen extends StatelessWidget {
  const PrioritySavedResultsScreen({required this.session, super.key});
  final PrioritySession session;
  @override
  Widget build(BuildContext context) => PriorityTheme(
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resumen guardado',
          key: ValueKey('priority-saved-results'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            session.match.phase == PriorityPhase.finished
                ? 'Partida finalizada'
                : 'Partida en curso',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('Inicio: ${priorityDateLabel(session.createdAt)}'),
          Text('Último guardado: ${priorityDateLabel(session.modifiedAt)}'),
          Text('Ronda ${session.match.round} · Turno ${session.match.turn}'),
          const SizedBox(height: 12),
          const Text('Clasificación por PV. Los empates comparten posición.'),
          for (final s in session.match.standings)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '${s.position}. ${s.player.name}: ${s.player.victoryPoints} PV · ${s.player.eliminated ? 'Eliminado' : 'No eliminado'}',
              ),
            ),
          const Divider(),
          PriorityStatistics(session: session),
          FilledButton.icon(
            key: const ValueKey('priority-saved-history'),
            onPressed: () => openPriorityHistory(context, session: session),
            icon: const Icon(Icons.history),
            label: const Text('Consultar historial'),
          ),
        ],
      ),
    ),
  );
}

Future<void> openPriorityLibrary(
  BuildContext context,
  PriorityController controller,
) {
  controller.pauseForNavigation();
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => PriorityLibraryScreen(controller: controller),
    ),
  );
}

class PriorityLibraryScreen extends StatefulWidget {
  const PriorityLibraryScreen({required this.controller, super.key});
  final PriorityController controller;
  @override
  State<PriorityLibraryScreen> createState() => _PriorityLibraryScreenState();
}

class _PriorityLibraryScreenState extends State<PriorityLibraryScreen> {
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    await widget.controller.flush();
    await widget.controller.refreshLibrary();
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _confirm(
    String title,
    String message,
    String key,
    String action,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => PriorityTheme(
          child: AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: ValueKey(key),
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ),
      ) ??
      false;
  void _error() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo completar la operación. La partida actual se conserva.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

  Future<void> _consult(String id) async {
    try {
      final saved = await widget.controller.readSaved(id);
      if (mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => PrioritySavedResultsScreen(session: saved),
          ),
        );
      }
    } catch (_) {
      _error();
    }
  }

  Future<void> _continue(String id) async {
    if (widget.controller.session != null &&
        widget.controller.session!.id != id &&
        !await _confirm(
          '¿Continuar esta partida?',
          'La partida actual quedará guardada para retomarla después.',
          'priority-open-confirm',
          'Continuar',
        )) {
      return;
    }
    if (!mounted) return;
    if (await widget.controller.openSaved(id)) {
      if (mounted) Navigator.pop(context);
    } else {
      _error();
    }
  }

  Future<void> _delete(String id) async {
    if (!await _confirm(
      '¿Descartar partida guardada?',
      'Se eliminarán su resumen e historial local.',
      'priority-delete-saved-confirm',
      'Descartar',
    )) {
      return;
    }
    if (!mounted) return;
    if (!await widget.controller.deleteSaved(id)) _error();
  }

  @override
  Widget build(BuildContext context) => PriorityTheme(
    child: ValueListenableBuilder<PriorityMatch?>(
      valueListenable: widget.controller,
      builder: (context, _, _) {
        final matches = widget.controller.savedMatches;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Partidas guardadas',
              key: ValueKey('priority-library-title'),
            ),
            actions: [
              IconButton(
                tooltip: 'Volver a consultar',
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  key: const ValueKey('priority-library-list'),
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (widget.controller.libraryError != null)
                      Text(widget.controller.libraryError!),
                    if (widget.controller.storageError != null)
                      Text(widget.controller.storageError!),
                    if (matches.isEmpty)
                      const Text('Todavía no hay partidas guardadas.'),
                    for (final s in matches)
                      Card(
                        key: ValueKey('priority-saved-${s.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.match.players.map((p) => p.name).join(' · '),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${s.finished ? 'Finalizada' : 'En curso'} · ${priorityDateLabel(s.modifiedAt)}',
                              ),
                              Text(
                                'Ronda ${s.match.round} · Turno ${s.match.turn}',
                              ),
                              if (widget.controller.session?.id == s.id)
                                const Text('Partida actual'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  OutlinedButton(
                                    key: ValueKey('priority-consult-${s.id}'),
                                    onPressed: () => _consult(s.id),
                                    child: const Text('Consultar'),
                                  ),
                                  if (!s.finished)
                                    FilledButton(
                                      key: ValueKey(
                                        'priority-continue-${s.id}',
                                      ),
                                      onPressed: widget.controller.busy
                                          ? null
                                          : () => _continue(s.id),
                                      child: const Text('Continuar'),
                                    ),
                                  if (widget.controller.session?.id != s.id)
                                    TextButton(
                                      key: ValueKey('priority-delete-${s.id}'),
                                      onPressed: widget.controller.busy
                                          ? null
                                          : () => _delete(s.id),
                                      child: const Text('Descartar'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    ),
  );
}
