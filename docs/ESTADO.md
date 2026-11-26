# Estado actual — TeamFight: GridLab

2026-11-25 (America/Bogota). **1.0.0-rc.21+34**, beta candidata debug.
Rama `codex/priority-score-alignment`, base `c7fb926` (arrastre rc.20).
Informe anterior: [ENTREGA_RC20.md](ENTREGA_RC20.md).

## Alineación del total de PV

- −, PV y + comparten centro vertical. El total se centra en una superficie de
  48 unidades; el aviso temporal queda en una franja inferior independiente.
- El total no se desplaza cuando aparece o desaparece +5/+10…; no hay superposición.
  Se conservan tamaño 22/negrilla, distancia próxima y objetivos táctiles de 48.
- No cambian estado, puntos, posiciones, arrastre, relojes, controles ni motor.

Alcance: [PRIORITY_PLAN.md](PRIORITY_PLAN.md). Sin cambios en Editor/Entrenador,
dependencias, permisos ni JSON. No se inicia etapa 4 o persistencia. La beta vence
el 30/12/2026 a las 00:00 Colombia, según el reloj del dispositivo.

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Focalizadas de Priority y renders | **201/201 aprobadas**, 1 min 39 s: 178 pruebas y 23 renders |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 191 archivos, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 46,0 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Se amplía la prueba existente de PV para verificar el eje vertical, estabilidad
antes/durante/después del aviso y ausencia de superposición. Se reutilizan
controles, arrastre, estado activo, gestión, relojes, teclado, dimensiones y texto
ampliado. Revisión visual de mesas de dos/seis y acumulado temporal. La última
suite general completa fue rc.16: 908/908 aprobadas; este ajuste verifica Priority
y análisis global.

Evidencia local: `build/verification/priority-score-alignment/`, con
`targeted-final.log`, `analyze-final.log`, `format-check-final.log`,
`apk-build.log` y `previews/`.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.21-debug.apk`, **159062763** bytes.
- SHA-256: `122D8FA8C197F089CD36235423FFA0CF1CE87D5A2E9DA0556F88E79E0ED05F69`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 34;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- El script retiró rc.20 solo después de validar compilación y copia. No cambió
  el flujo de APK y no se utilizó flutter clean. Historial de código/informes en Git.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Queda pendiente instalar y
verificar físicamente. Recorrido en [ANDROID.md](ANDROID.md). Instalar encima
para conservar biblioteca/progreso.
