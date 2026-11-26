import 'dart:convert';

import '../../domain/priority/priority.dart';
import 'priority_session.dart';

final class PriorityVersionException implements Exception {
  const PriorityVersionException();
  @override
  String toString() =>
      'La partida pertenece a una versión de Priority no compatible.';
}

final class PrioritySessionCodec {
  const PrioritySessionCodec();
  static const schemaVersion = 1;
  static const maxBytes = 32 * 1024 * 1024;
  static const snapshot = PrioritySnapshotCodec();

  String encode(PrioritySession? session) {
    final payload = session == null
        ? null
        : {
            'id': session.id,
            'created': session.createdAt.toIso8601String(),
            'modified': session.modifiedAt.toIso8601String(),
            'configuration': snapshot.configuration(
              session.match.configuration,
            ),
            'state': snapshot.state(session.match),
            'seats': session.seats,
            'history': [
              for (final e in session.history)
                {
                  'id': e.id,
                  'at': e.at.toIso8601String(),
                  'kind': e.kind.name,
                  'operation': e.operation?.name,
                  'player': e.playerId,
                  'other': e.otherPlayerId,
                  'turn': e.turn,
                  'round': e.round,
                  'undoOf': e.undoOf,
                  'events': e.events.map(snapshot.event).toList(),
                },
            ],
            'undo': [
              for (final c in session.undo)
                {
                  'entry': c.entryId,
                  'state': snapshot.state(c.match),
                  'seats': c.seats,
                },
            ],
          };
    if (session != null &&
        (session.history.length > 100000 ||
            session.undo.length > 100000 ||
            session.undo.any(
              (u) => !identical(
                u.match.configuration,
                session.match.configuration,
              ),
            ))) {
      throw const FormatException(
        'La partida excede la capacidad local o contiene estados ajenos.',
      );
    }
    final raw = jsonEncode({
      'prioritySchema': schemaVersion,
      'checksum': checksum(jsonEncode(payload)),
      'payload': payload,
    });
    if (utf8.encode(raw).length > maxBytes) {
      throw const FormatException('Partida demasiado grande.');
    }
    return raw;
  }

  Object? _payload(String raw) {
    if (utf8.encode(raw).length > maxBytes) PrioritySnapshotCodec.invalid();
    final root = PrioritySnapshotCodec.object(jsonDecode(raw));
    if (root['prioritySchema'] != schemaVersion) {
      throw const PriorityVersionException();
    }
    if (root['checksum'] != checksum(jsonEncode(root['payload']))) {
      throw const FormatException('La copia de Priority está dañada.');
    }
    return root['payload'];
  }

  PrioritySession? decode(String raw) {
    final payload = _payload(raw);
    if (payload == null) return null;
    final m = PrioritySnapshotCodec.object(payload);
    final header = _summary(m);
    final c = header.match.configuration;
    final seats = _seats(m['seats'], c);
    final history = <PriorityLogEntry>[];
    final undone = <int>{};
    var lastAt = header.createdAt;
    for (final row in PrioritySnapshotCodec.array(m['history'])) {
      final e = PrioritySnapshotCodec.object(row);
      final id = PrioritySnapshotCodec.integer(e['id'], min: 1);
      final at = _date(e['at']);
      if (id != history.length + 1 ||
          at.isBefore(lastAt) ||
          at.isAfter(header.modifiedAt)) {
        PrioritySnapshotCodec.invalid();
      }
      lastAt = at;
      final player = PrioritySnapshotCodec.nullableString(e['player']);
      final other = PrioritySnapshotCodec.nullableString(e['other']);
      if ([
        player,
        other,
      ].whereType<String>().any((id) => !c.players.any((p) => p.id == id))) {
        PrioritySnapshotCodec.invalid();
      }
      final kind = PrioritySnapshotCodec.enumeration(
        PriorityLogKind.values,
        e['kind'],
      );
      final operation = e['operation'] == null
          ? null
          : PrioritySnapshotCodec.enumeration(
              PriorityOperation.values,
              e['operation'],
            );
      final undoOf = e['undoOf'] == null
          ? null
          : PrioritySnapshotCodec.integer(e['undoOf'], min: 1);
      if (kind == PriorityLogKind.undo) {
        if (undoOf == null ||
            undoOf >= id ||
            !history[undoOf - 1].undoable ||
            !undone.add(undoOf)) {
          PrioritySnapshotCodec.invalid();
        }
      } else if (undoOf != null) {
        PrioritySnapshotCodec.invalid();
      }
      if (kind == PriorityLogKind.command && operation == null) {
        PrioritySnapshotCodec.invalid();
      }
      if (kind == PriorityLogKind.seats &&
          (player == null || other == null || player == other)) {
        PrioritySnapshotCodec.invalid();
      }
      final turn = PrioritySnapshotCodec.integer(e['turn'], min: 1);
      final round = PrioritySnapshotCodec.integer(e['round'], min: 1);
      if (round > turn) PrioritySnapshotCodec.invalid();
      history.add(
        PriorityLogEntry(
          id: id,
          at: at,
          kind: kind,
          operation: operation,
          playerId: player,
          otherPlayerId: other,
          undoOf: undoOf,
          turn: turn,
          round: round,
          events: PrioritySnapshotCodec.array(e['events'])
              .map((v) => snapshot.readEvent(v, c)),
        ),
      );
    }
    if (history.isEmpty || history.first.kind != PriorityLogKind.started) {
      PrioritySnapshotCodec.invalid();
    }
    final undo = <PriorityCheckpoint>[];
    var lastId = 0;
    for (final row in PrioritySnapshotCodec.array(m['undo'])) {
      final u = PrioritySnapshotCodec.object(row);
      final id = PrioritySnapshotCodec.integer(
        u['entry'],
        min: 1,
        max: history.length,
      );
      final before = snapshot.readState(u['state'], c);
      if (id <= lastId ||
          undone.contains(id) ||
          !history[id - 1].undoable ||
          before.underlyingPhase == PriorityPhase.configuration ||
          before.revision > header.match.revision) {
        PrioritySnapshotCodec.invalid();
      }
      lastId = id;
      undo.add(PriorityCheckpoint(before, _seats(u['seats'], c), id));
    }
    final expected = history
        .where((e) => e.undoable && !undone.contains(e.id))
        .map((e) => e.id)
        .toList();
    if (expected.length != undo.length ||
        Iterable<int>.generate(expected.length)
            .any((i) => expected[i] != undo[i].entryId)) {
      PrioritySnapshotCodec.invalid();
    }
    return PrioritySession(
      id: header.id,
      createdAt: header.createdAt,
      modifiedAt: header.modifiedAt,
      match: header.match,
      seats: seats,
      history: history,
      undo: undo,
    );
  }

  PrioritySavedMatch? summary(String raw) {
    final data = _payload(raw);
    return data == null ? null : _summary(PrioritySnapshotCodec.object(data));
  }

  PrioritySavedMatch _summary(Map<String, dynamic> m) {
    final id = PrioritySnapshotCodec.string(m['id']);
    final created = _date(m['created']), modified = _date(m['modified']);
    if (!PrioritySession.validId(id) || modified.isBefore(created)) {
      PrioritySnapshotCodec.invalid();
    }
    final c = snapshot.readConfiguration(m['configuration']);
    final state = snapshot.readState(m['state'], c);
    if (state.underlyingPhase == PriorityPhase.configuration) {
      PrioritySnapshotCodec.invalid();
    }
    return PrioritySavedMatch(id, created, modified, state);
  }

  static DateTime _date(Object? raw) {
    final date = DateTime.tryParse(PrioritySnapshotCodec.string(raw));
    if (date == null || !date.isUtc) PrioritySnapshotCodec.invalid();
    return date;
  }

  static List<String> _seats(Object? raw, PriorityConfiguration c) {
    final seats = PrioritySnapshotCodec.strings(raw);
    if (seats.length != c.players.length ||
        seats.toSet().length != seats.length ||
        !seats.every((id) => c.players.any((p) => p.id == id))) {
      PrioritySnapshotCodec.invalid();
    }
    return seats;
  }

  /// Detects accidental corruption; this is not an authentication signature.
  static String checksum(String raw) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(raw)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
