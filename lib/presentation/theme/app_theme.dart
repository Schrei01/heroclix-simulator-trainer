import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const background = Color(0xFF101C2B);
  static const surface = Color(0xFF1A2A3D);
  static const accent = Color(0xFF9DE8D3);
  static const muted = Color(0xFFB9C8D8);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: Color(0xFFF2F6FC),
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF2F6FC),
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: muted),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: muted),
      ),
    );
  }
}
