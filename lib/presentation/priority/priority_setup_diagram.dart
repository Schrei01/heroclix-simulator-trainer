import 'package:material_ui/material_ui.dart';

import 'priority_management.dart';
import 'priority_seat_drag.dart';
import 'priority_table_layout.dart';

typedef PrioritySetupSeat = ({String id, String name, Color color});

class PrioritySetupDiagram extends StatelessWidget {
  const PrioritySetupDiagram({
    required this.group,
    required this.seats,
    required this.first,
    required this.onSelect,
    required this.onSwap,
    required this.onDragStarted,
    this.preview,
    super.key,
  });
  final Object group;
  final List<PrioritySetupSeat> seats;
  final String first;
  final String? preview;
  final ValueChanged<String> onSelect;
  final void Function(String, String) onSwap;
  final VoidCallback onDragStarted;

  @override
  Widget build(BuildContext context) => Center(
    child: AspectRatio(
      aspectRatio: MediaQuery.orientationOf(context) == Orientation.portrait
          ? .75
          : 1.8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = priorityTableSeats(constraints.biggest, seats.length);
          return Stack(
            children: [
              for (var i = 0; i < seats.length; i++)
                Positioned.fromRect(
                  key: ValueKey('priority-setup-view-${seats[i].id}'),
                  rect: layout[i].bounds,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: RotatedBox(
                      quarterTurns: layout[i].quarterTurns,
                      child: PrioritySeatDropZone(
                        group: group,
                        playerId: seats[i].id,
                        onSwap: onSwap,
                        child: PrioritySeatDragSource(
                          onDragStarted: onDragStarted,
                          group: group,
                          playerId: seats[i].id,
                          name: seats[i].name,
                          color: seats[i].color,
                          quarterTurns: layout[i].quarterTurns,
                          child: Semantics(
                            button: true,
                            selected: preview == null && first == seats[i].id,
                            label:
                                '${i + 1}. ${seats[i].name}. Seleccionar para empezar.',
                            child: Material(
                              color: seats[i].color.withValues(alpha: .18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(
                                  color: (preview ?? first) == seats[i].id
                                      ? const Color(0xFFFFD878)
                                      : seats[i].color.withValues(alpha: .35),
                                  width: (preview ?? first) == seats[i].id
                                      ? 3
                                      : 1,
                                ),
                              ),
                              child: InkWell(
                                key: ValueKey(
                                  'priority-setup-select-${seats[i].id}',
                                ),
                                onTap: () => onSelect(seats[i].id),
                                borderRadius: BorderRadius.circular(4),
                                child: Center(
                                  child: ExcludeSemantics(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: SizedBox(
                                        width: 64,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${i + 1}. ${seats[i].name}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: seats[i].color,
                                              ),
                                            ),
                                            if ((preview ?? first) ==
                                                seats[i].id)
                                              Text(
                                                preview == null
                                                    ? 'INICIA'
                                                    : 'SORTEANDO',
                                                key: ValueKey(
                                                  'priority-setup-highlight-${seats[i].id}',
                                                ),
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFFFD878),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

Future<void> showPrioritySetupHelp(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => priorityRotatedDialog(
    0,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cómo preparar la mesa',
          key: const ValueKey('priority-setup-help-title'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Elige de 2 a 6 jugadores. Los puntos de construcción son comunes y las acciones adicionales se ajustan por jugador. El total de acciones aparece en cada ficha.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Los números y colores del diagrama representan los asientos en sentido horario. Toca a un jugador en el diagrama para que empiece; quedará marcado con INICIA.',
        ),
        const SizedBox(height: 12),
        const Text(
          'El dado sortea al jugador inicial: el resaltado recorre los jugadores disponibles y se detiene en el elegido. El sorteo no inicia la partida. Con animaciones reducidas la elección es inmediata.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Mantén pulsado un asiento y arrástralo sobre otro para intercambiarlos, o usa las flechas de sus fichas. Se conserva el jugador elegido para empezar. Turnos y prioridad siguen el orden horario de las posiciones.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Los cronómetros son opcionales y se configuran en minutos. Solo descuenta quien tiene prioridad. Al salir del módulo o volver de segundo plano, reanuda el reloj manualmente.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Al finalizar cualquier turno se recuperan las acciones de todos. La partida se guarda en este dispositivo para retomarla después. Recuperar o deshacer deja los relojes pausados.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Durante la partida, usa −/+ para cambiar 5 PV y la calavera para eliminar con confirmación. Toca un nombre para más opciones y el contador de acciones para cambiar adicionales.',
        ),
        const SizedBox(height: 12),
        TextButton(
          key: const ValueKey('priority-setup-help-close'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  ),
);
