# Entrega histórica rc.15 — TeamFight: GridLab

Informe archivado. La candidata vigente se describe en [ESTADO.md](ESTADO.md).

2026-11-25 (America/Bogota). **1.0.0-rc.15+28**, beta candidata debug.
Rama `codex/priority-visual-refresh`, base `acf9fba` (Priority, etapa 3).
Informe anterior: [ENTREGA_RC14.md](ENTREGA_RC14.md).

## Ajuste estético de Priority

- Botones rectangulares, con esquinas de radio 6 y mínimo táctil de 48 unidades.
  Se aplica a configuración, mesa y diálogos de Priority.
- Los paneles de 3 y 4 usan la distribución de lados opuestos de 5 y 6:
  izquierda/derecha en vertical y arriba/abajo en horizontal. Se conserva el
  orden antihorario y la disposición anterior de 2, 5 y 6.
- La mesa ocupa todo el espacio bajo la barra de herramientas, sin franja de
  ronda/turno/ventana/pases. Ronda y turno siguen disponibles en clasificación
  y semántica accesible; los eventos del motor se conservan.
- Se retira el rótulo PRIORIDAD. Borde dorado, fondo y semántica identifican la
  prioridad; ACTIVO/REACTIVO siguen visibles.
- Al agotar tiempo, aviso flotante de 8 s con **Ver** para abrir gestión y reloj
  rojo a cero. No reduce la mesa ni se repite en cada refresco; corregir a positivo
  y volver a agotar genera un aviso nuevo. La partida sigue pausándose a cero.

Alcance y decisiones: [PRIORITY_PLAN.md](PRIORITY_PLAN.md).
El motor y el controlador no cambian. Se conservan cronómetros, puntos,
eliminación y finalización de etapa 3. No se inicia historial, Deshacer ni
persistencia de Priority; la partida continúa solo en memoria.

## Compatibilidad

Editor y Entrenador conservan funciones y datos. JSON de escenario 5/capas 4 no
cambia; sin nuevas dependencias/permisos. Se conserva paquete, certificado y beta
hasta el 30/12/2026 00:00 Colombia (basada en el reloj local del dispositivo).

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Suite general final | **894/894 aprobadas**, 5 min 33 s |
| Nuevas pruebas del ajuste visual | 9 aprobadas |
| Pruebas focalizadas y renders | 27/27 aprobadas, 10 s: 9 pruebas y 18 renders |
| Análisis de todo el proyecto | Sin incidencias |
| Formato de lib/test/tool | 183 archivos, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 82,5 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Las pruebas nuevas verifican distribución para 3/4, conservación de 5/6, altura
completa de mesa, roles/borde/semántica, botones en mesa y gestión, avisos con texto
300 % en 320×320, desaparición y nuevos episodios de agotamiento. Los renders
incluyen 2–6 jugadores, 3/4 en ambas orientaciones, configuración, reloj/agotamiento,
gestión, eliminación y clasificación. Revisión visual de las nuevas disposiciones
y del aviso. Las 885 pruebas anteriores cubren también Editor y Entrenador.

Logs finales en `build/verification/priority-visual/`: `full-tests-final.log`,
`visual-final.log`, `analyze-final.log`, `format-final.log`, `apk-build.log`
y `previews/`. Son pruebas de dominio/controlador/widgets y renders Flutter;
no son pruebas Android nativas.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.15-debug.apk`, **159038155** bytes.
- SHA-256: `8233884E500F2AEBD0E5ECFBE2E069B3463D634B1499850E5BF503DBC688ED95`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 28;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Instalar encima para conservar biblioteca/progreso. El script retiró rc.14
  después de validar compilación y copia; informe/código histórico en Git.
  No cambió el flujo de APK y no se utilizó flutter clean.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Widgets/renders no sustituyen
la instalación, segundo plano real, lectura/pulsación desde cada lado, TalkBack,
precisión/performance nativa y actualización con datos anteriores. Recorrido en
[ANDROID.md](ANDROID.md). Sigue candidata debug; publicación/firma de Play aparte.
