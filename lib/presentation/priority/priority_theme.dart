import 'package:material_ui/material_ui.dart';

/// Scoped to Priority, including its dialogs; other modules keep their theme.
class PriorityTheme extends StatelessWidget {
  const PriorityTheme({required this.child, super.key});
  final Widget child;
  static const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
  );

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: shape,
            minimumSize: const Size(48, 48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: shape,
            minimumSize: const Size(48, 48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: shape,
            minimumSize: const Size(48, 48),
          ),
        ),
      ),
      child: child,
    );
  }
}
