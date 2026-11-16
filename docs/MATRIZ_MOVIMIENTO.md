# Movimiento verificado — etapa 09

Fuente: [reglamento oficial 2026-07-01](https://wizkids.com/wp-content/uploads/2026/07/HeroClix%20Comprehensive%20Rules%2007.01.26.pdf),
enlazado por [WizKids](https://wizkids.com/heroclix/gameplay/rules-format/) y revisado
el 2026-11-16. Se conserva la edición registrada. No se transcribe el reglamento.
El PDF local y su SHA-256 están registrados en MATRIZ_REGLAS_VISION.md.

## SOPORTADAS

| Condición | Decisión implementada | Fuente | Contrato |
| --- | --- | --- | --- |
| Pasos ortogonales y diagonales | Ocho direcciones, costo 1, ruta explícita sin interpolar saltos. Cero pasos es consultable, sin comando de confirmación. | 10.2/10.5, p. 24 | M01–M03 |
| Presupuesto | Velocidad declarada calculada por el usuario; límite exacto permitido, exceso inválido. La distancia directa es una dimensión distinta. | 10.2, p. 24 | M01–M02, M22 |
| Obstaculizado | No añade costo ni obliga a terminar. No se aplican reglas históricas de otras ediciones. | 16.2a, p. 39 | M04 |
| Bloqueado y muros | Impiden el paso, salvo su mejora específica. | 16.3a/16.4a, p. 40 | M05–M07 |
| Esquina | Inspecciona los dos lados, ambos tramos de muros y ocupantes; toma el menos restrictivo. B/altura puede obligar a terminar. | 16.8a, p. 44 | M06–M07, M14 |
| Aliados | Puede atravesarlos; no puede terminar compartiendo casilla. | 10.7a, p. 24; 13.2, p. 35 | M08, M23 |
| Enemigos | No puede atravesarlos sin mejora. Entrar en adyacencia permite terminar, pero prohíbe continuar. | 10.7b/d, p. 25 | M09–M10, M17–M18 |
| Adyacencia | Mismo nivel y paredes/esquinas B. Separación inicial desde toda la huella; la parada durante el recorrido de una base usa la referencia elegida. La mejora no borra muros para definir adyacencia. | 6.3, p. 14; 16.4c/16.5b/16.8c, pp. 40–44; 24.2b/d, pp. 69–70 | M11, M27 |
| Borde de altura | El cruce permite entrar, pero obliga a terminar salvo transición o IM Elevación. | 16.5a, p. 41 | M12, M14 |
| Transición | Atravesar las dos casillas conectadas permite continuar. No elimina la parada al cruzar en diagonal. | 16.7b, p. 43 | M13 |
| IM Elevación | Elimina la parada por altura, conserva B, paredes y enemigos. | 27.5a, p. 86 | M14–M15 |
| IM Bloqueado | Permite atravesar B y muros, conserva altura y figuras. No permite acabar sobre B/figuras/muros. | 27.5b, p. 86; 13.2, p. 35 | M16 |
| IM Personajes | Separación automática y paso por enemigos/adyacencia sin detenerse. Conserva otros obstáculos. | 27.5e, p. 86 | M17 |
| IM Atravesar personajes | Permite pasar junto a enemigos o por ellos; sigue requiriendo separación inicial. | 27.5f, p. 86 | M09, M18 |
| Bases múltiples | Traslación de orientación fija, referencia en el ancla superior izquierda; verifica todas las partes. Formatos reconocidos de 08. Destino completo libre, dentro y a nivel uniforme. | 24.2a/d, pp. 69–70; 16.5g, p. 42 | M19–M20, M26 |
| Alternativas | BFS por primer paso, máximo tres rutas con inicio diferente; costo ordenado y validación completa antes de mostrarlas. | Algoritmo del producto que usa las reglas anteriores | M22–M24 |
| Comparar posiciones | Snapshots original/futuro separados; vuelve a ejecutar visión y alcance de la ficha. No altera el escenario. | Servicios verificados de 06–08 | Estado/UI |

## NO SOPORTADAS / No evaluado

| Condición | Motivo y tratamiento |
| --- | --- |
| Separación que requiere dado | §10.8, p. 25. No se simula una tirada ni se supone éxito. IM Atravesar no concede separación automática. IM Personajes sí está verificada. |
| Tamaños Tiny/Giant/Colossal | Perfil conservador con figuras Normal en el escenario; otras interacciones de tamaño quedan pendientes. |
| IM Bloqueado exterior | No existe clasificación indoor/outdoor en el escenario; §27.5c. |
| IM Destruir bloqueado | Exige destrucción y efectos sobre el mapa que no se modelan; §27.5d. No se convierte en un simple permiso para ignorar B. |
| Vuelo, transporte, poderes/efectos arbitrarios | No se deducen del nombre o tamaño de base. Deben declararse como otro efecto o capacidad sin soporte. |
| Giro o elección de otra referencia de base | §24.2d mueve una referencia; no exige arrastrar rígidamente toda la base durante el trayecto. El producto verifica un subconjunto conservador: traslación fija. Si otra parte requiere una maniobra distinta se informa No evaluado, sin afirmar ilegalidad reglamentaria general. |
| Base mixta de niveles o formato no reconocido | Se preserva el dato antiguo, pero no se aprueba su movimiento. |
| Ocupación inicial incompatible / edición desconocida | Se exige corregir la posición de estudio o usar la edición registrada. |
| Acciones, turnos, dados, daño, valores modificados | Se consulta una trayectoria con el presupuesto declarado; no se valida una acción MOVE ni un ataque. |

Un destino sobre B, otra figura, fuera de límites o con muro interior de la base
es inválido; no se legaliza por una mejora de paso. Una ruta que continúa después
de una parada obligatoria es inválida. Una condición relevante sin soporte es
No evaluado. Los tres estados no son intercambiables.

## Búsqueda y confirmación

La búsqueda conserva prefijos que atraviesan aliados/B permitido aunque no puedan
ser destinos. No expande una parada obligatoria ni condiciones sin soporte. Una
visita que llegó detenida no descarta otra llegada que permita continuar.
Reutiliza verificaciones de aristas y adyacencia dentro de cada consulta. Devuelve
hasta tres soluciones por distinto primer paso, ordenadas por costo; no promete
enumerar todas las rutas. Si no encuentra una, informa **«No se encontró ruta
válida bajo las reglas implementadas y la velocidad declarada»**. Eso no prueba
imposibilidad bajo poderes o maniobras que el perfil no implementa.

El ensayo conserva el snapshot original, ruta y comparación en memoria. Cancelar,
volver al inicio o cerrar el informe no desplazan la figura. Cerrar el informe
permite seguir añadiendo pasos en el tablero. Confirmar exige ruta válida no vacía,
vuelve a validar el escenario vigente y aplica un comando de posición reversible.
Una edición, carga, cambio de contenido o salida de herramienta limpia el ensayo.
Cámara y selección no lo alteran. Editor mantiene el reposicionamiento libre para
montar escenarios; Simulador ofrece explícitamente movimiento reglamentario.

## Persistencia y pruebas

Esquema de documento 3: añade `movementAbilities` por figura, conserva visión,
tamaño y capas. Lee 1/2/3 y exporta 3. Antes de reemplazar 1 o 2, guarda copia
exacta `schema1-ID` / `schema2-ID` (también working). Los respaldos no aparecen en
la biblioteca. Si fallan, no se reemplaza el original. Las capas siguen esquema 2.
Ruta, alternativas y posiciones hipotéticas no se serializan ni escriben archivos.

Los casos M01–M27 son escenarios sintéticos con expectativas derivadas de los
apartados oficiales indicados, no ejemplos gráficos publicados ni reglas
inventadas por la geometría. Se ejecutan en Dart puro con
`dart run tool/verify_movement.dart` y como tests Flutter. Estado, migración, UI,
cancelación, historial y comparación tienen pruebas adicionales. Resultados,
mediciones y límites de dispositivo están en ESTADO.md.
