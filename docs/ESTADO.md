# Estado actual — etapa 10

2026-11-16 (America/Bogota). App **0.11.0+12**.
Repositorio privado: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama `codex/prompt-10`, sobre 09 (`cde37c6`). Informe previo: [ENTREGA_09.md](ENTREGA_09.md).

## A. Operativo y preparado

- Modo Entrenador disponible desde Inicio. Banco curado v1 de **24 ejercicios**,
  cuatro por cada categoría: visión, terreno/muros, distancias/alcance, movimiento,
  elevaciones/capacidades y posiciones sencillas. Tres dificultades sin cambiar reglas.
- Cinco tipos automáticos: opciones, tocar objetivo visible, elegir casilla, trazar
  ruta y justificar el dictamen. Flujo iniciar, responder, comprobar, feedback,
  continuar o repetir. Pistas explícitas; solución oculta hasta comprobar.
- Soluciones literales de regresión contrastadas con los mismos servicios de
  visión, distancia, objetivos y movimiento de 06–09. No se copian reglas en UI.
  Edición distinta, No evaluado o divergencia entre solución y motor inhabilitan
  autocorrección. Una respuesta sin soporte no se convierte en fallo estadístico.
- Progreso local por categoría: intentos, aciertos, porcentaje, último intento,
  completados y revisiones manuales. Practicar errores usa el último fallo elegible.
  Repetir/revisar no suman hasta confirmar una nueva respuesta. Token evita duplicados.
- Crear ejercicio personal desde escenario guardado, con título/pregunta, categoría,
  dificultad, opciones/pista y solución/guía. Modalidades: visión, distancia,
  alcance/visión, ruta y texto manual. El motor verifica antes de guardar preguntas
  automáticas; texto libre se identifica como evaluación manual y no asigna acierto.
- Tablero independiente del Editor. Copiar escenario, ensayar una respuesta y
  comparar un paso en ejercicios no cambia escena, historial ni biblioteca originales.
  Rutas aceptan alternativas verificables, no obligan a copiar la solución guardada.
- Estadísticas y ejercicios personales persisten en archivos privados separados.
  Reiniciar estadísticas requiere confirmación y conserva ejercicios. Entrenamiento
  formato 2 lee 1/2 con respaldo exacto del legado; escenarios mantienen esquema 3.
- Feedback entra automáticamente en vista al comprobar y cierra teclado; respuesta
  manual queda legible para revisar. Interfaz desplazable con texto ampliado.

Banco, referencias, criterios y límites en [ENTRENADOR.md](ENTRENADOR.md).
No se introduce análisis estratégico general ni las métricas del Prompt 11.

## B. Archivos principales

- `lib/domain/training/`: Exercise, Answer, Evaluation, Feedback, RuleSetVersion,
  ExerciseEvaluator, banco curado y progreso. Dart puro, snapshots inmutables.
- `lib/application/training/`: codec, repositorio y construcción de ejercicios
  personales; reutilizan ScenarioCodec y el puerto atómico LocalDocumentStore.
- `lib/presentation/training/`: banco/progreso, pregunta, autor, controlador y
  pintor de respuestas. Integración en app/main/Inicio y callback/overlay aislados
  de BoardCanvas. Escena abierta del Editor no se reutiliza para practicar.
- Tests: training_rules/state/codec/editor_test y fixtures; arranque actualizado
  para comprobar los cuatro modos disponibles. Herramienta verify_training y ocho
  renders nuevos. Pubspec 0.11.0+12, sin dependencias nuevas.

## C. Comandos y resultados reales

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0. Android minSdk 24, compile/target 36.
Se conserva configuración nativa y certificado de desarrollo; sin permisos nuevos.

| Comando | Resultado |
| --- | --- |
| `dart run tool/verify_training.dart` | **24/24 soluciones del banco verificadas** en Dart puro. |
| `dart format --output=none --set-exit-if-changed lib test tool` | **125 archivos, 0 cambios**, 1,36 s. |
| `flutter --no-version-check analyze --no-pub` | **No issues found**, 6,5 s, después de los ajustes finales. |
| `flutter --no-version-check test --no-pub --reporter expanded` | **380 aprobadas**, 134 s. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **58 renders aprobados**, 32 s. |
| `flutter --no-version-check test --no-pub test/training_editor_test.dart test/training_codec_test.dart --reporter expanded` | **18 aprobadas**, 16 s, tras el ajuste final de feedback/navegación y compatibilidad de banco. |
| `flutter --no-version-check test tool/preview_test.dart --name 'renderiza training_' --no-pub --reporter expanded` | **8 renders aprobados**, 9 s, después del ajuste de feedback; revisados visualmente. |
| `flutter --no-version-check build apk --debug --no-pub` | **Correcto**, Gradle 23,5 s, recompilación final. |
| `aapt dump badging` / `dump permissions` | 0.11.0/código 12, SDK 24/36; sin INTERNET ni almacenamiento amplio. |
| `apksigner verify --verbose --print-certs` | Verifies; v2 válida y mismo certificado. |
| `adb devices` | Ningún dispositivo conectado. |

Se conservan 321 pruebas anteriores y se añaden 59: 34 de dominio/banco, 7 de
estado, 6 de codec/archivos y 12 de interfaz. Cubren cinco tipos de respuesta,
correcta/incorrecta, H/B, rutas alternativas, manual, porcentajes/completados al
reabrir, filtro de errores, pista/revisión sin I/O, idempotencia, fallos de guardado,
reset conservando personales, versiones futuras y bloqueo por No evaluado.

Persistencia probada con repositorios/controladores nuevos y con archivos reales
separados de la biblioteca; lectura/migración no reescriben el original. El formato
legacy 1 de entrenamiento usa datos sintéticos, no una versión publicada anterior.
UI en 320×568, 800×360 y 320×320 al 300 %, manteniendo hit tests fatales.

Fallos intermedios: sintaxis de helpers de tests al combinar declaraciones con
patrones; uso de pageBack del framework con material_ui, corregido con navegación
explícita y accesible al banco; estilo/lints en código nuevo. Renders detectaron
una captura durante animación de etiqueta del formulario: la herramienta ahora
espera el frame estable. Se mantuvo legible el texto manual y se añadió entrada
al feedback visible al comprobar. Tras estas mejoras se repitieron las 18 pruebas
relevantes, los ocho renders nuevos, análisis y APK; no se repitió por tercera vez
la suite completa porque no cambiaron los motores ni otras pantallas.

Logs locales en `build/`: training-bank-10-final, format-10-check,
 analyze-10-final, test-10-final, preview-10-final, training-final-ux-10,
 preview-training-10-final, build-10-final y signature-10 (`.log`). Los fallos
intermedios están en training-ui-10-first/second y analyzes previos, fuera de Git.
Renders en `build/previews/prompt-10/`; son Flutter, no capturas nativas Android.
Ocho nuevos: banco, pregunta, feedback, ruta, progreso, autor, manual y edición
sin soporte. Se conservan las regresiones visuales previas. No se mide FPS/Android.

### APK definitivo

- `build/releases/heroclix-prompt-10-debug.apk`, **158413933 bytes** (151,08 MiB).
- SHA-256: `2616006F6C29EE5B372E8E09DBD401D5D67C3A1AF52CE33A461518EAA31EB3DA`.
- Paquete `com.valinor.heroclixtrainer`, versión 0.11.0, código 12.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Firma conservada permite actualizar sobre anteriores sin desinstalar. Esa
  instalación no se ejecutó en un dispositivo para 10. No hay validación release.
- APK, renders, logs y PDF fuera de Git; APK anteriores preservados.

## D. Comprobar manualmente

1. Instalar sobre la versión anterior. Abrir Editor y comprobar escenarios antiguos.
   Volver al Inicio → Entrenador: cuatro modos disponibles, 24 ejercicios curados.
2. Iniciar «Visión entre obstáculos verdes». Elegir respuesta: no debe mostrarse
   solución ni sumar intentos. Pista es opcional. Comprobar muestra feedback y §16.2b.
3. Repetir no suma. Comprobar otra respuesta sí. Volver al banco, revisar último
   intento y comprobar que mantiene estadísticas. Practicar errores muestra el
   último fallo elegible; acertar después lo retira.
4. Probar objetivo visible, casilla válida, justificar muro y ruta entre muros.
   La escena del Editor y su historial deben permanecer intactos. Otra ruta legal
   al mismo destino dentro de velocidad también puede acertar.
5. Abrir Progreso por categoría y cerrar/reabrir app: conservar intentos, porcentaje,
   completados y último intento. Texto manual cuenta revisión, no acierto automático.
6. Guardar una escena en biblioteca. Entrenador → +: elegirla, definir pregunta,
   opciones/pista, solución y explicación. Solución automática errada no se guarda;
   manual exige guía. Editar luego el original no cambia el snapshot del ejercicio.
7. Reiniciar estadísticas: cancelar conserva todo; confirmar borra progreso pero
   conserva personales. Probar rotación, texto al 300 %, teclado y desplazamiento.

## E. Limitaciones, supuestos y pendientes

- Hereda el perfil de los motores 06–09. No se interpreta texto de cartas, acciones,
  turnos, daño, dados ni capacidades sin soporte. No evaluado no equivale a error.
- Dificultad es complejidad didáctica. Posición sencilla comprueba un predicado de
  alcance/visión tras un paso; no recomienda jugadas ni implementa métricas de 11.
- Texto libre requiere revisión humana. Aciertos/porcentaje/completados automáticos
  excluyen revisión manual; pistas no penalizan. Se guarda último intento y totales,
  no cada respuesta histórica. Totales de categoría corresponden a edición activa.
- Creación personal ofrece cinco modalidades; tocar objetivo/casilla se usa en el
  banco curado. Sin editor posterior del ejercicio, exportación/importación, azar,
  ranking, cuentas o sincronización. Máximo 50 personales y 2 MiB de entrenamiento.
- No se hizo recorrido nativo Android, instalación física, FPS ni build release.
  No había dispositivos conectados. Verificaciones antiguas corresponden a sus
  entregas archivadas; los renders no se presentan como pruebas de dispositivo.

## F. Documentación y fuente

Actualizados ROADMAP, DECISIONES, ESTADO, README, ARQUITECTURA, ESCENARIOS, ANDROID
 y REGLAS. Nueva ENTRENADOR.md con banco, criterios, almacenamiento y límites.
09 archivada en ENTREGA_09.md. Se conserva reglamento oficial 2026-07-01 revisado
en la página de WizKids el 2026-11-16; se reutilizan las matrices ya verificadas.
No se distribuye el PDF de consulta ni se copian mapas o arte de terceros.

## G. Límite de etapa

**No se inició Prompt 11.** Análisis táctico general requiere una nueva orden.
