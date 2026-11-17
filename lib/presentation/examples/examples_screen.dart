import 'package:material_ui/material_ui.dart';

import '../../application/examples/local_examples.dart';
import '../editor/editor_controller.dart';
import '../editor/editor_screen.dart';
import '../editor/board_canvas.dart';
import '../scenarios/scenario_actions.dart';
import '../help/info_screen.dart';

class ExamplesScreen extends StatelessWidget {
  const ExamplesScreen({required this.editor, super.key});
  final EditorController editor;
  @override
  Widget build(BuildContext context) => InformationScreen(
    title: 'Ejemplos locales',
    children: [
      const Text(
        'Escenas originales con reglas ya verificadas. Vista previa independiente; Abrir copia crea una escena nueva y conserva el ejemplo. Puedes modificarla y practicar.',
      ),
      for (final example in localExamples)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  example.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(example.lesson),
                Text(
                  'Edición ${example.exercise.rules.value} · §${example.exercise.references.join(' / ')}',
                ),
                OutlinedButton(
                  key: ValueKey('example-${example.id}'),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExamplePreview(example: example, editor: editor),
                    ),
                  ),
                  child: const Text('Ver ejemplo'),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class ExamplePreview extends StatefulWidget {
  const ExamplePreview({
    required this.example,
    required this.editor,
    super.key,
  });
  final LocalExample example;
  final EditorController editor;
  @override
  State<ExamplePreview> createState() => _ExamplePreviewState();
}

class _ExamplePreviewState extends State<ExamplePreview> {
  late final _copy = widget.example.copy();
  late final _preview = EditorController()..loadScenario(_copy.session);
  bool _opening = false;
  Future<void> _open() async {
    setState(() => _opening = true);
    try {
      final workspace = widget.editor.workspace;
      if (workspace != null) {
        if (workspace.loading || workspace.busy) return;
        if (!await ScenarioActions(widget.editor).openExample(context, _copy)) {
          return;
        }
      } else {
        widget.editor.loadScenario(_copy.session);
      }
      if (mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => EditorScreen(controller: widget.editor),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InformationScreen(
    title: widget.example.title,
    children: [
      Text(widget.example.lesson),
      SizedBox(
        height: 300,
        child: BoardCanvas(controller: _preview, readOnly: true),
      ),
      Text(
        'Edición ${widget.example.exercise.rules.value} · §${widget.example.exercise.references.join(' / ')}',
      ),
      AnimatedBuilder(
        animation: widget.editor.workspace ?? _preview,
        builder: (context, _) => FilledButton.icon(
          key: const ValueKey('open-example-copy'),
          onPressed:
              _opening ||
                  widget.editor.workspace?.loading == true ||
                  widget.editor.workspace?.busy == true
              ? null
              : _open,
          icon: const Icon(Icons.copy_outlined),
          label: Text(
            _opening
                ? 'Abriendo copia…'
                : widget.editor.workspace?.loading == true
                ? 'Preparando escenario…'
                : 'Abrir copia en editor',
          ),
        ),
      ),
    ],
  );
}
