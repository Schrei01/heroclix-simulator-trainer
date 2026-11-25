import 'package:material_ui/material_ui.dart';

import 'presentation/home/home_screen.dart';
import 'presentation/beta/beta_access_gate.dart';
import 'domain/app_info.dart';
import 'presentation/editor/editor_controller.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/training/training_controller.dart';
import 'application/training/training_repository.dart';
import 'presentation/training/training_scope.dart';
import 'presentation/priority/priority_controller.dart';

import 'dart:async';

class HeroClixApp extends StatefulWidget {
  const HeroClixApp({
    this.controller,
    this.trainingController,
    this.priorityController,
    this.clock = DateTime.now,
    super.key,
  });
  final EditorController? controller;
  final TrainingController? trainingController;
  final PriorityController? priorityController;
  final DateTime Function() clock;

  @override
  State<HeroClixApp> createState() => _HeroClixAppState();
}

class _HeroClixAppState extends State<HeroClixApp> with WidgetsBindingObserver {
  late final _priorityController =
      widget.priorityController ?? PriorityController();
  late final _editorController = widget.controller ?? EditorController();
  late final _trainingController =
      widget.trainingController ??
      TrainingController(
        TrainingRepository(SessionTrainingStore()),
        scenarios: _editorController.workspace?.repository,
      );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_trainingController.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _priorityController.setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final workspace = _editorController.workspace;
      if (workspace != null) unawaited(workspace.flush());
      unawaited(_trainingController.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _editorController.dispose();
    _trainingController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.dark,
      builder: (context, child) => BetaAccessGate(
        clock: widget.clock,
        child: TrainingScope(
          controller: _trainingController,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: HomeScreen(
        editorController: _editorController,
        trainingController: _trainingController,
        priorityController: _priorityController,
      ),
    );
  }
}
