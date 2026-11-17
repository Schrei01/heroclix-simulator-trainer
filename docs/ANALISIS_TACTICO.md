# Análisis de posiciones — etapa 11

Seleccionar una figura en Editor → Analizar posición. El mapa de
análisis tiene cámara independiente y no reposiciona piezas al tocar. El motor
reutiliza visión, distancia y movimiento de 06–09 con edición 2026-07-01; no añade
permisos de ataque ni interpreta cartas. Las etiquetas V/T/C indican visibles,
amenazas conocidas y costo; `?` advierte incertidumbre. Color y texto se combinan.

## Definiciones

| Métrica | Cuenta | Referencias del perfil | Exclusiones |
| --- | --- | --- | --- |
| Objetivos visibles | Enemigos con visión saliente despejada u obstaculizada | §11.4/24.2e | No exige alcance |
| Enemigos que lo ven | Visión entrante con capacidades propias de cada enemigo | §11.4/27.6 | No exige alcance |
| Enemigos en su alcance | Distancia frente al alcance declarado del activo | §11.3b/11.5 | No exige visión |
| Líneas H / bloqueadas | Estado de la visión saliente, una consulta por enemigo | §16.2b/16.3b/16.4b | H está incluida en visibles |
| Amenazas conocidas | Enemigo con visión y alcance en un mismo par de referencias | §11.5 | No equivale a ataque legal |
| Costo | Ruta validada frente a velocidad declarada | Matriz de movimiento 09 | No evalúa acciones, turnos ni dados |

La evidencia separa referencias de visión y referencias de la consulta combinada.
No se intersectan contadores independientes para inventar una amenaza. Se muestran
terreno y niveles de la huella. No hay modificadores arbitrarios, diales, daño,
probabilidad de victoria ni recomendación estratégica universal.

## Destinos y comparación

Se exploran anclas dentro de una cota de distancia directa y velocidad; eso solo
genera el conjunto de búsqueda. Un destino se marca legal después de validar
parada, huella completa y ruta. Se conserva el perfil de traslación sin giro de 09.
Destinos ilegales quedan fuera de las opciones legales. Ausencia de ruta encontrada
o condición sin soporte permanece No evaluado, sin demostrar imposibilidad general.

Se calculan 12 destinos por página, ordenados inicialmente por distancia y casilla.
Dentro de esa página se pueden ordenar resultados completos por más visibles,
menos visión enemiga o menor costo; empates usan costo, fila y columna. No es una
ordenación global de todas las páginas. Los resultados legales pero incompletos
aparecen aparte, sin ranking categórico.

Hasta 32 enemigos por posición, ordenados por ID estable. Los omitidos cuentan
como No evaluados en cada métrica. `≥n · k No evaluados` es una cota inferior,
no un total exacto. Las diferencias son numéricas solo cuando ambos contadores
son completos. Escena sin enemigos muestra cero completo si no hay otros límites.

La opción HIPÓTESIS retira solo Improved Targeting/Movement soportados del activo;
mantiene tamaño, capacidades sin soporte y fichas enemigas. Compara las mismas
posiciones/rutas, indicando si la ruta deja de ser legal sin la mejora. No altera
la ficha real. Crear ejercicio usa siempre el contexto declarado.

Confirmar revalida la ruta en el estado actual y aplica un comando reversible.
Cancelar, salir o tocar el mapa no mueve la figura. Deshacer recupera el origen.

## Trabajo y caché

El cálculo de rutas y líneas se ejecuta en Isolate.spawn; publica progreso por
posición/enemigo. Cancelar termina el worker y descarta mensajes atrasados mediante
generación. Se conservan únicamente resultados ya completados y etiquetados.
Caché de ocho páginas: contenido, dimensiones, figuras/fichas/equipos, terreno,
muros, versión reglamentaria y efectos invalidan; cámara y prioridad no invalidan.
Cambiar activo o hipótesis limpia resultados. Las líneas se memoizan por enemigo
con un máximo de 648 pares dirigidos y se liberan tras compactar su evidencia.

## Entrenamiento y exportación

Genera recorrido al destino o «qué posición permite ver a B» usando validadores
del Entrenador y snapshot independiente. Véase ENTRENADOR.md para formato 3,
respaldo de datos de 10, límites personales y corrección.

Exporta TXT y PNG construidos desde datos controlados, sin capturar la interfaz.
Reemplaza nombres y equipos por etiquetas genéricas; excluye IDs, nombres de escena,
rutas locales, fechas, texto libre y credenciales. Versión desconocida se imprime
como «no soportada». Incluye alcance de las métricas e incertidumbre. PNG máximo
2048 px por eje; pie dimensionado al texto. Destino mediante selector Android
existente, sin permisos nuevos. Un cambio de escena durante el render descarta
la exportación. La anonimización no elimina la geometría, que es el diagnóstico.

## Evidencia y límites de medición

14 contratos puros A01–A14 cubren comparación, rutas, muros, H, capacidades
direccionales, bases con referencias coherentes, 40×40 sin enemigos, límite de
enemigos, prioridades, hipótesis y desconocidos. Pruebas de estado usan isolates
reales, cancelación, caché, cambio de edición y Deshacer. Integración crea y guarda
ambos ejercicios, practica y verifica migración 2→3 con respaldo exacto.

Benchmark Dart/JIT en Windows, i5-7200U, 8 GB, cuatro hilos lógicos: 36 figuras,
32 enemigos evaluados, tres pendientes, 12 destinos y origen; cinco muestras.
20×20: mediana 144,803 ms, primera/máxima 442,961 ms.
40×40: mediana 130,800 ms, primera 131,576 ms, máxima 137,457 ms.
La primera muestra incluye calentamiento; estos números no comparan rendimiento
Android ni FPS, ni representan una escena de 35 enemigos completamente evaluada.
Comando: `dart run tool/benchmark_tactics.dart`. Resultados globales en ESTADO.md.
