# Estado actual — TeamFight: GridLab

2026-11-25 (America/Bogota). **1.0.0-rc.18+31**, beta candidata debug.
Rama `codex/priority-active-highlight`, base `668a2ef` (márgenes rc.17).
Informe anterior: [ENTREGA_RC17.md](ENTREGA_RC17.md).

## Indicador del jugador activo

- ACTIVO en negrilla, con fondo, borde, punto y brillo del color del jugador.
- Dos pulsos suaves de luz al iniciar el turno, durante 3,2 s. Después permanece
  iluminado sin animación continua. La opción de reducir animaciones conserva
  el indicador fijo, tanto al abrir como si se activa durante el pulso.
- Sigue en el dueño del turno durante las respuestas; pasa al siguiente activo
  y se retira al eliminarlo/finalizar. El borde dorado mantiene su función de
  indicar prioridad. No cambia el color identificativo del nombre.
- Componente exclusivamente visual: no modifica relojes, acciones, PV ni motor.
  Se conservan controles rápidos, distribución y márgenes de las versiones previas.

Alcance: [PRIORITY_PLAN.md](PRIORITY_PLAN.md). No se inicia etapa 4 ni persistencia.
Editor/Entrenador, dependencias, permisos y formato JSON no cambian. La beta sigue
venciendo el 30/12/2026 a las 00:00 Colombia, según el reloj del dispositivo.

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Focalizadas de Priority y renders | **172/172 aprobadas**, 1 min 34 s: 152 pruebas y 20 renders |
| Nuevas del indicador | 4 aprobadas |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 187 archivos, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 85,1 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Pruebas nuevas: negrilla/color, variación del brillo y fin de la animación sin
alterar partida; mantenimiento durante respuestas, cambio de turno, eliminación
hasta finalizar; movimiento reducido inicial y activado durante el pulso. Se
reutilizan las 148 pruebas anteriores de configuración, acciones, PV, relojes,
eliminación, teclado, texto 300 % y dimensiones; incluye visibilidad de todos los
controles con seis en ambas orientaciones. Renders revisados de brillo, mesa de
seis en horizontal y mesa de dos, con roles y borde dorado diferenciados.
La última suite general completa fue rc.16: 908/908 aprobadas; en este incremento
se verifica Priority y el análisis global.

Evidencia local: `build/verification/priority-active/`, con `targeted-final.log`,
`analyze-final.log`, `format-check-final.log`, `apk-build.log` y `previews/`.
Las animaciones terminan y no mantienen un ticker continuo en reposo.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.18-debug.apk`, **159057519** bytes.
- SHA-256: `70BDDDB1C21C9CBDFD553A901D7328943CD4A2BA188FAB2FFBAA0948E3194EAC`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 31;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- El script retiró rc.17 solo después de validar compilación y copia. No cambió
  el flujo de APK y no se utilizó flutter clean. Historial de código/informes en Git.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Queda pendiente instalar y
verificar físicamente el brillo, la preferencia de movimiento reducido, TalkBack,
fluidez, teclado y actualización con datos anteriores. Recorrido en
[ANDROID.md](ANDROID.md). Instalar encima para conservar biblioteca/progreso.
