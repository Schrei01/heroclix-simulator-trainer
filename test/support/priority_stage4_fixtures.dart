import 'dart:async';

import 'package:heroclix_simulator_trainer/application/ports/local_document_store.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_repository.dart';
import 'package:heroclix_simulator_trainer/application/priority/priority_session.dart';
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';
import 'package:heroclix_simulator_trainer/presentation/priority/priority_controller.dart';

import 'priority_stage3_fixtures.dart';

class PriorityTestStore implements LocalDocumentStore {
  final documents = <String, String>{};
  bool failRead = false,
      failWrite = false,
      failDelete = false,
      failList = false;
  final failWriteIds = <String>{};
  Completer<void>? gate;
  int writes = 0, activeWrites = 0, maxActiveWrites = 0;
  @override
  Future<List<String>> listIds() async {
    if (failRead || failList) throw StateError('read');
    return documents.keys.where(PrioritySession.validId).toList();
  }

  @override
  Future<String?> read(String id) async {
    if (failRead) throw StateError('read');
    return documents[id];
  }

  @override
  Future<void> write(String id, String document) async {
    activeWrites++;
    if (activeWrites > maxActiveWrites) maxActiveWrites = activeWrites;
    try {
      if (gate != null) await gate!.future;
      if (failWrite || failWriteIds.contains(id)) throw StateError('write');
      documents[id] = document;
      writes++;
    } finally {
      activeWrites--;
    }
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw StateError('delete');
    documents.remove(id);
  }

  PriorityTestStore cloneDisk() =>
      PriorityTestStore()..documents.addAll(documents);
}

Future<PriorityController> savedPriority(
  PriorityTestStore store, {
  int count = 3,
  bool clock = true,
  String? first,
  Duration time = const Duration(minutes: 2),
  PriorityFakeClock? elapsed,
}) async {
  final c = PriorityController(
    repository: PriorityRepository(store),
    inputCooldown: Duration.zero,
    elapsedClock: (elapsed ?? PriorityFakeClock()).read,
  );
  await c.initialize();
  c.start(priorityConfig(count, clock: clock, first: first, time: time));
  return c;
}

Map<String, Object?> gameFields(PriorityMatch m) =>
    {...const PrioritySnapshotCodec().state(m)}
      ..remove('revision')
      ..remove('paused')
      ..remove('pauseReason');
