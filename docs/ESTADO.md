# Estado actual — etapa 01

2026-11-14 (America/Bogota). App **0.2.0+2**.
Repositorio: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama: `codex/prompt-01`, desde la entrega 00 (`c5d3413`).

**01 implementada; análisis, 52 pruebas, 5 renders, build debug e interacción
en emulador Android verificados. Pendiente revisión del usuario. No se inició 02.**

El informe anterior se conserva en [ENTREGA_00.md](ENTREGA_00.md).

## A. Operativo frente a preparado

| Función | Estado real |
| --- | --- |
| Inicio y navegación al Editor | Operativos; los otros tres modos son futuros |
| Tablero 4×4 inicial | Operativo; 16 casillas cuadradas |
| Filas/columnas independientes 2–40 | Operativo; validación de vacío, enteros y límites |
| Coordenadas A1…AN40 | Operativas; índices cero-base y conversión bidireccional |
| Selección/deselección | Táctiles, con borde/marcador y coordenada visible |
| Zoom, pinza y pan | Operativos; gestos no producen selección accidental |
| Centrar y ajustar | Operativos, independientes de la selección |
| Cuadrícula/coordenadas y limpiar selección | Controles operativos |
| Cambiar tamaño con selección | Confirmación; cancelar conserva la sesión |
| Giro y vuelta al inicio | Conservan sesión; giro mantiene zoom y centro lógico |
| Herramientas | Solo Seleccionar activa; otras siete deshabilitadas |
| Capas futuras | Separación documentada; sin terreno, muros ni ocupantes |
| Guardado, historial, figuras y reglas | No implementados en 01 |

## B. Archivos principales

- `lib/domain/board/`: BoardDimensions, CellCoordinate, BoardGeometry,
  BoardCamera y ViewportSize, en Dart puro.
- `lib/application/board/board_session.dart`: estado central inmutable.
- `lib/presentation/editor/`: controlador de presentación, canvas, painter,
  herramientas, controles y diálogo de tamaño.
- `lib/app.dart`, catálogo y HomeScreen: ciclo de vida de sesión y acceso al Editor.
- Tests de dominio, sesión y Editor; inicio actualizado a un modo disponible.
- `tool/preview_test.dart`: capturas del inicio y tableros 8×12 y 40×40.

## C. Verificación ejecutada

Flutter **3.50.0**, Dart **3.14.0**, desde
`C:\Users\ValinorPC\develop\flutter\bin` o el PATH temporal documentado.
Android: minSdk **24**, compile/targetSdk **36**, NDK **28.2.13676358**,
AGP **9.3.1**, Gradle **9.5.0**, Kotlin **2.4.20**, JBR **25.0.4**.

| Comando | Resultado real |
| --- | --- |
| `flutter pub get` | Correcto; ninguna dependencia nueva |
| `dart format lib test tool` | Fuentes formateadas |
| `flutter analyze` | **No issues found** |
| `flutter test` | **52 pruebas aprobadas** |
| `flutter test tool/preview_test.dart` | **5 renders aprobados**, revisados visualmente |
| `flutter build apk --debug` | **Correcto**, build definitivo en **65,5 s**, tras comprobar teclado y área segura |
| `aapt dump badging` / `dump permissions` | 0.2.0, código 2, SDK 24/36; sin INTERNET |
| `apksigner verify --verbose` | **Verifies**, firma debug APK v2 válida |
| `adb install -r --no-incremental` | **Success**, APK definitivo instalado en Android 17 / API 37 |
| Recorrido Android en modo avión | Selección, zoom/pan, 8×12, giro, confirmación y 40×40 comprobados |

Las 52 pruebas son 14 de dominio/aplicación, 16 del inicio y 22 del Editor.
Incluyen 4×4=16, 8×12=96, 16×24=384 y 40×40=1600; etiquetas hasta AA1/AN40;
4800 conversiones con tres cámaras; bordes exactos; pan y pinza con dos punteros;
cancelación/confirmación de tamaño y conservación tras giro/navegación.
También se simula el teclado del formulario para comprobar que no altera
viewport, cámara ni selección del tablero situado debajo.

Editor y configuración se abren en 320×568, 800×360, 320×320, 568×320 y
1024×768 con texto ×1, ×2 y ×3, sin desbordes. El inicio conserva sus otros
15 casos de tamaño/escala. No se silencian toques fallidos ni errores.

### APK comprobado

- Salida estándar: `C:\Users\ValinorPC\Documents\ChatGPT\App de heroclix\build\app\outputs\flutter-apk\app-debug.apk`.
- Copia de entrega: `C:\Users\ValinorPC\Documents\ChatGPT\App de heroclix\build\releases\heroclix-prompt-01-debug.apk`.
- **182427264 bytes**, aproximadamente **173,98 MiB**.
- SHA-256: `563CE16BB898F3F284EE18EBDE81EB15F679EB4077AA99A19F855A4C544F74EF`.
- ID: `com.valinor.heroclixtrainer`, versión 0.2.0, código 2.
- ABI: arm64-v8a, armeabi-v7a y x86_64. Firma debug; no release final.
- APK de 00 conservado en `build/releases/heroclix-prompt-00-debug.apk`,
  contrastado con su hash histórico antes de sustituir la salida estándar.

Renders en `build/previews/`: inicio vertical/horizontal, editor 8×12 en ambas
orientaciones (D6) y editor 40×40 (AA20). No son capturas de teléfono.

### Ejecución Android comprobada

AVD **Medium Phone API 37.0**, Android **17 / API 37**, x86_64, emulador 37.2.13,
WHPX y GPU host NVIDIA. Framebuffer **540×1200**, densidad **210**. La imagen
exige 4096 MiB de RAM; se probaron sesiones temporales `-read-only`, sin guardar
snapshots ni cambiar la configuración persistente de la AVD. Se cerró al finalizar.

Comprobado sobre el APK definitivo:

- Arranque offline, entrada al Editor 4×4 y selección A1.
- Formulario con teclado numérico: los rótulos de las filas conservaron las
  mismas posiciones de píxel al abrir el teclado tras el ajuste de área segura.
- Cambio a 8 filas × 12 columnas, selección D6 y giro a horizontal conservando D6.
- Confirmación antes de perder D6; el tablero anterior permanece mientras se decide.
- Cambio confirmado a 40×40, selección AA20 y navegación con seis ampliaciones
  y arrastre sin perder la coordenada seleccionada.
- Volver al inicio y abrir de nuevo conserva 40×40, AA20 y la vista de cámara.
- Modo avión `1`, Wi-Fi deshabilitado; sin RenderFlex overflow, FATAL EXCEPTION
  ni Unhandled Exception en el log del proceso. El buffer de crashes estuvo vacío.

Las pruebas de pinza con dos punteros y todas las entradas inválidas se verificaron
automáticamente en widgets; no se presentan como una prueba de pinza en teléfono.
La imagen del emulador tuvo un arranque lento y ANR inicial de System UI antes del
recorrido. Se cerraron servicios de Google de esa sesión temporal y se continuó;
esto no es una medición de rendimiento en teléfono físico. El aviso esperado del
servicio VM local sin INTERNET sigue documentado en ANDROID.md.

Capturas reales revisadas en `build/verification/prompt-01/`: `final_4x4.png`,
`tablero_8x12.png`, `horizontal_8x12_D6.png`, `confirmacion.png`, `teclado.png`,
`tablero_40x40_AA20.png`, `zoom_40x40_AA20.png` y `sesion_conservada.png`.
Estos archivos de build se ignoran en Git.

## D. Procedimiento manual

1. Instalar este APK según ANDROID.md y abrir **Editor**.
2. Comprobar 4×4; tocar A1 y volver a tocarla para deseleccionar.
3. Crear 8 filas y 12 columnas; seleccionar una casilla. Intentar 40×40 y
   cancelar: tamaño y selección anteriores deben conservarse.
4. Confirmar el cambio: limpia selección y ajusta cámara, conservando opciones.
   Probar vacío, letras, 1 y 41 sin alterar el tablero.
5. Hacer pinza/arrastre sin seleccionar; usar −/+, centrar, ajustar y opciones.
6. Girar y volver al inicio/Editor: conserva tamaño y selección. Las otras
   herramientas no permiten colocar ni borrar elementos.
7. Activar modo avión y reiniciar el proceso: funciona offline y empieza en 4×4,
   porque todavía no existe persistencia.

## E. Límites y supuestos

- Bordes compartidos: derecha/abajo. Borde externo derecho/inferior excluido.
  Tolerancia de 1e-9 de casilla para redondeo de transformaciones.
- Escala 0,02–6 y 64 unidades por celda son convenciones de render, no medidas
  de HeroClix. Las coordenadas seleccionadas nunca son píxeles.
- La sesión dura mientras el proceso siga abierto. Guardado/historial son de 04.
- No hay personajes, equipos, terreno, muros, visión, distancias ni reglas en 01.
- Teléfono físico y recorrido de TalkBack pendientes. No se intentó release firmado.
- Sin permiso INTERNET: el servicio local VM de debug no puede abrir un socket;
  la app se instala/abre manualmente sin hot reload (ANDROID.md).

## F. Documentación

ROADMAP, DECISIONES, ARQUITECTURA, README y el módulo board describen 01.
ENTREGA_00 conserva el informe anterior. REGLAS conserva la fuente oficial;
esta etapa no implementó ninguna regla del juego.

## G. Siguiente etapa

Revisar 01 y autorizar expresamente 02 para figuras y equipos.
**No se avanzó al Prompt 02.**
