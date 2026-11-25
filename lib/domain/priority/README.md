# Priority — motor, etapas 1–3

Formato personalizado de Valinor, independiente del tablero y de las reglas de
figuras. Entrada pública: `priority.dart`. `priority_engine.dart` es una parte de
esa biblioteca para mantener privados los constructores de estados válidos.
Solo se importa `dart:math`; no hay Flutter, archivos ni acceso al reloj del sistema.
`priority_clock.dart` interpreta duraciones explícitas recibidas desde fuera.

## Contrato

- `PriorityConfiguration.players` define los asientos en sentido antihorario.
  No se ordenan por nombre ni por ID. Se requieren 2–6 IDs únicos y nombres no
  vacíos; pueden coincidir los nombres. Se recortan espacios en nombre e ID.
- Cada jugador configura puntos y acciones adicionales enteros no negativos.
  Base = `max(1, puntos ~/ 100)`; total = base + adicionales. Se admite cero
  puntos por el mínimo explícito del formato. Las acciones adicionales representan
  bonificaciones; perderlas reduce ese valor hasta cero, sin modificar la base.
  Se rechazan totales que desborden el rango entero de Dart en Android.
- El inicial es el primer asiento o un ID explícito. `randomStart` recibe un
  `Random` externo; las transiciones nunca sortean nada.
- `configure` devuelve la fase configuración, turno/ronda 0 y sin prioridad.
  `start` inicia turno/ronda 1. Una ronda termina después de que cada participante
  haya tenido un turno desde el jugador inicial, aunque no sea el primer asiento.
- `apply(snapshot, comando)` devuelve un nuevo `PriorityTransition` con partida
  y eventos inmutables. Rechaza operaciones con `PriorityException` y código
  `PriorityError`, sin modificar el estado recibido. `rejection` consulta la misma
  validación que usa `apply`.
- Solo el activo con prioridad inicia ACTION/FREE o termina turno. Solo quien
  tiene prioridad puede responder o pasar, una vez por ventana. Las respuestas
  no abren ventanas. El pase voluntario solo existe dentro de una ventana.
- En ACTION se omiten jugadores sin acciones cuando llega su oportunidad. Cada
  omisión emite `automaticPass` sin otorgarles prioridad. En FREE no se omiten.
- `pendingResponders` incluye primero al reactivo con prioridad y después a los
  pendientes en orden. No contiene al activo ni a quienes ya participaron.
- `setAdditionalActions` permite cambiar a cualquier jugador en un turno/ventana
  sin exigirle prioridad. Conserva su consumo; disponibles =
  `max(0, total - consumidas)`. Si el reactivo actual queda a cero en ACTION,
  pasa automáticamente en esa misma transición. Un pendiente futuro puede
  recuperar acciones antes de su oportunidad. Recuperarlas después del pase no
  permite volver a responder en la ventana actual.
- END TURN restablece el consumo de **todos los no eliminados** a cero y conserva
  adicionales, puntuación y tiempos. `roundPending` conserva los asientos aún
  pendientes de jugar la ronda, incluido el activo primero; eliminar participantes
  no hace que la ronda dependa del tamaño inicial de la partida.
- Pausar preserva la fase subyacente, prioridad y pendientes; solo se permite
  reanudar o finalizar el juego mientras está pausado; también admite operaciones
  administrativas de puntos, corrección del tiempo y eliminación. Finalizar cierra
  la ventana, retira prioridad y congela relojes. Los puntos pueden corregirse
  después, sin reabrir turnos ni reanudar la partida.
- Cada comando válido incrementa `revision` una vez, incluidos sus pases
  automáticos. Es un dato para futuros consumidores, no un mecanismo de
  deduplicación: `PriorityController` serializa entradas síncronas y protege los
  toques repetidos. Repetir ACTION en un turno que ya recuperó
  prioridad puede ser una segunda acción legítima.
- Los eventos llevan jugador, turno y ronda; cambios de adicionales también
  incluyen valor anterior y nuevo. Se entregan por operación, sin mantener todavía
  historial acumulado, deshacer ni persistencia. No incluyen marcas de tiempo.

## Relojes, puntos y eliminación

- `clockEnabled` es opcional y se fija al configurar; `initialTime` es positivo,
  por defecto 30 minutos. Cada jugador conserva `remainingTime` y `spentTime`.
  Los tiempos no se reinician al cambiar de turno/ronda; corregir el restante
  tampoco borra el tiempo consumido. Sin relojes, `remainingTime` es null.
- `advanceTime(match, elapsed)` carga únicamente al jugador con prioridad si el
  juego está en marcha. No cobra más que su tiempo restante. Un pase automático
  nunca le otorga prioridad al omitido y no activa su reloj.
- Actualizar tiempo normalmente no incrementa `revision` ni emite eventos. Así,
  un callback de acción no caduca por un tick visual. Llegar a cero sí incrementa
  revisión, emite `timeExpired`/`paused` y conserva la fase de respuesta. No elimina
  a nadie. Recibir prioridad con reloj a cero también pausa la partida.
- `setRemainingTime` admite cero y pausa para permitir la corrección consciente;
  reanudar requiere tiempo positivo en el jugador con prioridad. El adaptador
  cobra el lapso previo a cada comando, evitando actuar después del vencimiento.
- El adaptador usa `Stopwatch` monotónico e inyectable, con ticks de refresco de
  100 ms. Cobra el tiempo real aunque se retrase el refresco. Al salir del módulo
  o pasar a segundo plano, pausa y rebasa el ancla; volver exige reanudar manualmente.
- `adjustVictoryPoints` suma/resta; `setVictoryPoints` corrige el total. Se rechazan
  negativos y desbordamientos. Se permite corregir jugadores eliminados y una
  partida finalizada. `standings` ordena por puntos con posición compartida en los
  empates; el orden de asientos solo estabiliza la presentación, no desempata.
- `eliminate` conserva puntos/tiempos y excluye de prioridad, respuestas y turnos.
  Si se elimina al activo, termina su turno y restablece acciones para los demás;
  si era un reactivo, continúa con los pendientes. Con un superviviente, finaliza.
  No declara un ganador ni sustituye una puntuación por supervivencia.
- La confirmación de eliminación pertenece a UI. La reversión por Deshacer y el
  almacenamiento/recuperación de partidas quedan para una etapa posterior.

## Uso mínimo

```dart
import 'package:heroclix_simulator_trainer/domain/priority/priority.dart';

const engine = PriorityEngine();
var match = engine.configure(PriorityConfiguration(players: [
  PriorityPlayerConfiguration(id: 'J1', name: 'Ana', buildPoints: 300),
  PriorityPlayerConfiguration(id: 'J2', name: 'Luis', buildPoints: 300),
]));
match = engine.apply(match, const PriorityCommand.start()).match;
final transition = engine.apply(match, const PriorityCommand.action('J1'));
match = transition.match; // J1 activo; J2 con prioridad para responder o pasar.
```

Pruebas: `flutter test test/domain/priority_test.dart test/domain/priority_stage3_test.dart`.
Alcance y resultados: [plan de Priority](../../../docs/PRIORITY_PLAN.md).
