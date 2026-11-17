import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'editor_controller.dart';
import '../theme/app_theme.dart';

/// Aviso temporal superpuesto: no cambia la cámara ni intercepta gestos del mapa.
class ToolHint extends StatelessWidget {
  const ToolHint({required this.controller, super.key});
  final EditorController controller;
  static const duration = Duration(seconds: 4);
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<({int id, String text})?>(
        valueListenable: controller.toolHint,
        builder: (context, hint, _) => hint == null
            ? const SizedBox.shrink()
            : _TimedHint(key: ValueKey(hint.id), text: hint.text),
      );
}

class _TimedHint extends StatefulWidget {
  const _TimedHint({required this.text, super.key});
  final String text;
  @override
  State<_TimedHint> createState() => _TimedHintState();
}

class _TimedHintState extends State<_TimedHint> {
  late final Timer _timer;
  bool visible = true;
  @override
  void initState() {
    super.initState();
    _timer = Timer(ToolHint.duration, () {
      if (mounted) setState(() => visible = false);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !visible
      ? const SizedBox.shrink()
      : IgnorePointer(
          child: Semantics(
            liveRegion: true,
            label: widget.text,
            child: ExcludeSemantics(
              child: RotatedBox(
                key: const ValueKey('tool-hint-vertical'),
                quarterTurns: 3,
                child: Material(
                  color: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.accent),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      widget.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
}
