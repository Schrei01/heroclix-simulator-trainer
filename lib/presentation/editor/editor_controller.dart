import 'package:flutter/foundation.dart';

import '../../application/board/board_session.dart';
import '../../domain/board/board_dimensions.dart';
import '../../domain/board/board_viewport.dart';

/// Adaptador de notificación: la sesión y las conversiones usan Dart puro.
final class EditorController extends ValueNotifier<BoardSession> {
  EditorController() : super(BoardSession.initial());

  void resizeViewport(ViewportSize size) => value = value.resizeViewport(size);
  void setCamera(BoardCamera camera) => value = value.withCamera(camera);
  void tap(BoardPoint point) => value = value.tapViewport(point);
  void clearSelection() => value = value.clearSelection();
  void changeDimensions(BoardDimensions dimensions) =>
      value = value.changeDimensions(dimensions);
  void toggleGrid() => value = value.toggleGrid();
  void toggleCoordinates() => value = value.toggleCoordinates();
  void zoom(double factor) => value = value.zoom(factor);
  void centerCamera() => value = value.centerCamera();
  void resetCamera() => value = value.resetCamera();
}
