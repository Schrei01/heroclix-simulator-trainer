import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_viewport.dart';
import '../theme/app_theme.dart';
import 'board_painter.dart';
import 'editor_controller.dart';

class BoardCanvas extends StatefulWidget {
  const BoardCanvas({required this.controller, super.key});

  final EditorController controller;

  @override
  State<BoardCanvas> createState() => _BoardCanvasState();
}

class _BoardCanvasState extends State<BoardCanvas> {
  late final TransformationController _transform;
  bool _synchronizing = false;
  final _pointers = <int>{};
  Offset? _pointerStart;
  bool _blockTap = false;

  static Matrix4 _matrix(BoardCamera camera) => Matrix4.identity()
    ..setEntry(0, 0, camera.scale)
    ..setEntry(1, 1, camera.scale)
    ..setEntry(2, 2, camera.scale)
    ..setEntry(0, 3, camera.offsetX)
    ..setEntry(1, 3, camera.offsetY);

  BoardCamera get _matrixCamera => BoardCamera(
    scale: _transform.value.storage[0],
    offsetX: _transform.value.storage[12],
    offsetY: _transform.value.storage[13],
  );

  @override
  void initState() {
    super.initState();
    _transform = TransformationController(
      _matrix(widget.controller.value.camera),
    )..addListener(_onTransform);
    widget.controller.addListener(_onSession);
  }

  @override
  void didUpdateWidget(BoardCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onSession);
      widget.controller.addListener(_onSession);
      _onSession();
    }
  }

  void _onTransform() {
    if (!_synchronizing) widget.controller.setCamera(_matrixCamera);
  }

  void _onSession() {
    final camera = widget.controller.value.camera;
    if (camera == _matrixCamera) return;
    _synchronizing = true;
    _transform.value = _matrix(camera);
    _synchronizing = false;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSession);
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  void _pointerDown(PointerDownEvent event) {
    if (_pointers.isEmpty) {
      _pointerStart = event.localPosition;
      _blockTap = false;
    }
    _pointers.add(event.pointer);
    if (_pointers.length > 1) _blockTap = true;
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_pointerStart != null &&
        (event.localPosition - _pointerStart!).distance > kTouchSlop) {
      _blockTap = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.value;
    const geometry = BoardGeometry();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        final viewport = ViewportSize(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        if (viewport != session.viewport) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.controller.resizeViewport(viewport);
          });
        }
        return Semantics(
          label:
              'Tablero de ${session.dimensions.rows} filas y '
              '${session.dimensions.columns} columnas. '
              '${session.selectedCell == null ? 'Sin selección' : 'Seleccionada ${session.selectedCell!.label}'}.',
          hint:
              'Toca una casilla para seleccionarla. Usa dos dedos para ampliar '
              'y arrastra para desplazar. También hay botones de zoom y centrar.',
          child: ColoredBox(
            color: AppTheme.background,
            child: Listener(
              key: const ValueKey('board-viewport'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: _pointerDown,
              onPointerMove: _pointerMove,
              onPointerUp: (event) => _pointers.remove(event.pointer),
              onPointerCancel: (event) {
                _blockTap = true;
                _pointers.remove(event.pointer);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  if (!_blockTap) {
                    widget.controller.tap(
                      BoardPoint(
                        details.localPosition.dx,
                        details.localPosition.dy,
                      ),
                    );
                  }
                },
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  alignment: Alignment.topLeft,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: BoardCamera.minimumScale,
                  maxScale: BoardCamera.maximumScale,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(
                        geometry.width(session.dimensions),
                        geometry.height(session.dimensions),
                      ),
                      painter: BoardPainter(
                        dimensions: session.dimensions,
                        selectedCell: session.selectedCell,
                        showGrid: session.showGrid,
                        showCoordinates: session.showCoordinates,
                      ),
                      isComplex: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
