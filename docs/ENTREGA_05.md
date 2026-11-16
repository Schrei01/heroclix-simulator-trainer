# Entrega archivada — etapa 05

2026-11-14 (America/Bogota). App **0.6.0+6**.
Repositorio: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama: `codex/prompt-05`, sobre etapa 04 (`1788e21`).
Informes archivados: [00](ENTREGA_00.md), [01](ENTREGA_01.md),
[02](ENTREGA_02.md), [03](ENTREGA_03.md), [04](ENTREGA_04.md).

**05 implementada: 168 pruebas, 13 contratos Dart puros, análisis limpio y APK
debug generado. Recorrido Android realizado; revisión del usuario pendiente.**

## A. Operativo y preparado

- Motor Dart puro de segmento centro-a-centro con fracciones exactas: Inicio,
  intervalos dentro de casillas, cruce de interior de borde, paso por vértice y Fin.
  Punto fijo explícito si coinciden extremos; inválidos reportados sin recortar.
- Contactos con muros diferenciados por interior o extremo de borde. En vértice
  se identifican los cuatro bordes incidentes y las dos celdas solo de esquina,
  separadas de las que tienen paso interior. Sin dictamen reglamentario.
- Herramienta Línea de visión · Geometría en Editor. Toques y formulario de casilla
  o figura, referencia explícita para 2×2, invertir/limpiar e inspector de todos los
  eventos ordenados, parámetros y coordenadas exactas.
- Superposiciones independientes de segmento/extremos O/D, casillas y contactos.
  Colores y formas distintos para borde/vértice; marcas sin relleno para esquina.
- Seguir figura al mover y recalcular al cambiar dimensiones/personajes/muros.
  Borrado o referencia inválida retira la trayectoria anterior y muestra motivo;
  undo puede recuperarla. Zoom/giro/selección no cambian el resultado geométrico.
- Preparado: hasta 16 candidatas explícitas con IDs únicos. No se genera un conjunto
  completo de referencias para bases ni se elige una trayectoria reglamentaria.
  Simulador, Árbitro y Entrenador siguen futuros. No se implementa Prompt 06.

## B. Archivos principales

- `lib/domain/geometry/exact_fraction.dart`, `sight_geometry.dart`.
- `lib/application/board/sight_probe.dart`, BoardSession/EditorController.
- `lib/presentation/editor/sight_controls.dart`, `sight_painter.dart`, canvas/pantalla.
- `test/geometry_test.dart`, `sight_probe_test.dart`, `sight_editor_test.dart` y
  `test/support/geometry_contract.dart` compartido con `tool/verify_geometry.dart`.
- `tool/preview_test.dart`, pubspec, README, GEOMETRIA, ARQUITECTURA, REGLAS,
  DECISIONES, ROADMAP y este informe. Entrega 04 archivada.

## C. Comandos y resultados reales

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0; sin dependencias nuevas.
Android minSdk 24, compile/target 36, NDK 28.2.13676358, AGP 9.3.1,
Gradle 9.5.0, Kotlin 2.4.20 y Android Studio JBR 25.

| Comando | Resultado |
| --- | --- |
| `dart format lib test tool` | Formato correcto |
| `dart run tool/verify_geometry.dart` | **13/13 contratos aprobados**, ejecución Dart puro, sin Flutter/UI |
| `flutter --no-version-check analyze --no-pub` | **No issues found**, 67,5 s |
| `flutter --no-version-check test --no-pub --reporter expanded` | **168 aprobadas**, 84 s |
| `flutter --no-version-check test test/sight_editor_test.dart --no-pub --reporter expanded` | **8 aprobadas**, 11 s, tras corregir barra de estado |
| `flutter --no-version-check test tool/preview_test.dart --no-pub` | **22 renders aprobados**, 16 s; seis vistas nuevas revisadas visualmente |
| `flutter --no-version-check build apk --debug --no-pub` | **Correcto**, build definitivo 55,2 s |
| `aapt dump badging` / `dump permissions` | 0.6.0/código 6, SDK 24/36, sin INTERNET ni permisos amplios de almacenamiento |
| `apksigner verify --verbose` | **Verifies**, firma debug APK v2 válida |

Las 29 nuevas pruebas son 13 contratos de geometría, 8 de integración del probe y
8 de widgets. Incluyen todas las pruebas obligatorias de 05, todos los 256 pares
orientados de 4×4 con muros para simetría y todos los 2.916 pares de 6×9 frente a
un oráculo independiente de recorte de interiores de cajas. El runner Dart usa
los mismos contratos y falla con código de salida distinto de cero ante un error.

También se verificó que elegir extremos, invertir y ocultar no modifica documento,
revisión de autoguardado ni historial; seguimiento de base 2×2, borrado y undo,
cambio de huella/dimensiones, muro y undo, casilla fija y reinicio al cargar.
UI en 320×568, 800×360 y 320×320 con texto al 300 %, además de regresiones de 04.

Se corrigió un botón demasiado ancho con texto al 300 % mediante límite de ancho
y elipsis. En barra lateral pequeña, la prueba desplaza la lista antes de elegir
herramienta, reproduciendo el acceso de usuario. No se desactivó hitTestWarning.
Revisión visual detectó glifos ausentes en rótulos O/D y flechas: se fijó la fuente
y se usó texto sin flechas. Los resultados finales incluyen esas correcciones.

Logs locales: `build/geometry-pure-05-final.log`, `analyze-05-final.log`,
`test-05-final.log`, `sight-ui-05-verified.log`, `preview-05-final.log`,
`build-05-final.log`. Renders Flutter: `build/previews/prompt-05/`.

### APK definitivo

- Local: `build/releases/heroclix-prompt-05-debug.apk`.
- Salida estándar: `build/app/outputs/flutter-apk/app-debug.apk`.
- Tamaño: **158139705 bytes (150,81 MiB)**.
- SHA-256: `C52CC5FBAEF8F5C4620F2C5B5803463989E9378E1D439655D85F0CA0E4084EC7`.
- APK/evidencias excluidos de Git; se conservan entregas anteriores.

### Recorrido Android ejecutado

AVD Medium_Phone_API_37.0, Android 17/API 37, instancia temporal sin ventana,
read-only y sin snapshots. Instalación `adb install -r --no-incremental`:
**Success**. Modo avión **1** y Wi-Fi **0** confirmados durante la prueba y al final.

- Crear figura A/T1 en A1; Línea de visión · Geometría; tocar A1 y D4.
  La línea y extremos O/D se dibujan; inspector: **4 tramos / 3 contactos**,
  primer vértice t=1/6 en (1,1), cuatro extremos de borde y solo esquina A2/B1.
- Ocultar Segmento y extremos: desaparece línea/O/D y permanecen casillas y
  contactos, sin alterar figura ni referencias.
- Volver a Seleccionar y mover figura desde su ficha de A1 a B1. Inspector:
  origen figura A/ref B1, destino fijo D4, **6 tramos / 5 contactos**; inicio
  (3/2,1/2), primer cruce t=1/6 en (11/6,1), interior de h:1:1.
- Reactivar segmento y cambiar viewport con `wm size 1200x540`, Ajustar. Misma
  trayectoria B1–D4 y seis tramos, herramientas a la izquierda. Es cambio de
  disposición del emulador; no se afirma rotación de un teléfono físico.
- Se cerró el emulador al terminar. Escenarios, archivos y configuración de AVD
  del usuario no se modificaron de forma persistente.

La captura horizontal mostró que el aviso flotante tapaba parte de la última fila.
Se corrigió moviendo el estado a la barra de cámara, fuera del canvas. El ajuste
se verificó después con los 8 tests UI, incluida una comprobación que exige que
el estado quede debajo del viewport, y los 22 renders. El recorrido Android
anterior corresponde a la compilación de 05 previa a ese último ajuste de barra;
no se repitió el recorrido nativo con el APK final reconstruido.
La compilación instalada durante el recorrido corresponde a `0545726`; el ajuste
de barra está en `140a82a`. Ambos cambios quedan separados para revisión.

Evidencias locales en `build/verification/prompt-05/`: `diagonal.png`,
`inspector_diagonal.png`, `sin_segmento.png`, `figura_movida.png`, `horizontal.png`,
`app_android.log`, `android_system.log` y logs del emulador. Son capturas Android;
los renders finales de la barra corregida están en `build/previews/prompt-05/`.

Arranque frío del guest: **252 s**, host de 8 GiB. Hubo repetidos avisos
«Process system isn't responding», atendidos con Wait; los logs registran ANR
en servicios Google/Wellbeing. La prueba solo continuó al recuperar respuesta.
También se produjo un fallo de UI Automator por capturas solapadas; se corrigió
secuenciando las lecturas y descartando estados fallidos. No es una medición de
rendimiento en un teléfono físico.

El log del PID de la app no contiene FATAL EXCEPTION, Unhandled Exception,
RenderFlex ni E/flutter; aparece el SocketException conocido del servicio HTTP
Dart VM debug en 127.0.0.1 por ausencia deliberada de INTERNET. La excepción fatal
del log de sistema corresponde al proceso de UI Automator, no al de la app.
Casos de muro, 2×2, borrado/undo, límites e inválidos se verificaron con contratos,
aplicación y widgets; no se afirma haber repetido todos ellos en Android.

## D. Comprobar manualmente

1. Instalar APK, abrir Editor sin conexión y elegir Línea de visión · Geometría
   en la barra desplazable. Tocar A1 y D4: cuatro interiores y tres vértices.
2. Inspeccionar geometría: revisar t=1/6, 1/2 y 5/6, puntos (1,1), (2,2), (3,3),
   y las casillas solo de esquina. Ocultar cada superposición y volver a activarla.
3. Coordenadas / figuras: probar A1→D3 y el mismo origen/destino. Una casilla fuera
   del tablero debe mostrar error y conservar la trayectoria anterior válida.
4. Crear muro entre A1/B1. A1→C1 lo cruza por interior; A1→D4 toca su extremo en
   un vértice. El inspector distingue ambos sin afirmar efecto reglamentario.
5. Elegir una figura de origen y moverla desde su ficha. Trayectoria actualizada.
   Borrarla retira resultado; deshacer lo recupera. Una casilla fija no la sigue.
6. Base 2×2: tocar cualquiera de sus casillas, elegir referencia, cancelar primero
   y luego aceptar. Formulario también permite elegir las cuatro referencias.
7. Cambiar zoom, girar y Ajustar: mismos eventos/coordenadas. Probar mapa 40×40;
   ampliar para leer. Dos dedos navegan sin elegir otro extremo.
8. Guardar escenario conserva inspección en memoria; abrir/nuevo/importar/guardar
   como limpia extremos. JSON y PNG mantienen formato de 04 sin overlay transitorio.

## E. Limitaciones, supuestos y pendientes

- Solo geometría: no hay veredictos de visión, legalidad de ataque, alcance,
  movimiento, elevación o excepciones de poderes. Motor de reglas corresponde a 06.
- Una referencia por extremo de base múltiple; evaluación completa reservada a 08.
  Candidatas son datos explícitos, sin generación automática ni elección de ganadora.
- La trayectoria va entre centros, así que no existe un tramo colineal con una
  recta de cuadrícula. Ese problema general no pertenece al contrato actual.
- Inspección transitoria: no se guarda en JSON/autoguardado ni se incluye en PNG.
  Cargar otro documento o reiniciar elimina extremos; no afecta mundo guardado.
- Las marcas se proyectan con doubles solo al dibujar. En mapa grande conviene
  ampliar/Ajustar; la exactitud del motor no depende de legibilidad de los píxeles.
- Historial y límites de persistencia de 04 se mantienen. La caché de geometría
  no retiene resultados de otra escena tras cargarla.
- No se probó teléfono físico ni APK release firmado con clave del usuario.
- El último ajuste visual de estado fuera del tablero se verificó en widgets y
  renders después del recorrido Android; no se reinstaló el APK final en el guest.

## F. Documentación

ROADMAP, DECISIONES y ESTADO actualizados. GEOMETRIA define contrato matemático,
precisión y ejemplos; README explica uso, ARQUITECTURA separación y REGLAS deja
explícito que no se ha añadido interpretación reglamentaria. Entrega 04 archivada.

## G. Límite de etapa

**No se inició Prompt 06.** Requiere una nueva orden tras revisar esta entrega.
