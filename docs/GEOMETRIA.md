# Geometría de trayectorias — Prompt 05

Motor puro Dart, sin reglas de HeroClix. Un contacto con un muro o una figura es
un dato geométrico; no demuestra que la línea esté permitida o impedida. No se
calcula alcance, movimiento ni legalidad de ataque. El Editor es la entrada
operativa; la tarjeta Simulador permanece futura.

## Sistema de coordenadas y precisión

Una casilla tiene lado 1. (0, 0) es la esquina superior izquierda del tablero,
x aumenta hacia la derecha e y hacia abajo. A1 tiene centro (1/2, 1/2), B2 tiene
centro (3/2, 3/2). El segmento usa P(t) = A + t(B−A), con 0 ≤ t ≤ 1.
Los puntos y parámetros se almacenan como ExactFraction normalizada, denominador
positivo y numerador/denominador enteros. Igualdad, orden y operaciones son exactos;
no se redondea para decidir intersecciones. Solo SightPainter convierte a double
al proyectar las coordenadas al canvas.

Las dimensiones admitidas son las del producto, 2–40 por eje; una coordenada fuera
del tablero produce ArgumentError, nunca se omite o recorta. Las operaciones con
enteros del algoritmo quedan acotadas por esas dimensiones. No se pretende usar
este tipo como biblioteca de precisión arbitraria para entradas ilimitadas.

## Algoritmo y eventos

Se enumeran los parámetros de corte con cada recta interna x=k e y=k, conservando
solo los estrictamente interiores al segmento. El conjunto de racionales elimina
duplicados exactos: cortes vertical/horizontal al mismo t forman un único vértice.
Se añaden 0 y 1 y se ordenan. El punto medio de cada intervalo identifica la única
casilla cuyo interior se atraviesa; no se añaden celdas vecinas por proximidad.

| Evento | Datos y significado |
| --- | --- |
| TraceStart | t=0 y centro exacto de origen |
| CellPass | Casilla, parámetro inicial/final y puntos exactos de entrada/salida |
| GridCrossing de borde | Punto interior de un borde unitario, un EdgeContact |
| GridCrossing de vértice | Punto entero en ambos ejes, cuatro EdgeContact terminales |
| TraceEnd | t=1 y centro exacto de destino |

Cada EdgeContact incluye el EdgeWall canónico (aunque no haya muro), el tipo
`edgeInterior` o `vertexEndpoint` y `hasWall`. La existencia de muro se consulta
por identidad en WallLayer, sin deducir efectos reglamentarios. Un vértice no se
convierte en cuatro cruces de interior: toca el extremo de cuatro bordes.
`cornerOnly` enumera las dos casillas laterales tocadas solo en la esquina.

Los eventos se ordenan por t. En un empate se emite primero el punto de inicio
o cruce y luego el CellPass que comienza allí; Fin aparece al terminar el último
intervalo. Los contactos de cada punto tienen orden estable por ID de borde.
Listas de resultado inmutables. La trayectoria tiene un CellPass por tramo.
En origen=destino existe un punto fijo: Inicio, un CellPass degenerado con el
mismo punto de entrada/salida y Fin, sin contactos con bordes.

Ejemplo A1→D4: interiores A1, B2, C3 y D4; vértices en t=1/6, 1/2 y 5/6,
puntos (1,1), (2,2) y (3,3). A2 y B1 aparecen como solo esquina en el primer
vértice. Un muro v:1:0 se toca por su extremo en ese punto; A1→C1 cruza ese mismo
muro por su interior en (1,1/2). Se muestran como contactos distintos.

Invertir extremos conserva puntos/bordes/tipos, invierte su orden y transforma
t en 1−t; el intervalo [a,b] de una casilla pasa a [1−b,1−a]. La búsqueda depende
solo de dimensiones, coordenadas y muros; no de cámara, pantalla, orientación o
captura de imagen. Complejidad por candidata O((filas+columnas) log(filas+columnas)
+ muros), con hasta filas+columnas−1 tramos; en 40×40 como máximo 79 tramos.

## Figuras y estado de inspección

ProbeEndpoint distingue casilla fija de figura por ID con desplazamiento relativo
dentro de su huella. Mover la figura mueve ese extremo y recalcula. Borrarla,
reducir su base dejando fuera la referencia o reducir tablero dejando una casilla
fuera retira el resultado anterior y muestra error. Deshacer puede restituirlo.
Una casilla fija no sigue la figura que la ocupa.

Tocar una base 2×2 abre selección explícita de referencia; el formulario permite
elegir figura y cualquiera de sus cuatro casillas. Se usa el centro de esa
referencia. No se generan ni evalúan todas las combinaciones de bases: eso
corresponde a Prompt 08. SightPath/traceCandidates admite hasta 16 candidatas
explícitas con IDs distintos para esa integración futura, sin elegir ganadora.

SightProbe está separado del documento guardado y del historial. Crear/cargar/
importar/guardar como limpia extremos y resultado. Guardar normal los conserva
en memoria; cerrar proceso no los recupera. Elegir extremos, invertir, limpiar u
ocultar superposiciones no ensucia ni autoguarda el escenario. Cámara/selección/
terreno no repiten la geometría; cambios en dimensiones, figuras o muros sí.
El inspector siempre consulta el resultado actual y las anotaciones de figuras
actuales. No conserva un dictamen obsoleto.

## Interfaz

Línea de visión · Geometría está en la barra desplazable de herramientas.
Primer toque elige origen, segundo destino; Origen/Destino permiten volver a
elegir uno. Dos dedos navegan sin elegir extremos. Coordenadas / figuras ofrece
la alternativa de formulario. Mantener pulsado en esta herramienta no mueve figuras;
para editar posición se usa Seleccionar/Personajes o su ficha.

La barra permite invertir, limpiar y abrir Inspeccionar geometría; este último
también está en Opciones del tablero. El inspector presenta extremos, coordenadas,
intervalos y todos los eventos en orden, y permite ocultar de forma independiente
segmento/extremos, casillas y contactos. Azul y círculos identifican borde/interior;
lila y rombos identifican vértices. Las casillas laterales solo tienen marcas de
esquina. O/D marcan extremos. La leyenda explica formas y colores sin veredicto.

La superposición se conserva visible al editar con otra herramienta para observar
el recálculo; se puede ocultar desde el inspector. PNG de 04 sigue exportando solo
el mundo lógico del tablero: no incluye esta inspección transitoria. El esquema
JSON permanece en versión 1, sin campos nuevos.
El estado de selección/error se presenta en la barra inferior, fuera del tablero,
con texto completo en su tooltip; no tapa la última fila en disposición horizontal.

## Pruebas

`dart run tool/verify_geometry.dart` ejecuta los 13 contratos con Dart puro, sin
importar Flutter ni arrancar UI. La suite Flutter reutiliza los mismos contratos,
además de pruebas del controlador y widgets. Incluyen horizontales, verticales,
diagonales principal/secundaria, pendientes 1:2 y 2:3, pendiente 1:3 con vértices
múltiples, contacto de muro interior/terminal, casilla idéntica, inválidos, 40×40
y candidatas. Se comparan todos los pares de 4×4 en ambos sentidos y todos los
2.916 pares de 6×9 contra un oráculo independiente de recorte de cajas abiertas.
