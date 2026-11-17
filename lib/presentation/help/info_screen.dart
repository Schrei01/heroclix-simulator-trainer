import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/app_info.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({
    required this.title,
    required this.children,
    super.key,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: math.max(
        56,
        MediaQuery.textScalerOf(context).scale(20) + 16,
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final child in children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: child,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class QuickGuideScreen extends StatelessWidget {
  const QuickGuideScreen({super.key});
  @override
  Widget build(BuildContext context) => const InformationScreen(
    title: 'Guía rápida',
    children: [
      Text(
        'Editor: prepara y guarda figuras, terreno, muros y alturas. El arrastre libre sirve para construir el escenario.',
      ),
      Text(
        'Analizar en el Editor: consulta visión y alcance, ensaya rutas y compara posiciones. Una hipótesis solo se aplica al confirmar un movimiento válido; toca el dictamen para ver explicación y referencias.',
      ),
      Text(
        'Entrenador: responde ejercicios con una copia independiente; Comprobar muestra explicación y registra el intento.',
      ),
      Text(
        'D · Despejado: sin ese obstáculo. H · Obstaculizado: permite visión con restricción. B · Bloqueado y muros: pueden impedir visión y movimiento según el perfil y las capacidades declaradas.',
      ),
      Text(
        'Visión es una línea recta entre referencias permitidas. En un vértice se comparan ambos lados; la línea no se curva. Visible y en alcance no garantiza un ataque legal.',
      ),
      Text(
        'Elevación: E2/E3… y borde rojo. Transición: dos triángulos numerados conectados, uno dentro de cada casilla, con su nivel. Una casilla elevada sin transición conserva la marca E2/E3….',
      ),
      Text(
        '? · No evaluado: faltan reglas o datos para decidir. No significa despejado, bloqueado, fallo del ejercicio ni permiso para actuar. Consulta el motivo antes de continuar.',
      ),
      Text(
        'Reglas implementadas: ${AppInfo.rules}. Las reglas pueden cambiar; compara esta edición con la fuente oficial antes de usar un dictamen. ${AppInfo.disclaimer}',
      ),
      Text(
        'Un dedo usa la herramienta elegida; dos dedos navegan. Amplía el tablero para tocar casillas pequeñas. Mantén pulsado un icono para leer su ayuda.',
      ),
      Text(
        'Cada apertura empieza con un escenario vacío y las figuras desde A. La sesión se conserva mientras la app siga abierta, también al cambiar de sección o dejarla en segundo plano si el proceso continúa activo. Guarda en biblioteca para conservar una escena después de cerrar; el progreso del Entrenador se guarda aparte. JSON sirve como copia externa y PNG es solo una imagen.',
      ),
      Text(
        'Todo el análisis, ejemplos, ejercicios y licencias funciona sin internet ni cuenta. El selector de archivos puede mostrar proveedores externos que requieran conexión; elige almacenamiento del dispositivo para trabajar offline.',
      ),
    ],
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => InformationScreen(
    title: 'Acerca de',
    children: [
      const Text(
        'HeroClix Simulator & Trainer',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const Text('Versión ${AppInfo.version} · compilación ${AppInfo.build}'),
      const Text(
        'Edición reglamentaria implementada: ${AppInfo.rules}. Perfil parcial; no se actualiza automáticamente.',
      ),
      const Text(AppInfo.disclaimer),
      const Text(
        'Fuente oficial de consulta (enlace para abrir fuera de la app cuando tengas conexión):',
      ),
      const SelectableText(AppInfo.source),
      const Text(
        'Cobertura: geometría exacta; visión y vértices; distancia/alcance declarado; elevaciones y transiciones; bases reconocidas; mejoras tipadas de visión y movimiento; rutas por traslación; métricas y ejercicios basados en esos motores.',
      ),
      const Text(
        'Sin soporte completo: tamaños especiales, poderes arbitrarios, separación con dados, maniobras con giro y modificadores no declarados. Se muestra No evaluado. No simula diales, ataques completos, daño, turnos ni victoria.',
      ),
      const Text(
        'Funcionamiento local, sin login, telemetría ni acceso de red de la aplicación. Personajes, mapas e iconografía genéricos; no incluye el reglamento completo ni arte oficial. HeroClix y las marcas relacionadas pertenecen a sus titulares; aplicación independiente, sin afiliación oficial.',
      ),
      const Text(
        'Componentes: Flutter/Dart y material_ui. Sus avisos de licencia se incluyen localmente con la aplicación.',
      ),
      OutlinedButton.icon(
        key: const ValueKey('open-licenses'),
        onPressed: () => showLicensePage(
          context: context,
          applicationName: 'HeroClix Simulator & Trainer',
          applicationVersion: '${AppInfo.version}+${AppInfo.build}',
        ),
        icon: const Icon(Icons.description_outlined),
        label: const Text('Licencias de dependencias'),
      ),
    ],
  );
}
