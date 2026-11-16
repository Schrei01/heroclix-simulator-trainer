import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../application/board/board_session.dart';
import '../../domain/app_mode.dart';
import '../../domain/rules/line_of_sight.dart';
import '../editor/editor_controller.dart';
import '../editor/editor_screen.dart';
import '../editor/board_canvas.dart';
import '../editor/sight_controls.dart';
import '../scenarios/scenario_actions.dart';
import 'vision_controls.dart';

/// Vista del mismo escenario y motor. El tablero aquí solo elige extremos/navega.
class VisionScreen extends StatefulWidget {
  const VisionScreen({required this.controller, required this.mode, super.key});
  final EditorController controller;
  final AppMode mode;
  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  void _activate() {
    widget.controller.setTool(EditorTool.vision);
    widget.controller.updateVision((v) => v.enabled = true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activate();
    });
  }

  Future<void> _edit() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(controller: widget.controller),
      ),
    );
    if (mounted) _activate();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<BoardSession>(
    valueListenable: widget.controller,
    builder: (context, session, _) {
      final result = widget.controller.vision.result;
      final status = result?.status ?? VisionStatus.notEvaluated;
      final workspace = widget.controller.workspace;
      return AbsorbPointer(
        absorbing: workspace?.loading == true || workspace?.switching == true,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: math.max(
              56,
              MediaQuery.textScalerOf(context).scale(20) + 16,
            ),
            title: Text(
              widget.mode == AppMode.referee
                  ? 'Modo árbitro'
                  : 'Simulador · Visión',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                key: const ValueKey('vision-edit-scene'),
                tooltip: 'Editar escenario',
                onPressed: _edit,
                icon: const Icon(Icons.edit_outlined),
              ),
              if (workspace != null)
                IconButton(
                  tooltip: 'Biblioteca local',
                  onPressed: workspace.busy
                      ? null
                      : () =>
                            ScenarioActions(widget.controller).library(context),
                  icon: const Icon(Icons.folder_open_outlined),
                ),
              IconButton(
                key: const ValueKey('vision-report'),
                tooltip: 'Dictamen y referencias',
                onPressed: () => showVisionReport(context, widget.controller),
                icon: const Icon(Icons.fact_check_outlined),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                SightToolbar(controller: widget.controller),
                Expanded(
                  child: BoardCanvas(
                    controller: widget.controller,
                    readOnly: true,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        key: const ValueKey('vision-status'),
                        onPressed: () =>
                            showVisionReport(context, widget.controller),
                        icon: Icon(
                          visionIcon(status),
                          color: visionColor(status),
                        ),
                        label: Text(
                          visionLabel(status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: visionColor(status)),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reducir',
                      onPressed: () => widget.controller.zoom(1 / 1.25),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      tooltip: 'Ampliar',
                      onPressed: () => widget.controller.zoom(1.25),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      key: const ValueKey('vision-fit'),
                      tooltip: 'Ajustar tablero',
                      onPressed: widget.controller.resetCamera,
                      icon: const Icon(Icons.fit_screen_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
