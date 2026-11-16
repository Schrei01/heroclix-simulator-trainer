import 'package:material_ui/material_ui.dart';

class ScenarioFormDialog extends StatelessWidget {
  const ScenarioFormDialog({
    required this.title,
    required this.children,
    super.key,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
}

Future<({String name, String rules})?> askScenarioName(
  BuildContext context, {
  required String title,
  required String name,
  required String rules,
}) => showDialog<({String name, String rules})>(
  context: context,
  builder: (_) => _NameDialog(title, name, rules),
);

class _NameDialog extends StatefulWidget {
  const _NameDialog(this.title, this.name, this.rules);
  final String title, name, rules;
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name),
      _rules = TextEditingController(text: widget.rules);
  @override
  void dispose() {
    _name.dispose();
    _rules.dispose();
    super.dispose();
  }

  String? _validate(String? value, int max) =>
      value == null || value.trim().isEmpty || value.trim().length > max
      ? 'Introduce de 1 a $max caracteres.'
      : null;
  @override
  Widget build(BuildContext context) => ScenarioFormDialog(
    title: widget.title,
    children: [
      Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('scenario-name'),
              controller: _name,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Nombre del escenario',
              ),
              validator: (value) => _validate(value, 80),
            ),
            TextFormField(
              key: const ValueKey('scenario-rules'),
              controller: _rules,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Versión reglamentaria objetivo',
              ),
              validator: (value) => _validate(value, 40),
            ),
            const Text(
              'La versión es una referencia del escenario. No implica que sus reglas estén implementadas.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('confirm-scenario-name'),
            onPressed: () {
              if (_form.currentState!.validate()) {
                Navigator.pop(context, (
                  name: _name.text.trim(),
                  rules: _rules.text.trim(),
                ));
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    ],
  );
}

Future<void> showScenarioError(BuildContext context, String message) =>
    showDialog<void>(
      context: context,
      builder: (context) => ScenarioFormDialog(
        title: 'No se pudo completar',
        children: [
          Text(message),
          const SizedBox(height: 16),
          const Text(
            'El escenario abierto se conserva. Puedes volver a intentarlo.',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
