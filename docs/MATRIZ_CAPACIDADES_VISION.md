# Cobertura de visión — etapa 08

El movimiento y el esquema de documento 3 añadidos en 09 se documentan en
[MATRIZ_MOVIMIENTO.md](MATRIZ_MOVIMIENTO.md). Este perfil de visión se conserva.

Fuentes oficiales consultadas el **2026-11-16**:
[WizKids](https://wizkids.com/heroclix/gameplay/rules-format/),
[Comprehensive Rulebook 2026-07-01](https://wizkids.com/wp-content/uploads/2026/07/HeroClix%20Comprehensive%20Rules%2007.01.26.pdf)
y [PAC enlazada por WizKids](https://wizkids.com/posters/repository/heroclix/WK-HEROCLIX-MV50%20HeroClix%20Miniatures%20Game%20PAC---PRINT-FRIENDLY---2023-03-15---PRINT.pdf), página 2.
La PAC enlazada es de 2023; las cuatro definiciones usadas coinciden con §27.6
del reglamento 2026. No se adopta una edición nueva ni se copian arte o párrafos.
El PDF de consulta 2026 y su SHA-256 están registrados en MATRIZ_REGLAS_VISION.md.

## SOPORTADAS

| Capacidad / condición | Decisión implementada | Fuente | Contratos |
| --- | --- | --- | --- |
| Elevaciones de casillas | Mismo nivel, niveles distintos, obstáculos intermedios y borde según el perfil descrito abajo. | 16.5c–e, pp. 42 | E01–E05, R14 |
| IT Elevación | Ignora el bloqueo por elevación; mantiene otros obstáculos relevantes. | 27.6a, p. 87; PAC p. 2 | I01 |
| IT Obstaculizado | La línea no queda obstaculizada por H. | 27.6b, p. 87; PAC p. 2 | I02 |
| IT Bloqueado | Ignora B y muros; conserva altura y personajes relevantes. | 27.6c, p. 87; 16.3/16.4; PAC p. 2 | I03, E05 |
| IT Personajes | Ignora figuras intermedias, incluida su huella completa. | 27.6e, p. 87; PAC p. 2 | I04, B04 |
| Bases reconocidas | 1×1, 1×2/2×1, 2×2, 2×4/4×2, 3×6/6×3. Referencias de casilla, ocupación completa y rotaciones ortogonales. | 24.2/a/e, pp. 69–70 | B01–B03, R15 |
| Alcance y visión de bases | Comparar pares, usando el mismo origen/destino para ambas dimensiones. | 11.5, p. 28; 24.2e, p. 70 | B02 |
| Tamaños intermedios | Tiny no bloquea a los extremos normales; Giant/Colossal bloquean entre niveles distintos. | 21.2b, p. 60; 16.5c, p. 42 | E04 |
| Transiciones de altura | Marcador entre vecinos ortogonales de niveles distintos, sin muro compartido. No cambia por sí solo la visión. | 16.7, p. 43 | Estado/UI y migración |
| Laboratorio | Sustitución temporal explícita de capacidades del origen; no modifica ficha ni JSON. | Hipótesis de producto; usa las mismas reglas tipadas | I05, estado/UI |

Las capacidades se declaran en la ficha; la huella no concede tamaño ni poderes.
El destino no presta sus IT al origen. Una excepción no es un interruptor general.

## NO SOPORTADAS / No evaluado

| Condición | Alcance de la limitación |
| --- | --- |
| Tiny/Giant/Colossal como extremos | No se implementan todas sus excepciones, como Great Size. Se registran como dato, pero el dictamen queda pendiente. |
| Vuelo o bases mixtas de altura | El editor coloca bases en un único nivel; se conservan configuraciones antiguas al importar, pero las referencias sin soporte no reciben un aprobado. |
| Base rectangular no reconocida, p. ej. 3×3 | Se preserva al importar; no se evalúa como una base reglamentaria soportada. |
| IT Destruir bloqueado en origen | Requiere contexto y resolución de ataque; no se simula destruir una pieza (§27.6d). |
| IT Adyacente en origen | Ataques y su adyacencia siguen fuera del perfil; declararlo como capacidad sin soporte produce SCOPE (§27.6f). |
| Otra excepción, poderes arbitrarios, mapas especiales o fuente remota | No se interpreta texto libre; un efecto no modelado declarado por origen/destino o contexto mantiene No evaluado. |
| Transiciones de puertas al mismo nivel | No se crean en este editor; solo se modelan transiciones de altura. |
| Posición incompatible / versión desconocida | Se conserva la política de 06–07. No evaluado no equivale a bloqueado. |
| Línea a sí mismo sobre H sin IT H | Clasificación pendiente de 06; no se fuerza a despejada. |

**Visible y en alcance no significa ataque legal.** No se implementan movimiento,
acciones, número de objetivos, daño ni un juez oficial de torneo. No se inicia 09.

## Orden y composición

1. Validar límites, identidad, ocupación y perfil/versionado. Las condiciones
   relevantes sin soporte tienen salida SCOPE. Una figura sobre B no se legaliza
   por tener IT Bloqueado.
2. Generar el segmento exacto de 05 para cada par. La geometría no interpreta reglas.
3. Clasificar por nivel. Con extremos iguales, se consideran altura superior y
   obstáculos del mismo plano o superiores. Los del plano inferior no se proyectan
   sobre él. Con extremos distintos se aplica el nivel inferior, se excluyen los
   extremos del bloqueo por altura y H solo cuenta en destino. Los muros de borde
   ocupan ambos niveles y los intermedios.
4. Aplicar cada IT a su componente: elevación, H, B/muro o figura. El registro
   conserva lo ignorado y lo que sigue restringiendo. Una colina y un B pueden
   requerir dos mejoras distintas.
5. En cada vértice comparar los dos lados, con sus muros incidentes, después de
   aplicar esas condiciones. Elegir el menos restrictivo; luego combinar toda la
   trayectoria. No se curva el segmento ni se busca una ruta de movimiento.
6. Para bases, consultar todos los pares reconocidos (máximo 18×18 = 324).
   Visión automática elige una referencia visible sin depender del alcance.
   Objetivos busca primero un par visible y dentro; si no existe, conserva
   incertidumbre relevante antes de negar un resultado. No combina la distancia
   de un par bloqueado con la visión de otro que queda fuera de alcance.

El informe de visión del Editor muestra par elegido, alturas, capacidades, hipótesis, resultados
de pares y registro por evento con referencias. Puede alternarse a referencia
manual en Visión; Objetivos siempre usa un par coherente para alcance y visión.

## Expectativas nuevas

Casos sintéticos derivados del texto oficial, no diagramas oficiales copiados.
Las expectativas literales están en `test/support/advanced_vision_contract.dart`;
`dart run tool/verify_advanced_vision.dart` las ejecuta sin Flutter.

| Caso | Expectativa / fuente |
| --- | --- |
| E01 | Extremos nivel 2: intermedio 3 bloquea; inferior no bloquea por altura; H/B del nivel 2 afectan. §16.5c. |
| E02 | A1 elevado y resto bajo permite visión; extender la plataforma a B1 bloquea. Ambos sentidos. §16.5c/d. |
| E03 | Entre niveles, H intermedio no obstaculiza; H de destino sí; B inferior bloquea. §16.5c. |
| E04 | Figura normal intermedia entre niveles no bloquea; Giant/Colossal sí. Tiny no bloquea extremos normales del mismo nivel. §16.5c/21.2b. |
| E05 | Muro del borde bloquea; IT Elevación no lo elimina; IT B sí. Muro inferior a una línea en altura no se proyecta sobre ella. §16.5e/27.6c. |
| E06 | Esquina con un lado B y otro elevado: ambos bloquean; ignorar uno deja un lado libre. §16.8b. |
| I01–I04 | Cada mejora elimina su componente y deja otros activos. §27.6a/b/c/e. |
| I05 | IT del destino no se aplica al origen; hipótesis copiada e inmutable, ficha intacta. |
| I06 | Capacidades o tamaños sin soporte conservan SCOPE, también otra excepción del destino. |
| B01 | Ocho formatos/orientaciones, todas las referencias; 18×18 pares y distancia coherente. §24.2. |
| B02 | A1 a base B3/B4: B3 a distancia 2 bloqueado; B4 a 3 visible. Alcance 2 no aprueba; alcance 3 sí. §11.5/24.2e. |
| B03 | Base normal en varios niveles o forma 3×3: No evaluado. §16.5g y SCOPE. |
| B04 | Huella intermedia 2×2 bloquea y se ignora completa con IT Personajes. §24.2e/27.6e. |

Se conservan los contratos de 05–07. R14/R15/T06 cambian únicamente donde el
soporte de altura/bases reemplaza una frontera antigua de cobertura.

## Esquema 2 y recuperación

- Importa esquema 1 o 2; exporta 2. Se añaden capacidades/tamaño por figura y
  transiciones por escenario. No se cambia el directorio privado de escenarios.
- El 0 histórico de elevación se conserva como alias interno del suelo, cuyo
  nivel oficial es 1; el editor muestra niveles 1–40. No se inventa un nivel 0.
- Abrir no sobrescribe el original. Antes del primer guardado de un esquema 1,
  se conserva una copia exacta `schema1-ID` o `schema1-working`, excluida de la
  lista de biblioteca. Si falla el respaldo, no se reemplaza el documento antiguo.
- IDs, nombres, fechas, equipos, posiciones, tamaños de base, velocidad, alcance,
  terreno, elevaciones, muros y contadores se conservan. Capacidades nuevas se
  inicializan vacías y tamaño Normal. No se pierden campos desconocidos en silencio:
  entradas no compatibles se rechazan sin sobrescribir.
- La ficha y las alturas/transiciones tienen historial. El laboratorio se limpia
  al cargar otra escena y no se serializa. Limpiar tipos de terreno conserva
  alturas y transiciones; pintar nivel 1 explícitamente restablece suelo.

La migración está probada con un JSON real producido por 07 y con archivos
temporales reales del adaptador de almacenamiento, además del puerto simulado.
Esto no es una prueba nativa Android; los resultados efectivos están en ESTADO.md.
