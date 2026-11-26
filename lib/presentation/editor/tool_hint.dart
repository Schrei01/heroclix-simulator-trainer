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

  Widget _card(BuildContext context, BoxConstraints constraints) {
    final lineHeight = MediaQuery.textScalerOf(context).scale(14) * 1.4;
    final lines = ((constraints.maxHeight - 16) / lineHeight).floor().clamp(
      1,
      100,
    );
    return Material(
      key: const ValueKey('tool-hint-vertical'),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.accent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          widget.text.replaceAll(' · ', '\n\n'),
          softWrap: true,
          maxLines: lines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.accent,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: widget.text,
        child: ExcludeSemantics(
          child: Align(
            alignment: Alignment.topRight,
            widthFactor: 1,
            child: SizedBox(
              width: (MediaQuery.sizeOf(context).width * .32).clamp(
                96.0,
                144.0,
              ),
              child: LayoutBuilder(builder: _card),
            ),
          ),
        ),
      ),
    );
  }
}
