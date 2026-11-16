import '../../domain/characters/movement_ability.dart';

import 'package:material_ui/material_ui.dart';

import '../../domain/board/cell_coordinate.dart';
import '../../domain/characters/character.dart';
import '../../domain/characters/vision_ability.dart';
import '../../domain/characters/team.dart';
import 'editor_controller.dart';

String patternName(TeamPattern pattern) => switch (pattern) {
  TeamPattern.solid => 'Liso',
  TeamPattern.stripes => 'Rayas',
  TeamPattern.dots => 'Puntos',
};

/// Todo el formulario, incluidos título y acciones, puede desplazarse con texto grande.
class _ScrollableFormDialog extends StatelessWidget {
  const _ScrollableFormDialog({
    required this.title,
    required this.content,
    required this.actions,
  });
  final Widget title, content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DefaultTextStyle(
              style: Theme.of(context).textTheme.headlineSmall!,
              child: title,
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showCharacterDialog(
  BuildContext context,
  EditorController controller, {
  Character? character,
  CellCoordinate? position,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  return showDialog<void>(
    context: context,
    builder: (_) => CharacterDialog(
      controller: controller,
      character: character,
      position: position,
    ),
  );
}

class CharacterDialog extends StatefulWidget {
  const CharacterDialog({
    required this.controller,
    this.character,
    this.position,
    super.key,
  });
  final EditorController controller;
  final Character? character;
  final CellCoordinate? position;
  @override
  State<CharacterDialog> createState() => _CharacterDialogState();
}

class _CharacterDialogState extends State<CharacterDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _position, _speed, _range;
  late String _team;
  late Footprint _footprint;
  late Set<VisionAbility> _abilities;
  late FigureSize _size;
  late Set<MovementAbility> _movementAbilities;
  bool _duplicate = false;
  bool _allowStudy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final figure = widget.character;
    _allowStudy =
        figure?.occupiedCells.any(
          (cell) => widget.controller.value.studyConflicts.contains(cell),
        ) ??
        false;
    _name = TextEditingController(text: figure?.name ?? 'Figura');
    _position = TextEditingController(
      text: (figure?.position ?? widget.position)?.label ?? 'A1',
    );
    _speed = TextEditingController(text: '${figure?.speed ?? 6}');
    _range = TextEditingController(text: '${figure?.range ?? 4}');
    _team = figure?.teamId ?? widget.controller.value.teams.first.id;
    _footprint = figure?.footprint ?? Footprint.single;
    _abilities = {...?figure?.abilities};
    _size = figure?.size ?? FigureSize.normal;
    _movementAbilities = {...?figure?.movementAbilities};
  }

  @override
  void dispose() {
    for (final field in [_name, _position, _speed, _range]) {
      field.dispose();
    }
    super.dispose();
  }

  String? _number(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < 0 || number > 99
        ? 'Entero de 0 a 99.'
        : null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final data = CharacterDraft(
      name: _name.text,
      teamId: _team,
      position: CellCoordinate.parse(_position.text),
      footprint: _footprint,
      speed: int.parse(_speed.text.trim()),
      range: int.parse(_range.text.trim()),
      abilities: _abilities,
      size: _size,
      movementAbilities: _movementAbilities,
    );
    final error = widget.controller.saveCharacter(
      data,
      id: _duplicate ? null : widget.character?.id,
      allowStudy: _allowStudy,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('¿Eliminar figura?'),
        content: const Text(
          'La figura se eliminará de esta sesión. Deshacer estará disponible en una etapa posterior.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-character'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.controller.deleteCharacter(widget.character!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => _ScrollableFormDialog(
    title: Text(
      widget.character == null
          ? 'Nueva figura'
          : '${_duplicate ? 'Duplicar' : 'Ficha'} ${widget.character!.label}',
    ),
    content: SizedBox(
      width: 380,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edición libre. Velocidad y alcance son datos; no se evalúan movimientos ni ataques.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('character-name'),
              controller: _name,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Introduce un nombre.'
                  : value.trim().length > 80
                  ? 'El nombre es demasiado largo.'
                  : null,
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('character-team-$_team'),
              initialValue: _team,
              isExpanded: true,
              itemHeight: null,
              decoration: const InputDecoration(labelText: 'Equipo'),
              items: [
                for (final team in widget.controller.value.teams)
                  DropdownMenuItem(
                    value: team.id,
                    child: Text(
                      '${team.code} · ${team.name} · ${patternName(team.pattern)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _team = value!),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('new-team'),
                onPressed: () async {
                  final id = await showDialog<String>(
                    context: context,
                    builder: (_) => _TeamDialog(controller: widget.controller),
                  );
                  if (id != null && mounted) {
                    setState(() => _team = id);
                  }
                },
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Nuevo equipo'),
              ),
            ),
            TextFormField(
              key: const ValueKey('character-position'),
              controller: _position,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Casilla de anclaje',
                hintText: 'A1',
              ),
              validator: (value) {
                try {
                  CellCoordinate.parse(value ?? '');
                  return null;
                } on FormatException {
                  return 'Usa una coordenada como A1.';
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Footprint>(
              isExpanded: true,
              itemHeight: null,
              key: const ValueKey('character-footprint'),
              initialValue: _footprint,
              decoration: const InputDecoration(labelText: 'Base'),
              items: [
                for (final base in [
                  ...Footprint.supported,
                  if (!_footprint.isSupported) _footprint,
                ])
                  DropdownMenuItem(value: base, child: Text(base.label)),
              ],
              onChanged: (value) => setState(() => _footprint = value!),
            ),
            if (_footprint != Footprint.single)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'El anclaje indica la esquina superior izquierda. La huella no concede un tamaño ni habilidades.',
                ),
              ),
            TextFormField(
              key: const ValueKey('character-speed'),
              controller: _speed,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Velocidad (0–99)'),
              validator: _number,
            ),
            TextFormField(
              key: const ValueKey('character-range'),
              controller: _range,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Alcance (0–99)'),
              validator: _number,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '⚠ $_error',
                    key: const ValueKey('character-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            CheckboxListTile(
              key: const ValueKey('allow-study-position'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Permitir posición sobre bloqueado para estudio',
              ),
              subtitle: const Text(
                'Se marcará con !. No afirma legalidad reglamentaria.',
              ),
              value: _allowStudy,
              onChanged: (value) =>
                  setState(() => _allowStudy = value ?? false),
            ),
            DropdownButtonFormField<FigureSize>(
              key: const ValueKey('character-size'),
              isExpanded: true,
              initialValue: _size,
              decoration: const InputDecoration(
                labelText: 'Tamaño (independiente de la base)',
              ),
              items: [
                for (final s in FigureSize.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (s) => setState(() => _size = s!),
            ),
            const Text(
              'Solo Normal se evalúa como origen/destino. Tiny/Giant/Colossal quedan pendientes como extremos. La huella no concede un tamaño ni poderes.',
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              key: const ValueKey('movement-abilities'),
              title: const Text('Improved Movement · movimiento'),
              children: [
                const Text(
                  'H no añade costo. Cada mejora ignora solo su componente; las opciones sin soporte dejan la ruta No evaluada.',
                ),
                for (final a in MovementAbility.values)
                  CheckboxListTile(
                    key: ValueKey('movement-ability-${a.name}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${a.label}${a.supported ? '' : ' · sin soporte'}',
                    ),
                    value: _movementAbilities.contains(a),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _movementAbilities.add(a);
                      } else {
                        _movementAbilities.remove(a);
                      }
                    }),
                  ),
              ],
            ),
            const Text(
              'Cada mejora actúa solo sobre su obstáculo. Las opciones sin soporte producen No evaluado; no se interpretan cartas.',
            ),
            const Text('Improved Targeting · capacidades declaradas'),
            for (final ability in VisionAbility.values)
              CheckboxListTile(
                key: ValueKey('ability-${ability.name}'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  ability.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                value: _abilities.contains(ability),
                onChanged: (checked) => setState(() {
                  if (checked!) {
                    _abilities.add(ability);
                  } else {
                    _abilities.remove(ability);
                  }
                }),
              ),
            if (widget.character != null && !_duplicate)
              Wrap(
                children: [
                  TextButton.icon(
                    key: const ValueKey('duplicate-character'),
                    onPressed: () {
                      final cell = widget.controller.value.firstFreeCell(
                        _footprint,
                      );
                      setState(() {
                        _duplicate = true;
                        _error = cell == null
                            ? 'No hay espacio libre para esta base. Indica otro destino o cambia la base.'
                            : null;
                        if (cell != null) _position.text = cell.label;
                      });
                    },
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Duplicar'),
                  ),
                  TextButton.icon(
                    key: const ValueKey('delete-character'),
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar figura'),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const ValueKey('save-character'),
        onPressed: _save,
        child: const Text('Guardar'),
      ),
    ],
  );
}

class _TeamDialog extends StatefulWidget {
  const _TeamDialog({required this.controller});
  final EditorController controller;
  @override
  State<_TeamDialog> createState() => _TeamDialogState();
}

class _TeamDialogState extends State<_TeamDialog> {
  final _name = TextEditingController();
  int _color = 0xff81c784;
  TeamPattern _pattern = TeamPattern.dots;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ScrollableFormDialog(
    title: const Text('Nuevo equipo'),
    content: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('team-name'),
            controller: _name,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Nombre del equipo'),
          ),
          DropdownButtonFormField<int>(
            isExpanded: true,
            itemHeight: null,
            initialValue: _color,
            decoration: const InputDecoration(labelText: 'Color'),
            items: [
              for (final entry in <int, String>{
                0xff81c784: 'Verde',
                0xffffd54f: 'Dorado',
                0xffce93d8: 'Violeta',
                0xff64b5f6: 'Azul',
                0xffff8a80: 'Rojo',
              }.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => _color = value!,
          ),
          DropdownButtonFormField<TeamPattern>(
            isExpanded: true,
            itemHeight: null,
            initialValue: _pattern,
            decoration: const InputDecoration(labelText: 'Patrón'),
            items: [
              for (final pattern in TeamPattern.values)
                DropdownMenuItem(
                  value: pattern,
                  child: Text(
                    patternName(pattern),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => _pattern = value!,
          ),
          if (_error != null) Text(_error!),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const ValueKey('save-team'),
        onPressed: () {
          final error = widget.controller.addTeam(_name.text, _color, _pattern);
          if (error != null) {
            setState(() => _error = error);
          } else {
            Navigator.pop(context, widget.controller.value.teams.last.id);
          }
        },
        child: const Text('Crear equipo'),
      ),
    ],
  );
}
