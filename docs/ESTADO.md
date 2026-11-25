# Estado actual — TeamFight: GridLab

2026-11-25 (America/Bogota). **1.0.0-rc.17+30**, beta candidata debug.
Rama `codex/priority-button-spacing`, base `d11a483` (controles rápidos rc.16).
Informe anterior: [ENTREGA_RC16.md](ENTREGA_RC16.md).

## Márgenes de botones de Priority

- Mayor margen horizontal de las acciones respecto al panel: 8 unidades.
  La superficie pintada deja aire vertical y conserva un objetivo táctil de al
  menos 48 unidades con densidad estándar. Se mantienen los controles de la barra.
- «Aplicar puntos» se separa del campo anterior con 12 unidades por arriba y 4
  por abajo; relleno interior de 16 horizontal y 12 vertical.
- Ajuste solo de presentación. Se conservan reglas, puntos, relojes, eliminación,
  acumulados de PV, configuración común y distribución de rc.16.

Alcance: [PRIORITY_PLAN.md](PRIORITY_PLAN.md). No se inicia etapa 4 ni persistencia.
Editor/Entrenador, dependencias, permisos y formato JSON no cambian. La beta sigue
venciendo el 30/12/2026 a las 00:00 Colombia, según el reloj del dispositivo.

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Focalizadas de Priority y renders | **167/167 aprobadas**, 1 min 38 s: 148 pruebas y 19 renders |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 185 archivos, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 72,2 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Se reutilizan 148 pruebas existentes de configuración/interfaz/controles rápidos,
rotación, relojes, PV, eliminación y teclado, incluidos texto 300 % y dimensiones
pequeñas. Dos verifican la visibilidad de todos los controles con seis jugadores
en ambas orientaciones. Renders: 19, incluyendo mesa y gestión de puntos.
No se añaden pruebas para un cambio de márgenes. La última suite general completa
fue rc.16: 908/908 aprobadas; en este ajuste se verifica Priority y el análisis global.

Evidencia local: `build/verification/priority-spacing/`, con `targeted-final.log`,
`analyze-final.log`, `format-check-final.log`, `apk-build.log` y `previews/`.
La revisión de renders comprueba el margen visible de ACTION y la separación
entre el campo y «Aplicar puntos», conservando lectura y acceso a los controles.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.17-debug.apk`, **159051431** bytes.
- SHA-256: `DA58243C1DE2943E734045290EE4F5B344925EB8DF11DB61A5B4F8B37AB0E6CC`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 30;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- El script retiró rc.16 solo después de validar compilación y copia. No cambió
  el flujo de APK y no se utilizó flutter clean. Historial de código/informes en Git.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Queda pendiente instalar y
verificar físicamente; los renders/pruebas Flutter no sustituyen interacción
nativa, TalkBack, teclado ni actualización con datos anteriores. Recorrido en
[ANDROID.md](ANDROID.md). Instalar encima para conservar biblioteca/progreso.
