import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_viewport.dart';
import '../theme/app_theme.dart';
import 'board_painter.dart';
import 'editor_controller.dart';
import '../../application/board/board_session.dart';
import '../../domain/board/cell_coordinate.dart';
import 'character_dialog.dart';

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
  bool _multiTouch = false;
  FigureDragPreview? _drag;
  int _dragColumnOffset = 0, _dragRowOffset = 0;

  BoardPoint _scene(Offset point) => widget.controller.value.camera
      .viewportToScene(BoardPoint(point.dx, point.dy));
  CellCoordinate? _cell(Offset point) => const BoardGeometry().cellAt(
    _scene(point),
    widget.controller.value.dimensions,
  );
  void _startDrag(LongPressStartDetails details) {
    if (_multiTouch) return;
    final cell = _cell(details.localPosition);
    final figure = cell == null
        ? null
        : widget.controller.value.characters.at(cell);
    if (figure == null) return;
    widget.controller.selectCharacter(figure.id);
    _dragColumnOffset = cell!.column - figure.position.column;
    _dragRowOffset = cell.row - figure.position.row;
    setState(
      () => _drag = FigureDragPreview(
        figure,
        figure.position,
        _scene(details.localPosition),
        true,
        'Destino válido: ${figure.position.label}',
      ),
    );
    _blockTap = true;
  }

  void _updateDrag(LongPressMoveUpdateDetails details) {
    final drag = _drag;
    if (drag == null || _multiTouch) return;
    final cell = _cell(details.localPosition);
    final col = (cell?.column ?? -1) - _dragColumnOffset;
    final row = (cell?.row ?? -1) - _dragRowOffset;
    final target = col < 0 || row < 0
        ? null
        : CellCoordinate(column: col, row: row);
    final state = widget.controller.value;
    final result = state.characters.validatePlacement(
      dimensions: state.dimensions,
      position: target,
      footprint: drag.figure.footprint,
      excludingId: drag.figure.id,
    );
    setState(
      () => _drag = FigureDragPreview(
        drag.figure,
        target,
        _scene(details.localPosition),
        result.isValid,
        result.isValid ? 'Destino válido: ${target!.label}' : result.reason,
      ),
    );
  }

  void _endDrag() {
    final drag = _drag;
    if (drag == null) return;
    setState(() => _drag = null);
    final error = !drag.valid || drag.position == null
        ? drag.message
        : widget.controller.moveCharacter(drag.figure.id, drag.position!);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _cancelDrag() {
    if (_drag != null) setState(() => _drag = null);
  }

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
      _multiTouch = false;
    }
    _pointers.add(event.pointer);
    if (_pointers.length > 1) {
      _blockTap = true;
      _multiTouch = true;
      _cancelDrag();
    }
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
            if (mounted) {
              _cancelDrag();
              widget.controller.resizeViewport(viewport);
            }
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
                _cancelDrag();
                _pointers.remove(event.pointer);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  if (!_blockTap) {
                    final cell = _cell(details.localPosition);
                    if (session.tool == EditorTool.characters &&
                        cell != null &&
                        session.characters.at(cell) == null) {
                      widget.controller.tap(
                        BoardPoint(
                          details.localPosition.dx,
                          details.localPosition.dy,
                        ),
                      );
                      showCharacterDialog(
                        context,
                        widget.controller,
                        position: cell,
                      );
                      return;
                    }
                    widget.controller.tap(
                      BoardPoint(
                        details.localPosition.dx,
                        details.localPosition.dy,
                      ),
                    );
                  }
                },
                onLongPressStart: _startDrag,
                onLongPressMoveUpdate: _updateDrag,
                onLongPressEnd: (_) => _endDrag(),
                onLongPressCancel: _cancelDrag,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        panEnabled: _drag == null,
                        scaleEnabled: _drag == null,
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
                              session: session,
                              preview: _drag,
                            ),
                            isComplex: true,
                          ),
                        ),
                      ),
                    ),
                    if (_drag != null)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: IgnorePointer(
                          child: Material(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${_drag!.valid ? '✓' : '×'} ${_drag!.message}',
                                key: const ValueKey('drag-status'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
