# Matriz de reglas de visión — Prompt 06

Fuente primaria consultada el 2026-11-14; contratos comprobados el 15 e integración
verificada el 16; corrección de vértices oblicuos comprobada el mismo día:
[página oficial](https://wizkids.com/heroclix/gameplay/rules-format/) y
[Comprehensive Rulebook 07.01.2026](https://wizkids.com/wp-content/uploads/2026/07/HeroClix%20Comprehensive%20Rules%2007.01.26.pdf).
La página sigue enlazando esa edición. Los pies de las páginas pertinentes dicen
7.01.2026; el título antiguo de los metadatos PDF no determina la edición usada.
SHA-256 del PDF consultado:
`164C2CE0463DD04777BFEA39EF7E5F66C1DE582FC2288686346E7E6F349BDFF2`.
El PDF y sus renders de lectura quedan en build/verification/prompt-06, fuera de Git.
No se redistribuyen sus páginas ni se copian párrafos a la app.

Páginas impresas; sumar 17 para la posición física en el PDF (p. 27 = PDF 44).
Se revisaron completas las páginas 27, 39, 40, 43 y 44, además de las secciones
de ocupación, elevación, habilidades y bases múltiples. La página de
[erratas](https://wizkids.com/heroclix/errata-clarifications/) se consultó como
índice; no se adoptan ajustes particulares de figuras o formatos en este perfil.

## Reglas verificadas y decisiones

| ID | Resumen propio | Sección / página | Aplicación y pruebas |
| --- | --- | --- | --- |
| V01 | La trayectoria une centros. | 11.4 / 27 | Reutilizar geometría exacta; R01, R20, R22. |
| V02 | Existe visión hacia sí mismo. | 11.4b / 27 | Caso despejado; R18. Clasificación sobre H pendiente. |
| V03 | Las figuras intermedias restringen; las de extremos se excluyen. | 11.4c / 27 | Sin excepción por equipo en perfil normal; R01, R05. |
| V04 | Obstaculizado cuenta en destino; normalmente se excluye origen. | 16.2b / 39 | Fuente propia ordinaria; R02, R06, R21. |
| V05 | Bloqueado atravesado impide la línea. | 16.3b / 40 | Sin excepciones de poderes o destrucción; R03, R07, R11. |
| V06 | Un muro cruzado bloquea. | 16.4b / 40 | Interior del borde; R04. Vértices mediante V07. |
| V07 | En intersecciones se usa el lado menos restrictivo. | 16.8b / 44 | Comparar celdas laterales, figuras y sus muros incidentes, incluso en líneas oblicuas; R08–R10, R17, R23–R25. |
| V08 | La elevación puede cambiar la visión. | 16.5c / 42 | Fuera de cobertura; R14. |
| V09 | Las bases múltiples tienen reglas de referencia propias. | 24.2e / 70 | Se difiere su evaluación; R15. |
| V10 | La ocupación superpuesta o sobre bloqueado es incompatible. | 13.2 / 35 | Rechazar dictamen de escena de estudio incompatible; R07, R16. |
| V11 | Las habilidades pueden introducir excepciones. | 19.3 / 54; 27.6 / 87 | Declaración explícita de caso especial; R13. No implementar esas excepciones. |
| V12 | Hay mapas con reglas particulares. | 15.6 / 38 | Contexto tipado sin soporte; R13. |

SCOPE identifica un **límite del producto**, no una regla oficial. Toda salida No
evaluado por cobertura lo incluye, acompañada de la sección que requiere soporte
cuando corresponde. No se atribuye al reglamento la decisión de aplazar un caso.

## Casos y expectativas trazables

Casos sintéticos derivados de reglas textuales, no diagramas oficiales copiados.
Las expectativas son literales en test/support/vision_contract.dart y no se
calculan llamando al algoritmo bajo prueba. Cada identificador nombra un test.

| Caso | Preparación / expectativa | Referencia o límite |
| --- | --- | --- |
| R01 | A1–D1 y A1–A4 con dos figuras: despejada. | 11.4, 11.4c |
| R02 | H en B1 entre A1–D1: obstaculizada, visión posible. | 16.2b |
| R03 | B en B1: bloqueada. | 16.3b |
| R04 | Muro A1/B1: bloqueada. | 16.4b |
| R05 | Figura C en B1, de cualquiera de los equipos: bloqueada. | 11.4c |
| R06 | H solo en A1: despejada; H en D1: obstaculizada. | 16.2b |
| R07 | Figura sobre B: No evaluada; destino vacío con B: bloqueada. | 13.2, 16.3b |
| R08 | A1–B2, lados B1/A2: C/C, C/H, C/B dan despejada; H/H, H/B dan obstaculizada; B/B bloqueada. Se prueban ambos órdenes. | 16.8b |
| R09 | Los 16 subconjuntos de cuatro muros terminales: bloqueada solo si ambos lados quedan cerrados. | 16.8b, 16.4b |
| R10 | Figura lateral y otro lado libre: despejada; dos figuras: bloqueada; figura/H: obstaculizada. | 16.8b, 11.4c |
| R11 | H en B2 y B en C3 de A1–D4: bloqueada. | 16.3b, 16.2b |
| R12 | Cambiar B1 de C a H a B cambia el resultado, sin mutar la copia inicial. | V01, V04, V05 |
| R13 | Versión futura o efecto especial declarado: No evaluada. | SCOPE; V11, V12 |
| R14 | Elevación relevante: No evaluada; fuera de trayectoria no la invalida. | SCOPE; 16.5c |
| R15 | Base múltiple relevante: No evaluada; ajena a la trayectoria no la invalida. | SCOPE; 24.2e |
| R16 | IDs/referencias inválidas, límites o figuras superpuestas: No evaluada. | SCOPE; 13.2 |
| R17 | A1–D10 pasa por varios vértices en una línea oblicua: despejada; A1–E3 también despejada. | 16.8b / 44 |
| R18 | Sí mismo en C: despejada; en H: clasificación No evaluada. | 11.4b y SCOPE |
| R19 | Origen vacío: No evaluada; objetivo vacío C/H: despejada/obstaculizada. | SCOPE; 11.4, 16.2b |
| R20 | A1–AN40 plano despejado: despejada; registro inmutable. | 11.4 |
| R21 | Invertir A1(H)–D1 cambia la clasificación al cambiar origen/destino. | 16.2b |
| R22 | Alcance anotado 0 no cambia este diagnóstico de visión. | Separación de 11.3 y 11.4; alcance en 07 |
| R23 | A1–D6 con B4 bloqueado: despejada en ambos sentidos. La línea solo toca B4 en el vértice (2,3); C3 libre es el lado menos restrictivo. | 16.8b / 44 |
| R24 | A1–D6, nueve pares C/H/B en B4/C3, ambos sentidos: tabla de menor restricción. Una figura lateral deja paso si el otro lado está libre; ambas bloquean. Bloqueado realmente atravesado en B3 o C4 bloquea; elevación relevante sigue No evaluada. | 16.8b, 11.4c, 16.3b; SCOPE para elevación |
| R25 | A1–D6, 16 subconjuntos de cuatro muros incidentes, ambos sentidos: bloqueada solo si ambos lados están cerrados. | 16.8b, 16.4b |

## Alcance de implementación y pendientes explícitos

El perfil asume figuras genéricas normales, sin poderes, en una superficie plana.
La elevación 0 del modelo significa ausencia de altura modelada, no un nivel
oficial adicional. No se deducen poderes o tamaños de los nombres escritos.
La casilla de origen debe contener una figura. El destino puede ser figura o
casilla; elegir una casilla vacía no declara que exista un objetivo de ataque.

Se inspeccionan interiores y laterales de vértices relevantes. En todo paso exacto
por un vértice, cada lado combina terreno, figura y los dos bordes de
esa celda que inciden en el vértice. Luego se elige el lado menos restrictivo.
El registro conserva ambos lados, aunque solo el elegido contribuya al dictamen.
El resultado de la trayectoria completa toma la restricción mayor entre sus pasos.
Las marcas decisivas excluyen alternativas descartadas y efectos menos restrictivos
que el resultado final. La dirección importa para el H de los extremos.

No se resuelven en 06: elevación relevante distinta de 0, bases múltiples
relevantes, poderes/tamaños declarados, fuentes remotas, reglas especiales de mapa,
versión no admitida, ocupación incompatible y clasificación de línea a sí mismo
en H. Para este último no se extrapola una interpretación de 11.4b/16.2b.

Corrección 0.7.1+8: se retira el rechazo global de vértices con pendiente distinta
de 45°. El párrafo introductorio 16.8 menciona diagonales perfectas, pero el
procedimiento de 16.8b se refiere al paso por una intersección y no impone esa
condición. Se aplica ese procedimiento a los dos lados que identifica la geometría
exacta. No se curva ni desvía el segmento; solo se clasifica su contacto puntual.
R23 reprodujo el error de 0.7.0+7 antes de corregir el motor.

No evaluado tiene precedencia conservadora aunque haya un bloqueo aparente,
pues una excepción pendiente podría cambiarlo. No equivale a bloqueado.
Solo despejada y obstaculizada devuelven canSee=true; bloqueada false; No evaluado
null. No se produce un permiso de ataque ni se aplica el modificador de defensa
de un ataque a distancia. Referencias de poderes/elevación/bases explican la
frontera de soporte, no indican que esas reglas ya estén implementadas.

## Contratos y reutilización

- LineOfSightService.evaluate es la única entrada reglamentaria; consume snapshot
  inmutable, extremos y VisionContext versionado. Usa SightGeometry sin replicarlo.
- Editor, Simulador y Árbitro comparten VisionAnalysis y el mismo escenario.
- El registro incluye contexto, extremos resueltos, geometría, reglas, observaciones
  por evento y elementos decisivos. No incluye fecha aleatoria: es determinista.
- Cambios de dimensiones, figuras, terreno, muros, extremos o contexto invalidan
  la caché. Cámara, selección y visibilidad no recomputan el dictamen.
- Archivo JSON conserva esquema 1; el perfil declarado y las superposiciones son
  transitorios. Al cargar otra escena se limpian extremos, resultado y declaración.
- `dart run tool/verify_vision.dart` ejecuta R01–R25 sin Flutter. La suite Flutter
  reutiliza los contratos y añade estado, navegación, accesibilidad y regresiones.
