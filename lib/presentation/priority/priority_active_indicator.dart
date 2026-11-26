import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A brief turn cue followed by a steady highlight, separate from priority.
class PriorityActiveIndicator extends StatefulWidget {
  const PriorityActiveIndicator({
    required this.playerId,
    required this.color,
    super.key,
  });
  final String playerId;
  final Color color;

  @override
  State<PriorityActiveIndicator> createState() =>
      _PriorityActiveIndicatorState();
}

class _PriorityActiveIndicatorState extends State<PriorityActiveIndicator>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _pulse.stop();
    } else {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (context, _) {
      final light = _reduceMotion == true
          ? 0.0
          : (1 - math.cos(_pulse.value * 4 * math.pi)) / 2;
      return DecoratedBox(
        key: ValueKey('priority-active-glow-${widget.playerId}'),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: .14 + .08 * light),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.color.withValues(alpha: .6 + .2 * light),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .12 + .12 * light),
              blurRadius: 6 + 6 * light,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'ACTIVO',
                  key: ValueKey('priority-active-${widget.playerId}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
