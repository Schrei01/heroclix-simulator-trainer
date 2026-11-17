import 'package:material_ui/material_ui.dart';

import 'presentation/home/home_screen.dart';
import 'presentation/editor/editor_controller.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/training/training_controller.dart';
import 'application/training/training_repository.dart';

import 'dart:async';

class HeroClixApp extends StatefulWidget {
  const HeroClixApp({this.controller, this.trainingController, super.key});
  final EditorController? controller;
  final TrainingController? trainingController;

  @override
  State<HeroClixApp> createState() => _HeroClixAppState();
}

class _HeroClixAppState extends State<HeroClixApp> with WidgetsBindingObserver {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeroClix Simulator & Trainer',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.dark,
      home: HomeScreen(
        editorController: _editorController,
        trainingController: _trainingController,
      ),
    );
  }
}
