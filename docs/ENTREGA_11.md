# Entrega archivada — etapa 11

2026-11-16 (America/Bogota). App **0.12.0+13**.
Repositorio privado: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama `codex/prompt-11`, sobre 10 (`2bc0f19`). Informe previo: [ENTREGA_10.md](ENTREGA_10.md).

## A. Operativo

- Analizar posición desde Editor, Simulador y Árbitro: figura activa, visibles,
  enemigos que la ven, alcance declarado, líneas H/bloqueadas y amenazas conocidas.
  Definiciones, referencias y límites visibles. H cuenta como visión; amenaza exige
  línea y alcance en un mismo par y no equivale a ataque legal.
- Mapa con indicadores V/T/C y desconocidos, terreno y niveles. Los destinos son
  anclas; se comprueba toda la huella. Rutas ilegales excluidas de candidatas legales.
  Se comparan posición actual y destino legal sin modificar escena hasta confirmar.
- Prioridades transparentes: más visibles, menos visión enemiga o menor movimiento.
  Orden dentro de la página, sin mejor jugada ni probabilidades. Resultados parciales
  separados, cotas inferiores y diferencias sin falsa precisión.
- HIPÓTESIS sin mejoras soportadas del activo, conservando capacidades desconocidas
  y fichas enemigas. Misma ruta revalidada sin mejoras; ficha original intacta.
- Cálculo en isolate: 12 destinos/página, progreso por enemigo/posición, cancelación
  real del worker y descarte de mensajes atrasados. Hasta 32 enemigos; restantes
  No evaluados. Caché de ocho páginas invalidada por contenido, capacidades,
  versión y efectos. Cámara/prioridad conservan resultados.
- Confirmar revalida la ruta declarada y aplica un único comando con Deshacer.
  Cancelar o salir conserva posición original.
- Crear ejercicios de recorrido o posición que ve un enemigo desde resultados
  verificados, usando fábrica en isolate y corrector del Entrenador. Persistencia,
  práctica y feedback reales; snapshot independiente, sin guardar fichas hipotéticas.
- TXT/PNG del diagnóstico con etiquetas genéricas, sin nombres, IDs ni metadatos
  libres. PNG generado desde datos, hasta 2048 px por eje. Puente Android existente.
- Entrenamiento formato 3 lee 1/2/3, con respaldo exacto de 1/2 antes de reemplazar.
  Contadores y ejercicios anteriores conservados. Escenarios siguen esquema 3.
  Banco curado v1 de 24 ejercicios intacto. Sin dependencias ni permisos nuevos.

Definiciones y límites: [ANALISIS_TACTICO.md](ANALISIS_TACTICO.md).

## B. Archivos principales

- `lib/domain/tactics/`: TacticalAnalysisService y diagnósticos inmutables.
- `lib/application/tactics/`: worker y resumen público del diagnóstico.
- `lib/presentation/tactics/`: controlador, pantalla, mapa y render PNG.
- `lib/application/training/analysis_exercises.dart`, TrainingCodec/Repository,
  Exercise/Evaluator: ejercicios con rutas por posición, formato 3 y respaldo.
- TrainingScope, app y navegación Editor/Simulador/Árbitro; versión en pubspec.
- Cinco archivos tactics_*_test, contratos A01–A14, verify_tactics,
  benchmark_tactics y ocho renders nuevos. Expectativa del codec anterior
  actualizada a exportación 3, conservando pruebas de compatibilidad.

## C. Verificación ejecutada

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0; Windows 10, i5-7200U, 8 GB.
Android minSdk 24, compile/target 36. No se cambian configuración nativa ni permisos.

| Comando | Resultado real |
| --- | --- |
| `dart run tool/verify_tactics.dart` | **14/14 contratos puros aprobados**. |
| `dart format --output=none --set-exit-if-changed lib test tool` | **143 archivos, 0 cambios**, 1,27 s, verificación final. |
| `flutter --no-version-check analyze --no-pub` | **No issues found**, 3,0 s. |
| `flutter --no-version-check test --no-pub --reporter expanded` | **419 aprobadas**, 166 s. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **66 renders aprobados**, 34 s. |
| `flutter --no-version-check test --no-pub test/tactics_state_test.dart test/tactics_training_test.dart --reporter expanded` | **13 aprobadas**, antes de la batería completa final. |
| `flutter --no-version-check test --no-pub test/tactics_editor_test.dart test/tactics_export_test.dart --reporter expanded` | **12 aprobadas**, incluye generación real de PNG. |
| `dart run tool/benchmark_tactics.dart` | Cinco muestras por tablero; resultados y límites abajo. |
| `flutter --no-version-check build apk --debug --no-pub` | **Correcto**, Gradle 48,4 s. |
| `aapt dump badging` / `dump permissions` | 0.12.0/código 13, SDK 24/36; sin INTERNET ni almacenamiento amplio. |
| `apksigner verify --verbose --print-certs` | **Verifies**, firma v2 válida y mismo certificado. |
| `adb devices` | **Ningún dispositivo conectado**. |

Se conservan 380 pruebas y se añaden 39: 14 dominio, 8 estado/isolate, 5 integración
Entrenador/codec/migración, 10 UI y 2 privacidad/PNG. Casos incluyen muro/recalculo,
capacidades direccionales, par coherente de base, destino ilegal, 40×40 sin enemigos,
35 enemigos con tres omitidos, incertidumbre, cancelación, caché/cámara, versión
reglamentaria distinta, confirmar/Deshacer, persistencia y práctica de ambos ejercicios.
UI comprobada a 320×568, 800×360 y 320×320 con texto al 300 %.

Durante el desarrollo se corrigieron dos declaraciones de variables con patrón
incompatibles con la sintaxis usada, una expectativa antigua de exportación 2,
observaciones del analyzer y el dimensionado del pie PNG. Las verificaciones
finales de arriba ya incluyen esas correcciones; no queda fallo conocido pendiente.

Renders en `build/previews/prompt-11/`: ocho de análisis nuevos y 58 regresiones.
Se revisaron visualmente mapa, comparación, hipótesis, incertidumbre, evidencia,
ejercicio y exportación. PNG real en `build/verification/prompt-11/diagnostico.png`.
Son renders Flutter/Windows, no capturas de un teléfono. Logs/evidencia en build/,
fuera de Git; copias de escenas de verificación usan carpeta de etapa 11.

### Medición de CPU

Dart/JIT, cinco muestras por tamaño, 36 figuras, 32 de 35 enemigos evaluados,
12 destinos más origen. 20×20: primera/máxima **442,961 ms**, mediana **144,803 ms**.
40×40: primera **131,576 ms**, mediana **130,800 ms**, máxima **137,457 ms**.
El calentamiento de la primera muestra impide atribuir diferencias al tamaño.
No es una medición de FPS, rendimiento Android ni latencia de pantalla; tampoco
un análisis completo de los 35 enemigos. Ver `build/performance-11.log`.

### APK

- `build/releases/heroclix-prompt-11-debug.apk`: **158490773 bytes** (151,15 MiB).
- SHA-256: `AE527F99ADC31616C9A41AA1AD9D726AFEFB93FE363E31048E7EAA14703335AA`.
- Copia archivada y `build/app/outputs/flutter-apk/app-debug.apk` tienen el mismo hash.
- Paquete `com.valinor.heroclixtrainer`, versión 0.12.0, código 13.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- La firma permite actualizar sobre anteriores sin desinstalar; instalación física
  no ejecutada para 11. APK anteriores preservados. Sin variante release validada.
- APK, PDF, logs y renders no se suben a Git; no se incluyen credenciales ni claves.

## D. Comprobación manual en Android

1. Instalar el APK sobre la versión anterior. Comprobar biblioteca y progreso de 10.
2. Simulador → Elegir análisis → Analizar posición: elegir figura y analizar.
   Consultar métricas/evidencia, tocar destino legal y comparar ruta/costo/diferencias.
3. Cambiar prioridad/página y comparar sin mejoras. Sin soporte debe mostrar
   No evaluado, sin ceros falsos ni ranking categórico.
4. Cancelar durante cálculo: figura intacta. Reanalizar, confirmar destino válido
   y Deshacer desde Editor: recuperar origen. Un muro nuevo invalida los resultados.
5. Crear ejercicio de recorrido y practicarlo en Entrenador. Crear uno de posición
   visible cuando haya contraste entre opciones; comprobar solución y progreso.
6. Exportar resumen e imagen mediante selector nativo; revisar etiquetas genéricas,
   incertidumbre y ausencia de nombres. Rotar y ampliar texto al 300 %.
7. Probar mapa 40×40 con varios enemigos, progreso/cancelación y cerrar/reabrir app.

Estos pasos nativos quedan pendientes de dispositivo; no se presentan como ejecutados.

## E. Limitaciones y pendientes

- Hereda perfiles de visión/movimiento: traslación sin giro, tamaños/capacidades
  soportados y separación sin dados. Efectos sin soporte permanecen No evaluados.
  Alcance/velocidad son datos declarados, sin cálculo arbitrario de modificadores.
- Ordenación por página y límites de 12 destinos/32 enemigos, sin garantía global
  ni recomendación estratégica. Visión y alcance no prueban legalidad de ataque.
- El mapa representa anclas de bases, aunque el validador comprueba la huella entera.
- Ejercicio de visibilidad necesita al menos dos posiciones con contraste verificable;
  usa hasta cuatro. Límite personal de 50 ejercicios/2 MiB se conserva.
- Generación de ejercicio cancelada descarta el resultado; su isolate acotado puede
  terminar el cálculo. El worker principal sí se termina al cancelar. Escritura
  atómica ya iniciada no se cancela a mitad.
- Exportación usa datos genéricos, pero conserva geometría y parámetros de juego.
- No se hizo instalación/recorrido nativo, FPS, emulador ni build release. Sin
  dispositivos conectados; el puente nativo se reutiliza y se prueba por adaptador.

## F. Documentación

Actualizados README, ROADMAP, DECISIONES, ARQUITECTURA, ANDROID, ESCENARIOS, REGLAS,
ENTRENADOR y este ESTADO. Nueva ANALISIS_TACTICO.md; informe 10 archivado en ENTREGA_10.md.
Se mantiene edición oficial 2026-07-01 y las matrices verificadas de 06–09. No se
adopta una regla nueva ni se redistribuye el reglamento o arte de terceros.

## G. Límite de etapa

**No se inició Prompt 12.** La siguiente etapa requiere una nueva orden del usuario.
