# Estado actual — TeamFight: GridLab

2026-11-26 (America/Bogota). **1.0.0-rc.24+37**, beta candidata debug.
Rama `codex/priority-toolbar-actions`, base `601ce6d` (rc.23).
Informe anterior: [ENTREGA_RC23.md](ENTREGA_RC23.md).

## Deshacer y Finalizar en la barra

- Flecha curva verde para Deshacer, con acceso directo a la operación anterior.
- X dentro de un círculo rojo para Finalizar; mantiene confirmación y guardado
  del resumen. Cancelar conserva la partida; al finalizar el botón queda atenuado.
- Se habilitan según el controlador y se ocultan durante la configuración. Deshacer
  conserva la restauración completa y deja los relojes pausados.
- Clasificación general y Nueva partida pasan al menú ⋮ para mantener objetivos
  táctiles de 48×48 con Volver, reloj y los dos accesos nuevos, sin ampliar la barra.
- La confirmación de finalizar usa el diálogo desplazable común, con las acciones
  dentro del desplazamiento para pantallas pequeñas y texto al 300 %.

Solo cambia presentación; reutiliza los manejadores existentes. Motor, orden horario
por posiciones, giros de tres, relojes, puntos, historial/undo y formato Priority 2
permanecen. Sin paquetes/permisos nuevos ni cambios del flujo de APK. La beta sigue
venciendo el 30/12/2026 a las 00:00 Colombia según el reloj del dispositivo.
Detalles: [PRIORITY_PLAN.md](PRIORITY_PLAN.md).

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Nuevas pruebas de barra | **6/6 aprobadas** |
| Regresión focalizada UI + renders | **183/183 aprobadas**, 1 min 33 s: 154 pruebas y 29 renders |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 203 archivos Dart, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 70,2 s; copia/hash verificados; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Se comprueban iconos/colores, habilitación, undo real, pausa, cancelar/finalizar y
revertir final, acceso a clasificación/nueva partida sin perder el archivo anterior,
configuración sin botones y objetivos táctiles completos/no solapados con Volver y
reloj en 320×320 y 800×360, texto 100 %/300 %. Se reutilizan las pruebas de mesa,
configuración, teclado, gestión, relojes, historial, persistencia y resultados.
Los renders se amplían a 29 con una vista de la barra con Volver/reloj en 320×568.

La última regresión general completa fue rc.23: 1046 pruebas + 28 renders aprobados.
Este cambio se limita a la interfaz y se verifica con las suites de pantalla de
Priority, incluidos los controles de etapas anteriores, y análisis global.

Evidencia local: `build/verification/priority-toolbar-actions/`:
`toolbar-tests.log`, `targeted-final.log`, `analyze-final.log`,
`format-check-final.log`, `apk-build.log`, `apk-identity.log` y `previews/`.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.24-debug.apk`, **159135495** bytes.
- SHA-256: `7A10FA4B4DAC3F4305F9ED3C6B6697C79473474D9BF341023A75932A243CCD20`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 37;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Solo queda rc.24. El script retiró rc.23 después de verificar la compilación y
  la copia; no cambió el flujo de APK ni se utilizó flutter clean.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Instalación/validación física,
TalkBack y rendimiento siguen pendientes. Recorrido en [ANDROID.md](ANDROID.md).
Instalar encima con la misma firma conserva biblioteca, progreso y partidas Priority.
