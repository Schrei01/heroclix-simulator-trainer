import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/app.dart';
import 'package:heroclix_simulator_trainer/domain/beta_expiration.dart';
import 'package:heroclix_simulator_trainer/presentation/beta/beta_access_gate.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('la app real bloquea Editor y Entrenador al arrancar vencida', (
    tester,
  ) async {
    await tester.pumpWidget(HeroClixApp(clock: () => BetaExpiration.deadline));
    await tester.pumpAndSettle();
    expect(find.text('Versión de prueba finalizada'), findsOneWidget);
    expect(find.byKey(const ValueKey('mode-editor')), findsNothing);
    expect(find.byKey(const ValueKey('mode-trainer')), findsNothing);
  });

  test(
    'corte inclusivo a las 00:00 de Colombia, mismo instante en otras zonas',
    () {
      expect(
        BetaExpiration.hasExpired(
          DateTime.parse('2026-12-29T23:59:59.999999-05:00'),
        ),
        isFalse,
      );
      for (final instant in [
        '2026-12-30T00:00:00-05:00',
        '2026-12-30T05:00:00Z',
        '2026-12-30T06:00:00+01:00',
        '2027-01-01T00:00:00Z',
      ]) {
        expect(BetaExpiration.hasExpired(DateTime.parse(instant)), isTrue);
      }
    },
  );

  testWidgets('arranque vencido no construye el contenido protegido', (
    tester,
  ) async {
    var built = false;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            BetaAccessGate(clock: () => BetaExpiration.deadline, child: child!),
        home: Builder(
          builder: (context) {
            built = true;
            return const Scaffold(body: Text('Contenido protegido'));
          },
        ),
      ),
    );
    expect(built, isFalse);
    expect(find.text('Versión de prueba finalizada'), findsOneWidget);
    expect(find.textContaining(BetaExpiration.label), findsOneWidget);
    expect(find.text('Contenido protegido'), findsNothing);
  });

  testWidgets('bloquea en el corte con ruta y diálogo abiertos', (
    tester,
  ) async {
    var now = BetaExpiration.deadline.subtract(const Duration(seconds: 2));
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (context, child) =>
            BetaAccessGate(clock: () => now, child: child!),
        home: const Scaffold(body: Text('Inicio protegido')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Editor protegido')),
      ),
    );
    await tester.pumpAndSettle();
    showDialog<void>(
      context: tester.element(find.text('Editor protegido')),
      builder: (_) => const AlertDialog(title: Text('Diálogo protegido')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Diálogo protegido'), findsOneWidget);

    now = BetaExpiration.deadline;
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Versión de prueba finalizada'), findsOneWidget);
    expect(find.text('Editor protegido'), findsNothing);
    expect(find.text('Diálogo protegido'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Versión de prueba finalizada'), findsOneWidget);
  });

  testWidgets('revisa al reanudar y no reactiva la sesión al atrasar reloj', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 11, 17);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            BetaAccessGate(clock: () => now, child: child!),
        home: const Scaffold(body: Text('Inicio protegido')),
      ),
    );
    expect(find.text('Inicio protegido'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime.utc(2027);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Versión de prueba finalizada'), findsOneWidget);

    now = DateTime.utc(2026, 11, 17);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Versión de prueba finalizada'), findsOneWidget);
  });

  testWidgets(
    'detecta salto del reloj mientras permanece abierta y cancela timer',
    (tester) async {
      var now = DateTime.utc(2026, 11, 17);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              BetaAccessGate(clock: () => now, child: child!),
          home: const Scaffold(body: Text('Inicio protegido')),
        ),
      );
      now = DateTime.utc(2027);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Versión de prueba finalizada'), findsOneWidget);
      expect(find.text('Inicio protegido'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('desmontar antes de vencer cancela la comprobación pendiente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => BetaAccessGate(
          clock: () => DateTime.utc(2026, 11, 17),
          child: child!,
        ),
        home: const Scaffold(body: Text('Inicio protegido')),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('aviso vencido accesible a texto x3 en $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => BetaAccessGate(
            clock: () => BetaExpiration.deadline,
            child: child!,
          ),
          home: const SizedBox.shrink(),
        ),
      );
      await tester.ensureVisible(
        find.textContaining('Tus escenarios guardados'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
