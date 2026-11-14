import 'package:material_ui/material_ui.dart';

import 'presentation/home/home_screen.dart';
import 'presentation/editor/editor_controller.dart';
import 'presentation/theme/app_theme.dart';

class HeroClixApp extends StatefulWidget {
  const HeroClixApp({super.key});

  @override
  State<HeroClixApp> createState() => _HeroClixAppState();
}

class _HeroClixAppState extends State<HeroClixApp> {
  final _editorController = EditorController();

  @override
  void dispose() {
    _editorController.dispose();
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
      home: HomeScreen(editorController: _editorController),
    );
  }
}
