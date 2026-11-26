# Plan de implementación — Priority

Actualización: 2026-11-25 (America/Bogota).

Referencia: contexto «Implementación del módulo HeroClix Priority», proporcionado
por el usuario, secciones 1–19, y orden posterior de implementar exclusivamente
la etapa 1. No había un plan específico de Priority en el repositorio; este
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

## Trabajo posterior — pendiente de nuevos prompts

No se inicia automáticamente ni se fija aquí el orden de las siguientes etapas.

- Interfaz de configuración y modo mesa, navegación, señales y protección de toques.
- Cronómetros, ciclo de vida y agotamiento de tiempo.
- Puntuación, eliminación y clasificación/resultados.
- Historial acumulado, deshacer, persistencia, recuperación y consulta local.
- Integración, pruebas de interfaz y verificación Android/APK.

No se modifican navegación, versión, formatos del editor ni flujo de APK en la
etapa 1. No se genera APK: el motor todavía no tiene una entrada en la interfaz.

## Verificación — 2026-11-25

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

**Cierre:** se detiene el trabajo al terminar esta etapa. No se inicia ninguna
función pendiente ni se publica una nueva versión/APK.
