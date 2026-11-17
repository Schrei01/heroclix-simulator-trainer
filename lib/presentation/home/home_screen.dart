import 'package:material_ui/material_ui.dart';

import '../../application/home_catalog.dart';
import '../../domain/app_mode.dart';
import '../theme/app_theme.dart';
import '../editor/editor_controller.dart';
import '../editor/editor_screen.dart';
import '../vision/vision_screen.dart';
import '../training/training_controller.dart';
import '../training/training_screen.dart';

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
                                                : mode == AppMode.editor
                                                ? EditorScreen(
                                                    controller:
                                                        editorController,
                                                  )
                                                : VisionScreen(
                                                    controller:
                                                        editorController,
                                                    mode: mode,
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
                    'Autoguardado local y biblioteca de escenarios en el editor.',
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
        'Construye escenarios con figuras, terreno y muros.',
        Icons.edit_outlined,
      ),
      AppMode.simulator => (
        'Simulador',
        'Compara posiciones, ensaya rutas y consulta alcance, objetivos y visión.',
        Icons.route_outlined,
      ),
      AppMode.trainer => (
        'Entrenador',
        'Practica con ejercicios y explicaciones.',
        Icons.school_outlined,
      ),
      AppMode.referee => (
        'Árbitro',
        'Consulta el motivo de cada evaluación.',
        Icons.fact_check_outlined,
      ),
    };

    final openLabel = switch (mode) {
      AppMode.editor => 'Abrir editor',
      AppMode.simulator => 'Abrir simulador',
      AppMode.referee => 'Abrir árbitro',
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
