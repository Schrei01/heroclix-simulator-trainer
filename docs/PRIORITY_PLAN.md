# Plan de implementación — Priority

Actualización: 2026-11-25 (America/Bogota).

Referencia: contexto «Implementación del módulo HeroClix Priority», proporcionado
por el usuario, secciones 1–19, y órdenes posteriores de implementar las etapas
1 y 2 por separado. No había un plan específico de Priority en el repositorio; este
documento registra el alcance autorizado y su seguimiento.

Priority es un asistente del formato personalizado de Valinor para partidas
físicas. Se conserva Editor/Entrenador. No interpreta poderes ni tablero.

## Etapa 1 — motor independiente

Estado: **completada y verificada**. Rama `codex/priority-engine-stage1`.

- [x] Configuración de 2–6 jugadores, nombres, IDs, puntos, base y adicionales.
- [x] Asientos antihorarios e inicial manual o sorteado con aleatoriedad inyectada.
- [x] Partida/jugadores y colecciones inmutables; construcción de estados cerrada
  al motor. Transiciones deterministas, sin Flutter ni dependencias nuevas.
- [x] Fases configuración, turno, respuesta ACTION, respuesta FREE, pausa y final.
  La pausa conserva la fase y los pendientes; no incluye cronómetros.
- [x] Turnos y rondas desde cualquier asiento inicial.
- [x] Prioridad independiente del jugador activo y cola única de respuestas.
- [x] ACTION, FREE, RESPONSE ACTION, RESPONSE FREE, PASS y END TURN.
- [x] Pase automático al llegar la oportunidad sin acciones en ventana ACTION;
  nunca en FREE. Eventos por operación para distinguir pases voluntarios/automáticos.
- [x] Restablecimiento de acciones de todos al finalizar cualquier turno.
- [x] Modificación de adicionales sin borrar consumo y con efecto persistente
  entre turnos; reevaluación de pase automático cuando corresponde.
- [x] Validación centralizada, errores tipados y rechazo sin mutar el estado.
- [x] Pruebas para 2–6 jugadores, casos límite y ejemplo obligatorio de tres.
- [x] Completar y registrar resultados de análisis y regresión.

Archivos de esta etapa:

- `lib/domain/priority/priority.dart`: configuración, modelos, comandos,
  transiciones, eventos y errores.
- `lib/domain/priority/priority_engine.dart`: máquina de estados y validaciones.
- `lib/domain/priority/README.md`: contrato, decisiones y uso de la API.
- `test/domain/priority_test.dart`: pruebas unitarias.

Decisiones explícitas: puntos y adicionales no negativos; mínimo una acción base;
se rechaza un total que desborde el entero de Dart en Android.
Nombres duplicados permitidos, identidad por ID. Una ronda comienza al volver al
asiento inicial tras un ciclo completo. Los eventos se entregan sin timestamps
ni historial acumulado. La finalización es solo un estado terminal sin resultados.

## Etapa 2 — configuración y mesa

Estado: **completada y verificada**. Entregable beta `1.0.0-rc.13+26`.
Rama `codex/priority-ui-stage2`, sobre `b9a7e6d`.

Antes de comenzar se revisó el contrato/máquina de estados y se volvieron a
ejecutar las **134 pruebas del motor: todas aprobadas**. El motor no se modifica.

- [x] Nueva tarjeta Priority desde inicio, conservando Editor y Entrenador.
- [x] Configuración de 2–6 jugadores, nombres, puntos y adicionales por jugador.
  Los valores iniciales son 300 puntos y cero adicionales. Los totales de vista
  previa proceden de `PriorityPlayerConfiguration`, sin repetir fórmulas en UI.
- [x] Organización de asientos mediante controles anterior/siguiente, numeración,
  colores y esquema de ubicación. Inicial manual o sorteado por el motor.
- [x] Mesa por cantidad/orientación: dos mitades opuestas; con 3–6 participantes,
  paneles que recorren el perímetro en sentido antihorario. `RotatedBox` gira el
  panel completo con sus controles, hit testing y semántica.
- [x] Ronda, turno, ventana actual, activo y prioridad; ambas identidades se
  muestran independientemente con texto y color.
- [x] Disponibles/totales y edición de adicionales desde el contador del panel.
  El diálogo muestra base y consumo; los cambios y pases automáticos los resuelve
  el motor. Los totales no se editan sobrescribiendo el consumo.
- [x] ACTION, FREE y END TURN en el panel activo; RESPONSE ACTION, RESPONSE FREE
  y PASS en los reactivos. Solo se habilitan comandos aceptados por el motor.
- [x] Adaptador de presentación `PriorityController`: estado en memoria propiedad
  de la app; delega comandos/validación a `PriorityEngine`. Se puede salir al
  inicio y regresar sin perder la partida durante el mismo proceso.
- [x] Comprobación de revisión para callbacks antiguos y bloqueo de 350 ms por
  operación/jugador contra pulsaciones dobles. No bloquea la respuesta de otro
  jugador y cancela sus temporizadores al reiniciar/disponer el controlador.
- [x] Nueva partida solo mediante confirmación. No se sobrescribe una en curso
  desde el método de inicio del adaptador.
- [x] Configuración desplazable y adaptación de botones al tamaño de texto;
  controles táctiles de al menos 48 unidades en los tamaños habituales. Los
  paneles permiten desplazamiento interno cuando el contenido ampliado no cabe.
- [x] Completar pruebas de interfaz/regresión, revisar renders y documentar APK.

Archivos nuevos: `lib/presentation/priority/` contiene controlador, configuración,
mesa, geometría visual y validación sintáctica de entradas. Nuevas pruebas en
`test/priority_controller_test.dart`, `test/priority_layout_test.dart`,
`test/priority_screen_test.dart` y renders en `tool/priority_preview_test.dart`.
Se actualizan el catálogo, navegación y las pruebas de modos/inicio/vencimiento.

No se implementan cronómetros, puntuación, eliminación, historial acumulado,
deshacer ni persistencia. El único temporizador es la protección de pulsaciones;
no mide ni administra el tiempo de juego. La partida de esta etapa vive en memoria.

## Trabajo posterior — pendiente de nuevos prompts

No se inicia automáticamente ni se fija aquí el orden de las siguientes etapas.

- Sonidos/vibración, pantalla encendida y otras mejoras del modo mesa.
- Cronómetros, ciclo de vida y agotamiento de tiempo.
- Puntuación, eliminación y clasificación/resultados.
- Historial acumulado, deshacer, persistencia, recuperación y consulta local.
- Integración, pruebas de interfaz y verificación Android/APK.

No se modifican navegación, versión, formatos del editor ni flujo de APK en la
etapa 1. No se genera APK: el motor todavía no tiene una entrada en la interfaz.

## Verificación de etapa 1 — 2026-11-25

| Comprobación | Resultado |
| --- | --- |
| Pruebas unitarias finales de Priority | **134/134 aprobadas**, 1 s de ejecución |
| Regresión general de la app | **666/666 aprobadas**, 5 min 2 s; incluye las 533 pruebas existentes |
| Análisis de todo el proyecto (`dart analyze`) | Sin incidencias |
| Formato de los tres archivos Dart de esta etapa | 0 cambios pendientes |
| Secuencia obligatoria ejecutada directamente con Dart VM | Aprobada sin Flutter |
| `git diff --check` | Sin errores |

La suite general incluyó 133 pruebas de Priority. La ejecución final específica
aprobó 134, incluyendo el caso de desbordamiento añadido durante la revisión.
Los últimos cambios de código están limitados al motor aislado y quedan cubiertos
por esa ejecución final; no se han modificado las funciones existentes.

Cobertura de comportamiento:

- 2–6 participantes, cada asiento como inicial, tres rondas completas por asiento,
  y orden de asientos deliberadamente distinto del orden de sus IDs.
- 726 combinaciones de reactivos con/sin acciones, pase y respuesta entre ACTION
  y FREE; consumo, orden, cierre de ventana y restablecimiento global verificados.
- 7500 comandos reproducibles válidos e inválidos, comprobando invariantes,
  determinismo y conservación del estado original.
- Matriz explícita de permisos por fase y actor; inicio repetido, jugador ajeno,
  tipo de respuesta incorrecto, falta de prioridad/acciones, respuesta repetida,
  ventanas encadenadas, fin de turno pendiente, pausa y estado terminal.
- Configuración inválida, límites de puntos, IDs duplicados/normalizados,
  colecciones inmutables y desbordamiento de enteros.
- Cambios dinámicos antes/durante una ventana; pérdida/recuperación de acciones,
  mínimo cero disponible sin borrar consumo y pases automáticos al corresponder.

**Ejemplo obligatorio aprobado:** J1 ACTION → J2 RESPONSE ACTION → J3 PASS →
prioridad J1 → END TURN: todos recuperan 3 acciones y J2 queda activo/con prioridad.
Su siguiente ACTION abre respuestas J3 → J1 y finalmente devuelve prioridad a J2.

Comandos reproducibles con dependencias instaladas:

```powershell
flutter --no-version-check test --no-pub --reporter expanded
flutter --no-version-check test --no-pub test/domain/priority_test.dart --reporter expanded
dart analyze
dart format --output=none --set-exit-if-changed lib/domain/priority test/domain/priority_test.dart
```

Logs locales en `build/verification/priority-stage1/`: `tests.log`,
`priority-final.log`, `analyze.log` y comprobación `standalone.dart` para Dart VM.
Son evidencia técnica ignorada por Git, no persistencia de partidas.

**Cierre de etapa 1:** se detuvo el trabajo tras entregar el motor, sin iniciar
funciones pendientes ni generar APK en esa etapa.

## Verificación de etapa 2 — 2026-11-25

| Comprobación | Resultado final |
| --- | --- |
| Motor antes de comenzar la implementación | 134/134 aprobadas |
| Suite general final | **805/805 aprobadas**, 9 min 7 s |
| Pruebas nuevas etapa 2 | **138**, incluidas en la suite general: 8 controlador, 26 geometría y 104 interfaz |
| Análisis de todo el proyecto | Sin incidencias |
| Formato de lib/test/tool | 174 archivos, 0 cambios |
| Renders y casos finales de teclado | 11/11 aprobados: 8 renders revisados y 3 casos de teclado |
| APK debug rc.13 / código 26 | Compilado, copia/hash/firma/paquete/SDK validados |

Las 104 pruebas de pantalla cubren configuración para cada cantidad de jugadores,
el ejemplo obligatorio, consumo y edición, FREE sin acciones, pases automáticos,
inicial manual/sorteado, orden antihorario, reducción de participantes, entradas
inválidas/desbordamiento, ida/vuelta por Editor sin perder partida, confirmación
de nueva partida y giro durante una ventana. Incluyen 90 combinaciones de
2–6 participantes, seis tamaños y texto 100/200/300 %, y tres casos con teclado
simulado y texto 300 %. Se verifican controles de al menos 48 unidades con texto
normal; los tamaños extremos pueden requerir desplazamiento dentro del panel.

Decisiones de presentación verificadas: la distribución sigue la orientación del
dispositivo, igual que el esquema de asientos; la mesa permanece estable detrás
del diálogo de edición cuando se abre el teclado; etiquetas con tipografía de la
app y tres botones por papel evitan desplazar las operaciones habituales en los
renders de teléfono normales, incluido el de seis jugadores en horizontal.

Comandos y evidencia:

```powershell
flutter --no-version-check test --no-pub --reporter expanded
flutter --no-version-check test --no-pub tool/priority_preview_test.dart --reporter expanded
dart analyze
dart format --output=none --set-exit-if-changed lib test tool
./tool/build_apk.ps1
```

Logs/imágenes locales en `build/verification/priority-stage2/`. Identidad,
SHA-256, tamaño del entregable y aceptación nativa pendiente en
[ESTADO.md](ESTADO.md). Solo queda el nuevo APK en `build/releases/`; los anteriores
se retiraron después de validar la copia. No se cambió el script de APK.

**Cierre de etapa 2:** se detiene el trabajo aquí. Cronómetros, puntuación,
historial/persistencia y demás funciones pendientes requieren un nuevo prompt.
