# Entrega rc.3 — sesión temporal y visión inmediata

2026-11-17 (America/Bogota). **1.0.0-rc.3+16**, candidata debug.
Rama `codex/temporary-scenario-vision`, sobre `298833a` (rc.2).
Informe anterior: [ENTREGA_RC2.md](ENTREGA_RC2.md).

## A. Cambios operativos

- Cada apertura usa escenario vacío y figuras nuevas desde A. No se recupera ni
  se escribe el `working.json` antiguo del Editor, aunque contenga figuras hasta AA
  o esté dañado. Se ignora sin borrarlo ni modificar los escenarios de biblioteca.
- La misma sesión se mantiene al navegar por Editor/Simulador/Árbitro y al pasar
  a segundo plano mientras siga activa la instancia. Un arranque nuevo la reinicia.
  Guardar/Guardar como persisten explícitamente en biblioteca; los guardados se
  abren manualmente. Ejercicios y progreso del Entrenador conservan su persistencia.
- Al elegir Línea de visión se habilita su evaluación. Tras escoger origen y
  destino aparece el dictamen en una franja sobre el mapa, sin abrir un menú.
  Muestra icono/color/texto, las referencias elegidas y acceso al informe completo
  al tocarla. Bases reconocidas usan referencias automáticas; el modo manual sigue
  disponible mediante Referencias automáticas del informe.
- La franja se actualiza al cambiar terreno, figuras o contexto; conserva No evaluado
  ante condiciones sin soporte y se retira al limpiar extremos. Comparte el mismo
  resultado y motor de los informes, sin reglas duplicadas ni permiso de ataque.
- Inicio, Guía, detalles y confirmaciones explican la sesión temporal. Reintentar
  guardado vuelve a Guardar. En texto ampliado la franja prioriza el estado, con
  contexto completo en tooltip/semántica/informe, sin recortar la escala global.

## B. Archivos

WorkspaceController: política de sesión en memoria por defecto, guardados explícitos
 y compatibilidad heredada de recuperación opt-in. EditorController habilita visión.
Nuevo VisionVerdictBar e integración en EditorScreen/VisionScreen. Ayudas/Inicio y
acciones de archivos ajustadas; AppInfo/pubspec con versión/build actuales.

Nuevo `test/session_vision_test.dart` con 13 casos. Fixtures antiguas y E2E de
recuperación activan explícitamente `persistWorkingSession: true`: se mantienen
sus contratos de formatos/archivos, pero **la app no usa ese modo**. Los casos nuevos
usan la configuración false de producción, incluido almacenamiento real. La prueba
manual de base 2×2 declara su contexto de referencia manual explícitamente.

PreviewTest usa sesión temporal; el render de error corresponde ahora a Guardar
explícito. Añade seis capturas y escribe en `build/previews/session-vision/`.

## C. Verificación real

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0. Sin dependencias, permisos ni esquemas nuevos.

| Comando | Resultado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | 152 archivos, 0 cambios, 1,99 s. |
| `flutter --no-version-check analyze --no-pub` | No issues found, 3,5 s. |
| `flutter --no-version-check test --no-pub --reporter expanded` | **457 aprobadas**, 178 s. |
| `flutter --no-version-check test --no-pub test/session_vision_test.dart --reporter expanded` | **13 aprobadas**, 11 s, después del ajuste final de texto ampliado. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **84 renders aprobados**, 53 s. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --name 'renderiza session_' --reporter expanded` | **6 renders aprobados**, 9 s, después del ajuste final de texto ampliado. |
| `flutter --no-version-check build apk --debug --no-pub` | Correcto, Gradle 23,7 s, recompilación final. |
| `aapt dump badging` / `dump permissions` | 1.0.0-rc.3/código 16, SDK 24/36; sin INTERNET ni almacenamiento amplio. |
| `apksigner verify --verbose --print-certs` | Verifies; firma v2 válida y mismo certificado. |

457 = 444 anteriores + 13 nuevos. Cobertura: recuperación anterior AA ignorada y
arranque A sin escrituras, guardado/reintento explícito, biblioteca/progreso en
archivos reales, navegación/pausa/resume de widgets, dictamen directo en los tres
modos (despejada/H/B), No evaluado/invalidez/limpieza, bases automáticas, A1–D6/B4
por vértice, tamaños 360×800/800×360/320×320 y texto al 300 %.

La batería completa y los 84 renders pasaron antes del último ajuste exclusivamente
de presentación con texto ampliado. Después se repitieron los 13 casos y seis
renders afectados y se recompiló el APK. No se desactivaron pruebas ni errores de
hit test. Se corrigió el helper de navegación a tarjetas con texto ampliado y se
mantiene comprobación explícita del estado mostrado a escala 300 %.

Los seis renders nuevos (clear/blocked/hindered/unknown/compact/fresh) se revisaron
visualmente. Son Flutter/Windows, no capturas de Android. Los 78 casos anteriores
se conservan, renombrando el caso de error de autoguardado a guardado explícito.
Logs en build/ y metadatos APK en build/verification/session-vision/, fuera de Git.
No se vuelven a ejecutar pruebas nativas ni se afirma cierre real en un teléfono.

### APK definitivo de esta candidata

- `build/releases/heroclix-1.0.0-rc.3-debug.apk`, **158513961 bytes** (151,17 MiB).
- SHA-256: `1F160502E7F90EE1C7E07DCCB16B1B7F6B0C93DF5BFAEA65533256A19C7A5538`.
- Copia archivada y salida estándar con el mismo hash.
- Paquete `com.valinor.heroclixtrainer`, versión 1.0.0-rc.3, código 16.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Firma debug conservada; puede instalarse encima sin desinstalar para mantener
  biblioteca/progreso. APK anteriores conservados y binarios excluidos de Git.

## D. Comprobar manualmente en Android

1. Guardar en biblioteca cualquier escena que se quiera conservar. Instalar el
   APK encima de la versión anterior, sin desinstalar.
2. Abrir: debe haber escenario vacío. Colocar figura: etiqueta A. Crear varias,
   navegar a Simulador/Árbitro y volver: se mantienen. Segundo plano y regreso con
   instancia viva: se mantienen. Cerrar completamente y abrir: vuelve vacío y A.
3. Abrir manualmente la copia de biblioteca: datos conservados. Progreso y ejercicios
   del Entrenador siguen disponibles. Cambios temporales sin guardar no reaparecen.
4. Línea de visión: elegir dos figuras y comprobar dictamen arriba del mapa sin menú.
   Tocar la franja abre explicación/referencias. Añadir H/B o efectos no soportados
   debe actualizar el estado. Limpiar retira el resultado anterior.
5. Probar base múltiple automática, referencia manual, giro y texto ampliado.

Recorrido Android pendiente: se mantiene la decisión previa de continuar sin teléfono.
La prueba de reconstruir controladores y de ciclo de vida de widgets no sustituye
el cierre/pausa del proceso Android real.

## E. Límites

Al abrir un escenario guardado se conservan sus identidades/contadores; no se
renumera la biblioteca. Dentro de una sesión se mantiene unicidad de IDs y etiquetas.
La escena temporal se pierde al terminar esa instancia; Guardar en biblioteca es
la forma de conservarla. Progreso y snapshots de ejercicios son independientes.

Reglas y No evaluados siguen bajo el perfil documentado 2026-07-01. No cambia el
motor, los formatos 1/2/3 ni las capacidades soportadas. La franja muestra un resumen;
con texto muy grande puede abreviarse visualmente, pero tooltip/semántica/informe
conservan el resultado completo. Aceptación nativa, TalkBack, radios apagadas y
rendimiento Android siguen pendientes. Sin claves release, no se promueve estable.

## F. Documentación y alcance

README/README_FINAL, ESCENARIOS, ARQUITECTURA, DECISIONES, ANDROID, ENTRENADOR,
ROADMAP y matriz de aceptación actualizados. AC22/23 cubren estos cambios.
Rc.2 archivada en ENTREGA_RC2.md. Sin eliminar escenarios guardados ni datos del
Entrenador; sin unificar modos y sin funciones de partida completa.
