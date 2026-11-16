import 'package:material_ui/material_ui.dart';

import '../../application/scenarios/scenario_repository.dart';
import 'workspace_controller.dart';
import 'scenario_dialogs.dart';

class ScenarioLibrary extends StatefulWidget {
  const ScenarioLibrary({required this.workspace, super.key});
  final WorkspaceController workspace;
  @override
  State<ScenarioLibrary> createState() => _ScenarioLibraryState();
}

class _ScenarioLibraryState extends State<ScenarioLibrary> {
  late Future<List<LibraryItem>> _items = widget.workspace.library();
  bool _byName = false, _busy = false;
  void _refresh() {
    final items = widget.workspace.library();
    setState(() {
      _items = items;
    });
  }

  Future<void> _action(LibraryItem item, String action) async {
    final doc = item.document;
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => ScenarioFormDialog(
          title: '¿Eliminar de la biblioteca?',
          children: [
            Text(doc?.name ?? 'Escenario ilegible'),
            const Text(
              'Se elimina este archivo local. Si está abierto, el tablero se conserva como borrador sin guardar. No se puede deshacer esta eliminación.',
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  key: const ValueKey('confirm-delete-scenario'),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    } else {
      final result = await askScenarioName(
        context,
        title: action == 'rename'
            ? 'Renombrar escenario'
            : 'Duplicar escenario',
        name: doc!.name,
        rules: doc.rulesVersion,
      );
      if (result == null || !mounted) return;
      setState(() => _busy = true);
      final success = action == 'rename'
          ? await widget.workspace.rename(item.id, result.name, result.rules)
          : await widget.workspace.duplicate(
              item.id,
              result.name,
              rulesVersion: result.rules,
            );
      if (!mounted) return;
      if (!success) {
        await showScenarioError(
          context,
          widget.workspace.error ?? 'No se pudo modificar la biblioteca.',
        );
      }
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    final success = await widget.workspace.delete(item.id);
    if (!mounted) return;
    if (!success) {
      await showScenarioError(
        context,
        widget.workspace.error ?? 'No se pudo eliminar.',
      );
    }
    if (mounted) {
      setState(() => _busy = false);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Biblioteca local',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar biblioteca',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TextButton.icon(
                  key: const ValueKey('library-new'),
                  onPressed: _busy ? null : () => Navigator.pop(context, 'new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
                PopupMenuButton<bool>(
                  key: const ValueKey('library-sort'),
                  tooltip: 'Ordenar biblioteca',
                  onSelected: (name) => setState(() => _byName = name),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: false,
                      child: Text('Última edición'),
                    ),
                    const PopupMenuItem(value: true, child: Text('Nombre')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(_byName ? 'Nombre' : 'Última edición'),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: FutureBuilder<List<LibraryItem>>(
              future: _items,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text(
                          'No se pudo leer la biblioteca. El tablero abierto se conserva.',
                        ),
                        TextButton(
                          onPressed: _refresh,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final items = [...snapshot.data!];
                items.sort((a, b) {
                  if (a.document == null) {
                    return b.document == null ? a.id.compareTo(b.id) : 1;
                  }
                  if (b.document == null) return -1;
                  final result = _byName
                      ? a.document!.name.toLowerCase().compareTo(
                          b.document!.name.toLowerCase(),
                        )
                      : b.document!.modifiedAt.compareTo(
                          a.document!.modifiedAt,
                        );
                  return result == 0 ? a.id.compareTo(b.id) : result;
                });
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aún no hay escenarios guardados. Usa Guardar para añadir el tablero actual.',
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index], doc = item.document;
                    final time = doc?.modifiedAt.toLocal().toString().substring(
                      0,
                      16,
                    );
                    return ListTile(
                      key: ValueKey('library-${item.id}'),
                      enabled: !_busy,
                      title: Text(doc?.name ?? 'Escenario ilegible'),
                      subtitle: Text(
                        doc == null
                            ? 'El archivo se conserva. Puedes eliminarlo explícitamente.'
                            : '${doc.rows} × ${doc.columns} · ${doc.figures} figuras\n$time · ID ${item.id.substring(2, 10)}',
                      ),
                      onTap: _busy || doc == null
                          ? null
                          : () => Navigator.pop(context, item.id),
                      trailing: PopupMenuButton<String>(
                        key: ValueKey('library-actions-${item.id}'),
                        tooltip: 'Opciones del escenario',
                        enabled: !_busy,
                        onSelected: (action) => _action(item, action),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'rename',
                            enabled: doc != null,
                            child: const Text('Renombrar'),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            enabled: doc != null,
                            child: const Text('Duplicar'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar de biblioteca'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
