import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../domain/app_info.dart';
import '../../domain/beta_expiration.dart';

/// Se coloca fuera del Navigator para cubrir también rutas y diálogos abiertos.
class BetaAccessGate extends StatefulWidget {
  const BetaAccessGate({
    required this.child,
    this.clock = DateTime.now,
    super.key,
  });

  final Widget child;
  final DateTime Function() clock;

  @override
  State<BetaAccessGate> createState() => _BetaAccessGateState();
}

class _BetaAccessGateState extends State<BetaAccessGate>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExpiration();
  }

  void _checkExpiration() {
    _timer?.cancel();
    final now = widget.clock();
    // Una sesión bloqueada no se reactiva al atrasar el reloj.
    if (_expired || BetaExpiration.hasExpired(now)) {
      if (!_expired) setState(() => _expired = true);
      return;
    }
    final remaining = BetaExpiration.deadline.difference(now);
    const interval = Duration(minutes: 1);
    // Revisa cambios de reloj y programa el último control en el corte exacto.
    _timer = Timer(
      remaining < interval ? remaining : interval,
      _checkExpiration,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkExpiration();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _expired
      ? Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AppInfo.iconAsset, width: 80, height: 80),
                      const SizedBox(height: 20),
                      Text(
                        AppInfo.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Versión de prueba finalizada',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Esta versión de prueba venció el '
                        '${BetaExpiration.label}.\n\n'
                        'Para continuar, instala una versión actualizada '
                        'de TeamFight: GridLab.\n\n'
                        'Tus escenarios guardados y tu progreso se conservan '
                        'en este dispositivo.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
      : widget.child;
}
