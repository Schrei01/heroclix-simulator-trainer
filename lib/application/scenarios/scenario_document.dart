import 'dart:math';

import '../board/board_session.dart';

final class ScenarioDocument {
  ScenarioDocument({
    required this.id,
    required String name,
    required this.rulesVersion,
    required this.createdAt,
    required this.modifiedAt,
    required this.session,
  }) : name = name.trim() {
    if (!validId(id) ||
        this.name.isEmpty ||
        this.name.length > 80 ||
        rulesVersion.trim().isEmpty ||
        rulesVersion.length > 40 ||
        !createdAt.isUtc ||
        !modifiedAt.isUtc ||
        modifiedAt.isBefore(createdAt)) {
      throw ArgumentError('Metadatos de escenario inválidos.');
    }
  }
  static const schemaVersion = 1;
  static bool validId(String id) => RegExp(r'^s-[a-f0-9]{32}$').hasMatch(id);
  static String newId() {
    final random = Random.secure();
    return 's-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }

  factory ScenarioDocument.fresh({
    String name = 'Nuevo escenario',
    String rulesVersion = '2026-07-01',
    BoardSession? session,
  }) {
    final now = DateTime.now().toUtc();
    return ScenarioDocument(
      id: newId(),
      name: name,
      rulesVersion: rulesVersion,
      createdAt: now,
      modifiedAt: now,
      session: session ?? BoardSession.initial(),
    );
  }
  final String id, name, rulesVersion;
  final DateTime createdAt, modifiedAt;
  final BoardSession session;
  ScenarioDocument revised({
    String? name,
    String? rulesVersion,
    BoardSession? session,
  }) {
    final now = DateTime.now().toUtc();
    return ScenarioDocument(
      id: id,
      name: name ?? this.name,
      rulesVersion: rulesVersion ?? this.rulesVersion,
      createdAt: createdAt,
      modifiedAt: now.isBefore(modifiedAt) ? modifiedAt : now,
      session: session ?? this.session,
    );
  }

  ScenarioDocument copyAs(String name) => ScenarioDocument.fresh(
    name: name,
    rulesVersion: rulesVersion,
    session: session,
  );
}
