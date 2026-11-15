import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/board/board_viewport.dart';
import '../theme/app_theme.dart';
import 'board_painter.dart';
import 'editor_controller.dart';
import '../../application/board/board_session.dart';
import '../../domain/board/cell_coordinate.dart';
import 'character_dialog.dart';
import '../../application/board/layer_draft.dart';
import '../../domain/terrain/editing_geometry.dart';

import 'layer_actions.dart';
import 'sight_controls.dart';
import 'sight_painter.dart';

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
  BoardPoint? _editLast;
  CellCoordinate? _editAnchor;
  bool _layerGesture = false;
  bool _compactDialogOpen = false;

  Future<void> _compactPreview(LayerDraft draft) async {
    if (!mounted || widget.controller.draft.value != draft) {
      _compactDialogOpen = false;
      return;
    }
    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => ValueListenableBuilder<LayerDraft?>(
        valueListenable: widget.controller.draft,
        child: Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Vista previa: ${draft.cells.length} casillas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${terrainName(draft.type)} · ${draft.cells.first.label} a ${draft.cells.last.label}. La selección se muestra en el tablero. El escenario aún no ha cambiado.',
                  ),
                  Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        key: const ValueKey('cancel-layer-preview'),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        key: const ValueKey('apply-layer-preview'),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Aplicar terreno'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        builder: (context, current, child) {
          if (current != draft) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted &&
                  (ModalRoute.of(context)?.isCurrent ?? false)) {
                Navigator.pop(context, false);
              }
            });
          }
          return child!;
        },
      ),
    );
    if (mounted && widget.controller.draft.value == draft) {
      if (apply == true) {
        await commitLayerDraft(context, widget.controller);
      } else {
        widget.controller.cancelDraft();
      }
    }
    _compactDialogOpen = false;
    if (mounted) setState(() {});
  }

  void _onDraft() {
    if (mounted) setState(() {});
  }

  void _beginLayer(Offset point) {
    final controller = widget.controller;
    final state = controller.value;
    if (controller.draft.value?.pending ?? false) return;
    _layerGesture = true;
    _editAnchor = _cell(point);
    _editLast = _scene(point);
    controller.draft.value = LayerDraft(
      tool: state.tool,
      type: state.terrainType,
      rectangle: state.rectangleBrush && state.tool == EditorTool.terrain,
      eraseWalls: state.eraseWalls,
      eraseLayer: state.eraseLayer,
    );
    _updateLayer(point);
  }

  void _updateLayer(Offset point) {
    final controller = widget.controller;
    final draft = controller.draft.value;
    if (!_layerGesture || draft == null || _multiTouch) return;
    final state = controller.value;
    final scene = _scene(point), previous = _editLast ?? _scene(point);
    final cell = _cell(point);
    const geometry = EditingGeometry();
    if (draft.tool == EditorTool.terrain) {
      if (draft.rectangle) {
        _editAnchor ??= cell;
        if (_editAnchor != null && cell != null) {
          controller.draft.value = draft.update(
            cells: geometry.rectangle(_editAnchor!, cell),
          );
        }
      } else {
        controller.draft.value = draft.update(
          cells: {
            ...draft.cells,
            ...geometry.cellsAlong(previous, scene, state.dimensions),
          },
        );
      }
    } else if (draft.tool == EditorTool.erase &&
        draft.eraseLayer == EraseLayer.figures) {
      final figure = cell == null ? null : state.characters.at(cell);
      controller.draft.value = draft.update(
        figureId: figure?.id,
        cells: figure?.occupiedCells ?? [],
      );
    } else {
      final dx = scene.x - previous.x, dy = scene.y - previous.y;
      final steps = ((dx.abs() + dy.abs()) / (BoardGeometry.cellExtent / 8))
          .ceil()
          .clamp(1, 20000);
      final edges = {...draft.edges};
      for (var step = 0; step <= steps; step++) {
        final edge = geometry.edgeAt(
          BoardPoint(
            previous.x + dx * step / steps,
            previous.y + dy * step / steps,
          ),
          state.dimensions,
          axis: edges.isEmpty ? null : edges.first.axis,
        );
        if (edge != null) edges.add(edge);
      }
      controller.draft.value = draft.update(edges: edges);
    }
    _editLast = scene;
  }

  void _pointerUp(PointerUpEvent event) {
    if (_layerGesture && !_multiTouch && _pointers.length == 1) {
      _updateLayer(event.localPosition);
      final draft = widget.controller.draft.value;
      _layerGesture = false;
      if (draft != null && draft.rectangle && draft.cells.isNotEmpty) {
        widget.controller.draft.value = draft.update(pending: true);
      } else {
        commitLayerDraft(context, widget.controller);
      }
    }
    _pointers.remove(event.pointer);
  }

  BoardPoint _scene(Offset point) => widget.controller.value.camera
      .viewportToScene(BoardPoint(point.dx, point.dy));
  CellCoordinate? _cell(Offset point) => const BoardGeometry().cellAt(
    _scene(point),
    widget.controller.value.dimensions,
  );
  void _startDrag(LongPressStartDetails details) {
    if (_multiTouch ||
        widget.controller.value.editsLayers ||
        widget.controller.value.tool == EditorTool.vision) {
      return;
    }
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
    final result = state.validateFigurePlacement(drag.figure, target);
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
    widget.controller.draft.addListener(_onDraft);
  }

  @override
  void didUpdateWidget(BoardCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onSession);
      oldWidget.controller.draft.removeListener(_onDraft);
      widget.controller.addListener(_onSession);
      widget.controller.draft.addListener(_onDraft);
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
    widget.controller.draft.removeListener(_onDraft);
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
    if (_pointers.length == 1 && widget.controller.value.editsLayers) {
      _blockTap = true;
      _beginLayer(event.localPosition);
    }
    if (_pointers.length > 1) {
      _blockTap = true;
      _multiTouch = true;
      _cancelDrag();
      _layerGesture = false;
      widget.controller.cancelDraft();
      setState(() {});
    }
  }

  void _pointerMove(PointerMoveEvent event) {
    if (widget.controller.value.editsLayers) _updateLayer(event.localPosition);
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
        final draft = widget.controller.draft.value;
        if (constraints.maxHeight < 240 &&
            draft != null &&
            draft.pending &&
            !_compactDialogOpen) {
          _compactDialogOpen = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _compactPreview(draft),
          );
        }
        if (viewport != session.viewport) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _cancelDrag();
              widget.controller.cancelDraft();
              _layerGesture = false;
              widget.controller.resizeViewport(viewport);
            }
          });
        }
        return Semantics(
          label:
              'Tablero de ${session.dimensions.rows} filas y '
              '${session.dimensions.columns} columnas. '
              '${session.selectedCell == null ? 'Sin selección' : 'Seleccionada ${session.selectedCell!.label}'}. '
              '${session.studyConflicts.isEmpty ? '' : '${session.studyConflicts.length} casillas incompatibles para estudio, marcadas con admiración.'}',
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
              onPointerUp: _pointerUp,
              onPointerCancel: (event) {
                _blockTap = true;
                _cancelDrag();
                _layerGesture = false;
                widget.controller.cancelDraft();
                _pointers.remove(event.pointer);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  if (!_blockTap) {
                    final cell = _cell(details.localPosition);
                    if (session.tool == EditorTool.vision) {
                      if (cell != null) {
                        widget.controller.tap(
                          BoardPoint(
                            details.localPosition.dx,
                            details.localPosition.dy,
                          ),
                        );
                        pickSightCell(context, widget.controller, cell);
                      }
                      return;
                    }
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
                        panEnabled:
                            _drag == null &&
                            (!session.editsLayers || _multiTouch),
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
                              layerPreview: widget.controller.draft.value,
                            ),
                            foregroundPainter: SightPainter(
                              widget.controller.sight.trace,
                              line: widget.controller.sight.showLine,
                              cells: widget.controller.sight.showCells,
                              contacts: widget.controller.sight.showContacts,
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
                    if (widget.controller.draft.value case final draft?)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * .6,
                          ),
                          child: SingleChildScrollView(
                            child: Material(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Vista previa · ${draft.tool == EditorTool.terrain
                                          ? '${draft.cells.length} casillas · ${terrainName(draft.type)}'
                                          : draft.figureId != null
                                          ? 'Borrar figura'
                                          : '${draft.edges.length} bordes internos'}',
                                      key: const ValueKey(
                                        'layer-preview-status',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (draft.pending &&
                                        constraints.maxHeight >= 240)
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        children: [
                                          TextButton(
                                            key: const ValueKey(
                                              'cancel-layer-preview',
                                            ),
                                            onPressed:
                                                widget.controller.cancelDraft,
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            key: const ValueKey(
                                              'apply-layer-preview',
                                            ),
                                            onPressed: () => commitLayerDraft(
                                              context,
                                              widget.controller,
                                            ),
                                            child: const Text(
                                              'Aplicar terreno',
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
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
