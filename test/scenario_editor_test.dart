import 'support/test_clock.dart';

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/application/ports/scenario_files.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_codec.dart';
import 'package:heroclix_simulator_trainer/application/scenarios/scenario_document.dart';
import 'package:heroclix_simulator_trainer/presentation/editor/editor_controller.dart';

import 'support/scenario_fakes.dart';
import 'character_editor_test.dart' show press, edit, keyed;
import 'scenario_codec_test.dart' show character, sampleDocument, cell;

Future<EditorController> openPersistent(
  WidgetTester tester, {
  MemoryStore? store,
  FakeScenarioFiles? files,
}) async {
  final controller = await persistentController(
    store ?? MemoryStore(),
    files: files,
  );
  await tester.pumpWidget(
    HeroClixApp(clock: testClock, controller: controller),
  );
  await tester.ensureVisible(find.text('Abrir editor'));
  await tester.tap(find.text('Abrir editor'));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> action(WidgetTester tester, String key) async {
  await press(tester, 'board-view-options');
  await press(tester, key);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('biblioteca ordena por última edición o por nombre', (
    tester,
  ) async {
    final controller = await openPersistent(tester),
        workspace = controller.workspace!;
    final a = ScenarioDocument(
      id: ScenarioDocument.newId(),
      name: 'Alfa',
      rulesVersion: '2026-07-01',
      createdAt: DateTime.utc(2026, 1, 1),
      modifiedAt: DateTime.utc(2026, 2, 1),
      session: controller.value,
    );
    final z = ScenarioDocument(
      id: ScenarioDocument.newId(),
      name: 'Zeta',
      rulesVersion: '2026-07-01',
      createdAt: DateTime.utc(2026, 1, 1),
      modifiedAt: DateTime.utc(2026, 3, 1),
      session: controller.value,
    );
    await workspace.repository.save(a);
    await workspace.repository.save(z);
    await press(tester, 'scenario-library');
    expect(
      tester.getTopLeft(keyed('library-${z.id}')).dy,
      lessThan(tester.getTopLeft(keyed('library-${a.id}')).dy),
    );
    await press(tester, 'library-sort');
    await tester.tap(find.text('Nombre'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(keyed('library-${a.id}')).dy,
      lessThan(tester.getTopLeft(keyed('library-${z.id}')).dy),
    );
  });
  testWidgets(
    'deshacer y rehacer desde barra restaura figuras y una rama nueva invalida rehacer',
    (tester) async {
      final controller = await openPersistent(tester);
      controller.saveCharacter(character('A1'));
      await tester.pumpAndSettle();
      await press(tester, 'undo-edit');
      expect(controller.value.characters.isEmpty, isTrue);
      await press(tester, 'redo-edit');
      expect(controller.value.characters.length, 1);
      expect(controller.value.characters.all.single.id, 'figure-1');
      await press(tester, 'undo-edit');
      controller.saveCharacter(character('B2'));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(keyed('redo-edit')).onPressed, isNull);
      expect(controller.value.selectedCharacter!.label, 'B');
    },
  );
  testWidgets(
    'guardar como y biblioteca con nombres iguales, renombrar y abrir reinicia historial',
    (tester) async {
      final controller = await openPersistent(tester);
      controller.saveCharacter(character('A1'));
      await tester.pumpAndSettle();
      await action(tester, 'save-scenario');
      expect(controller.workspace!.saved, isTrue);
      final first = controller.workspace!.current.id;
      await action(tester, 'save-as-scenario');
      await edit(tester, 'scenario-name', 'Gemelos');
      await press(tester, 'confirm-scenario-name');
      final second = controller.workspace!.current.id;
      expect(second, isNot(first));
      expect(controller.history.canUndo, isFalse);
      await press(tester, 'scenario-library');
      expect(keyed('library-$first'), findsOneWidget);
      expect(keyed('library-$second'), findsOneWidget);
      await press(tester, 'library-actions-$first');
      await tester.tap(find.text('Renombrar'));
      await tester.pumpAndSettle();
      await edit(tester, 'scenario-name', 'Gemelos');
      await press(tester, 'confirm-scenario-name');
      await press(tester, 'library-$first');
      expect(controller.workspace!.current.id, first);
      expect(controller.value.characters.length, 1);
      expect(controller.history.canUndo, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'nuevo con cambios pide cancelar, descartar o guardar antes de sustituir sesión',
    (tester) async {
      final controller = await openPersistent(tester);
      controller.saveCharacter(character('A1'));
      await tester.pumpAndSettle();
      final before = controller.value;
      await action(tester, 'new-scenario');
      expect(find.text('Cambios fuera de la biblioteca'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(controller.value, same(before));
      await action(tester, 'new-scenario');
      await press(tester, 'save-before-leave');
      await edit(tester, 'scenario-name', 'Nuevo');
      await press(tester, 'confirm-scenario-name');
      expect(controller.value.characters.isEmpty, isTrue);
      expect((await controller.workspace!.library()).length, 1);
      expect(controller.history.canUndo, isFalse);
    },
  );
  testWidgets(
    'eliminar archivo de biblioteca exige confirmar y mantiene el escenario abierto',
    (tester) async {
      final controller = await openPersistent(tester);
      controller.saveCharacter(character('A1'));
      await tester.pumpAndSettle();
      await action(tester, 'save-scenario');
      final id = controller.workspace!.current.id, before = controller.value;
      await press(tester, 'scenario-library');
      await press(tester, 'library-actions-$id');
      await tester.tap(find.text('Eliminar de biblioteca'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect((await controller.workspace!.library()).length, 1);
      await press(tester, 'library-actions-$id');
      await tester.tap(find.text('Eliminar de biblioteca'));
      await tester.pumpAndSettle();
      await press(tester, 'confirm-delete-scenario');
      expect((await controller.workspace!.library()), isEmpty);
      expect(controller.value, same(before));
      expect(controller.workspace!.dirty, isTrue);
    },
  );
  testWidgets(
    'fallo de guardado muestra error legible y preserva memoria e historial',
    (tester) async {
      final store = MemoryStore(),
          controller = await openPersistent(tester, store: store);
      controller.saveCharacter(character('A1'));
      await tester.pumpAndSettle();
      final before = controller.value;
      store.failWrite = true;
      await action(tester, 'save-scenario');
      expect(find.text('No se pudo completar'), findsOneWidget);
      expect(find.textContaining('almacenamiento local'), findsOneWidget);
      expect(controller.value, same(before));
      expect(controller.history.canUndo, isTrue);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      store.failWrite = false;
      await action(tester, 'save-scenario');
      expect(controller.workspace!.saved, isTrue);
    },
  );
  testWidgets(
    'importación corrupta no cambia nada y JSON válido abre con identidad nueva',
    (tester) async {
      final files = FakeScenarioFiles(),
          controller = await openPersistent(tester, files: files);
      controller.saveCharacter(character('A1'));
      await tester.pumpAndSettle();
      await action(tester, 'save-scenario');
      final before = controller.value, id = controller.workspace!.current.id;
      files.picked = PickedScenario(
        Uint8List.fromList(utf8.encode('{"schemaVersion":999}')),
        'corrupto.json',
      );
      await action(tester, 'import-scenario');
      expect(find.text('No se pudo completar'), findsOneWidget);
      expect(controller.value, same(before));
      expect(controller.workspace!.current.id, id);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      files.picked = PickedScenario(
        Uint8List.fromList(
          utf8.encode(const ScenarioCodec().encode(sampleDocument())),
        ),
        'valido.json',
      );
      await action(tester, 'import-scenario');
      expect(controller.workspace!.current.name, 'Mi escenario');
      expect(controller.workspace!.current.id, isNot(sampleDocument().id));
      expect(controller.value.studyConflicts, {cell('C3')});
      expect(controller.history.canUndo, isFalse);
    },
  );
  testWidgets(
    'JSON y PNG se envían al puerto nativo sin modificar el escenario',
    (tester) async {
      final files = FakeScenarioFiles(),
          controller = await openPersistent(tester, files: files);
      controller.saveCharacter(character('A1'));
      await tester.pumpAndSettle();
      final before = controller.value;
      await action(tester, 'export-json');
      expect(files.savedMime, 'application/json');
      expect(
        const ScenarioCodec()
            .decode(utf8.decode(files.savedBytes!))
            .session
            .characters
            .length,
        1,
      );
      await action(tester, 'share-json');
      expect(files.sharedMime, 'application/json');
      expect(controller.value, same(before));
      await action(tester, 'export-png');
      await press(tester, 'png-legend');
      await press(tester, 'png-coordinates');
      files.savedSignal = Completer<void>();
      await tester.tap(keyed('save-png'));
      // El GPU/encoder usa el reloj real; las continuaciones del diálogo usan el del test.
      for (
        var attempt = 0;
        attempt < 250 && !files.savedSignal!.isCompleted;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      expect(files.savedSignal!.isCompleted, isTrue);
      await tester.pumpAndSettle();
      expect(files.savedMime, 'image/png');
      expect(files.savedBytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(controller.value, same(before));
      expect(controller.history.undoCount, 1);
    },
  );
  testWidgets('cancelar selector nativo no crea ni sustituye un escenario', (
    tester,
  ) async {
    final files = FakeScenarioFiles(),
        controller = await openPersistent(tester, files: files);
    await action(tester, 'save-scenario');
    final id = controller.workspace!.current.id;
    await action(tester, 'import-scenario');
    expect(controller.workspace!.current.id, id);
    expect((await controller.workspace!.library()).length, 1);
  });
  for (final size in [
    const Size(320, 568),
    const Size(800, 360),
    const Size(320, 320),
  ]) {
    testWidgets('biblioteca y formulario de escenario en $size texto 300 %', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openPersistent(tester);
      await action(tester, 'save-as-scenario');
      await edit(tester, 'scenario-name', 'Accesible');
      await press(tester, 'confirm-scenario-name');
      await press(tester, 'scenario-library');
      await tester.tap(find.byTooltip('Cerrar biblioteca'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
