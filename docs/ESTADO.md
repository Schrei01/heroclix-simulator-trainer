# Estado actual — etapa 03

2026-11-14 (America/Bogota). App **0.4.0+4**.
Repositorio: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama: `codex/prompt-03`, sobre 02 (`36d704a`).
Informes previos: [00](ENTREGA_00.md), [01](ENTREGA_01.md), [02](ENTREGA_02.md).

**03 implementada y verificada: análisis limpio, 106 pruebas, 12 renders, APK debug
firmado y recorrido offline instalado en Android. Pendiente revisión del usuario.**

## A. Operativo y preparado

- Terreno despejado (implícito), obstaculizado y bloqueado. Toque, trazo interpolado
  y rectángulo con vista previa y Aplicar/Cancelar; coordenadas como alternativa.
- Muros solo sobre bordes internos. IDs normalizados sin duplicar el borde que
  comparten dos vecinas. Añadir/borrar por toque, trazo con orientación fija o par
  de coordenadas. Franja de toque explícita, sin confundir muro con celda bloqueada.
- Borrar elemento elige muro o figura; pintar despejado cambia el terreno.
  Tres limpiezas independientes con confirmación. Las otras capas se conservan.
- Bloqueado bajo figura: Cancelar o Conservar para estudio, sin eliminarla. Casillas
  incompatibles marcadas con ! y texto accesible. La ficha exige opción de estudio
  para crear/editar sobre bloqueado; arrastre normal rechaza ese destino.
- Leyenda con H/puntos, B/rayas y muro de línea doble, además del color. Figuras y
  equipos conservan sus códigos/patrones. Zoom, giro y navegación preservan capas.
- Previa fuera del escenario: cancelar/segundo dedo/cambio de herramienta o giro
  la descartan. Un trazo confirmado genera un solo comando, sin snapshots por píxel.
- Preparado: elevación 0–40 sin editor/análisis, BoardEdit reversible sin historial
  en UI y fragmento LayerCodec versionado en memoria. Ninguna función de guardado,
  importar/exportar o deshacer de 04 se presenta como operativa.

## B. Archivos principales

- `lib/domain/terrain/terrain.dart`, `edge_wall.dart`, `editing_geometry.dart`.
- `lib/application/board/board_session.dart`, `board_edit.dart`, `layer_draft.dart`,
  `layer_codec.dart`.
- `lib/presentation/editor/layer_toolbar.dart`, `layer_actions.dart`, canvas,
  painter, controlador, ficha y pantalla Editor.
- `test/terrain_test.dart`, `test/terrain_editor_test.dart`, regresiones y renders.
- README, ARQUITECTURA, ROADMAP, DECISIONES y este informe. Entrega 02 archivada.

## C. Comandos y resultados reales

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0. Sin dependencias nuevas.
Android minSdk 24, compile/target 36, NDK 28.2.13676358, AGP 9.3.1,
Gradle 9.5.0, Kotlin 2.4.20 y Android Studio JBR 25.

| Comando | Resultado |
| --- | --- |
| `dart format lib test tool` | 38 archivos, formato correcto |
| `flutter --no-version-check analyze --no-pub` | **No issues found**, 5,1 s |
| `flutter --no-version-check test --no-pub --reporter expanded` | **106 aprobadas**, 54 s |
| `flutter --no-version-check test tool/preview_test.dart --no-pub` | **12 renders aprobados**, 9 s; revisados visualmente |
| `flutter --no-version-check test test/terrain_test.dart --no-pub` | **12 aprobadas** tras revisar reproducción de comandos e IDs |
| `flutter --no-version-check build apk --debug` | **Correcto**, build definitivo 25,4 s |
| `aapt dump badging` / `dump permissions` | Versión 0.4.0/código 4, SDK 24/36, sin INTERNET |
| `apksigner verify --verbose` | **Verifies**, firma debug APK v2 válida |
| `adb install -r --no-incremental` | **Success**, APK definitivo instalado en Android 17/API 37 |
| Recorrido Android sin conexión | Terreno/figura, muro compartido, rectángulo, estudio, limpiar muros y giro comprobados |

106 pruebas: 35 de dominio/aplicación y 71 de widgets. Las 29 añadidas en 03
son 12 de terreno/edición/serialización y 17 de UI. Incluyen los 3.120 bordes internos
de 40×40, orden inverso de vecinas, no duplicación, límites externos, rectángulos,
trazos rápidos sin huecos, estudio explícito, independencia de capas, comandos
reversibles, memoria/fragmento JSON, datos corruptos, limpieza confirmada con zoom,
giro/navegación y alternativas por coordenadas.

Interfaz comprobada en 320×568, 800×360 y 320×320 con texto al 300 %, además de
las regresiones previas con tamaños y escalas 100/200/300 %. En viewport pequeño,
la previa se confirma mediante diálogo desplazable. Se mantiene fatal el aviso de
hit test en las pruebas: no se ignoran controles ocultos o inaccesibles.

Durante la implementación se corrigieron: orientación espuria en vértices por
redondeo, controles fuera del árbol por barra virtualizada, acciones de previa
inaccesibles en viewport mínimo, cierre de confirmación al girar y glifos ausentes
en los renders. Se comprobó además que reproducir comandos mantiene los contadores
de identidad para poder seguir creando figuras sin colisiones de ID. Las pruebas
finales pasan con las correcciones; no se atribuyen éxitos a las ejecuciones fallidas.

Logs locales: `build/test-03-final.log`, `preview-03-final.log`,
`analyze-03-final.log`, `terrain-test-03-final.log`, `build-03-verified.log`. Renders: `build/previews/prompt-03/`.
Son renders Flutter; no se presentan como capturas de dispositivo Android.

### APK definitivo

- Archivo local: `build/releases/heroclix-prompt-03-debug.apk`.
- Copia estándar: `build/app/outputs/flutter-apk/app-debug.apk`.
- Tamaño: **182617240 bytes (174,16 MiB)**.
- SHA-256: `2965192C35948BFE2C2EFA90577D94911C3D5A6239DCC0CDE1C3870AFA31F357`.
- Los APK y evidencias permanecen locales, excluidos de Git; 00/01/02 conservados.

### Recorrido Android ejecutado

AVD `Medium_Phone_API_37.0`, Android 17/API 37; 540×1200 y luego 1200×540.
Instancia temporal sin ventana, `-read-only` y `-no-snapshot`, GPU host. Modo avión
confirmado en **1** y Wi-Fi en **0** antes y después del recorrido.

- Crear figura A/T1 en A1. Aplicar obstaculizado a A1 por Coordenadas; la figura
  permanece en su casilla y conserva etiqueta/equipo.
- Añadir muro compartido A1/B1 por par de coordenadas. La línea doble se dibuja
  sobre el borde; no cambia la figura ni su terreno.
- Rellenar B2–D3: previa de seis celdas, todavía sin puntos de terreno; Aplicar
  transforma exactamente esas seis celdas en obstaculizado, conservando A1 y muro.
- Bloquear A1 ocupado: aparece Cancelar/Conservar para estudio; elegir Conservar
  mantiene la figura, añade ! y texto de estudio en selección/semántica.
- Limpiar solo muros con confirmación retira la línea compartida y conserva figura,
  bloqueado en A1 y las seis celdas obstaculizadas.
- Girar a horizontal y Ajustar: figura A en A1, advertencia y terreno conservados.

Capturas reales revisadas en `build/verification/prompt-03/`:
`obstaculizado_con_figura.png`, `muro_compartido.png`, `rectangulo_previa.png`,
`rectangulo_aplicado.png`, `advertencia_bloqueado.png`, `estudio_con_figura.png`,
`limpiar_solo_muros.png` y `girado.png`. El emulador se cerró al terminar.

El arranque frío demoró unos **195 s**. System UI mostró un aviso de lentitud,
atendido para continuar; UI Automator devolvió dos lecturas sin raíz que se
rechazaron y se repitieron sin usar estados obsoletos. Se detuvieron servicios de
fondo solo en la instancia temporal. No representa una medición de rendimiento en
un teléfono físico.

`app_android.log`, limitado al PID de la app, no contiene `FATAL EXCEPTION`,
`Unhandled Exception`, `RenderFlex` ni `E/flutter`. Sí registra que el servicio
HTTP de Dart VM debug no pudo abrir 127.0.0.1 por falta de permiso de red; la UI y
la edición funcionaron. También hay avisos de plataforma/intent de lanzamiento
por adb; no se da por verificado un APK release.

En Android se comprobó el flujo por coordenadas. Los trazos rápidos, cancelación,
bordes externos y las otras limpiezas fueron verificados por dominio/widgets;
no se afirma haber repetido todos esos casos en el emulador.

## D. Comprobar manualmente

1. Instalar el APK de 03 y abrir Editor sin conexión. Crear dos figuras de equipos
   diferentes y dejar una en B2.
2. Terrenos → Obstaculizado: tocar B2 y arrastrar A2…D2. La figura permanece en B2;
   el trazo no deja huecos. Probar Despejado sobre B2 sin borrar la figura.
3. Bloqueado → B2: cancelar conserva el estado; Conservar para estudio mantiene la
   figura con !. Quitar bloqueado elimina la advertencia derivada.
4. Rellenar rectángulo → A1…C3: revisar previa y cancelar; repetir y aplicar.
   Repetir con Coordenadas (inicio/fin) y cancelar la confirmación.
5. Muros: tocar el borde entre A1/B1 y volver a añadirlo; hay un solo muro.
   Trazo vertical y horizontal; Borrar muro no afecta terreno ni figuras.
   Un borde externo muestra explicación sin modificar el mapa.
6. Borrar elemento → figura: confirmar y comprobar que terreno/muros permanecen.
   Probar el selector de muro. Despejado es una acción diferente de Borrar elemento.
7. Menú superior → Limpiar solo terreno/muros/figuras: cancelar primero y luego
   confirmar una de ellas. Solo cambia la capa indicada, incluso tras ampliar.
8. Girar y navegar al inicio/editor: figuras, terreno y muros conservan sus
   coordenadas. Dos dedos cancelan un trazo y navegan sin pintar.

## E. Limitaciones, supuestos y pendientes

- Solo sesión en memoria; cerrar proceso pierde escenario. Sin historial/deshacer,
  archivos, importación/exportación ni biblioteca de escenarios. Corresponden a 04.
- LayerCodec es un fragmento, layerSchemaVersion 1, sin I/O; no define aún el esquema
  de documento completo. Altura 0–40 es un límite de producto preparado, no una regla.
- Solo muros internos unitarios. Trazo conserva orientación del primer borde;
  cambiar de vertical a horizontal requiere otro trazo. Paso exacto por vértice
  no pinta celdas cuyo interior no se atraviesa.
- Compatibilidad figura/bloqueado es una política de representación para estudio.
  No se evalúan visión, movimiento, ataques, elevación ni reglas de bases especiales.
  No se admite solapar figuras. 2×2 sigue siendo representación de posición.
- BoardEdit conserva referencias inmutables por operación terminada; solo se retiene
  el último comando. Revertir rechaza capas/dimensiones ajenas y no restaura cámara
  ni recicla IDs; aún no existe una política de historial de usuario.
- Con mapas grandes es necesario ampliar; barra de capa desplazable horizontalmente.
  Reducir se rechaza si eliminaría terreno o convertiría un muro en borde externo.
- No se probó teléfono físico ni APK release firmado con una clave del usuario.

## F. Documentación

ROADMAP, DECISIONES y ESTADO actualizados. README explica uso, política de estudio
y límites; ARQUITECTURA distingue capas, previa y comandos/fragmento preparados.
Las entregas previas y sus APK locales permanecen conservados.

## G. Límite de etapa

**No se inició Prompt 04.** Se requiere nueva orden después de revisar esta entrega.
