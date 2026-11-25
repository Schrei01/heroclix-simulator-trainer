# Entrega histórica rc.16 — TeamFight: GridLab

Informe archivado. La candidata vigente se describe en [ESTADO.md](ESTADO.md).

2026-11-25 (America/Bogota). **1.0.0-rc.16+29**, beta candidata debug.
Rama `codex/priority-quick-controls`, base `1fb7871` (ajuste visual rc.15).
Informe anterior: [ENTREGA_RC15.md](ENTREGA_RC15.md).

## Configuración y controles rápidos de Priority

- Puntos de construcción comunes: un solo campo aplica a todos los jugadores.
  Los nombres, asientos y acciones adicionales siguen siendo individuales.
- Reloj configurado y corregido solo con minutos completos. La corrección sustituye
  el tiempo restante, propone redondearlo hacia arriba y deja pausa. Admite cero
  en corrección; al iniciar se exige un tiempo positivo. La cuenta muestra segundos.
- Calavera en la cabecera para eliminar con confirmación compartida con gestión.
  Conserva PV y aplica las reglas existentes de exclusión/turnos/prioridad/final.
- −/+ en la cabecera cambian −5/+5 PV por pulsación, también para eliminados y al
  finalizar. Se impiden negativos y desbordamientos mediante el motor.
- Acumulado temporal independiente por jugador: +5, +10… o −5, −10…; cada toque
  del mismo signo acumula y reinicia el difuminado de 3 segundos. Cambiar de signo
  inicia una cuenta nueva. Al desaparecer el indicador se conserva el total de PV.
- Las pulsaciones rápidas de ajuste se cuentan todas. Las acciones de juego
  conservan su protección de doble toque y todos los comandos su validación.
- Cabecera en una fila cuando cabe, dos en paneles estrechos, controles de 48
  unidades y desplazamiento en dimensiones/textos extremos. Se ajusta altura de
  acciones para conservar visibilidad completa con seis jugadores a tamaño normal.

Se mantiene el diseño de lados opuestos, borde dorado y ACTIVO/REACTIVO de rc.15,
la gestión manual de PV/tiempo y la edición de acciones tocando su contador.
Alcance: [PRIORITY_PLAN.md](PRIORITY_PLAN.md). El dominio no cambia.
No se inicia etapa 4, historial, Deshacer ni persistencia de Priority.

## Compatibilidad

Editor y Entrenador conservan funciones y datos. JSON de escenario 5/capas 4 no
cambia; sin nuevas dependencias/permisos. Se conserva paquete, certificado y beta
hasta el 30/12/2026 00:00 Colombia (basada en el reloj local del dispositivo).

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Suite general final | **908/908 aprobadas**, 5 min 30 s |
| Nuevas pruebas | 14 de controles/configuración/distribución |
| Focalizadas finales y renders | **33/33 aprobadas**, 20 s: 14 pruebas y 19 renders |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 185 archivos, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 55,8 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Pruebas nuevas: pulsaciones rápidas reales con el bloqueo de producción,
acumulación/opacidad/reinicio a 3 s, signos e independencia, límites y edición
manual, calavera en partidas de 2–6, cancelación/reactivo con prioridad, corrección
solo en minutos y valores inválidos/cero, giro/reinicio, texto 300 % en 320×320 y
visibilidad de todos los controles para seis en vertical/horizontal sin desplazar.
Las pruebas anteriores de configuración para 2–6 y reloj se adaptan a los nuevos
campos y conservan validaciones de reglas, ciclos y consumos. Se conservan las
894 pruebas anteriores. Renders de 2–6, barras, configuración, gestión, reloj,
agotamiento, eliminados, clasificación y acumulado +15.

La revisión visual y dos pruebas específicas verifican visibilidad completa de
barra y acciones con seis jugadores en ambas orientaciones a tamaño normal.
Evidencia local en `build/verification/priority-quick/`:
`full-tests-final.log`, `quick-render-final.log`, `analyze-final.log`,
`format-check-final.log`, `apk-build.log` y `previews/`. Son pruebas Flutter y renders;
no son pruebas Android nativas.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.16-debug.apk`, **159050323** bytes.
- SHA-256: `FE8615D1A35C170D47AA6710CCE017B011A07D06D9597808A2A69D37508DC748`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 29;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Instalar encima para conservar biblioteca/progreso. El script retiró rc.15
  después de validar compilación y copia; informe/código histórico en Git.
  No cambió el flujo de APK y no se utilizó flutter clean.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Quedan pendientes instalación,
segundo plano real, lectura/pulsación desde cada lado, TalkBack y actualización con
los datos anteriores. Recorrido en [ANDROID.md](ANDROID.md). Candidata debug;
publicación/firma de Play aparte.
