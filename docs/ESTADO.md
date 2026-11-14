# Estado actual — etapa 02

2026-11-14 (America/Bogota). App **0.3.0+3**.
Repositorio: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama: `codex/prompt-02`, sobre la entrega 01 (`6618597`).

**02 implementada y verificada: análisis limpio, 77 pruebas, 8 renders, APK
debug firmado y recorrido parcial instalado en Android. Pendiente revisión del usuario.**
Informes anteriores: [ENTREGA_00.md](ENTREGA_00.md), [ENTREGA_01.md](ENTREGA_01.md).

## A. Operativo frente a preparado

- Herramienta Personajes: crear al tocar casilla vacía, seleccionar desde tablero
  o lista, ver/editar ficha, cambiar equipo, duplicar con nueva identidad y eliminar
  previa confirmación. Nombre, posición, base, velocidad y alcance configurables.
- Fichas A…Z, AA… con ID estable independiente de nombre/coordenada. Nombres iguales
  admitidos. Azul/T1 liso y Rojo/T2 rayado iniciales; crear equipos con código,
  nombre, paleta y patrón. Color nunca es el único identificador.
- Bases 1×1 y 2×2: ocupación completa, límites y colisiones validados centralmente.
  2×2 es representación de posición, no legalidad reglamentaria.
- Mantener pulsado y arrastrar: preview ✓/× más explicación. Destino válido se
  confirma al soltar; inválido/cancelación/segundo dedo deja la ocupación intacta.
  Movimiento por coordenada editable como alternativa accesible.
- Zoom, pan, giro y navegación al inicio preservan las figuras durante la sesión.
  Reducción de tablero rechazada si una base quedaría fuera; ampliación las conserva.
- Solo Seleccionar y Personajes activas. Los otros modos siguen deshabilitados.
  Deshacer, persistencia, terreno, muros y reglas son futuros.

## B. Archivos principales

- `lib/domain/characters/{character,team,character_repository}.dart`: modelos puros,
  huellas extensibles, colección inmutable e índice de ocupación.
- `lib/application/board/board_session.dart`: escenario local, equipos, identidad
  monotónica y operaciones atómicas.
- `lib/presentation/editor/character_dialog.dart`: ficha, duplicación, borrado y equipos.
- Canvas, painter, controller y Editor: gestos, preview, fichas y lista accesible.
- `test/characters_test.dart`, `test/character_editor_test.dart`, regresiones del Editor
  y `tool/preview_test.dart`. README, arquitectura, decisiones y roadmap actualizados.

## C. Verificación ejecutada

Entorno sin cambio: Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0; Android
minSdk 24, compile/target 36, JBR 25, Gradle 9.5.0, AGP 9.3.1 y Kotlin 2.4.20.
No se añadieron dependencias.

| Comando | Resultado real |
| --- | --- |
| `dart format lib test tool` | Correcto |
| `flutter --no-version-check analyze` | **No issues found**, 9,5 s |
| `flutter --no-version-check test --reporter expanded` | **77 pruebas aprobadas**, 32 s |
| `flutter --no-version-check test tool/preview_test.dart` | **8 renders aprobados**, 6 s; revisados visualmente |
| `flutter --no-version-check test test/character_editor_test.dart` | **16 aprobadas** tras el último ajuste de nombre Unicode |
| `flutter --no-version-check build apk --debug` | **Correcto**, build definitivo 79,6 s |
| `aapt dump badging` / `dump permissions` | Versión 0.3.0/código 3, SDK 24/36, sin INTERNET |
| `apksigner verify --verbose` | **Verifies**, firma debug APK v2 válida |
| `adb install -r --no-incremental` | **Success**, versión 0.3.0/código 3 instalada en Android 17/API 37 |
| Recorrido instalado en modo avión | Creación, equipos, arrastre válido/colisión, edición y duplicación comprobados |

Las 77 pruebas comprenden 23 de dominio/aplicación, 16 del inicio, 22 del Editor
anterior y 16 de interfaz de figuras. Incluyen colisiones completas, límites 2×2,
identidad, nombres repetidos, duplicación, liberación de origen, equipos, rechazo
atómico, redimensionamiento y conservación ante cámara/orientación/navegación.
Widgets: creación/edición, mensajes inválidos, duplicar/borrar, equipos, arrastre
válido/inválido/fuera, cancelar, segundo dedo y anclaje desde celda secundaria.
Formularios comprobados a 320×568, 800×360 y 320×320 con texto 100 % y 300 %.

Se corrigieron dos fallos encontrados en el recorrido de pruebas: aviso que tapaba
el botón de ficha y formularios con dropdowns desbordados o acciones inaccesibles
con texto grande. Las pruebas definitivas pasan después de esas correcciones.
La comprobación de actualizaciones del SDK intentó descargar etiquetas Git; se
canceló esa consulta y se utilizó `--no-version-check`, sin actualizar Flutter.

Evidencia local en `build/`: `test-02-final.log`, `analyze-02-final.log`,
`preview-02.log`, `character-test-02-final.log`, `build-02-final.log`; renders en `build/previews/prompt-02/`. Son renders Flutter,
no evidencia de instalación en Android. Las capturas reales del recorrido instalado
se conservan por separado en `build/verification/prompt-02/`.

APK definitivo: `build/releases/heroclix-prompt-02-debug.apk`, **182514718 bytes**
(**174,06 MiB**). SHA-256:
`C20C49E98DAA1890D8E22395E94D37663C3F9A3BD465A2AA95934290025FCB0C`.
También disponible en `build/app/outputs/flutter-apk/app-debug.apk`.
Los binarios y capturas se conservan locales, excluidos de Git.

### Recorrido Android realmente ejecutado

AVD Android 17/API 37, 540×1200, instancia temporal sin ventana, `-read-only` y
`-no-snapshot`. Modo avión confirmado en 1 y Wi-Fi en 0. Se instaló el APK definitivo.

- Crear A en A1 con Azul/T1 y B en C1 con Rojo/T2. Letras, códigos y patrones visibles.
- Arrastrar A desde A1 a B2: preview válida con ✓; el origen permanece ocupado hasta
  soltar y después queda libre. El pie muestra A en B2.
- Arrastrar A hacia C1: preview inválida con × y explicación «C1 está ocupada por la
  ficha B». Al soltar, A permanece en B2 y B en C1.
- Editar el nombre de A con teclado y guardar conserva su letra/posición. Duplicar
  crea la ficha C en A1 con el nombre editado, sin desplazar A ni B.
- Capturas reales revisadas: `dos_equipos.png`, `preview_valida.png`, `movida_B2.png`,
  `preview_invalida.png`, `colision_rechazada.png` y `duplicada_C.png`.

El arranque en frío demoró unos 197 s y Android mostró avisos de System UI y
Digital Wellbeing; se atendieron y se detuvieron servicios de fondo únicamente en
la instancia temporal. Son limitaciones del entorno y no se presentan como errores
de la aplicación. El emulador ya no estaba activo al retomar la conversación.
No se completó en el recorrido instalado la comprobación de base 2×2 ni el giro;
ambos casos sí pasaron en las pruebas de dominio/widgets descritas arriba.
No se afirma haber revisado un log final de crashes del proceso Android.

## D. Comprobación manual

1. Instalar el APK debug de 02 y abrir Editor sin conexión.
2. Personajes → A1 → nombre/equipo/velocidad/alcance → Guardar. Repetir en C1 con
   Rojo/T2. Confirmar fichas A/B y códigos/patrones distintos.
3. Tocar A, pulsar lápiz inferior, cambiar nombre/posición/equipo. Crear un equipo
   adicional. Guardar mantiene su etiqueta e ID.
4. Mantener A y arrastrar hacia una celda libre: preview ✓, soltar mueve. Hacia B:
   preview ×, soltar explica colisión y conserva origen. Tocar vacío con Seleccionar
   selecciona la casilla. La ficha también permite escribir una coordenada.
5. Duplicar desde ficha, elegir destino y guardar; aparece nueva letra. Eliminar
   la copia y confirmar. Revisar lista de figuras del icono superior.
6. Crear base 2×2: D4 se rechaza en tablero 4×4; C3 ocupa C3,D3,C4,D4. Revisar
   aviso de representación sin legalidad reglamentaria. Intentar superponer otra
   figura sobre cualquiera de sus cuatro casillas.
7. Zoom/pan, girar y volver al inicio/editor: las coordenadas no cambian. Reducir
   dimensiones con una base fuera se rechaza sin borrar figuras.

## E. Limitaciones y pendientes

- Sesión solo en memoria: cerrar el proceso pierde figuras/equipos. Guardar e
  historial/deshacer corresponden a 04. La eliminación actual exige confirmación.
- Velocidad/alcance 0–99 son anotaciones validadas; no se calculan ataques, rutas,
  alcance efectivo, visión ni legalidad de movimiento. Bases especiales se evaluarán
  en 08. No hay excepciones que permitan solapar figuras.
- Anclaje de bases rectangulares: esquina superior izquierda. UI ofrece solo 1×1/2×2.
- Crear un equipo es una operación explícita; permanece en la sesión aunque luego
  se cancele el formulario de figura. No se ofrece gestión/borrado de equipos existentes.
- En 40×40 se requiere ampliar para leer y tocar con precisión. Se pinta un único
  canvas; no se creó un widget por celda ni se incorporó un motor de reglas.
- No se probó un teléfono físico ni APK release firmado con clave del usuario.

## F. Documentación

ROADMAP, DECISIONES y este ESTADO actualizados; README y ARQUITECTURA describen
el uso y los límites reales. El informe 01 se archivó antes de sustituir el estado.
Las etapas anteriores y sus APK locales permanecen conservados.

## G. Límite de etapa

**No se inició Prompt 03.** La siguiente etapa requiere nueva orden del usuario.
