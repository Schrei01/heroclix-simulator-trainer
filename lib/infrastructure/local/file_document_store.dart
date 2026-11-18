import 'dart:convert';
import 'dart:io';

import '../../application/ports/local_document_store.dart';
import '../../application/scenarios/scenario_document.dart';

/// Archivos privados: nombre por ID validado, temporal + flush + rename en el mismo directorio.
final class FileDocumentStore implements LocalDocumentStore {
  FileDocumentStore(this.directory);
  final Future<Directory> Function() directory;
  Future<Directory>? _root;
  static const maxStoredBytes = 3 * 1024 * 1024;
  Future<Directory> _directory() => _root ??= (() async {
    try {
      final root = await directory();
      await root.create(recursive: true);
      return root.absolute;
    } catch (_) {
      _root = null;
      rethrow;
    }
  })();
  Future<File> _file(String id) async {
    if (id != 'working' &&
        !ScenarioDocument.validId(id) &&
        !RegExp(r'^recovery-s-[a-f0-9]{32}$').hasMatch(id) &&
        !RegExp(r'^schema[123]-(working|s-[a-f0-9]{32})$').hasMatch(id)) {
      throw ArgumentError('ID de almacenamiento inválido.');
    }
    final root = await _directory(),
        file = File(
          '${(await _directory()).path}${Platform.pathSeparator}$id.json',
        );
    if (!file.absolute.path.startsWith(
      '${root.path}${Platform.pathSeparator}',
    )) {
      throw ArgumentError('Ruta fuera del directorio privado.');
    }
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FileSystemException('No se admiten enlaces simbólicos.');
    }
    return file;
  }

  @override
  Future<List<String>> listIds() async {
    final result = <String>[];
    await for (final entity in (await _directory()).list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.json')) continue;
      final id = name.substring(0, name.length - 5);
      if (ScenarioDocument.validId(id)) result.add(id);
      if (result.length > 200) {
        throw const FileSystemException(
          'La biblioteca supera el límite de 200 escenarios.',
        );
      }
    }
    return result..sort();
  }

  @override
  Future<String?> read(String id) async {
    final file = await _file(id);
    if (!await file.exists()) return null;
    if (await file.length() > maxStoredBytes) {
      throw const FormatException('Archivo privado demasiado grande.');
    }
    final bytes = <int>[];
    await for (final chunk in file.openRead()) {
      if (bytes.length + chunk.length > maxStoredBytes) {
        throw const FormatException('Archivo privado demasiado grande.');
      }
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes, allowMalformed: false);
  }

  @override
  Future<void> write(String id, String document) async {
    final bytes = utf8.encode(document);
    if (bytes.length > maxStoredBytes) {
      throw const FormatException('Documento demasiado grande.');
    }
    final target = await _file(id);
    final temp = File('${target.path}.tmp-${ScenarioDocument.newId()}');
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(target.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  @override
  Future<void> delete(String id) async {
    final file = await _file(id);
    if (await file.exists()) await file.delete();
  }
}
