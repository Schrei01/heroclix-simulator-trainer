# Estado actual — TeamFight: GridLab

2026-11-26 (America/Bogota). **1.0.0-rc.23+36**, beta candidata debug.
Rama `codex/priority-clockwise-layout`, base `6d924e5` (rc.22).
Informe anterior: [ENTREGA_RC22.md](ENTREGA_RC22.md).

## Tres jugadores, giros del dibujo y turnos horarios

- Mirando el celular de frente: 1 arriba izquierda orientado hacia la izquierda;
  2 arriba derecha orientado hacia la derecha; 3 abajo, de frente y a todo el ancho.
  Se gira cada panel completo; configuración y mesa usan los mismos giros/posiciones.
- Turnos y prioridad recorren los asientos en sentido horario. En 4–6 se conservan
  superficies y giros hacia cada lado, con la numeración horaria correspondiente.
- Arrastrar un jugador cambia también el ciclo de juego según las posiciones nuevas.
  Conserva inicial, activo/prioridad actuales y datos individuales. Reorganiza solo
  pendientes; no hace responder de nuevo a quien ya completó su oportunidad.
- Guardado y Deshacer incluyen el orden actual. Formato Priority 2 migra formato 1,
  incluyendo los checkpoints, sin reiniciar la partida ni perder PV/acciones/tiempos.
  Recuperar o deshacer mantiene los relojes pausados hasta reanudación manual.

Detalles: [PRIORITY_PLAN.md](PRIORITY_PLAN.md), [ARQUITECTURA.md](ARQUITECTURA.md)
y contrato de dominio. El Editor y Entrenador mantienen formatos y comportamiento.
Sin paquetes/permisos nuevos ni cambios del flujo de APK. La beta conserva el corte
30/12/2026 00:00 Colombia según el reloj del dispositivo. No se inicia otra etapa.

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Pruebas nuevas | 27: geometría/motor, UI/arrastre, respuestas, rondas, persistencia/undo y migración |
| Focalizadas de orden dinámico | **91/91 aprobadas**, 17 s |
| Suite general + renders finales | **1074/1074 aprobadas**, 6 min 43 s: 1046 pruebas y 28 renders |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 202 archivos Dart, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 31,8 s; copia/hash verificados, solo rc.23 |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; certificado conservado; sin INTERNET |

Las pruebas existentes de arrastre se adaptan a la petición de cambiar el ciclo
al mover paneles. Los 4000 roundtrips de snapshots ahora incluyen permutaciones.
La nueva cobertura prueba todos los pares de asientos en 2–6 y ambas ventanas;
conserva datos, prioridad en curso, respuestas completadas, rondas parciales,
eliminados, reinicio, reversión y migración de formato 1 con uno/dos intercambios.
Los renders incluyen la nueva distribución de tres en vertical/horizontal y la
vista de configuración. Las pruebas anteriores de dimensiones/texto ampliado se
reutilizan para todos los participantes.

Evidencia local: `build/verification/priority-clockwise-layout/`, con
`full-final.log`, `reseat-final.log`, `analyze-final.log`, `format-check-final.log`,
`apk-build.log`, `apk-identity.log` y `previews/`.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.23-debug.apk`, **159133671** bytes.
- SHA-256: `834A477E55BE6AB616B3ABB5545AA1E1444BD6D5132CF3FE13C0FEB1B11095E2`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 36;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Solo queda rc.23. El script retiró rc.22 tras validar la primera copia; la
  compilación definitiva reemplazó esa copia de rc.23 después de verificarla.
  No se cambió el flujo de APK ni se usó flutter clean.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Instalación/validación física,
TalkBack y rendimiento siguen pendientes. Recorrido en [ANDROID.md](ANDROID.md).
Instalar encima con la misma firma conserva biblioteca, progreso y partidas Priority.
