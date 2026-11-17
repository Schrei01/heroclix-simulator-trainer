# Entrenador — etapa 10

Banco curado **versión 1**, 24 ejercicios originales, IDs estables `hc10-*`.
Se conserva Comprehensive Rulebook **2026-07-01**, enlazado por
[WizKids](https://wizkids.com/heroclix/gameplay/rules-format/) y consultado el
2026-11-16. Fuentes detalladas en REGLAS.md y matrices de visión, capacidades y
movimiento. No se copian mapas, personajes ni párrafos oficiales.

## Práctica

Inicio → Entrenador → categoría/dificultad → Iniciar → responder → Comprobar →
leer acierto/error, solución y evidencia → Continuar o Repetir. La dificultad
describe complejidad; no cambia reglas. Las pistas solo aparecen al solicitarlas.
El tablero de práctica es independiente del Editor y no altera su historial.
Trazos y selecciones permanecen neutrales hasta comprobar; no se dibuja la solución.

Repetir vacía la respuesta sin sumar intentos. Solo comprobar una nueva respuesta
suma estadísticas. Revisar último intento muestra el resultado guardado con fecha,
pista y edición, sin recalificar ni añadir intentos.

## Banco y regresión

Los escenarios son sintéticos derivados de reglas ya verificadas, no ejemplos
oficiales publicados. Cada solución literal se guarda junto al escenario en
`lib/domain/training/curated_exercises.dart` y se contrasta con los mismos motores
del Simulador. La coincidencia se verifica en tests y con
`dart run tool/verify_training.dart`.

| IDs | Categoría | Casos y referencias |
| --- | --- | --- |
| hc10-v01–v04 | Visión | Despejada, H, figura intermedia, elegir objetivo visible; §11.4/16.2b/16.4b |
| hc10-t01–t04 | Terreno/muros | Justificar muro y H, B interior, A1–D6/B4 por vértice; §16.2b/16.3b/16.4b/16.8b |
| hc10-d01–d04 | Distancia/alcance | Distancias 5 y 2, fuera de alcance, en alcance con H; §11.3a/b/11.5 |
| hc10-m01–m04 | Movimiento | Velocidad exacta, rodeo entre muros, destino libre, H sin costo extra; §10.2/13.2/16.2a/16.4a/16.8a |
| hc10-e01–e04 | Elevación/capacidades | Altura superior bloquea, borde libre, IT H, IT B conserva figura; §16.5c/d/27.6b/c/11.4c |
| hc10-p01–p04 | Posiciones sencillas | Paso legal con alcance/visión, acercamiento, objetivo obstaculizado visible, esquina libre; §10.2/11.5/16.2b/16.8a |

Cada categoría tiene cuatro ejercicios. Hay tres dificultades y cinco tipos
automáticos: opciones, tocar objetivo, elegir casilla, ruta y justificación.
Las rutas aceptan cualquier recorrido verificable al destino dentro del presupuesto,
no solo la ruta de regresión. La comparación de posiciones pregunta un predicado
concreto después de un paso: visión despejada y alcance. No puntúa daño, amenazas,
ventaja estratégica ni recomienda la mejor jugada; no se inicia 11.

## Correctores y límites

ExerciseEvaluator adapta respuestas a LineOfSightService/TargetAnalysisService,
DistanceService y MovementRulesService. Los motivos de justificación provienen
de las observaciones decisivas, no de reglas de terreno escritas en pantallas.
Posición sencilla compone un paso validado y alcance/visión en un snapshot futuro.

Solución registrada distinta del motor, edición diferente o No evaluado inhabilita
la autocorrección. Una respuesta que alcanza una condición sin soporte muestra
el motivo y no se transforma en fallo estadístico. Se conservan límites de
06–09: tamaños/bases, separación, poderes y efectos no modelados. No se interpretan
cartas ni se valida un ataque, acción o turno completo.

## Ejercicios personales

Guardar primero el escenario en la biblioteca del Editor. Entrenador → + → elegir
escenario → definir título, pregunta, categoría, dificultad, opciones, pista y
solución/explicación. Se copia un snapshot: editar después el escenario original
no cambia ese ejercicio. Tipos al crear: visión, distancia, alcance con visión,
ruta y texto manual. Tocar objetivo/casilla está disponible en el banco curado.

La solución automática declarada debe coincidir con el motor antes de guardar.
Se aplica únicamente el corrector elegido; no se interpreta semánticamente el texto
libre. La modalidad manual exige guía y se identifica como **evaluación manual**:
no asigna acierto automático. Registrar la revisión muestra la guía del autor.

Máximo 50 ejercicios personales y 2 MiB para el documento completo; mapas grandes
pueden alcanzar antes el límite. No hay editor posterior, sincronización,
importación/exportación del banco ni generador aleatorio. Crear otra variante
produce un ejercicio independiente. El banco curado es determinista.

## Progreso y almacenamiento

Por categoría de la edición activa: intentos totales, aciertos, porcentaje sobre
intentos automáticos, revisiones manuales, completados y último intento.
Completado exige al menos un acierto automático; las revisiones manuales no cuentan
como acierto ni completado automático. Las pistas no penalizan el porcentaje;
se conserva si el último intento utilizó una.

Practicar errores incluye solo ejercicios autocorregibles cuyo último intento de
su revisión/edición actual fue incorrecto. Acertar lo retira; fallar después lo
reincorpora aunque ya estuviera completado. Se conserva el último intento y los
contadores agregados, no todas las respuestas individuales.

Los registros quedan ligados a ID, revisión y edición. Revisar por ID permite
consultar el resultado antiguo con su edición; no se reinterpreta con otro motor.
Reiniciar estadísticas requiere confirmación y conserva los ejercicios personales.

Producción: subdirectorio privado `files/scenarios_v1/training_v1`, independiente
de los documentos del Editor. Reutiliza FileDocumentStore atómico, sin permisos
nuevos. `trainingSchemaVersion: 2`, `bankVersion: 1`: lee 1/2, rechaza versiones
futuras y campos desconocidos sin sobrescribir. Leer no escribe. Antes de reemplazar
formato 1 guarda copia exacta `schema1-working`; si falla, protege el original.
La compatibilidad con formato 1 se prueba con datos sintéticos; no hubo Entrenador
publicado en 09. El formato 2 añade revisión y uso de pista, por defecto 1/false
al migrar. Snapshots usan ScenarioCodec: importa 1/2/3 y exporta 3; capas siguen 2.

Escrituras serializadas y token de intento evitan duplicados al confirmar. El
estado se publica después de guardar; fallos conservan los datos anteriores.
No hay cuentas, ranking online, IA externa ni red en runtime.

Resultados de pruebas, renders y APK: [ESTADO.md](ESTADO.md).
