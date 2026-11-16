# Entrega histórica — etapa 00

Informe archivado antes de iniciar 01. Las rutas de capturas son las originales
de esa entrega y pueden regenerarse desde el commit `c5d3413`; el estado actual
está en ESTADO.md. El APK histórico se conserva en la ruta de archivo indicada.

Actualizado: 2026-11-14 (America/Bogota). Versión de app: `0.1.0+1`.

**Base de 00 implementada; APK debug, instalación y arranque en emulador Android verificados. Pendiente revisión del usuario.**
No se ha iniciado la etapa 01.

## Operativo y preparado

| Elemento | Estado |
| --- | --- |
| Arranque Flutter e inicio en español | Probado en widgets y emulador Android 17 |
| Tema original y disposición adaptable | Probado en widgets y emulador vertical/horizontal |
| Editor, Simulador, Entrenador y Árbitro | Tarjetas futuras, deshabilitadas y sin rutas |
| Semántica de accesibilidad | Estado deshabilitado comprobado automáticamente |
| Contrato de identificadores de modos | Dart puro, probado |
| Módulos board/characters/terrain/geometry/rules/movement/training | Carpetas de arquitectura documentadas; sin funcionalidad |
| Persistencia local | Solo interfaz LocalDocumentStore, sin adaptador |
| Proyecto Android, nombre, icono original y firma configurable | Compilación debug verificada; firma debug válida |
| Red, usuarios y servicios externos | No implementados; sin permisos de red en manifiestos |
| Tablero y reglas del juego | No implementados, según alcance de 00 |

## Entorno encontrado y preparado

- Windows 10 Home x64 22H2, compilación 19045.6466.
- Repositorio inicialmente vacío, rama master sin commits. Se conserva la raíz.
- Flutter y Dart no estaban instalados en las rutas comprobadas ni en PATH.
- Se descargó Flutter stable en
  `C:\Users\ValinorPC\develop\flutter`, fuera del repositorio.
- Flutter **3.50.0**, revisión `ab2912035e160d9cad6306df307576da6128ebdb`.
- Dart **3.14.0**; DevTools **2.61.0**; analytics de la CLI deshabilitadas.
- Java inicial: Oracle JDK **21.0.12.1**. Tras instalar Android Studio, Flutter
  selecciona su JBR **OpenJDK 25.0.4**, usado en la compilación Gradle correcta.
- No se cambió el PATH global: README explica cómo habilitarlo por terminal.
- Android SDK y adb estaban ausentes en la primera entrega. En la reevaluación
  del 2026-11-13 ya están instalados en
  `C:\Users\ValinorPC\AppData\Local\Android\Sdk`.
- Instalados y comprobados: Command-line Tools, plataforma API 36, Build Tools
  **36.0.0**, Platform Tools y NDK **28.2.13676358**, la versión que usa el
  proyecto. También están presentes API 37 y NDK 30; no sustituyen los valores
  declarados por esta aplicación.
- `flutter doctor -v` termina con **No issues found** y confirma todas las
  licencias aceptadas. Se ejecutaron correctamente `aapt2 version` y el `clang`
  del NDK requerido. Se inició un emulador temporal para las pruebas y se cerró
  al completarlas. No hay un teléfono físico conectado.
- Flutter detectó Windows, Chrome y Edge; no se añadieron esas plataformas al
  proyecto ni se presentan como prueba de ejecución Android.

Valores de la plantilla de Flutter instalada, heredados por Gradle:
`minSdk=24`, `targetSdk=36`, `compileSdk=36`, `ndkVersion=28.2.13676358`.
Android Gradle Plugin `9.3.1`, Kotlin `2.4.20`, wrapper Gradle `9.5.0`.
Compilación debug completada el 2026-11-14 con esos valores.

Dependencias directas de producción: Flutter y `material_ui 1.11.0` oficial.
`cupertino_ui 1.1.6` y localizaciones del SDK llegan transitivamente por Material.
Herramientas de pruebas: flutter_test y flutter_lints 6.0.0. El lockfile versionado
conserva la resolución. No se forzaron actualizaciones de dependencias que el SDK
mantiene restringidas.

## Comandos ejecutados y resultados

Se invocó Flutter por su ruta absoluta y con `--no-version-check`. Los siguientes
comandos abreviados son equivalentes al habilitar el PATH como indica README.

| Comando | Resultado real |
| --- | --- |
| `flutter --version` | Flutter 3.50.0 y Dart 3.14.0 confirmados |
| `flutter --disable-analytics --no-version-check` | Analytics deshabilitadas |
| `flutter create --no-pub --platforms=android --org=com.valinor --project-name=heroclix_simulator_trainer --android-language=kotlin .` | Proyecto Android generado conservando archivos existentes |
| `flutter pub get` | Correcto; dependencias resueltas y lockfile actualizado |
| `dart format lib test tool` | Ejecutado, fuentes formateadas |
| `dart format --output=none --set-exit-if-changed lib test tool` | Correcto; 10 archivos sin cambios |
| `flutter analyze` | Repetido el 2026-11-14: correcto; No issues found |
| `flutter test` | Repetido el 2026-11-14: **18 pruebas aprobadas** |
| `flutter test tool/preview_test.dart` | **2 renders de revisión aprobados** |
| `flutter doctor -v` | Reevaluación: **No issues found**, todas las licencias Android aceptadas |
| `flutter devices` | Sin Android; solo Windows, Chrome y Edge |
| `flutter build apk --debug` (primer intento, antes de instalar SDK) | **Falló, código 1:** `[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.` |
| `flutter build apk --debug` (reevaluación con SDK completo) | Se inició assembleDebug, pero se interrumpió durante la descarga inicial de Gradle, antes de compilar la app |
| Descarga de Gradle 9.5.0 mediante curl desde la distribución oficial | Timeout de 240 segundos; recibidos 176897401 de 240667887 bytes. Archivo parcial sin instalar ni dar por verificado |
| Reanudación de Gradle (2026-11-14) | Descarga completada; 240667887 bytes; SHA-256 coincide con el oficial |
| `flutter pub get` (2026-11-14) | Correcto; acceso a pub.dev recuperado sin cambiar DNS del sistema |
| `flutter build apk --debug` (2026-11-14) | **Correcto**, assembleDebug completado en 669,9 segundos |
| `aapt dump badging` y `aapt dump permissions` | minSdk 24, target/compileSdk 36, tres ABI; APK sin permiso INTERNET |
| `apksigner verify --verbose` | **Verifies**, firma APK v2 válida, un firmante debug |
| `adb -s emulator-5554 install -r --no-incremental .../app-debug.apk` | **Success**, instalación real en Android 17 / API 37 |
| Inicio, giro, desplazamiento y reinicio sin conectividad | Comprobados visualmente en el emulador; app en ejecución, sin crash registrado |

Las 18 pruebas incluyen dos contratos de dominio, arranque/idioma/tarjetas
deshabilitadas y 15 combinaciones: 320×568, 360×800, 800×360, 568×320 y
1024×768, con escalas de texto 1, 2 y 3. Se recorre el contenido para comprobar
que las tarjetas siguen accesibles y no aparecen desbordes.

La primera ejecución detectó APIs de Material obsoletas y un recurso de semántica
sin liberar en una prueba. Se migró a Material oficial independiente y se corrigió
la limpieza de la prueba; se repitieron análisis y tests hasta aprobarlos, sin
desactivar comprobaciones.

Comprobaciones adicionales realizadas: nueve XML Android parseados; dominio y
aplicación sin imports de Flutter, Material, dart:ui ni dart:io; código de app sin
clientes ni URLs de red; manifiestos sin permisos de red ni bloqueo de orientación;
Git ignora key.properties, keystores y claves privadas.

## Capturas

Renders generados por Flutter Test, **no por un dispositivo Android**:

- `build/previews/inicio_vertical.png`, 400×900, contenido desplazable.
- `build/previews/inicio_horizontal.png`, 1000×700.

Son archivos locales de build ignorados por Git. Para regenerarlos:
`flutter test tool/preview_test.dart`. La revisión carga fuentes e iconos locales
del SDK; no descarga assets en runtime de la aplicación.

## Lo que no se verificó

- Instalación y comportamiento en un teléfono físico y en otras versiones Android.
- Recorrido completo con TalkBack y escalas de texto en Android real. Las escalas
  1–3 sí están cubiertas por las pruebas de widgets.
- Firma release: no hay keystore ni credenciales, y no se intentó un release.

## APK debug verificado — 2026-11-14

- Ruta: `C:\Users\ValinorPC\Documents\ChatGPT\App de heroclix\build\releases\heroclix-prompt-00-debug.apk`.
- Tamaño comprobado: **157880735 bytes (150,57 MiB)**.
- SHA-256: `824A42ECE51C9E438CE41113B3C8CB2778966E43D17B8E9658F78067B73EEDF0`.
- Identidad: `com.valinor.heroclixtrainer`, versión `0.1.0`, código `1`.
- ABI: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- minSdk **24**, targetSdk y compileSdk **36**, confirmados en el APK.
- Firma **debug** válida; no es un release firmado para distribución final.
- Manifiesto fusionado sin permiso INTERNET. Solo solicita el permiso privado
  de receptores no exportados generado por AndroidX.

El fallo temporal de resolución de pub.dev ya no se reproduce. Se reanudó la
descarga parcial de Gradle, se comparó su SHA-256 con el publicado oficialmente
y se completó la compilación sin cambiar versiones del SDK o dependencias.
SHA-256 de la distribución Gradle 9.5.0 all:
`A3C4BA4ACA8F0075688B9C5B18939FD28E8CB4357C227DA5C1D9F38343791439`.

En el equipo se detectaron 8 GiB de RAM. La configuración de Gradle se ajustó
a heap máximo 2 GiB, metaspace 768 MiB, caché de código 256 MiB y dos workers,
en lugar de los límites de 8/4 GiB de la plantilla. El build pasó con estos límites.

## Verificación de ejecución Android — 2026-11-14

- AVD: **Medium Phone API 37.0**, imagen Google APIs / Play Store x86_64.
- Emulador **37.2.13**, Android **17**, API **37**, aceleración WHPX.
- Se inició sin ventana, sin snapshots y en modo `-read-only`, sin modificar
  permanentemente los datos de la AVD del usuario. Se cerró al finalizar.
- Instalación del APK: **Success**. Identidad y actividad corresponden al APK
  inspeccionado, y la pantalla inicial en español se renderizó correctamente.
- Se comprobó el giro vertical/horizontal y el desplazamiento para llegar a las
  cuatro tarjetas. Todas muestran «Próximamente». No se habilitaron modos nuevos.
- Se activó modo avión (`airplane_mode_on=1`), se deshabilitaron Wi-Fi y datos,
  se cerró la app y se abrió de nuevo. El inicio y las tarjetas siguieron visibles.
- El buffer de crashes estuvo vacío; en el log del proceso de la app no se
  encontraron `FATAL EXCEPTION`, `Unhandled Exception` ni `RenderFlex overflow`.

El arranque del emulador fue lento y aparecieron ANR de Pixel Launcher y System
UI, ajenos al proceso de esta app. El host llegó a disponer de menos de 500 MiB
de memoria física libre. Se redujo la resolución a **540×1200, densidad 210**,
se desactivaron animaciones y se detuvieron servicios de Google del emulador
temporal para completar la comprobación. No se cambiaron esos ajustes en el
Windows del usuario ni en una AVD persistente. No se extrapolan tiempos de
arranque o rendimiento de este entorno a teléfonos reales.

En debug aparece el mensaje de que no se puede iniciar el servicio HTTP local
de la VM Dart porque el APK no solicita INTERNET. Es la limitación de depuración
documentada en ANDROID.md: la pantalla funciona y se comprobó sin hot reload.
No se agregó permiso de red para ocultar este aviso.

Capturas reales del emulador, guardadas localmente y revisadas:

- `build/verification/inicio_android_vertical.png`.
- `build/verification/inicio_android_horizontal.png`.
- `build/verification/inicio_android_offline.png`.
- `build/verification/modos_android_offline.png`.

Los archivos de verificación de build se ignoran en Git. Son distintos de los
renders de Flutter Test descritos arriba.

## Procedimiento y siguiente paso

El código, las pruebas y esta documentación están versionados para el repositorio
privado https://github.com/Schrei01/heroclix-simulator-trainer, rama `main`.
Los artefactos de build y credenciales siguen excluidos por `.gitignore`.

SDK, licencias, Gradle y APK debug ya están listos; el recorrido básico en
emulador también está verificado. Para probar en un teléfono, seguir
docs/ANDROID.md y registrar modelo, versión Android y resultados reales aquí.

Tras revisar esta entrega, la siguiente orden podrá autorizar el Prompt 01.
**No se avanzó a esa etapa.**
