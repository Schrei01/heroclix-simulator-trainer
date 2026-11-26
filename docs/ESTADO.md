# Estado actual — TeamFight: GridLab

2026-11-25 (America/Bogota). **1.0.0-rc.19+32**, beta candidata debug.
Rama `codex/priority-scores-ranks`, base `e03dd02` (resaltado del activo rc.18).
Informe anterior: [ENTREGA_RC18.md](ENTREGA_RC18.md).

## PV grandes y posiciones

- PV separados del contador de acciones, a tamaño 22 (antes 11), en negrilla y
  centrados entre −/+. Los cambios temporales +5/+10… siguen apareciendo debajo
  durante tres segundos desde la última pulsación, conservando su comportamiento.
- Posición por PV dentro de un círculo junto al nombre: 1 y 2 dorados por petición
  expresa, 3 bronce, del 4 en adelante verde común de la app.
- El círculo lee la clasificación del motor y actualiza con ajustes/correcciones.
  Comparte posiciones en empates y conserva eliminados; no declara ganador por
  supervivencia. El número delante del nombre sigue siendo el asiento estable.
- Cabecera de dos filas: posición/nombre/acciones/calavera y −/PV/+. En paneles muy
  estrechos se puede desplazar horizontalmente. Se reserva la altura al distribuir
  acciones y se conservan objetivos táctiles, márgenes y controles anteriores.
- Motor, relojes, estado activo y reglas permanecen sin cambios.

Alcance: [PRIORITY_PLAN.md](PRIORITY_PLAN.md). No se inicia etapa 4 ni persistencia.
Editor/Entrenador, dependencias, permisos y formato JSON no cambian. La beta sigue
venciendo el 30/12/2026 a las 00:00 Colombia, según el reloj del dispositivo.

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Focalizadas de Priority y renders | **177/177 aprobadas**, 1 min 45 s: 156 pruebas y 21 renders |
| Nuevas de PV/posición | 4 aprobadas |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 189 archivos, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 43,8 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Pruebas nuevas: forma/colores/posiciones 1–6, actualización con ±5/correcciones,
empates y eliminados, tamaño/negrilla/centrado entre botones y valor máximo de PV
con texto 300 %. Las 152 anteriores verifican dimensiones, controles, estado
activo, relojes, teclado y gestión, incluida visibilidad de todos los controles
con seis en ambas orientaciones. Revisión visual de dos/cuatro/seis y acumulado,
con captura específica de posiciones 1–6 y los tres colores solicitados.
La última suite general completa fue rc.16: 908/908 aprobadas; en este incremento
se verifica Priority y el análisis global.

Evidencia local: `build/verification/priority-scores/`, con `targeted-final.log`,
`analyze-final.log`, `format-check-final.log`, `apk-build.log` y `previews/`.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.19-debug.apk`, **159060627** bytes.
- SHA-256: `F9AD0AED9857D1963BF00A417D900DC196D40C450F34CF830FC0F50EB85D54DE`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 32;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- El script retiró rc.18 solo después de validar compilación y copia. No cambió
  el flujo de APK y no se utilizó flutter clean. Historial de código/informes en Git.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Queda pendiente instalar y
verificar físicamente legibilidad, pulsación, TalkBack, teclado y actualización
con datos anteriores. Recorrido en [ANDROID.md](ANDROID.md). Instalar encima
para conservar biblioteca/progreso.
