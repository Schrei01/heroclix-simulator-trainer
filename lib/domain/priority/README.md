# Priority — motor, etapa 1

Formato personalizado de Valinor, independiente del tablero y de las reglas de
figuras. Entrada pública: `priority.dart`. `priority_engine.dart` es una parte de
esa biblioteca para mantener privados los constructores de estados válidos.
Solo se importa `dart:math`; no hay Flutter, archivos, plataforma ni reloj.

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
- END TURN restablece el consumo de **todos** a cero y conserva sus adicionales.
- Pausar preserva la fase subyacente, prioridad y pendientes; solo se permite
  reanudar o finalizar mientras está pausada. Finalizar cierra la ventana, retira
  la prioridad y deja el estado terminal; no calcula puntuaciones/resultados.
- Cada comando válido incrementa `revision` una vez, incluidos sus pases
  automáticos. Es un dato para futuros consumidores, no un mecanismo de
  deduplicación: una futura capa de aplicación deberá serializar comandos y
  proteger los toques repetidos. Repetir ACTION en un turno que ya recuperó
  prioridad puede ser una segunda acción legítima.
- Los eventos llevan jugador, turno y ronda; cambios de adicionales también
  incluyen valor anterior y nuevo. Se entregan por operación, sin mantener todavía
  historial acumulado, deshacer ni persistencia. No incluyen marcas de tiempo.

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

Pruebas: `flutter test test/domain/priority_test.dart`.
Alcance y resultados: [plan de Priority](../../../docs/PRIORITY_PLAN.md).
