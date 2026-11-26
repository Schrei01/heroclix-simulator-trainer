# Estado actual — TeamFight: GridLab

2026-11-26 (America/Bogota). **1.0.0-rc.22+35**, beta candidata debug.
Rama `codex/priority-stage4`, base `d739a8e` (rc.21).
Informe anterior: [ENTREGA_RC21.md](ENTREGA_RC21.md).

## Priority etapa 4

- Historial cronológico de operaciones y consecuencias automáticas, con jugador,
  fecha/hora, ronda/turno y cambios de prioridad. No hay registros por segundo.
- Deshacer consecutivo restaura ventana, activo/prioridad, acciones, PV, eliminados,
  tiempos, pendientes de turno/ronda y posiciones visuales. Conserva auditoría de
  anulaciones y excluye operaciones deshechas del resumen.
- Guardado automático local y recuperación al abrir. Recuperar o deshacer deja
  relojes pausados hasta reanudación manual y no cobra tiempo de ausencia.
- Biblioteca de partidas en curso/finalizadas, consulta de resultados e historial,
  continuación y descarte confirmado. Crear otra partida conserva la actual;
  un fallo de guardado impide sustituirla.
- Finalización manual confirmada y resumen con clasificación/empates, estado,
  seis tipos de operación, tiempos, ronda/turno e historial.

Alcance y decisiones: [PRIORITY_PLAN.md](PRIORITY_PLAN.md) y
[PRIORITY_STAGE4.md](PRIORITY_STAGE4.md). No se inicia ninguna etapa posterior.
Sin dependencias/permisos nuevos ni cambios de reglas del motor o formatos del
Editor/Entrenador. Los límites ampliados del almacén se inyectan solo a Priority.
La beta vence el 30/12/2026 a las 00:00 Colombia, según el reloj del dispositivo.

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Motor/controladores antes del incremento | **201/201 aprobadas** |
| Regresión general de la app | **1018/1018 aprobadas**, 6 min 13 s |
| Verificación final de Priority | **263/263 aprobadas**, 29 s; motor etapas 1/3 y toda etapa 4 |
| Pruebas nuevas | **81**: 64 unitarias/aplicación, 3 archivos reales, 14 UI/ciclo de vida |
| UI y renders | **41/41 aprobadas**, 28 s; 14 pruebas UI y 27 renders |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 200 archivos, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 77,9 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

La regresión cubre las 938 pruebas anteriores más las 80 iniciales de etapa 4.
La revisión final añade un caso para nombres/IDs largos admitidos por el motor:
se retira un límite de lectura arbitrario para conservar el roundtrip, manteniendo
el límite global de tamaño. Se verifica de nuevo motor y toda la etapa 4 tras ese
cambio, sin volver a ejecutar widgets ajenos al codec.

Incluye recuperación para 2–6 jugadores, ACTION/FREE, con/sin reloj, 4000 roundtrips,
undo mixto consecutivo, eliminaciones/finalización, colas y rondas, fallos de E/S,
archivos reales/reinicio, corrupción/copia anterior/esquema futuro, callbacks
obsoletos, biblioteca/resultados, ciclo de vida y texto 300 %. Revisión visual de
historial con reversión, mesa pausada, biblioteca y resumen guardado.

Evidencia local: `build/verification/priority-stage4/`: `baseline.log`,
`full-final.log`, `priority-final.log`, `ui-renders-final.log`, `analyze-final.log`,
`format-check-final.log`, `apk-build.log`, `apk-identity.log` y `previews/`.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.22-debug.apk`, **159133899** bytes.
- SHA-256: `C829FEA77921EAF57506DFFE8A964DA8B68092F7F82491FE19CEE6977367611F`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 35;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- El script retiró rc.21 solo después de validar la compilación y la copia. No
  cambió el flujo de APK y no se utilizó flutter clean. Informes/código históricos en Git.

## Aceptación Android y datos locales

Se mantiene la decisión de continuar sin teléfono. Queda pendiente instalar y
verificar físicamente, incluyendo cierre forzado, almacenamiento Android, TalkBack
y rendimiento. Recorrido: [ANDROID.md](ANDROID.md). Las pruebas de widgets y archivos
no sustituyen la validación nativa.

Instalar encima con la misma firma conserva datos privados. Desinstalar/borrar
los datos elimina las partidas Priority; esta etapa no incorpora exportación.
La copia anterior puede recuperar un estado previo si el principal queda dañado;
se avisa al usuario para revisarlo. No se garantiza salvar una escritura que Android
no completó antes de un corte abrupto. Límites explícitos en PRIORITY_STAGE4.md.
