# Entrega archivada — etapa 06 (0.7.0+7)

Informe de la primera entrega. La corrección de vértices oblicuos en 0.7.1+8
se registra en ESTADO.md; sustituye el límite de pendientes distintas de 45°
descrito aquí. Se conserva este informe como evidencia histórica.

2026-11-16 (America/Bogota). App **0.7.0+7**.
Repositorio: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama: `codex/prompt-06`, sobre 05 (`408e40f`).
Informes archivados: [00](ENTREGA_00.md), [01](ENTREGA_01.md),
[02](ENTREGA_02.md), [03](ENTREGA_03.md), [04](ENTREGA_04.md), [05](ENTREGA_05.md).

## A. Operativo y preparado

- LineOfSightService en Dart puro aplica el perfil básico documentado a la
  geometría exacta de 05. Salida: DESPEJADA, OBSTACULIZADA, BLOQUEADA o NO EVALUADA;
  visibilidad true/true/false/null. No produce permiso de ataque.
- Figuras intermedias de cualquiera de los equipos, terreno H/B y muros; exclusión
  de figuras de extremos y H de origen bajo las condiciones del perfil ordinario.
- En vértices de diagonal perfecta, comparar los dos lados con sus terrenos,
  figuras y muros incidentes. Elegir el menos restrictivo y conservar ambas
  alternativas en el registro. No bloquear por cualquier contacto aislado.
- Texto, icono y color de estado; segmento verde/ámbar/rojo/gris y marcas de causas.
  Informe con explicación, referencias, evento consultado y elementos decisivos.
  Resaltados y declaración de efectos especiales controlables.
- Recalcular ante cambios de mundo, extremos o versión de reglas. Borrar/reducir
  un extremo retira el resultado anterior. Cámara y selección reutilizan la caché.
- Editor, Simulador y Modo árbitro comparten escenario y motor. Los dos últimos
  navegan/seleccionan y ofrecen edición explícita en Editor. Entrenador sigue futuro.
- Preparado: interfaz VisionEvaluator/contexto tipado para futuras capacidades.
  No se implementan poderes, elevación, bases completas, alcance ni movimiento.

## B. Archivos principales

- `lib/domain/rules/line_of_sight.dart`, `line_of_sight_service.dart`.
- `lib/application/board/vision_analysis.dart` y EditorController.
- `lib/presentation/vision/vision_controls.dart`, `vision_screen.dart`.
- Home/catalog, canvas, pantalla Editor, controles geométricos y painter.
- `test/support/vision_contract.dart`, `vision_rules_test.dart`,
  `vision_state_test.dart`, `vision_editor_test.dart`; ajustes de inicio y renders.
- `tool/verify_vision.dart`, `preview_test.dart`, pubspec y documentación.
- MATRIZ_REGLAS_VISION, REGLAS, README, ARQUITECTURA, DECISIONES, ROADMAP, este
  informe y archivo histórico de 05.

## C. Comandos y resultados reales

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0. Sin dependencias nuevas.
Android minSdk 24, compile/target 36, NDK 28.2.13676358, AGP 9.3.1,
Gradle 9.5.0, Kotlin 2.4.20 y Android Studio JBR 25.

| Comando | Resultado |
| --- | --- |
| `dart run tool/verify_vision.dart` | **22/22 contratos aprobados** con Dart puro, sin Flutter/UI |
| `flutter --no-version-check analyze --no-pub` | **No issues found**, 2,8 s |
| `flutter --no-version-check test --no-pub --reporter expanded` | **205 aprobadas**, 86 s |
| `flutter --no-version-check test tool/preview_test.dart --no-pub` | **30 renders aprobados**, 22 s; ocho vistas nuevas revisadas |
| `flutter --no-version-check build apk --debug --no-pub` | **Correcto**, 43,0 s |
| `aapt dump badging` / `dump permissions` | 0.7.0/código 7, SDK 24/36, sin INTERNET ni permisos amplios de almacenamiento |
| `apksigner verify --verbose` | **Verifies**, firma debug v2 válida |

Las 37 pruebas nuevas son 22 contratos de reglas, 7 de estado y 8 de interfaz;
se mantienen las 168 anteriores. Incluyen los 9 pares de terrenos laterales y
16 subconjuntos de muros terminales, equipos, extremos, cambios deterministas,
altura/base/capacidades/versión sin soporte, inválidos, 40×40 e inmutabilidad.
La matriz contiene la tabla R01–R22 de expectativas y secciones oficiales.

Se verifican actualización por terreno aunque la geometría conserve identidad,
borrado/undo, cambio de dimensiones y versión de metadatos, caché sin escrituras
por cámara/selección/resaltados y limpieza al cargar otra escena. UI: tres estados
reglamentarios y No evaluado, informe/referencias, causa resaltada, Árbitro/Simulador,
lectura sin mover figuras y navegación de ida/vuelta a Editor. Pantallas 320×568,
800×360 y 320×320 con texto al 300 %, además de regresiones previas.

Durante la verificación se corrigieron competencia de viewports entre rutas y
controles demasiado altos a 300 %. Las pruebas eligen el texto/clave del control
visible y distinguen el resultado del informe de la barra inferior. Dos renders
fallaron inicialmente al confundir la etiqueta del menú con la de la barra; se
seleccionó el elemento del menú. Las ejecuciones finales pasan; no se ocultan
avisos de hit test ni se cuentan ejecuciones fallidas como aprobadas.

Logs locales: `build/vision-pure-06.log`, `analyze-06-final.log`, `test-06-final.log`,
`vision-ui-06-final.log`, `vision-state-06.log`, `preview-06-final.log`, `build-06.log`.
Renders Flutter en `build/previews/prompt-06/`: cuatro estados, esquina, informe,
registro, Árbitro y regresiones. No son capturas de dispositivo.

### Recorrido nativo del APK definitivo — 2026-11-16

Instalación `adb install -r` correcta en Medium_Phone_API_37.0, Android 17/API 37,
emulator-5554, 540×1200, densidad 210. Se abrió el APK archivado de esta entrega.
El escenario sintético A1/D1 con H en B1 se preparó escribiendo el JSON de sesión
en el almacenamiento privado de esta app de prueba mediante `run-as`; esto no
verifica el selector nativo de importación. No se modificó un escenario del usuario.

| Comprobación observada | Resultado |
| --- | --- |
| Inicio y acceso al Modo árbitro | Correctos; dos figuras y terreno de la sesión recuperados. |
| Elegir A1 y D1 | OBSTACULIZADA, segmento ámbar y B1 resaltada con marca de causa. |
| Abrir Dictamen de visión | Explica H en B1, distingue visión de ataque e indica edición 2026-07-01. |
| Activar Efectos especiales | NO EVALUADA; explica el límite de poderes/tamaños. |
| Expandir Registro y referencias | V01 §11.4 p. 27 y SCOPE/V11 §19.3 p. 54 visibles en el caso especial. |
| Sin conexión | Modo avión 1 y Wi-Fi 0 durante el recorrido. |

Capturas nativas locales en `build/verification/prompt-06/`:
`arbitro_inicial.png`, `nativo_obstaculizada.png`,
`nativo_informe_recuperado.png`, `nativo_no_evaluada_recuperado.png` y
`nativo_referencias_recuperado.png`. Las capturas con el diálogo de System UI no
se cuentan como prueba de la interfaz subyacente. El emulador se cerró al terminar;
`adb devices` quedó sin dispositivos.

El huésped mostró repetidamente «System UI isn't responding» y exigió pulsar
Wait; no se presenta esta sesión como medición de rendimiento ni como recorrido
nativo exhaustivo. En `app_android.log`, filtrado por PID 3021 de la app, no se
encontraron FATAL EXCEPTION, Unhandled Exception, RenderFlex ni E/flutter.
Sí aparece el fallo esperado del servidor HTTP del servicio VM de Dart al intentar
abrir un socket local sin permiso INTERNET; la interfaz instalada funciona.
Despejada, bloqueada, combinaciones de esquinas, rotación y accesibilidad de esta
entrega se comprobaron mediante contratos/widgets/renders, no mediante un nuevo
recorrido nativo completo. No se probó un teléfono físico.

### APK definitivo

- Local: `build/releases/heroclix-prompt-06-debug.apk`.
- Salida estándar: `build/app/outputs/flutter-apk/app-debug.apk`.
- Tamaño: **158175653 bytes (150,85 MiB)**.
- SHA-256: `01A20A93014BFB15D306CE02F7BB6D8F2B781195E3F84BFFFDD1048CAC9D1A76`.
- APK/evidencias y PDF de lectura excluidos de Git; entregas previas conservadas.

## D. Comprobar manualmente

1. Instalar APK, abrir Editor sin conexión y crear dos figuras normales en A1 y D1.
   Elegir Línea de visión, tocar ambas y abrir Dictamen de visión: despejada.
2. H en B1: obstaculizada; aún puede trazar visión. B en B1: bloqueada. El informe
   identifica B1 y su sección. Muro A1/B1 o figura intermedia también bloquean.
3. Solo H en origen A1 no obstaculiza; H en destino D1 sí. No confundir esto con
   legalidad de ataque, alcance o acciones: esas condiciones no se comprueban.
4. Diagonal A1–B2: B1 bloqueado y A2 libre deja paso; ambos bloqueados lo impiden;
   B1 bloqueado y A2 H da obstaculizada. Revisar ambos lados en el registro.
5. Activar Efectos especiales: No evaluado. Cambiar una figura/terreno o borrar un
   extremo actualiza/retira el dictamen; deshacer puede restituirlo.
6. Volver a Inicio y abrir Simulador o Árbitro: mismo escenario y resultado.
   Mantener pulsado no mueve una figura; Editar escenario permite modificarla y
   regresar al análisis. El Árbitro no sustituye al juez oficial.
7. Abrir Registro y referencias, ocultar resaltados, ampliar/Ajustar y girar.
   Probar texto ampliado. Las marcas no entran en PNG ni JSON del escenario.

## E. Limitaciones, supuestos y pendientes

- Perfil básico: figuras genéricas normales, sin poderes, mismo plano. Nombres,
  velocidad y alcance anotados no se interpretan como cartas o poderes oficiales.
- No evaluado ante condiciones relevantes sin soporte: altura, bases múltiples,
  poderes/tamaños declarados, fuente remota, mapa especial o versión desconocida.
  También ante ocupación incompatible, clasificación a sí mismo en H y vértices
  de pendiente no perfecta. Los límites se distinguen de una regla oficial.
- SCOPE tiene precedencia conservadora aunque exista un bloqueo aparente; una
  excepción pendiente podría cambiarlo. No evaluado no equivale a bloqueado.
- Origen requiere figura; destino puede ser figura o casilla. La visibilidad de
  una casilla vacía no la convierte en objetivo legal de ataque.
- Se mantiene esquema JSON 1. Referencias, resultado y declaración de efectos son
  transitorios y se limpian al cargar otra escena/reiniciar. Solo se guarda mundo
  y referencia de edición; capacidades persistentes completas se reservan a 08.
- Posiciones de estudio incompatibles invalidan el dictamen. No hay evaluación de
  alcance, ataques completos, movimiento o entrenador. No se implementa 07.
- No se ha probado un teléfono físico ni un APK release con clave del usuario.

## F. Documentación y fuente

ROADMAP, DECISIONES y ESTADO actualizados. MATRIZ_REGLAS_VISION enlaza todas las
reglas/casos y distingue cobertura de norma; REGLAS registra la validación de
edición; README uso y límites; ARQUITECTURA motor compartido. Entrega 05 archivada.
El PDF oficial se consultó mediante texto y renders de páginas completas, sin
incorporarlo a la app. La matriz registra enlace y SHA-256 de la copia de lectura.

## G. Límite de etapa

**No se inició Prompt 07.** Requiere una nueva orden tras revisar esta entrega.
