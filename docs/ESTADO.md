# Estado actual — etapa 07

2026-11-16 (America/Bogota). App **0.8.0+9**.
Repositorio privado: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama: `codex/prompt-07`, sobre 06 corregida (`9697fc9`).
Informes de 06: [inicial](ENTREGA_06.md), [corrección 0.7.1](ENTREGA_06_FIX.md).

## A. Operativo y preparado

- Medir distancia entre dos casillas, incluidas vacías: horizontal, vertical,
  diagonal, oblicua y origen igual a destino. Cuenta en ocho direcciones con
  cero en origen, §11.3a; diferencias de filas/columnas opcionales en el informe.
- Elegir figura de origen desde selección o lista. Mostrar las demás figuras con
  filtro inicial Enemigas y opciones Aliadas/Todas, sin inferir permisos de ataque.
- Distancia, alcance declarado y visión independientes. Categorías: en alcance
  con visión despejada, en alcance con visión obstaculizada, visión bloqueada,
  fuera de alcance y No evaluado. Se conserva una visión bloqueada aunque el
  encabezado de lista indique fuera de alcance.
- Seleccionar una fila resalta objetivo y línea, anota distancia/alcance y permite
  abrir explicación, referencias y dimensiones pendientes. Se reutiliza el motor
  de visión de 06, incluida la corrección A1–D6/B4 de 0.7.1.
- Editar alcance 0–99 desde la lista o ficha; actualización de todos los objetivos,
  persistencia existente y deshacer/rehacer. No interpreta modificadores de cartas.
- Herramientas disponibles en Editor y mediante Elegir análisis en Simulador y
  Árbitro. Sus tableros permiten navegar/elegir, sin mover piezas al tocar.
- Caché de visión acotada al mundo/contexto y 256 pares. Cámara/filtro/selección no
  recalculan visión; rango/nombre reutilizan obstáculos y actualizan comparación.
- Preparadas entradas tipadas para extender capacidades; no se implementa 08.
  Consulta, filtro y superposiciones transitorios. JSON conserva esquema 1.

## B. Archivos principales

- `lib/domain/rules/distance_service.dart`, `target_analysis_service.dart`.
- `lib/application/board/tactical_analysis.dart`; adaptación de EditorController.
- `lib/presentation/vision/tactical_controls.dart`; cambios de VisionScreen,
  BoardCanvas, SightPainter, EditorScreen, catálogo visual de Inicio y herramientas.
- `test/support/target_contract.dart`, `target_rules_test.dart`,
  `target_state_test.dart`, `target_editor_test.dart`; expectativas anteriores de
  disponibilidad de herramientas/título de Simulador actualizadas.
- `tool/verify_targets.dart`, `benchmark_targets.dart`, nuevos renders en preview_test.
- Pubspec 0.8.0+9, README, ARQUITECTURA, REGLAS, ANDROID, ROADMAP, DECISIONES,
  MATRIZ_DISTANCIAS_OBJETIVOS, este informe y archivo histórico de 06 corregida.

## C. Comandos y resultados reales

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0. Sin dependencias nuevas.
Android minSdk 24, compile/target 36. Se conserva la configuración de 06.

| Comando | Resultado |
| --- | --- |
| `dart run tool/verify_targets.dart` | **13/13 contratos aprobados** en Dart puro. |
| `dart format --output=none --set-exit-if-changed lib test tool` | **85 archivos, 0 cambios**, 0,65 s. |
| `flutter --no-version-check analyze --no-pub` | **No issues found**, 5,6 s. |
| `flutter --no-version-check test --no-pub --reporter expanded` | **238 aprobadas**, 96 s. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **37 renders aprobados**, 26 s; seis nuevos revisados visualmente. |
| `flutter --no-version-check build apk --debug --no-pub` | **Correcto**, 45,9 s. |
| `aapt dump badging` / `dump permissions` | 0.8.0/código 9, SDK 24/36; sin INTERNET ni almacenamiento amplio. |
| `apksigner verify --verbose --print-certs` | **Verifies**, v2 válida y mismo certificado que la entrega anterior. |

Las 30 pruebas nuevas son 13 contratos, 9 de estado y 8 de interfaz. Se mantienen
las 208 previas. Cubren límites de alcance, dos objetivos, muro, figura intermedia,
terrenos, bases/elevación/condiciones/versión sin soporte, ocupación incompatible,
undo/redo, invalidación, carga, filtro, origen desde lista y ausencia de I/O por
consultas. La regresión oblicua de 06 también se aplica al análisis combinado.
Las expectativas y secciones están en MATRIZ_DISTANCIAS_OBJETIVOS.md.

UI comprobada en 320×568, 800×360 y 320×320 con texto al 300 %. En verificaciones
intermedias fallaron compilaciones de helpers de prueba por tipos/constructores;
se ajustaron a las interfaces reales. También se detectaron controles demasiado
anchos/altos a texto ampliado: se acotaron al ancho visible, se compactaron filas
con acceso al informe completo y se conservan hit tests fatales. La primera suite
completa falló solo por la expectativa histórica de Distancia deshabilitada;
se actualizó para comprobar Distancia/Objetivos disponibles y Movimiento futuro.
Los resultados aprobados de la tabla corresponden a las ejecuciones finales.

### Rendimiento medido

Dispositivo: PC de desarrollo Windows 10 Home 10.0.19045 x64, Intel Core i5-7200U @ 2,50 GHz,
4 procesadores lógicos y 8 GB RAM; Dart 3.14.0. Ejecución del motor con
`dart run tool/benchmark_targets.dart --mixed`, sin la suite Flutter ejecutándose
a la vez. Figuras distribuidas determinísticamente por el tablero, terreno H/B,
muros y figuras intermedias. No se colocan figuras sobre bloqueado.

| Escenario | 20×20 / 40 figuras | 40×40 / 120 figuras |
| --- | --- | --- |
| Objetivos analizados | 39 | 119 |
| Casillas de terreno / muros | 40 / 40 | 80 / 80 |
| Primera llamada por escenario | 82,711 ms | 79,039 ms |
| Mediana de 25 muestras sin caché | 7,562 ms | 65,222 ms |
| Percentil 95 / máximo | 43,289 / 43,953 ms | 78,482 / 80,812 ms |
| Media de 100 cambios de filtro con caché | 0,00698 ms | 0,00872 ms |
| Actualizar alcance reutilizando visión | 0,333 ms | 0,954 ms |
| Llamadas de visión antes/después de filtro y alcance | 39 / 39 | 119 / 119 |

Muestras en orden dentro del mismo proceso JIT, sin reiniciar Dart para el
segundo escenario. Son mediciones de CPU del motor; no son FPS, latencia total de
UI ni tiempos de un teléfono/emulador Android. Una ejecución preliminar durante
la suite produjo tiempos mayores por contención y no se usa como medición final.
La herramienta permite repetir también la variante sin terreno/muros.

Logs locales: `build/targets-pure-07-final.log`, `format-07-final.log`,
`analyze-07-final.log`, `test-07-final.log`, `preview-07-final.log`, `build-07.log`,
`performance-07-final.log`, `signature-07.log`. Fallos intermedios en targets-first,
second, third, targets-ui-07-fourth y test-07-first-full, todos fuera de Git.
Renders en `build/previews/prompt-07/`: distancia, diferencias, lista de cinco
categorías, objetivo en horizontal, detalle y base sin soporte, además de las
regresiones. Son renders Flutter, no capturas nativas de Android.

### APK definitivo

- `build/releases/heroclix-prompt-07-debug.apk`; salida estándar
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Tamaño: **158211717 bytes** (aprox. 150,88 MiB).
- SHA-256: `52ACB1A19449BEEF6B1AA92E0C3B9BDA41F33028DE2F8DAB051AFD40928E776A`.
- Paquete `com.valinor.heroclixtrainer`, versión 0.8.0, código 9.
- Firma de desarrollo conservada; se puede actualizar sin desinstalar ni borrar
  datos. No se ha ejecutado esa instalación en dispositivo para esta entrega.
- APK/evidencias/PDF excluidos de Git. Binarios de entregas anteriores conservados.

## D. Comprobar manualmente

1. Instalar el APK sobre la app anterior. En Editor, Medir distancia y A1/D6:
   5 casillas. Pulsar Distancia y activar diferencias: filas 5, columnas 3.
2. Figuras normales A1/D1, alcance del origen 3: Mostrar objetivos debe indicar
   distancia 3 y en alcance con visión despejada. Seleccionar D1 y abrir su resumen.
3. Editar alcance a 2: fuera; subir a 4: dentro. Deshacer/rehacer actualiza todas
   las filas. El alcance editado se guarda como dato del escenario.
4. H en B1: obstaculizada; B o muro A1/B1: bloqueada. Figura intermedia también
   bloquea. Alcance 2 con ese bloqueo conserva ambas dimensiones en el informe.
5. Añadir aliada y otra enemiga lejana. Probar filtros; elegir origen desde la
   lista sin selección previa; comprobar casilla/segmento/anotación del objetivo.
6. En Simulador o Árbitro usar Elegir análisis; comprobar que tocar no mueve
   figuras. Editar escenario permite modificarlas y regresar al análisis.
7. Base múltiple de extremo: distancia/rango sin evaluar. Efectos especiales o
   elevación relevante: conservar los límites del perfil, sin aprobado global.
8. Borrar un extremo, cargar otra escena, girar y ampliar texto. Las barras son
   desplazables; el informe conserva los textos completos que la lista abrevia.

## E. Limitaciones, supuestos y pendientes

- Perfil de figuras genéricas normales sin poderes, en tablero plano. El valor
  declarado no incorpora modificadores, habilidades ni cartas interpretadas.
- Distancia entre casillas no es movimiento. Altura, bases múltiples y excepciones
  relevantes conservan dimensiones pendientes según la matriz; no se inicia 08.
- Visible y en alcance no valida un ataque. No se comprueban acciones, adyacencia
  para atacar, estados, poderes ni cantidad de objetivos. Aliados consultables no
  equivalen a permiso universal para atacarlos.
- Se conserva el resto de límites de 06: ocupación incompatible, versión sin
  soporte y clasificación a sí mismo en H. El listado excluye al propio origen.
- No se implementa movimiento, combate completo ni Entrenador.
- No se realizó un recorrido nativo Android de 07, medición de FPS/Android ni
  prueba física/release. La instalación nativa de 06 queda documentada en su archivo.

## F. Documentación y fuente

ROADMAP, DECISIONES, ESTADO, README, ARQUITECTURA, ANDROID y REGLAS actualizados.
MATRIZ_DISTANCIAS_OBJETIVOS enlaza reglas, contratos, decisiones y metodología de
rendimiento. Fuentes oficiales consultadas el 2026-11-16; se conserva 2026-07-01.
El informe de 06 corregida se archiva en ENTREGA_06_FIX.md.

## G. Límite de etapa

**No se inició Prompt 08.** Se espera una nueva orden tras revisar esta entrega.
