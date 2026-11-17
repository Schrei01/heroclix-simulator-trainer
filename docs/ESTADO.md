# Estado actual — equipos, avisos y trazos

2026-11-17 (America/Bogota). **1.0.0-rc.6+19**, candidata debug.
Rama `codex/editor-brush-teams`, sobre `7d8f95b` (rc.5). Código: 0382420.
Informe anterior: [ENTREGA_RC5.md](ENTREGA_RC5.md).

## Cambios

- Personajes: cada par de toques sobre una figura existente pasa al equipo siguiente
  de la lista disponible; después del último vuelve al primero. La colocación sigue
  usando el primer equipo y no cuenta como un toque de cambio. Se conservan ID,
  etiqueta, nombre, posición, base, tamaño, atributos y capacidades. Un solo equipo
  no produce cambios; cada cambio real permite Deshacer/Rehacer.
- Ayuda de herramienta en una franja vertical a la derecha del mapa durante cuatro
  segundos, con renovación al seleccionar otra herramienta/pincel. RotatedBox e
  IgnorePointer: no desplaza cámara/viewport ni intercepta los gestos. El temporizador
  se cancela al desmontar. Los errores de validación siguen usando sus avisos.
- Elevado comparte el trazo interpolado de terreno. Cada casilla única sube un nivel
  desde el valor previo al trazo (1→2, 2→3…), aunque se regrese sobre ella sin soltar.
  Se muestra el nivel de destino en la vista previa, sin el badge antiguo debajo.
  Tipo de terreno y figuras se conservan. Las bases completas se validan al final;
  una región parcial que las dejaría entre niveles o E40 rechazan todo el trazo.
- Borrar entra siempre en Borrar todo: trazar devuelve las casillas recorridas a
  suelo despejado y retira muros/transiciones incidentes y figuras completas cuya
  base toca. Otras casillas, equipos y contadores se conservan. No pide confirmación
  para el trazo total; un Deshacer lo recupera completo. Siguen las variantes de
  borrado de una capa elegidas explícitamente en el menú.
- En ambos trazos, cancelar o añadir un segundo dedo descarta la vista previa sin
  cambios parciales. Cada trazo se confirma en una operación al soltar. Borrar vacío
  no crea historial. Selección con confirmación de borrado y demás herramientas conservadas.

## Verificación real

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0, Windows. Sin nuevas dependencias,
permisos ni esquemas. Los avisos y pinceles son transitorios y no se exportan.

| Comando | Resultado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | 155 archivos, 0 cambios |
| `flutter --no-version-check analyze --no-pub` | No issues found, 3,8 s |
| `flutter --no-version-check test --no-pub --reporter expanded` | **485 aprobadas**, 230 s |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **101 renders aprobados**, 55 s |
| `flutter --no-version-check build apk --debug --no-pub` | Correcto; Gradle 49,3 s |
| `aapt dump badging` / `dump permissions` | 1.0.0-rc.6/código 19, SDK 24/36; sin INTERNET ni almacenamiento amplio |
| `apksigner verify --verbose --print-certs` | Verifies; firma v2 válida, mismo certificado |

Nuevo editor_brush_teams_test: 12 casos. Ciclos de dos/tres equipos y uno solo,
base múltiple y ficha completa, identidad/contador, Undo/Redo; niveles mixtos con
regreso y vista previa, validación final de base/E40; borrado con todas las capas,
base completa y elementos ajenos conservados, contador/no-op e historial único;
cancelación/segundo dedo en ambos pinceles; cuatro segundos exactos/renovación del
aviso, posición, ausencia de SnackBar y no interceptar gestos, tres tamaños/escala.
La prueba anterior Borrar figura elige ahora explícitamente esa variante; no se
retiran sus aserciones de conservación. Las regresiones anteriores se mantienen.

Previews: se conservan los 94 anteriores y se añaden siete: ayuda vertical en
400×900, 1000×700 y 320×320 con texto al 300 %, altura durante/después de un trazo
con regreso, resultado de borrado total y figura cambiada a T2. Revisión visual de
los nuevos casos; advertencias de hit test fatales. Con altura extrema/texto grande
la ayuda puede abreviarse visualmente, pero semántica conserva el texto completo;
mapa y herramientas permiten zoom/pan. Capturas Flutter, no Android real.
Logs en build/; renders en build/previews/brush-teams/; metadatos del APK en
build/verification/brush-teams/, excluidos de Git.

## APK entregable

- `build/releases/heroclix-1.0.0-rc.6-debug.apk`, 158529325 bytes.
- SHA-256: `A3DEF9F8B32B0B1F0CCA19F8B0F117AA4BAA71E3A101A9CEA3D7A4DBF328169B`.
- Archivo archivado y salida estándar con el mismo hash; APK anteriores conservados.
- Paquete `com.valinor.heroclixtrainer`, versión 1.0.0-rc.6/código 19, SDK 24/36.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Firma debug conservada. Instalar encima, sin desinstalar, para conservar biblioteca
  y progreso. NOTICES.Z comprobado; binarios y claves fuera de Git.

## Pendientes y límites

Recorrido manual actualizado en ANDROID.md. Sigue pendiente la comprobación real
en Android de instalación, gestos, giro/texto, TalkBack, archivos, radios apagadas,
cierre/pausa de proceso y rendimiento. Se mantiene la decisión de continuar sin
teléfono. No se repite el emulador fallido ni se declara aceptación nativa a partir
de Windows. Sin claves release, no se genera release ni se promueve a estable.

No se cambian reglas de visión, movimiento, transiciones ni los formatos 1/2/3.
Las bases siguen requiriendo un único nivel; no se permite colocar sobre bloqueado.
Borrar una figura no reinicia identidades durante la sesión. El nuevo arranque
sigue vacío, 10×10 y figuras desde A; biblioteca y progreso persistentes.

README/README_FINAL, Guía/leyenda, arquitectura, decisiones, Android, hoja de ruta y
matriz de aceptación actualizados. AC29–32 añadidos. Rc.5 en ENTREGA_RC5.md.