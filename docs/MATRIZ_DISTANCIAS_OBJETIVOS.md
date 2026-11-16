# Distancias, alcance y objetivos — etapa 07

Consulta del 2026-11-16 a la [página oficial de WizKids](https://wizkids.com/heroclix/gameplay/rules-format/)
y al [Comprehensive Rulebook 2026-07-01](https://wizkids.com/wp-content/uploads/2026/07/HeroClix%20Comprehensive%20Rules%2007.01.26.pdf).
La página sigue enlazando esa edición. Se revisaron las secciones 11.2–11.5 y 12.1,
páginas impresas 26–28. Se conserva la edición verificada en 06. La copia local de
lectura y su SHA-256 están registrados en MATRIZ_REGLAS_VISION.md; no se redistribuye.

## Referencias y decisiones

| ID | Fuente | Aplicación |
| --- | --- | --- |
| D01 | §11.3a, p. 26 | Cero en origen; contar en ocho direcciones, incluidas diagonales. |
| D02 | §11.3b, p. 26 | Comparar distancia con alcance declarado mediante `distancia <= alcance`. |
| D03 | §11.4a, p. 27 | Usar la misma casilla de origen para medir y trazar visión. |
| D04 | §11.5, p. 28 | Para figuras normales, rango y visión parten de la misma referencia. |
| D05 | §12.1, p. 28 | El análisis no verifica todas las condiciones de ataque. Adyacencia pendiente: también §11.2a, p. 26. |
| D06 | §24.2e, p. 70 | Distancia/rango de bases múltiples pendientes; no elegir una referencia arbitraria como resultado completo. |
| SCOPE | Límite de implementación | No evaluado conserva la incertidumbre, sin atribuir esa política al reglamento. |

La fórmula `max(abs(Δfila), abs(Δcolumna))` se deriva del conteo de §11.3a:
cada incremento reduce cada diferencia a lo sumo en uno; los pasos diagonales
reducen ambas hasta agotar la menor y los restantes reducen la mayor. No se
cuentan cruces del segmento ni se busca una ruta alrededor de obstáculos.
Terreno, muros y figuras afectan la visión por el servicio existente de 06.

## Dimensiones independientes y clasificación

Cada resultado conserva distancia, alcance declarado, comparación de alcance,
visión estructurada, restricciones comprobadas/pendientes y referencias.

1. Sin soporte o datos suficientes en alcance o visión: **No evaluado**.
2. Comparación conocida fuera del alcance: **Fuera de alcance**. Se conserva y
   muestra por separado una visión bloqueada u obstaculizada si también existe.
3. Dentro del alcance: visión despejada, obstaculizada o bloqueada determina la
   categoría correspondiente.

El rango anotado no es un cálculo automático de modificadores de una carta.
Efectos especiales declarados invalidan la comparación. En bases múltiples de
extremos, distancia y rango quedan sin evaluar. Una elevación relevante deja
pendiente la visión; puede conservarse la cuenta entre casillas y su comparación
con el valor anotado, sin emitir una categoría aprobada de objetivo.

Se consultan todas las demás figuras, excluyendo el propio origen. El filtro
inicial muestra enemigas, con opciones Aliadas/Todas. El filtro no decide permisos
de ataque a aliados; la lista y el informe explicitan que se debe consultar el
efecto concreto. No se evalúan acciones, poderes, adyacencia para ataques ni
número de objetivos. **Visible y en alcance no significa ataque legal.**

## Contratos verificables

Expectativas literales en `test/support/target_contract.dart`, ejecutables con
Dart puro (`dart run tool/verify_targets.dart`) y en la suite Flutter.

| Caso | Preparación / resultado esperado | Sección |
| --- | --- | --- |
| D01 | A1–D1 = 3; A1–A6 = 5; A1–D4 = 3; A1–D6 = 5; D6–B2 = 4; C3–C3 = 0; A1–AN40 = 39; ambos sentidos. | 11.3a |
| D02 | A1–D3: diferencias 2/3, distancia 3. Fuera del tablero o versión desconocida: No evaluado. | 11.3a y SCOPE |
| T01 | Distancia 3, alcance 2/3/4: fuera/dentro/dentro. | 11.3b |
| T02 | A1 con alcance 3: D1 visible y dentro; H4 fuera a distancia 7. | 11.3b, 11.4 |
| T03 | H intermedio: dentro + obstaculizada; B intermedio: bloqueada. | 16.2b, 16.3b |
| T04 | Figura intermedia, de cualquier equipo: bloqueada. | 11.4c |
| T05 | Muro cruzado: bloqueada; alcance insuficiente conserva también ese diagnóstico independiente. | 16.4b, 11.3b |
| T06 | Bases relevantes: distancia/rango pendientes; elevación: visión pendiente; efectos o versión desconocida: No evaluado. | 24.2e, 16.5c y SCOPE |
| T07 | Origen inexistente: informe con error; origen único: lista vacía. | SCOPE |
| T08 | Figuras superpuestas o sobre B: No evaluado. | 13.2 y SCOPE |
| T09 | Alcance 0: las demás figuras están fuera; aliados consultables con aviso. | 11.3b, 12.1 |
| T10 | Resultado inmutable con referencias y condiciones de ataque pendientes. | 11.5, 12.1 |
| T11 | A1–D6/B4 y alcance 5: dentro + despejada. Regresión de 0.7.1. | 16.8b, 11.3b |

Estado/UI añaden invalidación por mundo, extremos, rango, versión y condiciones,
borrado, undo/redo, limpieza al cargar, filtros, origen desde lista, ausencia de
escrituras por consultas, edición persistente del alcance y accesibilidad al 300 %.

## Caché y rendimiento

La aplicación calcula fuera de `build`. La caché de visión compara dimensiones,
posiciones/huellas/identidades/equipos/etiquetas, terreno, muros y contexto. Cambiar
solo rango/nombre conserva sus resultados; cámara/filtro/selección no recalculan.
Se limita a un mundo/contexto y 256 pares. Cambiar el mundo descarta resultados;
el análisis de distancia/rango se actualiza aunque la visión pueda reutilizarse.

`tool/benchmark_targets.dart` mide una primera llamada, 25 muestras sin caché,
100 cambios de filtro con caché y un cambio de alcance. Tableros 20×20/40 figuras
y 40×40/120 figuras, repartidas de forma determinista. `--mixed` añade terreno H/B
y muros; sin ese argumento usa solo figuras. Cantidades y tiempos reales se
registran en ESTADO.md junto con el equipo. Son mediciones del motor Dart en
Windows, no FPS de la interfaz ni mediciones de un teléfono Android.
