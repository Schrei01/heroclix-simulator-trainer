# Plan de implementación — Priority

Actualización: 2026-11-26 (America/Bogota).

Referencia: contexto «Implementación del módulo HeroClix Priority», proporcionado
por el usuario, secciones 1–19, y órdenes posteriores de implementar las etapas
1, 2, 3 y 4 por separado. No había un plan específico de Priority en el repositorio; este
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
- Verificación manual en Android real y aceptación de rendimiento/accesibilidad.

Historial, Deshacer, persistencia, recuperación y consulta local corresponden a
la etapa 4 descrita al final. No se inicia una etapa posterior.

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

## Controles rápidos y configuración común rc.16 — 2026-11-25

Incremento posterior autorizado, sin iniciar la etapa 4:

- Un único campo de puntos de construcción aplica a todos los jugadores; nombres,
  asientos y acciones adicionales siguen siendo individuales. El motor recibe
  las configuraciones habituales y mantiene el cálculo de acciones base.
- Configuración inicial y corrección de reloj solo recogen minutos completos.
  La corrección reemplaza el tiempo restante y deja pausa; propone redondearlo
  hacia arriba. Se permite corregir a cero. La cuenta conserva segundos y precisión.
- Calavera vectorial en la cabecera del jugador: comparte confirmación y comando
  de eliminación con gestión, conservando PV y reglas de turnos/prioridad/final.
- Botones −/+ en la misma cabecera envían ajustes de −5/+5 PV al motor. La resta
  se deshabilita si produciría negativos; se respeta el límite de enteros del motor.
  Se permite editar PV de eliminados y después de finalizar, igual que en gestión.
- Cada jugador mantiene un indicador temporal independiente (+5, +10… o −5, −10…)
  que se difumina durante 3 s desde la última pulsación. Cada toque del mismo signo
  acumula y reinicia la animación; cambiar de signo inicia otra cuenta. Al cumplirse
  los 3 s se elimina el indicador, conservando el total permanente. Giro no cambia
  de dueño el acumulado; reiniciar partida lo limpia.
- El controlador permite todos los toques de ajuste de PV sin el bloqueo de
  350 ms; conserva validaciones/revisiones y la protección de las acciones de juego.
- Cabecera de una fila cuando cabe y dos filas en paneles estrechos; controles
  táctiles de 48 unidades y desplazamiento para dimensiones/textos extremos.
  Se ajusta el umbral de tres columnas de acciones para dejar sitio a la cabecera.

Se conservan las funciones de gestión manual y edición de acciones tocando el
contador. No cambia el dominio ni la persistencia. Pruebas nuevas: 14 casos de
pulsaciones rápidas, acumulación/difuminado/reinicio, independencia/signos/límites,
eliminación con confirmación para 2–6, cancelación y reactivo, corrección de minutos,
giro/reinicio, controles con texto 300 % en 320×320 y visibilidad completa de barra/acciones para seis jugadores en ambas orientaciones. Las pruebas anteriores de
configuración/reloj se adaptan a los nuevos campos y mantienen sus comprobaciones.
Renders ampliados a 19 con el acumulado +15. Evidencia local en
`build/verification/priority-quick/`; resultados y APK en [ESTADO.md](ESTADO.md).

Verificación final: **908/908 pruebas generales aprobadas**, 5 min 30 s;
controles rápidos y renders **33/33 aprobados**, 20 s (14 pruebas y 19 renders).
Análisis completo sin incidencias; formato de 185 archivos sin cambios pendientes.
Se conservan las 894 pruebas anteriores, con los formularios adaptados al requisito.
APK rc.16/código 29 generado mediante `./tool/build_apk.ps1`: paquete, versión,
SDK, firma v2, mismo certificado y copia/hash verificados, sin permiso INTERNET.
Solo queda rc.16 en `build/releases/`; rc.15 se retiró tras validar la nueva copia.
No cambió el flujo de APK. Se cierra este incremento; la aceptación nativa sigue
pendiente y se conserva la decisión de continuar sin teléfono.

## Márgenes de botones rc.17 — 2026-11-25

Ajuste visual solicitado: margen horizontal de 8 unidades en el panel de cada
jugador. La superficie pintada de las acciones deja aire vertical dentro de su
objetivo táctil de al menos 48 unidades; se conserva la densidad estándar y el
objetivo padded para no perder espacio en mesas de seis. No cambia la cabecera.
«Aplicar puntos» incorpora separación superior de 12 e inferior de 4 unidades,
con relleno interior de 16 horizontal y 12 vertical. No cambian comandos/reglas.
Se reutilizan las pruebas existentes de interacción, dimensiones y teclado,
además de los 19 renders, sin añadir pruebas que repitan valores de estilo.
Resultados, APK y aceptación nativa en [ESTADO.md](ESTADO.md).

Verificación final: **167/167 aprobadas**, 1 min 38 s (148 pruebas existentes y
19 renders). Análisis global sin incidencias; 185 archivos con formato correcto.
Revisión visual de márgenes de la mesa y diálogo, incluyendo seis en horizontal.
APK rc.17/código 30 validado: paquete, versión, SDK, firma v2 y mismo certificado,
sin INTERNET. Se conserva solo rc.17 tras validar la copia y retirar rc.16 mediante
el script habitual; no se modificó ese flujo. Incremento cerrado.

## Resaltado del activo rc.18 — 2026-11-25

ACTIVO pasa a una etiqueta en negrilla con fondo, borde, punto y brillo del color
del asiento. Un componente de presentación independiente anima dos pulsos suaves
al iniciar cada turno (3,2 s) y conserva después el resaltado fijo, sin animación
perpetua. La preferencia de movimiento reducido detiene los pulsos y mantiene el
resaltado. No modifica la prioridad, los controles, relojes ni el motor.

El indicador permanece en el dueño del turno mientras responden los demás,
cambia al siguiente activo y desaparece al eliminarlo o finalizar la partida.
El borde dorado de prioridad se conserva. Cuatro pruebas nuevas verifican negrilla,
color/brillo finito sin alterar partida, transiciones de turno/eliminación/final,
movimiento reducido inicial y activado durante el pulso. Se reutilizan los casos
de dimensiones, teclado y visibilidad; los renders se amplían a 20 con una captura
del brillo en su punto alto. Evidencia en `build/verification/priority-active/`;
resultados y APK en [ESTADO.md](ESTADO.md). No se inicia la etapa 4.

Verificación final: **172/172 aprobadas**, 1 min 34 s (152 pruebas y 20 renders).
Análisis global sin incidencias; 187 archivos con formato correcto. El indicador
mantiene los controles visibles con seis y termina su animación al quedar en reposo.
APK rc.18/código 31 validado: paquete, versión, SDK, firma v2 y mismo certificado,
sin INTERNET. Solo se conserva rc.18 después de validar la copia y retirar rc.17
con el script habitual, sin modificarlo. Incremento cerrado; aceptación nativa
pendiente, manteniendo la decisión de continuar sin teléfono.


## PV centrados y posiciones rc.19 — 2026-11-25

El total de PV se separa del contador de acciones y se muestra centrado entre
−/+ a tamaño 22 (antes 11), en negrilla. Su acumulado temporal sigue apareciendo
debajo y se conserva el comportamiento de tres segundos. La cabecera utiliza
dos filas: posición/nombre/acciones/calavera y −/PV/+, con desplazamiento horizontal
para paneles muy estrechos. Se reserva su altura al calcular los botones de acción.

La posición aparece dentro de un círculo junto al nombre: 1 y 2 dorados por
petición expresa, 3 bronce y del 4 en adelante el verde común de la app.
Se lee `match.standings`, sin duplicar reglas: actualiza por PV, comparte posiciones
en empates y conserva a eliminados. El número de asiento delante del nombre sigue
siendo estable; el del círculo es la posición por PV. No declara un ganador por
supervivencia ni modifica el motor.

Cuatro pruebas nuevas verifican colores/forma/posiciones 1–6, actualización por
±5/corrección/empates/eliminación, tamaño/negrilla/centrado y valores máximos con
texto 300 %. Se reutilizan las pruebas de controles, dimensiones, estado activo,
relojes y gestión. Renders ampliados a 21 con clasificación de los seis jugadores.
Evidencia en `build/verification/priority-scores/`; resultados y APK en
[ESTADO.md](ESTADO.md). No se inicia la etapa 4.

Verificación final rc.19: **177/177 aprobadas**, 1 min 45 s (156 pruebas y 21
renders). Análisis global sin incidencias; 189 archivos con formato correcto.
PV y controles permanecen visibles con seis en ambas orientaciones a tamaño normal.
APK rc.19/código 32 validado: paquete, versión, SDK, firma v2 y mismo certificado,
sin INTERNET. Se conserva únicamente rc.19 tras validar la copia y retirar rc.18
con el script habitual, sin modificarlo. Incremento cerrado; aceptación nativa
pendiente, manteniendo la decisión de continuar sin teléfono.

## PV próximos y arrastre de asientos rc.20 — 2026-11-25

El grupo −/PV/+ se limita a 208 unidades centradas para acercar los botones al
total, conservando objetivos táctiles de 48 y tamaño/negrilla de los PV.

Se añade arrastre por pulsación mantenida: desde una celda de la vista de asientos
en configuración, y desde el nombre durante la partida. Soltar sobre otro jugador
intercambia las dos posiciones; soltar fuera cancela. Un borde temporal marca el
destino y una tarjeta sigue el dedo. El toque corto conserva la gestión del nombre.

En configuración se intercambian los borradores y se conserva el ID seleccionado
para iniciar; la vista muestra nombres e INICIA. El orden configurado resultante
define los asientos al crear la partida. Durante la partida se intercambian solo
vistas, usando una permutación inmutable de IDs en el controlador: conserva inicial,
orden de juego, cola, revisión, eventos, identidad/color, puntos, acciones y relojes.
No se pausa ni se transfiere el reloj por mover una vista. Se conserva al salir/
volver y se limpia con una nueva partida. El aviso de tiempo agotado consulta la
posición/orientación actual al abrir gestión. No cambia el dominio.

22 pruebas nuevas: todos los pares en partidas 2–6, sesión/IDs/primer plano/estado
inmutable, ejemplo obligatorio y reloj; arrastre real 2–6 en ambas orientaciones,
inicial distinto del primer asiento en configuración, cancelación, reapertura y
orientación desde el aviso del reloj. Se reutilizan pruebas de controlador,
geometría, interfaz y gestión. Renders ampliados a 23, incluidos intercambio y
arrastre en curso. Evidencia en `build/verification/priority-seat-drag/`; resultados
y APK en [ESTADO.md](ESTADO.md). No se inicia etapa 4 ni persistencia.

Verificación final: **246/246 aprobadas**, 1 min 31 s (223 pruebas y 23 renders),
con las 22 nuevas incluidas. Análisis global sin incidencias; 191 archivos con
formato correcto. Revisión visual del grupo de PV próximo y del arrastre/destino.
APK rc.20/código 33 validado: paquete, versión, SDK, firma v2 y mismo certificado,
sin INTERNET. Se conserva únicamente rc.20 tras validar la copia y retirar rc.19
con el script habitual, sin modificarlo. Incremento cerrado; aceptación nativa
pendiente, manteniendo la decisión de continuar sin teléfono.

## Alineación de PV rc.21 — 2026-11-25

Se corrige el desplazamiento vertical causado por reservar el acumulado como
otra línea bajo el total. El total queda en el centro de una superficie de 48
unidades, alineado con los centros de −/+. El cambio temporal se pinta en una
franja inferior independiente, sin participar en el centrado ni superponerse.
Se conservan tamaño 22/negrilla, separación próxima, objetivos táctiles y estado.

La prueba existente de PV amplía sus comprobaciones al eje vertical, a la
alineación durante el aviso y tras desaparecer, y a la ausencia de superposición.
Se reutilizan las pruebas de controles, arrastre, estado activo, gestión, teclado,
dimensiones y renders. Resultados y APK en [ESTADO.md](ESTADO.md).

Verificación final: **201/201 aprobadas**, 1 min 39 s (178 pruebas y 23 renders).
Análisis completo sin incidencias y 191 archivos con formato correcto. Revisión
visual de la alineación con dos/seis jugadores y durante el aviso temporal.
APK rc.21/código 34 validado: paquete, versión, SDK, firma v2 y mismo certificado,
sin INTERNET. Solo queda rc.21 tras validar la copia y retirar rc.20 mediante el
script habitual, sin modificarlo. Corrección cerrada; aceptación nativa pendiente.

## Etapa 4 — historial, Deshacer y persistencia (rc.22)

2026-11-26. Rama `codex/priority-stage4`, base `d739a8e` (rc.21).
Estado: **completada y verificada**. Entregable beta `1.0.0-rc.22+35`.

Antes de implementar se revisaron motor/controladores y se ejecutaron **201/201
pruebas de etapas anteriores**, todas aprobadas. No se cambian reglas de juego,
consumos, ciclos ni distribución de la mesa.

- [x] Historial cronológico por operación con timestamp, actor, ronda/turno y todos
  los eventos: ACTION/FREE/respuestas/pases, turnos, prioridad, adicionales, PV,
  correcciones/pausas/agotamiento de tiempo, eliminación y finalización.
- [x] Deshacer consecutivo mediante checkpoints completos e inmutables. Restaura
  ambos ciclos pendientes, ventana, activo/prioridad, acciones, eliminados, PV,
  tiempos y asientos; aumenta revisión y limpia callbacks/toques pendientes.
- [x] Relojes pausados tras Deshacer/recuperar, sin cobrar tiempo de ausencia.
  Pausa/reanudación y eventos automáticos de reloj son auditables pero no añaden
  pasos a la pila; inicio tampoco. El historial marca anulaciones sin borrarlas.
- [x] Guardado automático local, cola de escrituras y checkpoints de reloj cada
  segundo sin eventos por tick. Archivos privados Priority separados de los demás
  módulos, escritura atómica y copia anterior válida para corrupción/interrupción.
- [x] Recuperación automática al arrancar y biblioteca para continuar otra partida
  guardada. Nueva partida/cambio conserva la actual antes de sustituirla. Un fallo
  de guardado impide el reemplazo; error de lectura no sobrescribe datos desconocidos.
- [x] Confirmaciones para nueva/finalizar/descartar. No se borra la partida abierta.
- [x] Resumen final y consulta local de partidas finalizadas: clasificación con
  empates, estado, seis tipos de operaciones, tiempo consumido, rondas, turnos e
  historial. No inventa desempates ni ganador por supervivencia.
- [x] Sin Internet, dependencias o permisos nuevos. Límites y formato propios;
  formatos de escenarios/progreso conservados.
- [x] 81 pruebas nuevas: 64 unitarias/de aplicación, 3 integración con archivos
  reales y 14 interfaz/ciclo de vida. Recuperación 2–6 × ACTION/FREE × con/sin reloj,
  4000 roundtrips, undo mixto consecutivo, errores/corrupción/versiones futuras,
  copia válida, biblioteca, resultados, callbacks antiguos y texto 300 %.
- [x] Renders ampliados a 27 y revisión visual de historial, undo pausado, biblioteca
  y resultados guardados. Ejecución UI/renders: **41/41 aprobadas**, 28 s.
- [x] Regresión general: **1018/1018 aprobadas**, 6 min 13 s. Tras añadir el caso
  de nombres/IDs largos admitidos por el motor y retirar el límite arbitrario de
  lectura, verificación final del motor y toda la etapa 4: **263/263 aprobadas**, 29 s.
  Análisis completo sin incidencias; 200 archivos Dart con formato correcto.
- [x] APK generado con `./tool/build_apk.ps1`, Gradle 77,9 s; paquete/versión/SDK,
  firma v2, certificado anterior y copia/hash verificados, sin INTERNET. Solo queda
  rc.22 en `build/releases/`: el script retiró rc.21 después de validar la copia.
  No cambió el flujo de APK ni se utilizó flutter clean.

Archivos: `domain/priority/priority_snapshot.dart` (codec puro),
`application/priority/` (sesión, historial, checkpoints, codec y repositorio),
`priority_history.dart` (historial/biblioteca/resultados); adaptación del controlador,
composición en main y ciclo de vida. El almacenamiento existente admite límites
inyectados solo para Priority, preservando los predeterminados de los otros módulos.

Contrato, límites y recuperación de copia anterior: [PRIORITY_STAGE4.md](PRIORITY_STAGE4.md).
Resultados definitivos de pruebas/APK y aceptación Android: [ESTADO.md](ESTADO.md).
No se inicia ninguna función posterior a etapa 4.

## Tres jugadores, circulación horaria y arrastre rc.23 — 2026-11-26

Rama `codex/priority-clockwise-layout`, base `6d924e5` (rc.22).
Solicitud: reproducir los giros del dibujo mirando el celular de frente. Se aplica
arriba izquierda (1, 90° horario), arriba derecha (2, 270° horario) y mitad inferior
completa (3, sin giro). Se gira el panel completo con controles, gestión y semántica.
Configuración y mesa comparten geometría en ambas orientaciones. Para 4–6 se mantienen
rectángulos y giros hacia cada lado, enumerados ahora en sentido horario.

El usuario confirmó que arrastrar durante la partida debe cambiar el orden de juego.
`PriorityMatch.turnOrder` guarda el ciclo actual; `PriorityEngine.reseat` valida cada
permutación, mantiene al activo y a quien ya tiene prioridad, y reorganiza los
pendientes desde ese jugador sin repetir respuestas completadas. El siguiente turno
busca al vecino no eliminado en el nuevo orden. La ronda mantiene quiénes aún deben
jugar; puede repetirse un jugador que ya actuó si las nuevas posiciones lo colocan
antes de otros pendientes. El inicial elegido, los datos individuales y los relojes
se conservan; no se reinicia la partida al mover paneles.

El movimiento de asientos se guarda como una operación deshacible con revisión.
Formato Priority 2 incluye el orden actual en cada snapshot; migra formato 1 y
los checkpoints de undo adoptando sus posiciones guardadas sin perder activo,
prioridad, consumos, puntos ni tiempos. La ubicación privada de archivos se conserva.
No se implementan funciones de una etapa posterior.

- [x] Distribución y giros específicos de tres en configuración/mesa.
- [x] Enumeración horaria en ambas orientaciones y texto de ayuda actualizado.
- [x] Motor, colas de respuesta y rondas adaptados al orden dinámico.
- [x] Guardado, recuperación, Deshacer y migración del formato 1 al 2.
- [x] 27 pruebas nuevas: 10 de geometría/motor para 2–6 y todos los iniciales;
  2 de UI con dibujo, giros y arrastre seguido de turno; 10 con todos los pares
  de asientos en ACTION/FREE; ronda parcial/eliminación, órdenes inválidos,
  reinicio/undo y dos casos de migración. Se actualizan las pruebas previas de
  arrastre al nuevo contrato y se añaden permutaciones a los 4000 roundtrips.
- [x] Verificación focalizada de orden dinámico: **91/91 aprobadas**, 17 s.
- [x] Regresión general final: **1074/1074 aprobadas**, 6 min 43 s (1046 pruebas
  y 28 renders), sobre el alcance completo incluido el orden dinámico. Revisión
  visual de tres en ambas orientaciones, configuración y mesas de seis.
- [x] Análisis completo sin incidencias y 202 archivos Dart con formato correcto.
- [x] APK definitivo rc.23/código 36 generado con `./tool/build_apk.ps1`, Gradle
  31,8 s; copia/hash, paquete, SDK y firma v2 verificados, mismo certificado y sin
  INTERNET. Solo queda rc.23, sin cambios del flujo de APK ni flutter clean.

Incremento completado. Se detiene el trabajo sin iniciar funciones posteriores.

Evidencia en `build/verification/priority-clockwise-layout/`; resultados definitivos
sobre el alcance completo y APK en [ESTADO.md](ESTADO.md). La aceptación Android
sigue pendiente conforme a la decisión de continuar sin teléfono.

## Accesos superiores de Deshacer/Finalizar rc.24 — 2026-11-26

Rama `codex/priority-toolbar-actions`, base `601ce6d` (rc.23). La barra de Priority
incorpora una flecha curva verde para Deshacer y una X rodeada en rojo para finalizar.
Se reutilizan los mismos manejadores que el menú, sin duplicar reglas. Deshacer
consulta `canUndo`; finalizar consulta `can(finish)` y conserva la confirmación.
Los botones se muestran con partida abierta y se atenúan cuando están deshabilitados.
Clasificación y Nueva partida pasan al menú ⋮ para mantener espacio y objetivos
48×48 con Volver, reloj y las dos acciones. Se mantienen las opciones anteriores
al alcance del menú y del historial. La confirmación de finalizar utiliza el
diálogo desplazable común, con título, texto y acciones dentro del desplazamiento.

- [x] Accesos verde/rojo en la barra, estados habilitados y finalización confirmada.
- [x] Clasificación y Nueva partida accesibles desde ⋮, sin perder archivo de partida.
- [x] Seis pruebas nuevas de UI: iconos/colores y operaciones reales, cancelación,
  final/undo, menús, ausencia en configuración y objetivos táctiles sin solapamiento
  con Volver/reloj en 320×320/800×360 y texto 100 %/300 %.
- [x] Nuevas pruebas de barra: **6/6 aprobadas**; sin cambios de negocio o guardado.
- [x] Regresión focalizada de interfaz y renders: **183/183 aprobadas**, 1 min 33 s
  (154 pruebas y 29 renders). Análisis completo sin incidencias; 203 archivos Dart
  con formato correcto. Revisión visual de ambos accesos, incluida una nueva vista
  de la barra con Volver/reloj en 320×568.
- [x] APK rc.24/código 37 generado mediante `./tool/build_apk.ps1`, Gradle 70,2 s;
  paquete/versión/SDK, firma v2, certificado anterior y copia/hash verificados,
  sin INTERNET. Solo queda rc.24 tras retirar rc.23 con el script habitual.

Se conservan orientación y orden horario, incluida reorganización por arrastre,
relojes, PV, historial, recuperación y Deshacer de las etapas anteriores.
No se cambia el flujo de APK ni se inicia una etapa nueva. La validación física
continúa pendiente conforme a la decisión de seguir sin teléfono.
Resultados definitivos y APK: [ESTADO.md](ESTADO.md).

## Preparar mesa: ayuda única, selección táctil y sorteo rc.25 — 2026-11-26

Rama `codex/priority-setup-selector`, base `6918fd4` (rc.24).
Las explicaciones se reúnen en ⓘ arriba, dentro de un diálogo desplazable.
El formulario conserva etiquetas, errores y el total de acciones de cada jugador;
se retiran párrafos repetidos, lista textual de orden y selector desplegable del inicial.
El diagrama mantiene geometría/giros y arrastre; el toque corto elige quién empieza.
El dado se coloca junto al diagrama y sortea con una animación de 2,2 segundos,
resaltando jugadores en sentido horario antes de detenerse en el resultado.

- [x] Botón ⓘ y ayuda reunida, accesible sin perder datos del formulario.
- [x] Selección del inicial por toque, borde/INICIA y conservación al mover asientos.
- [x] Dado adyacente con giro, recorrido horario finito y desaceleración final.
  Se elige una sola vez con el API del motor antes de animar; `Random` inyectable.
- [x] Sorteo no inicia la partida; dado/Listo se deshabilitan durante el efecto.
  No hay callbacks tardíos al elegir manualmente, editar, mover, abrir ayuda/menú,
  pasar a segundo plano o salir. Reducir animaciones entrega la misma elección
  inmediatamente; puede activarse durante el sorteo.
- [x] Validación de campos reutilizada; los errores funcionales siguen visibles.
- [x] 20 pruebas nuevas: selección/sorteo para 2–6 con resultado sembrado y visita a
  todos; tres sorteos tras reordenar; ayuda/datos/gestos, inválidos, seis interrupciones,
  movimiento reducido antes/durante y objetivos táctiles en 320×320/800×360 a 300 %.
  Dos pruebas anteriores de selector desplegable se adaptan a seleccionar en el diagrama.
- [x] Verificación focalizada de pantalla/arrastre/orden y renders: **240/240
  aprobadas**, 2 min 31 s (208 pruebas y 32 renders). Análisis completo sin incidencias
  y 205 archivos Dart con formato correcto. Revisión visual de configuración, ayuda,
  sorteo en curso y resultado; las cuatro variantes mantienen posiciones/giros.
- [x] APK rc.25/código 38 generado mediante `./tool/build_apk.ps1`, Gradle 51,6 s;
  paquete/versión/SDK, firma v2, certificado anterior y copia/hash verificados,
  sin INTERNET. Solo queda rc.25 tras retirar rc.24 con el script habitual.

El resto de Priority, Editor y Entrenador mantiene su comportamiento. Sin paquetes,
permisos ni cambios del formato de partida o del flujo de APK. La aceptación Android
sigue pendiente según la decisión de continuar sin teléfono. Evidencia local en
`build/verification/priority-setup-selector/`; resultados y APK en [ESTADO.md](ESTADO.md).

## Finalizar manualmente vuelve a Preparar mesa rc.26 — 2026-11-27

Rama `codex/priority-finish-setup`, base `9ecd325` (rc.25).
Al confirmar Finalizar desde la X roja o el menú, se finaliza con el motor, se
archiva la partida y se limpia la actual antes de volver a Preparar mesa, sin
abrir la clasificación. El resumen e historial permanecen en Partidas guardadas.
Se conserva la confirmación; Cancelar mantiene la partida. Los campos de preparación
siguen reutilizando sus valores como al configurar Nueva partida.

El retorno espera el guardado correcto. Si falla, la partida terminada sigue abierta
con Reintentar y volver; no abre resumen ni borra datos. Deshacer mientras sigue
abierta cancela el retorno pendiente y restaura la partida pausada. Se evita la
clasificación automática incluso si liquidar el reloj notifica cambios de estado.
El cierre automático por eliminación conserva su comportamiento; motor, repositorio
y formato no cambian.

- [x] Cierre manual confirmado → archivo → Preparar mesa, sin resumen automático.
- [x] Resultados e historial accesibles desde Partidas guardadas tras el cierre.
- [x] Protección de guardado, reintento y reversión durante un fallo.
- [x] Cinco pruebas nuevas: reloj con notificaciones y reinicio, fallo de escritura
  general/archivo/working y Deshacer después de un fallo. Se adaptan las pruebas
  de toolbar y cierre manual del historial al nuevo destino.
- [x] Primera ejecución: **25/25 aprobadas**, 33 s, incluidos cierre, consulta e historial.
- [x] Regresión final de interfaz, cierres automáticos y renders: **265/265 aprobadas**,
  3 min 2 s (231 pruebas y 34 renders). Análisis completo sin incidencias; 206 archivos
  Dart con formato correcto. Revisión visual del retorno y consulta posterior.
- [x] APK rc.26/código 39 generado mediante `./tool/build_apk.ps1`, Gradle 86,2 s;
  paquete/versión/SDK, firma v2, certificado anterior y copia/hash verificados,
  sin INTERNET. Solo queda rc.26 tras retirar rc.25 con el script habitual.

Sin nuevas dependencias/permisos ni cambios de flujo de APK. La aceptación Android
sigue pendiente conforme a la decisión de continuar sin teléfono. Evidencia en
`build/verification/priority-finish-setup/`; resultados y APK en [ESTADO.md](ESTADO.md).

## Mesa sin letreros temporales rc.27 — 2026-11-27

Rama `codex/priority-quiet-table`, base `3a89c8d` (rc.26).
Se retiran los avisos inferiores de Deshacer, recuperación y agotamiento del reloj.
Se ocultan las etiquetas visuales de controles mientras hay una partida abierta,
incluidas pulsación larga y hover. Se conservan los nombres accesibles con semántica
explícita y la acción del menú agrupada. La preparación conserva sus ayudas.

El reloj a cero sigue rojo/pausado y se corrige desde el nombre; no elimina jugadores.
La información de recuperación, incluida copia anterior válida, queda consultable
al abrir Historial. Los errores de biblioteca pasan a su lista; los de guardado
mantienen su panel y reintento. No se ocultan errores ni se cambian confirmaciones.
El acumulado temporal de PV permanece junto a su contador, según el requisito previo.

- [x] Sin SnackBars generados por Priority.
- [x] Sin tooltips visuales de la mesa, manteniendo semántica de controles.
- [x] Información y errores dentro de Historial/biblioteca/panel correspondiente.
- [x] Seis pruebas nuevas: acciones/PV/undo, pulsación larga/hover, recuperación
  normal y desde copia válida, nombres accesibles incluyendo Atrás y menú, y error
  de consulta visible/reintento. Se adaptan cuatro pruebas previas de agotamiento
  y orientación para abrir la gestión desde el nombre sin usar un aviso flotante.
- [x] Regresión focalizada: 272/272 (237 pruebas y 35 renders), 3 min 12 s; análisis sin incidencias y formato de 207 archivos correcto.
- [x] APK rc.27 generado/validado con firma y paquete conservados; solo queda el entregable reciente.

Motor, reglas, cronómetros, acciones y persistencia conservados. Sin nuevas
dependencias/permisos ni cambios del flujo de APK. Aceptación física pendiente
según la decisión de continuar sin teléfono. Evidencia en
`build/verification/priority-quiet-table/`; resultados y APK en [ESTADO.md](ESTADO.md).
