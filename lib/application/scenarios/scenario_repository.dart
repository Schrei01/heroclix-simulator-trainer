import 'dart:convert';

import '../ports/local_document_store.dart';
import 'scenario_codec.dart';
import 'scenario_document.dart';

final class ScenarioSummary {
  ScenarioSummary(ScenarioDocument doc)
    : id = doc.id,
      name = doc.name,
      rulesVersion = doc.rulesVersion,
      modifiedAt = doc.modifiedAt,
      rows = doc.session.dimensions.rows,
      columns = doc.session.dimensions.columns,
      figures = doc.session.characters.length;
  final String id, name, rulesVersion;
  final DateTime modifiedAt;
  final int rows, columns, figures;
}

final class LibraryItem {
  const LibraryItem(this.id, this.document, this.error);
  final String id;
  final ScenarioSummary? document;
  final String? error;
}

final class WorkingScenario {
  const WorkingScenario(this.document, this.dirty, this.saved);
  final ScenarioDocument document;
  final bool dirty, saved;
}

final class ScenarioRepository {
  const ScenarioRepository(this.store);
  final LocalDocumentStore store;
  static const codec = ScenarioCodec();
  Future<List<LibraryItem>> list() async {
    final items = <LibraryItem>[];
    for (final id in await store.listIds()) {
      try {
        items.add(LibraryItem(id, ScenarioSummary(await open(id)), null));
      } on Exception catch (error) {
        items.add(LibraryItem(id, null, error.toString()));
      }
    }
    return items;
  }

  Future<ScenarioDocument> open(String id) async {
    if (!ScenarioDocument.validId(id)) {
      throw const FormatException('ID de escenario inválido.');
    }
    final raw = await store.read(id);
    if (raw == null) throw const FormatException('El escenario ya no existe.');
    final doc = codec.decode(raw);
    if (doc.id != id) {
      throw const FormatException('La identidad del archivo no coincide.');
    }
    return doc;
  }

  Future<void> save(ScenarioDocument document) async {
    final ids = await store.listIds();
    if (ids.contains(document.id)) {
      try {
        await open(document.id);
      } on FormatException {
        throw const FormatException(
          'El archivo existente no es compatible o está dañado. Usa Guardar como para conservarlo.',
        );
      }
    }
    if (ids.length >= 200 && !ids.contains(document.id)) {
      throw const FormatException(
        'La biblioteca admite como máximo 200 escenarios.',
      );
    }
    await _backupLegacy(document.id);
    await store.write(document.id, codec.encode(document));
  }

  Future<void> delete(String id) async {
    if (!ScenarioDocument.validId(id)) {
      throw const FormatException('ID de escenario inválido.');
    }
    await store.delete(id);
  }

  Future<void> archiveWorking() async {
    final raw = await store.read('working');
    if (raw != null) {
      await store.write('recovery-${ScenarioDocument.newId()}', raw);
    }
  }

  Future<void> _backupLegacy(String id) async {
    final raw = await store.read(id);
    if (raw == null) return;
    Object? parsed;
    try {
      parsed = ScenarioCodec.parseBounded(raw, limit: 3 * 1024 * 1024);
    } on FormatException {
      return;
    }
    final document = id == 'working' && parsed is Map
        ? parsed['document']
        : parsed;
    final version = document is Map ? document['schemaVersion'] : null;
    if (document is Map &&
        version is int &&
        version >= 1 &&
        version < ScenarioDocument.schemaVersion) {
      codec.fromMap(document);
      final backup = 'schema${document['schemaVersion']}-$id';
      if (await store.read(backup) == null) {
        await store.write(backup, raw);
      }
    }
  }

  Future<void> saveWorking(WorkingScenario working) async {
    await _backupLegacy('working');
    await store.write(
      'working',
      jsonEncode({
        'workspaceSchemaVersion': 1,
        'document': codec.toMap(working.document),
        'dirty': working.dirty,
        'saved': working.saved,
      }),
    );
  }

  Future<WorkingScenario?> readWorking() async {
    final raw = await store.read('working');
    if (raw == null) return null;
    final root = ScenarioCodec.object(
      ScenarioCodec.parseBounded(raw, limit: 3 * 1024 * 1024),
      {'workspaceSchemaVersion', 'document', 'dirty', 'saved'},
    );
    if (root['workspaceSchemaVersion'] is! int ||
        root['workspaceSchemaVersion'] != 1 ||
        root['dirty'] is! bool ||
        root['saved'] is! bool) {
      throw const FormatException(
        'Autoguardado de versión desconocida o inválido. No se ha sobrescrito.',
      );
    }
    return WorkingScenario(
      codec.fromMap(root['document']),
      root['dirty'] as bool,
      root['saved'] as bool,
    );
  }
}
