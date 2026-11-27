# Estado actual — TeamFight: GridLab

2026-11-27 (America/Bogota). **1.0.0-rc.26+39**, beta candidata debug.
Rama `codex/priority-finish-setup`, base `9ecd325` (rc.25).
Informe anterior: [ENTREGA_RC25.md](ENTREGA_RC25.md).

## Finalizar vuelve a Preparar mesa

- Confirmar Finalizar desde X roja o menú guarda y archiva la partida, vuelve a
  Preparar mesa y no abre el resumen. Cancelar conserva el juego.
- Los resultados e historial siguen disponibles en Partidas guardadas → Consultar,
  también después de reiniciar la app.
- La partida actual solo se limpia después del guardado. Si falla, permanece
  terminada y abierta con Reintentar y volver; no se pierden puntos/tiempos.
- Deshacer durante ese fallo restaura el juego pausado y cancela el retorno pendiente.
- La marca de cierre manual evita que los avisos del reloj disparen la clasificación
  entre finalizar y archivar. El cierre automático por eliminación conserva su flujo.

Sin cambios de motor/repositorio/formato, Editor o Entrenador, paquetes, permisos ni
flujo de APK. Se conservan los campos de Preparar mesa como al crear Nueva partida.
La beta mantiene el corte 30/12/2026 00:00 Colombia según el reloj del dispositivo.
Detalles: [PRIORITY_PLAN.md](PRIORITY_PLAN.md).

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Pruebas nuevas | 5 de cierre, reloj, persistencia/reinicio, fallos y reversión |
| Primera ejecución de cierre/toolbar/historial | **25/25 aprobadas**, 33 s |
| Regresión focalizada final + renders | **265/265 aprobadas**, 3 min 2 s: 231 pruebas y 34 renders |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 206 archivos Dart, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 86,2 s; copia/hash verificados; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Se prueban cierre desde barra y menú, cancelación, ausencia del resumen, retorno a
configuración, archivo/resultados/historial consultables, tiempo detenido y lectura
después de reinicio. Se provocan fallos de escritura general, archivo de partida y
working: la partida se conserva y el reintento completa el retorno. Se verifica
Deshacer después del fallo y los cierres automáticos de etapas previas. Se reutilizan
pantallas, configuración/sorteo, arrastre, geometría, acciones, PV, relojes y biblioteca.
Dos nuevos renders muestran Preparar mesa tras confirmar y la consulta posterior.

La última regresión general completa sigue siendo rc.23: 1046 pruebas y 28 renders.
Este cambio verifica la interfaz y el flujo de archivo reutilizado mediante pruebas
focalizadas y análisis global.

Evidencia local: `build/verification/priority-finish-setup/`: `finish-first.log`,
`targeted-final.log`, `analyze-final.log`, `format-check-final.log`, `apk-build.log`,
`apk-identity.log` y `previews/`.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.26-debug.apk`, **159150967** bytes.
- SHA-256: `5D73F6CF0DEC4F13FA378D06A674AAC0D05E54C8EE1962D09F2797CE596DBC24`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 39;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Solo queda rc.26. El script retiró rc.25 después de verificar la compilación y
  la copia; no cambió el flujo de APK ni se utilizó flutter clean.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Instalación/validación física,
TalkBack y rendimiento siguen pendientes. Recorrido en [ANDROID.md](ANDROID.md).
Instalar encima con la misma firma conserva biblioteca, progreso y partidas Priority.
