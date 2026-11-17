import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/scenarios/scenario_codec.dart';
import '../../application/scenarios/scenario_document.dart';
import '../editor/editor_controller.dart';
import 'workspace_controller.dart';
import 'scenario_dialogs.dart';
import 'scenario_library.dart';
import 'board_png_exporter.dart';

final class ScenarioActions {
  const ScenarioActions(this.controller);
  final EditorController controller;
  WorkspaceController get workspace => controller.workspace!;
  Future<void> _failure(BuildContext context) async {
    if (context.mounted) {
      await showScenarioError(
        context,
        workspace.error ?? 'No se pudo acceder al archivo.',
      );
    }
  }

  Future<bool> _mayLeave(BuildContext context) async {
    if (!workspace.dirty && workspace.saved) return true;
    final choice = await showDialog<int>(
      context: context,
      builder: (context) => ScenarioFormDialog(
        title: 'Cambios fuera de la biblioteca',
        children: [
          Text(
            !workspace.persistWorkingSession
                ? 'Este escenario solo se conserva mientras la app está abierta. Guarda en la biblioteca antes de cambiarlo si quieres conservarlo.'
                : workspace.autosaveCurrent
                ? 'El autoguardado protege la sesión actual. Al cambiar de escenario será sustituido. Guarda en la biblioteca para conservar estos cambios.'
                : 'El autoguardado está pendiente o ha fallado. Cambiar de escenario puede perder estos cambios. Guarda en la biblioteca para conservarlos.',
          ),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, 0),
                child: const Text('Cancelar'),
              ),
              TextButton(
                key: const ValueKey('discard-library-changes'),
                onPressed: () => Navigator.pop(context, 1),
                child: const Text('Continuar sin guardar'),
              ),
              FilledButton(
                key: const ValueKey('save-before-leave'),
                onPressed: () => Navigator.pop(context, 2),
                child: const Text('Guardar y continuar'),
              ),
            ],
          ),
        ],
      ),
    );
    if (choice == 1) return true;
    if (choice == 2) {
      final saved = await workspace.save();
      if (!saved && context.mounted) await _failure(context);
      return saved;
    }
    return false;
  }

  Future<void> create(BuildContext context) async {
    if (!await _mayLeave(context) || !context.mounted) return;
    final result = await askScenarioName(
      context,
      title: 'Nuevo escenario',
      name: 'Nuevo escenario',
      rules: workspace.current.rulesVersion,
    );
    if (result != null &&
        !await workspace.create(result.name, result.rules) &&
        context.mounted) {
      await _failure(context);
    }
  }

  Future<void> save(BuildContext context) async {
    if (!await workspace.save() && context.mounted) await _failure(context);
  }

  Future<bool> openExample(
    BuildContext context,
    ScenarioDocument document,
  ) async {
    if (!await _mayLeave(context) || !context.mounted) return false;
    final opened = await workspace.importDocument(document);
    if (!opened && context.mounted) await _failure(context);
    return opened;
  }

  Future<void> saveAs(BuildContext context) async {
    final result = await askScenarioName(
      context,
      title: 'Guardar como',
      name: workspace.current.name,
      rules: workspace.current.rulesVersion,
    );
    if (result != null &&
        !await workspace.saveAs(result.name, result.rules) &&
        context.mounted) {
      await _failure(context);
    }
  }

  Future<void> library(BuildContext context) async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => ScenarioLibrary(workspace: workspace),
    );
    if (id == null || !context.mounted) return;
    if (id == 'new') {
      await create(context);
      return;
    }
    if (!await _mayLeave(context) || !context.mounted) return;
    if (!await workspace.open(id) && context.mounted) await _failure(context);
  }

  Future<void> details(BuildContext context) async {
    final doc = workspace.current;
    await showDialog<void>(
      context: context,
      builder: (context) => ScenarioFormDialog(
        title: 'Escenario actual',
        children: [
          Text(doc.name),
          Text('ID: ${doc.id}'),
          Text(
            'Esquema JSON: ${ScenarioDocument.schemaVersion} · referencia: ${doc.rulesVersion}',
          ),
          Text('Creado (UTC): ${doc.createdAt.toIso8601String()}'),
          Text('Modificado (UTC): ${doc.modifiedAt.toIso8601String()}'),
          const SizedBox(height: 12),
          Text(workspace.status),
          const Text(
            'Deshacer/rehacer conserva hasta 100 operaciones. Abrir, importar, crear o guardar como reinicia el historial. La cámara no se guarda.',
          ),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              if (workspace.error != null || workspace.autosaveError != null)
                TextButton(
                  key: const ValueKey('retry-autosave'),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (!await workspace.retry() && context.mounted) {
                      await _failure(context);
                    }
                  },
                  child: Text(
                    workspace.persistWorkingSession
                        ? 'Reintentar autoguardado'
                        : 'Reintentar guardado',
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fileTask(
    BuildContext context,
    Future<void> Function() task,
  ) async {
    if (controller.fileBusy) return;
    controller.setFileBusy(true);
    try {
      await task();
    } catch (error) {
      if (context.mounted) {
        await showScenarioError(
          context,
          error is PlatformException
              ? error.message ?? 'No se pudo acceder al proveedor.'
              : error is FormatException
              ? error.message.toString()
              : 'No se pudo generar o escribir el archivo.',
        );
      }
    } finally {
      controller.setFileBusy(false);
    }
  }

  Future<void> importJson(BuildContext context) => _fileTask(context, () async {
    if (!await _mayLeave(context) || !context.mounted) return;
    final picked = await controller.files!.pickJson();
    if (picked == null) return;
    if (picked.bytes.length > ScenarioCodec.maxBytes) {
      throw const FormatException('El JSON supera 2 MiB.');
    }
    final document = const ScenarioCodec().decode(
      utf8.decode(picked.bytes, allowMalformed: false),
    );
    if (!await workspace.importDocument(document) && context.mounted) {
      await _failure(context);
    }
  });
  Future<void> exportJson(BuildContext context, {required bool share}) =>
      _fileTask(context, () async {
        final document = workspace.current;
        final bytes = Uint8List.fromList(
          utf8.encode(const ScenarioCodec().encode(document)),
        );
        final name = 'heroclix_${document.id}.json';
        if (share) {
          await controller.files!.shareFile(bytes, name, 'application/json');
        } else {
          await controller.files!.saveFile(bytes, name, 'application/json');
        }
      });
  Future<void> exportPng(BuildContext context) => _fileTask(context, () async {
    final options =
        await showDialog<
          ({bool coordinates, bool legend, int limit, bool share})
        >(context: context, builder: (_) => const _PngDialog());
    if (options == null) return;
    final png = await const BoardPngExporter().render(
      controller.value,
      coordinates: options.coordinates,
      legend: options.legend,
      maxDimension: options.limit,
    );
    final name = 'heroclix_${workspace.current.id}.png';
    if (options.share) {
      await controller.files!.shareFile(png.bytes, name, 'image/png');
    } else {
      await controller.files!.saveFile(png.bytes, name, 'image/png');
    }
  });
}

class _PngDialog extends StatefulWidget {
  const _PngDialog();
  @override
  State<_PngDialog> createState() => _PngDialogState();
}

class _PngDialogState extends State<_PngDialog> {
  bool _coordinates = true, _legend = true, _large = false;
  @override
  Widget build(BuildContext context) => ScenarioFormDialog(
    title: 'Exportar tablero PNG',
    children: [
      const Text(
        'Mapa completo, sin controles, selección ni vista previa. Se ignora el zoom de pantalla.',
      ),
      CheckboxListTile(
        key: const ValueKey('png-coordinates'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Incluir coordenadas'),
        value: _coordinates,
        onChanged: (value) => setState(() => _coordinates = value!),
      ),
      CheckboxListTile(
        key: const ValueKey('png-legend'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Incluir leyenda'),
        value: _legend,
        onChanged: (value) => setState(() => _legend = value!),
      ),
      CheckboxListTile(
        key: const ValueKey('png-large'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Alta resolución: máximo 4096 px'),
        subtitle: const Text(
          'Por defecto: 2048 px. 4096 puede necesitar unos 64 MiB de memoria de imagen, además de la app.',
        ),
        value: _large,
        onChanged: (value) => setState(() => _large = value!),
      ),
      Wrap(
        alignment: WrapAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const ValueKey('share-png'),
            onPressed: () => Navigator.pop(context, (
              coordinates: _coordinates,
              legend: _legend,
              limit: _large ? 4096 : 2048,
              share: true,
            )),
            child: const Text('Compartir'),
          ),
          FilledButton(
            key: const ValueKey('save-png'),
            onPressed: () => Navigator.pop(context, (
              coordinates: _coordinates,
              legend: _legend,
              limit: _large ? 4096 : 2048,
              share: false,
            )),
            child: const Text('Guardar PNG'),
          ),
        ],
      ),
    ],
  );
}
