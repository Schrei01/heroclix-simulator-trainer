# Plan de implementación — Priority

Actualización: 2026-11-25 (America/Bogota).

Referencia: contexto «Implementación del módulo HeroClix Priority», proporcionado
por el usuario, secciones 1–19, y órdenes posteriores de implementar las etapas
1, 2 y 3 por separado. No había un plan específico de Priority en el repositorio; este
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

## Etapa 3 — relojes, puntos y eliminación

Estado: **completada y verificada**. Entregable beta `1.0.0-rc.14+27`.
Rama `codex/priority-stage3`, sobre `8d13b43`.

Revisión previa: contrato del motor, adaptador, interfaz y pruebas de etapas 1–2.
**272/272 pruebas de Priority aprobadas antes de modificar el código.**

- [x] Reloj opcional desde configuración, 30 minutos por defecto, configurable
  en minutos/segundos. Sin activarlo se ocultan sus indicadores y controles.
- [x] Tiempo restante/consumido por jugador en el dominio; `advanceTime` carga
  únicamente al poseedor de prioridad y omite a quienes pasan automáticamente.
- [x] Transferencias por ACTION/FREE/respuestas/PASS/END TURN y eliminación,
  sin reiniciar relojes ni cobrar a otros jugadores.
- [x] Fuente monotónica `Stopwatch` inyectable en presentación; cobra el lapso real
  al refrescar y antes de comandos, sin acumular retrasos de ticks. Refresco 100 ms.
- [x] Pausa/reanudación conservando fase y cola. Salir del módulo, perder foco o
  pasar a segundo plano pausa; volver exige reanudación manual y no cobra el lapso
  en segundo plano. Los callbacks antiguos se rechazan al agotarse el tiempo.
- [x] Corrección manual de tiempo con confirmación; deja pausa y conserva consumo.
  A cero pausa/avisa sin eliminar. Para reanudar hay que corregir el reloj con
  prioridad a un valor positivo o eliminar manualmente al jugador.
- [x] PV manuales: suma, resta y corrección total; rechazo de negativos/overflow.
  Se conservan entre turnos/rondas y tras eliminación. También se pueden corregir
  después de finalizar sin reabrir turnos ni poner en marcha relojes.
- [x] Clasificación general derivada del motor, con posiciones compartidas en
  empates. No se declara ganador mediante supervivencia o desempates inventados.
- [x] Menú al tocar el nombre/tres puntos; eliminación con confirmación, excluye
  turnos/prioridad/respuestas y conserva puntos/tiempos. Si era activo, cierra
  ventana, restablece acciones y pasa turno; si era reactivo, continúa su cola.
- [x] Rondas mediante cola de supervivientes aún pendientes en lugar del tamaño
  inicial. Eliminar a alguien que ya jugó no vuelve a darle una oportunidad.
- [x] Con un superviviente, finaliza y abre clasificación; relojes y controles de
  juego detenidos. Se conservan todas las filas, incluidos los eliminados.
- [x] Pruebas nuevas: 48 dominio, 11 controlador y 21 interfaz (**80**); más
  **16 renders**. Ejecución focalizada final: **96/96 aprobadas**, 43 s.
- [x] Regresión general: **885/885 aprobadas**, 5 min 20 s; análisis sin incidencias
  y formato de 181 archivos Dart sin cambios pendientes.
- [x] APK compilado con el script, copia/hash/paquete/versión/SDK/firma validados;
  certificado anterior conservado y solo el último entregable en `build/releases/`.

Archivos nuevos: `priority_clock.dart` (dominio), `priority_management.dart` y
`priority_player_header.dart` (presentación), tres suites `priority_stage3_*` y
fixtures de tiempo. Se amplían modelos/motor/controlador/configuración/mesa y
se conecta ciclo de vida en `HeroClixApp`; no se añaden paquetes ni permisos.

La revisión de reloj normal no cambia la revisión de comandos ni genera eventos;
el agotamiento sí lo hace. Los eventos administrativos guardan valores anterior y
nuevo (microsegundos para tiempo). No se implementa historial acumulado, Deshacer
ni persistencia: la partida sigue viviendo en memoria hasta cerrar el proceso.

## Trabajo posterior — pendiente de nuevos prompts

No se inicia automáticamente ni se fija aquí el orden de las siguientes etapas.

- Sonidos/vibración, pantalla encendida y otras mejoras del modo mesa.
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

## Verificación de etapa 3 — 2026-11-25

| Comprobación | Resultado |
| --- | --- |
| Pruebas anteriores Priority, antes de modificar | 272/272 aprobadas |
| Nuevas de dominio / controlador / interfaz | 48 / 11 / 21: **80 aprobadas** |
| Focalizadas con renders | **96/96 aprobadas**, 43 s; 16 renders revisados |
| Suite general final | **885/885 aprobadas**, 5 min 20 s |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 181 archivos, 0 cambios pendientes |
| APK rc.14 / código 27 | Correcto, Gradle 95,6 s; copia/hash/paquete/SDK/firma v2 válidos |

Casos verificados: 2–6 jugadores, carga exclusiva y transferencia de reloj,
pausas durante ventanas, retardos de actualización, precisión de microsegundos,
agotamiento al actuar, omisiones automáticas, correcciones manuales, segundo plano
y navegación sin reanudar/cobrar automáticamente. Puntos negativos/desbordados,
correcciones después de finalizar, empates y conservación tras eliminación.
Eliminación de cada asiento en ventanas ACTION/FREE, del activo, del reactivo con
prioridad, de pendientes y de quien ya respondió; rondas con inicial desplazado,
supervivientes y finalización con un único jugador. Hasta 10000 comandos aleatorios
con invariantes, además de 12 combinaciones de gestión/reloj/teclado en pantallas
pequeñas, horizontal y texto 100/300 %. Las 805 pruebas anteriores se conservan.

Evidencia local: `build/verification/priority-stage3/`, incluyendo `baseline.log`,
`targeted-final.log`, `full-tests-final.log`, `analyze-final.log` y `previews/`.
Instalación/segundo plano/precisión/TalkBack en Android real siguen pendientes;
se mantiene la autorización de continuar sin teléfono.

APK, tamaño, SHA-256 e identidad en [ESTADO.md](ESTADO.md). Se eliminó rc.13
solo después de validar la copia; el informe anterior se conserva en Git.
No se modificó el script de APK ni se utilizó flutter clean.

**Cierre de etapa 3:** completada; se detiene el trabajo aquí. No se inicia
historial, Deshacer, persistencia ni otra función posterior sin un nuevo prompt.

## Incremento visual rc.15 — 2026-11-25

Petición posterior a la etapa 3, limitada a la presentación de Priority:

- Botones rectangulares con esquinas de radio 6 y área mínima de 48 unidades.
  Tema local aplicado a configuración, mesa y diálogos; conserva colores de la app.
- Para 3 y 4 se utiliza el esquema de lados opuestos de 5 y 6: en vertical,
  paneles a izquierda/derecha girados hacia cada participante; en horizontal,
  filas arriba/abajo. Conserva orden antihorario. No cambia la geometría de 2, 5 y 6.
- Se retira la franja superior de ronda/turno/ventana/pases automáticos. La mesa
  comienza debajo de la barra y aprovecha toda su altura. Ronda/turno siguen
  disponibles en clasificación y semántica; los eventos del motor se conservan.
- Se retira el texto PRIORIDAD. Borde dorado de 3 unidades, fondo y semántica
  accesible identifican quién tiene prioridad. ACTIVO/REACTIVO permanecen visibles.
- El agotamiento se anuncia mediante un aviso flotante de 8 segundos, con **Ver**
  para abrir gestión; se conserva reloj rojo a cero y pausa. No repite el aviso
  en cada refresco. Una corrección positiva y un nuevo agotamiento sí vuelven
  a anunciarse. El aviso no ocupa espacio permanente en la mesa.

Motor, controlador, reglas, cronómetros, puntuación y eliminación permanecen con
la implementación de etapa 3. No se inicia etapa 4 ni se añade persistencia.

Pruebas nuevas: 9, sobre orientaciones, conservación de 5/6, geometría sin franja,
roles y accesibilidad, estilos en mesa/diálogo y agotamiento con texto 300 %,
desaparición, corrección y nuevos episodios. Renders: 18, incluidos 3 y 4 en ambas
orientaciones. Evidencia local en `build/verification/priority-visual/`; resultados
finales, APK y aceptación Android pendiente en [ESTADO.md](ESTADO.md).

Resultado final: **894/894 pruebas generales aprobadas**, 5 min 33 s; focalizadas
y renders **27/27**, 10 s. Análisis completo sin incidencias y formato de 183
archivos sin cambios pendientes. Se conservan las 885 pruebas anteriores.
APK rc.15/código 28 generado mediante `./tool/build_apk.ps1`: paquete/versión/SDK,
firma v2, mismo certificado y copia/hash verificados, sin permiso INTERNET.
Solo queda rc.15 en `build/releases/`; rc.14 se retiró tras validar la nueva copia.
No se modificó el flujo de APK. Se cierra este incremento estético.
