import 'package:material_ui/material_ui.dart';

import 'presentation/home/home_screen.dart';
import 'presentation/theme/app_theme.dart';

class HeroClixApp extends StatelessWidget {
  const HeroClixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeroClix Simulator & Trainer',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
