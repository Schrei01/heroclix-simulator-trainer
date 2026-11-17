import 'package:flutter/widgets.dart';

import 'training_controller.dart';

class TrainingScope extends InheritedWidget {
  const TrainingScope({
    required this.controller,
    required super.child,
    super.key,
  });
  final TrainingController controller;
  static TrainingController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TrainingScope>()?.controller;
  @override
  bool updateShouldNotify(covariant TrainingScope oldWidget) =>
      controller != oldWidget.controller;
}
