# Entrega archivada — ajustes del Editor rc.2

2026-11-17 (America/Bogota). **1.0.0-rc.2+15**, candidata debug.
Rama `codex/editor-quick-tools`, sobre `387a460` (entrega 12).
Informe anterior: [ENTREGA_12.md](ENTREGA_12.md). Modos Editor/Simulador/Árbitro siguen separados.

## A. Cambios operativos

1. Terrenos muestra Bloqueado, Obstaculizado y Despejado como tres iconos centrados
   al pie del mapa. Se elimina el desplegable de tipo. La selección tiene borde,
   check, tooltip y semántica; seleccionar no pinta ni registra una edición.
   Su franja está fuera del receptor de gestos y no tapa las casillas.
2. Alturas propone **nivel 2** sobre suelo. Al editar un nivel existente mayor que
   1 se conserva ese valor; se puede escribir 1 para volver a suelo. No se cambian
   alturas guardadas ni el nivel inicial de las casillas.
3. Personajes coloca inmediatamente en una casilla vacía con valores predeterminados:
   Figura, primer equipo, base 1×1, tamaño Normal, velocidad 6, alcance 4, sin mejoras.
   La ficha se abre después con el lápiz para editar. Colocación usa el comando de
   creación existente, con validación, selección, Deshacer/Rehacer y autoguardado.
   Sobre bloqueado se mantiene una confirmación de posición de estudio, sin formulario.
4. Al colocar se retira la ayuda transitoria que podía interceptar el lápiz inferior.
   En poco alto se usa barra lateral y controles de capa compactos, conservando
   objetivos táctiles ≥48 y ayudas accesibles. No se recorta la escala de texto.

## B. Archivos

- Nuevo `lib/presentation/editor/terrain_palette.dart`.
- BoardCanvas, EditorScreen y LayerToolbar: paleta, disposición compacta y colocación.
- ElevationControls: valor propuesto; AppInfo/pubspec: identidad de candidata/build.
- Nuevo `test/editor_quick_tools_test.dart` con seis pruebas; tests previos de creación,
  edición y terreno adaptados al nuevo flujo, conservando validaciones y casos de estudio.
- PreviewTest añade cinco renders y escribe en carpeta propia de esta actualización.
- README, README_FINAL, ARQUITECTURA, DECISIONES, ANDROID, ROADMAP y matriz de aceptación
  actualizados; el informe de 12 queda archivado.

## C. Verificación real

Mismo entorno: Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0; Android SDK 24/36.
Sin dependencias, permisos, reglas ni esquemas nuevos.

| Comando | Resultado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | **150 archivos, 0 cambios**, 1,47 s. |
| `flutter --no-version-check analyze --no-pub` | **No issues found**, 2,6 s. |
| `flutter --no-version-check test --no-pub test/editor_quick_tools_test.dart --reporter expanded` | **6 aprobadas**, 9 s. |
| `flutter --no-version-check test --no-pub --reporter expanded` | **444 aprobadas**, 168 s. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **78 renders aprobados**, 40 s. |
| `flutter --no-version-check build apk --debug --no-pub` | Correcto, Gradle 72,0 s. |
| `aapt dump badging` / `dump permissions` | 1.0.0-rc.2/código 15, SDK 24/36, sin INTERNET ni almacenamiento amplio. |
| `apksigner verify --verbose --print-certs` | Verifies; firma v2 válida, mismo certificado. |

Se conservan 438 pruebas y se añaden seis: paleta/elegir/pintar/ocultar sin ediciones
accidentales; varias figuras por defecto sin formulario, ficha/Deshacer/Rehacer;
altura inicial/existente/suelo; tamaños 360×800, 800×360 y 320×320 al 300 %.
Las pruebas previas conservan rectángulos, coordenadas, errores de base/ocupación,
confirmación de estudio, gestos, persistencia y motores de reglas.

La revisión detectó y corrigió interferencia de SnackBar sobre el lápiz y falta
inicial de espacio con texto al 300 %. También se corrigieron imports/helpers
nuevos de pruebas. No se desactivaron pruebas ni se silenciaron errores de hit test.
Los resultados finales ya incluyen esas correcciones.

Renders: `build/previews/editor-quick-tools/`, 73 anteriores y cinco nuevos:
quick_palette_portrait/landscape/compact, quick_character y quick_elevation.
Los cinco nuevos se revisaron visualmente. Logs en build/ y evidencia en
build/verification/editor-quick-tools/, fuera de Git. Capturas Flutter/Windows,
no de Android real. No se repite ni se afirma una prueba nativa.

### APK

- `build/releases/heroclix-1.0.0-rc.2-debug.apk`, **158513805 bytes** (151,17 MiB).
- SHA-256: `F4D5950EAF5FD145C80267AD2E37F4435DC6A004C57B72F18E555EC5CBE922E8`.
- Paquete `com.valinor.heroclixtrainer`, versión 1.0.0-rc.2, código 15.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Misma firma debug que versiones anteriores; copia archivada y salida estándar
  con hash idéntico. APK anteriores conservados, binarios excluidos de Git.

## D. Comprobación manual

1. Instalar el APK encima de la versión anterior, sin desinstalar para conservar datos.
2. Editor → Terrenos: elegir los tres iconos; solo tocar/arrastrar el mapa debe pintar.
   Probar rectángulo, Deshacer/Rehacer, giro y texto ampliado.
3. Alturas sobre suelo: comprobar que propone 2. Aplicar 3 y reabrir: conserva 3.
   Cambiar a 1 debe recuperar suelo.
4. Personajes: tocar varias casillas vacías. Debe colocar sin ficha. Seleccionar una
   y pulsar lápiz, cambiar nombre/valores: conserva identidad. Deshacer/Rehacer.
5. Colocar sobre bloqueado: cancelar conserva escenario; aceptar crea marca de estudio.
6. Esperar autoguardado, cerrar y reabrir; verificar posiciones y cambios guardados.

Recorrido Android pendiente. Se mantiene la decisión del usuario de continuar sin
teléfono; esta actualización no promueve 1.0.0 estable ni genera release con otra firma.

## E. Límites

Los perfiles de reglas y No evaluados siguen siendo los documentados de 06–12.
En pantallas pequeñas o texto muy grande la paleta usa iconos con tooltip/semántica,
sin nombres visibles para conservar espacio. El usuario puede editar los valores
predeterminados después de colocar. Las comprobaciones nativas, TalkBack, radios
apagadas y rendimiento Android siguen pendientes; no se suministraron claves release.

## F. Documentación

[README_FINAL](../README_FINAL.md) describe APK actual y uso; [MATRIZ_ACEPTACION](MATRIZ_ACEPTACION.md)
incorpora AC21 para estos ajustes. El informe original de 12 permanece en ENTREGA_12.md.
La actualización mantiene formatos y rutas de datos; no requiere migración.

## G. Alcance

Solo ajustes del Editor solicitados por el usuario. La futura unificación de los
tres modos no se ejecuta en esta actualización. Sin funciones de partida completa.
