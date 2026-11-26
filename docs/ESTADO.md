# Estado actual — TeamFight: GridLab

2026-11-25 (America/Bogota). **1.0.0-rc.13+26**, beta candidata debug.
Rama `codex/priority-ui-stage2`, base `b9a7e6d` (motor Priority, etapa 1).
Informe anterior: [ENTREGA_RC12.md](ENTREGA_RC12.md).

## Priority — etapa 2

- Inicio ofrece Editor, Entrenador y Priority. El nuevo módulo configura de 2 a 6
  participantes, nombres, puntos y acciones adicionales. Los asientos se ordenan
  en sentido antihorario con flechas; esquema de ubicación e inicial manual/sorteado.
- La mesa distribuye paneles según participantes y orientación del dispositivo,
  en el mismo orden del motor. Cada panel completo gira hacia su lado, incluidos
  controles y edición de acciones. Dos jugadores tienen mitades opuestas.
- Estado global de ronda, turno, activo, prioridad y tipo de respuesta. El activo
  y quien tiene prioridad se identifican por separado con texto y color.
- ACTION/FREE/END TURN en el activo; RESPONSE ACTION/RESPONSE FREE/PASS en reactivos.
  Habilitación y resultados se delegan al motor de etapa 1, que no se modifica.
- El contador disponibles/totales abre edición de adicionales, con base y consumo
  visibles. El motor conserva el consumo, aplica pases automáticos y restablece
  las acciones de todos en END TURN. Los pases automáticos se anuncian en la mesa.
- El controlador vive en HeroClixApp: volver a inicio, usar Editor y regresar
  conserva la partida durante el mismo proceso. Nueva partida pide confirmación.
  No se añade persistencia ni se alteran los formatos del editor/entrenador.
- Comandos con revisión antigua se descartan; bloqueo de 350 ms por operación y
  jugador evita pulsaciones dobles, incluso tras pases automáticos inmediatos,
  sin bloquear respuestas de otras personas. Los temporizadores son de entrada,
  no cronómetros de juego, y se cancelan al reiniciar/disponer.
- Botones de al menos 48 unidades en la matriz de tamaños de texto normal.
  Distribución y columnas se adaptan al texto; se puede desplazar un panel si
  el contenido ampliado no cabe. Configuración y diálogos admiten teclado/scroll.

Alcance, archivos y decisiones: [PRIORITY_PLAN.md](PRIORITY_PLAN.md).
No se implementan cronómetros, puntuación, eliminación, historial acumulado,
deshacer ni guardado de partidas Priority. No se inicia la siguiente etapa.

## Compatibilidad

Editor y Entrenador mantienen sus funcionalidades, datos y motores. Se conserva
JSON de escenario 5/capas 4, biblioteca/progreso, paquete y firma. Continúa offline,
sin nuevas dependencias ni permisos. Beta hasta el 30/12/2026 00:00 Colombia,
basada en reloj local. Funciones de rc.12 documentadas en el informe archivado.

## Verificación

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0, Windows.

| Comprobación | Resultado |
| --- | --- |
| Motor antes de iniciar la etapa | **134/134 aprobadas** |
| Suite completa final | **805/805 aprobadas**, 9 min 7 s |
| Análisis de todo el proyecto | Sin incidencias |
| Formato lib/test/tool | 174 archivos, 0 cambios pendientes |
| Renders Priority + casos finales de teclado | **11/11 aprobados**, 13 s; 8 imágenes revisadas |
| ./tool/build_apk.ps1 | Correcto, Gradle 426 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete, versión, SDK y firma v2 válidos; mismo certificado, sin INTERNET |

Las 138 pruebas nuevas de etapa 2 (8 controlador, 26 geometría, 104 interfaz)
se suman a las 134 del motor Priority y las 533 existentes. Incluyen el ejemplo
obligatorio desde botones, FREE a cero, cambio de adicionales con consumo/pase,
inicial manual/sorteado, reordenación y reducción de jugadores, validación de
entradas, protección de pulsaciones/revisiones y confirmación de nueva partida.

La matriz de mesa cubre 2–6 participantes en seis tamaños de pantalla con texto
100/200/300 %. Tres casos adicionales simulan teclado con insets de 140 unidades
y texto 300 %, incluidos 320×320 y horizontal. La mesa conserva su tamaño detrás
del diálogo, que gestiona sus propios insets. El giro no reinicia la partida ni
la ventana de respuesta; se verifica salir a Editor y regresar a Priority.

Evidencia local en `build/verification/priority-stage2/`: `full-tests-final.log`,
`analyze-final.log`, `keyboard-previews-final.log`, `apk-build.log` y `previews/`.
Los renders muestran configuración y mesas para 2–6 jugadores, horizontal y compacto.
No son pruebas de un dispositivo Android.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.13-debug.apk`, **159004795 bytes**.
- SHA-256: `C2DF0413902C12838277BCDCBB3253DCAB1364FFE38F5D975075B89BF19FDE29`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 26;
  SDK mínimo 24, objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Instalar encima para conservar biblioteca/progreso. Se eliminó rc.12 solo
  después de validar la compilación y la copia; código e informe histórico quedan
  en Git. No se cambió el flujo de APK ni se usó flutter clean.

## Aceptación Android

Se mantiene la decisión del usuario de continuar sin teléfono. La revisión
automatizada de widgets/renders no sustituye la instalación, gestos desde cada
lado de una mesa, teclado, giro/TalkBack, rendimiento y actualización nativa.
Recorrido de aceptación ampliado en [ANDROID.md](ANDROID.md). Sigue candidata
debug; la firma/publicación de Google Play se prepara en otro incremento.
