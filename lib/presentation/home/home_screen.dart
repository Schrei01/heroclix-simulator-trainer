import 'package:material_ui/material_ui.dart';

import '../../application/home_catalog.dart';
import '../../domain/app_mode.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    'Tu próximo espacio de práctica táctica.',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prepara escenarios, explora posiciones y aprende a tu '
                    'ritmo. Las herramientas estarán disponibles en próximas '
                    'versiones.',
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    header: true,
                    child: Text(
                      'Herramientas en preparación',
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
                          for (final mode in plannedModes)
                            SizedBox(
                              width: width,
                              child: _PlannedModeCard(mode: mode),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Sin cuentas ni conexión a internet. '
                    'Esta versión presenta el inicio de la aplicación.',
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

class _PlannedModeCard extends StatelessWidget {
  const _PlannedModeCard({required this.mode});

  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    final (title, description, icon) = switch (mode) {
      AppMode.editor => (
        'Editor',
        'Construye y guarda tus propios escenarios.',
        Icons.edit_outlined,
      ),
      AppMode.simulator => (
        'Simulador',
        'Explora visión, alcance y movimiento.',
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

    return Semantics(
      key: ValueKey('mode-${mode.id}'),
      label: '$title. Próximamente. $description',
      button: true,
      enabled: false,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF34465C)),
          ),
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
                const Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: AppTheme.muted,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Próximamente',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
