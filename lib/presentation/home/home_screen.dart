import 'package:material_ui/material_ui.dart';

import '../../application/home_catalog.dart';
import '../../domain/app_mode.dart';
import '../theme/app_theme.dart';
import '../editor/editor_controller.dart';
import '../editor/editor_screen.dart';
import '../training/training_controller.dart';
import '../training/training_screen.dart';
import '../help/info_screen.dart';
import '../examples/examples_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.editorController,
    required this.trainingController,
    super.key,
  });

  final EditorController editorController;
  final TrainingController trainingController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _OfflineBadge(),
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    child: Text(
                      'HeroClix Simulator & Trainer',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu espacio de práctica táctica.',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Construye tu escenario y ensaya movimiento, distancias, alcance y visión con '
                    'explicaciones y referencias. Practica ejercicios y guarda tu progreso local.',
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    header: true,
                    child: Text(
                      'Elige una herramienta',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 640 ? 2 : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 16) / columns;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final mode in homeModes)
                            SizedBox(
                              width: width,
                              child: _ModeCard(
                                mode: mode,
                                onOpen: availableModes.contains(mode)
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                mode == AppMode.trainer
                                                ? TrainingScreen(
                                                    controller:
                                                        trainingController,
                                                  )
                                                : EditorScreen(
                                                    controller:
                                                        editorController,
                                                  ),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Sin cuentas ni conexión a internet. '
                    'Escenario temporal mientras la app está abierta. Guarda en biblioteca para conservarlo.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('open-examples'),
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ExamplesScreen(editor: editorController),
                          ),
                        ),
                        icon: const Icon(Icons.collections_bookmark_outlined),
                        label: const Text('Ejemplos locales'),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('open-guide'),
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QuickGuideScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Guía rápida'),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('open-about'),
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Acerca de'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF395B62)),
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1B343A),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_bolt_outlined, color: AppTheme.accent, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'PRÁCTICA OFFLINE',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onOpen});

  final AppMode mode;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final (title, description, icon) = switch (mode) {
      AppMode.editor => (
        'Editor',
        'Construye escenarios, consulta visión y alcance, ensaya rutas y compara posiciones.',
        Icons.edit_outlined,
      ),
      AppMode.trainer => (
        'Entrenador',
        'Practica con ejercicios y explicaciones.',
        Icons.school_outlined,
      ),
    };

    final openLabel = switch (mode) {
      AppMode.editor => 'Abrir editor',
      AppMode.trainer => 'Abrir entrenador',
    };
    return Semantics(
      key: ValueKey('mode-${mode.id}'),
      label:
          '$title. ${onOpen == null ? 'Próximamente' : openLabel}. $description',
      button: true,
      enabled: onOpen != null,
      onTap: onOpen,
      child: ExcludeSemantics(
        child: Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: onOpen == null
                  ? const Color(0xFF34465C)
                  : const Color(0xFF568A82),
            ),
          ),
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppTheme.accent, size: 28),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        onOpen == null
                            ? Icons.schedule_outlined
                            : Icons.arrow_forward,
                        size: 16,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          onOpen == null ? 'Próximamente' : openLabel,
                          style: const TextStyle(color: AppTheme.muted),
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
    );
  }
}
