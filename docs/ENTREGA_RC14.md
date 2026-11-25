# Entrega histórica rc.14 — TeamFight: GridLab

Informe archivado. La candidata vigente se describe en [ESTADO.md](ESTADO.md).

2026-11-25 (America/Bogota). **1.0.0-rc.14+27**, beta candidata debug.
Rama `codex/priority-stage3`, base `8d13b43` (Priority, etapa 2).
Informe anterior: [ENTREGA_RC13.md](ENTREGA_RC13.md).

## Priority — etapa 3

- Relojes individuales opcionales desde configuración, 30 minutos por defecto;
  admite minutos/segundos. Solo descuenta el jugador con prioridad; transferencias
  automáticas, sin reiniciar al cambiar de turno/ronda ni cobrar pases automáticos.
- El motor recibe duraciones explícitas; el adaptador usa Stopwatch monotónico
  inyectable y refresco de 100 ms. Cobra el tiempo real antes de cada comando,
  aunque se retrase la interfaz. Los ticks normales no caducan revisiones de acción.
- Pausa/reanudación conservan fase y cola. Segundo plano o salir de Priority pausa
  los relojes; volver exige reanudación manual. El lapso fuera no se descuenta.
- A cero se avisa y pausa sin eliminar. La corrección de tiempo se confirma en un
  diálogo orientado al jugador, conserva tiempo consumido y deja pausa. Se reanuda
  tras corregir el reloj con prioridad a positivo o eliminar manualmente al agotado.
- PV visibles por jugador. Toca el nombre/tres puntos para sumar, restar o corregir
  total; se rechazan negativos/desbordamientos. El contador sigue editando acciones.
  PV y tiempos se conservan al cambiar turno/ronda y al eliminar.
- Clasificación por PV con posición compartida en empates, incluidos eliminados.
  Permite corregir PV después de finalizar sin reabrir turnos ni arrancar relojes.
- Eliminar pide confirmación y excluye de turnos/prioridad/ventanas. Si es activo,
  cierra ventana, restablece acciones y abre turno del siguiente; si es reactivo,
  sigue por los pendientes. Las rondas consideran supervivientes aún pendientes.
- Con un superviviente finaliza y abre clasificación automáticamente. No declara
  un ganador mediante supervivencia o desempates no definidos.

Alcance y decisiones: [PRIORITY_PLAN.md](PRIORITY_PLAN.md).
No se implementan historial acumulado, Deshacer ni persistencia de Priority.
La partida continúa solo en memoria; se detiene el trabajo al terminar la etapa 3.

## Compatibilidad

Editor y Entrenador conservan funciones y datos. JSON de escenario 5/capas 4 no
cambia; sin nuevas dependencias/permisos. Se conserva paquete, certificado y beta
hasta el 30/12/2026 00:00 Colombia (basada en el reloj local del dispositivo).

## Verificación

Revisión previa: **272/272 pruebas de Priority de etapas 1–2 aprobadas**.
Pruebas focalizadas de etapa 3: **96/96 aprobadas**, 43 s: 80 nuevas y 16 renders.

| Comprobación | Resultado |
| --- | --- |
| Suite general final | **885/885 aprobadas**, 5 min 20 s |
| Nuevas etapa 3 | 80: 48 dominio, 11 controlador y 21 interfaz |
| Renders revisados | 16 aprobados, incluidos reloj/agotamiento/gestión/eliminación/clasificación |
| Análisis de todo el proyecto | Sin incidencias |
| Formato de lib/test/tool | 181 archivos, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 95,6 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Se conservan las 805 pruebas anteriores, incluidos Editor/Entrenador. Los casos
nuevos verifican retardos del refresco, carga/transferencia/agotamiento, pausa en
ventanas, navegación/segundo plano, correcciones de tiempo/PV, límites y empates,
eliminación de activo/reactivo/pendientes, rondas y finalización. Doce combinaciones
adicionales prueban gestión y relojes con teclado, 2/6 participantes y texto 100/300 %.

Logs finales en `build/verification/priority-stage3/`: `full-tests-final.log`,
`targeted-final.log`, `analyze-final.log`, `apk-build.log` y `previews/`. Son pruebas
de dominio/controlador/widgets y renders Flutter; no son pruebas Android nativas.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.14-debug.apk`, **159038127 bytes**.
- SHA-256: `02F809E7BA3A24D5A2734C8640E0B5A0F685F6980B78968ED180979146BE7513`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 27;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Instalar encima para conservar biblioteca/progreso. El script retiró rc.13
  después de validar compilación y copia; informe/código histórico en Git.
  No cambió el flujo de APK y no se utilizó flutter clean.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Widgets/renders no sustituyen
la instalación, segundo plano real, lectura/pulsación desde cada lado, TalkBack,
precisión/performance nativa y actualización con datos anteriores. Recorrido en
[ANDROID.md](ANDROID.md). Sigue candidata debug; publicación/firma de Play aparte.
