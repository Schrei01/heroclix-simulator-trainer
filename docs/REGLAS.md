# Fuentes reglamentarias y validación

Consulta realizada el 2026-11-13 durante el desarrollo, sin dependencia de red
en la aplicación.

- Fuente oficial: https://wizkids.com/heroclix/gameplay/rules-format/
- Publicación: **2026 HeroClix Comprehensive Rulebook**.
- La página indica literalmente la fecha `Updated 07.01.2026`.
- Documento enlazado:
  https://wizkids.com/wp-content/uploads/2026/07/HeroClix%20Comprehensive%20Rules%2007.01.26.pdf
- Referencia objetivo de planificación: **2026-07-01** (1 de julio de 2026),
  consistente con el nombre y directorio del archivo oficial.

La cabecera extraída automáticamente del PDF conserva referencias históricas;
antes de implementar cada regla se revisará la fecha de la página pertinente,
sección, erratas y ejemplos. No se presume que toda regla fue revisada por haber
consultado el enlace. La edición objetivo no significa cobertura implementada.

## Cobertura en 00

**Ninguna regla implementada ni validada.** No hay cálculos de visión, distancias,
movimiento, ataques ni excepciones. El inicio no emite dictámenes.

## Método obligatorio para etapas posteriores

1. Consultar fuente oficial y confirmar edición aplicable; informar de una
   publicación nueva antes de adoptarla.
2. Registrar ID de regla, sección y fecha, resumen propio, límites, ejemplos
   oficiales y tests vinculados.
3. Separar datos geométricos de interpretación reglamentaria.
4. Derivar expectativas de las fuentes, no del algoritmo implementado.
5. Registrar ambigüedades y devolver «No evaluado» cuando falte soporte.
6. Versionar cambios y revisar escenarios/ejercicios que dependan de ellos.

No se distribuyen el PDF, texto completo, iconografía ni ilustraciones oficiales.
La herramienta futura será de apoyo, no una decisión oficial de torneo.

## Cobertura en 05

Geometría exacta centro-a-centro operativa en el Editor: casillas interiores,
bordes y vértices. Un contacto con muro/figura no se interpreta como veredicto.
No se implementa ni valida una regla oficial adicional en esta etapa; la versión
objetivo del documento permanece como referencia. GEOMETRIA.md describe el
contrato matemático; la evaluación reglamentaria de visión corresponde a 06.

## Validación para 06

Consulta de la página y PDF oficiales iniciada el 2026-11-14, lectura/contratos
verificados el 15 e integración cerrada el 16. Se mantiene 2026-07-01: la página
continúa enlazando esa edición y los pies de las páginas 27, 39, 40, 43 y 44 la
confirman. No se tomó el título histórico de metadatos como versión del contenido.
La matriz MATRIZ_REGLAS_VISION.md enlaza secciones, decisiones, límites y pruebas.

Implementado un perfil de visión para figuras genéricas normales, sin poderes,
en tablero plano. Bases/elevaciones relevantes, condiciones declaradas fuera de
cobertura e interpretaciones pendientes regresan No evaluado. Ese estado es una
política de implementación, no un dictamen oficial de bloqueo. No se evalúa ataque
completo ni alcance. Fuente y SHA-256 del PDF de consulta figuran en la matriz;
no se distribuye el reglamento con la app ni con el repositorio.

### Revisión de vértices oblicuos — 2026-11-16

Se vuelve a consultar el enlace oficial y §16.8b, página impresa 44, ante el
reporte A1–D6/B4. Se retira la limitación de 45° del perfil inicial: el texto
operativo de esa sección prescribe comparar los dos lados de la intersección
sin condicionar el procedimiento a la pendiente global. Con B4 bloqueado y
C3 libre, el contacto puntual en (2,3) no bloquea. No se cambian la edición
ni las reglas de obstáculos que la línea atraviesa por el interior.
La matriz registra R23–R25 y corrige la expectativa anterior de R17.

## Validación para 07 — 2026-11-16

La página oficial sigue enlazando 2026-07-01. Revisión de §11.3a–b (conteo y
comparación con alcance), §11.4a y §11.5 (misma fuente), y §11.2a/12.1 (condiciones
de ataque que exceden esta consulta), páginas 26–28. Se conserva la edición.
MATRIZ_DISTANCIAS_OBJETIVOS.md documenta fórmula derivada, límites por dimensión,
prioridad de categorías y contratos D01–D02/T01–T11. Rango declarado no equivale
a cálculo completo del valor modificado; aliados consultables no se declaran
objetivos de ataque universalmente legales. En 07, bases y excepciones quedaron
pendientes de 08. Se reutilizó la corrección oblicua de 0.7.1.

## Validación para 08 — 2026-11-16

Se revisan nuevamente las fuentes oficiales, manteniendo 2026-07-01: elevación
§16.5c–g (p. 42), transiciones §16.7 (p. 43), tamaños intermedios §21.2b (p. 60),
bases §24.2/a/e (pp. 69–70), y mejoras §27.6a/b/c/e (p. 87). La PAC enlazada por
WizKids es de 2023; solo se usan las definiciones que coinciden con el texto 2026.

## Composición para 11 — 2026-11-16

No se implementan nuevas reglas: el analizador compone los motores verificados de
06–09 bajo 2026-07-01. Definiciones de métricas y referencias en ANALISIS_TACTICO.md.
Visible incluye H y no exige alcance. Amenaza conocida exige visión y alcance
desde un par coherente (§11.5), sin validar ataque, acción, daño ni dados.
Capacidades actúan solo en su dirección y componente; retirar mejoras soportadas
no elimina tamaño/otros efectos sin soporte. Esos casos conservan No evaluado.
Los contratos A01–A14 incluyen bases que tienen una referencia visible y otra en
alcance sin una referencia común: no se cuenta una amenaza falsa. No se copia
texto oficial ni se redistribuye el PDF. Fuente y hash conservados en matrices.
La matriz MATRIZ_CAPACIDADES_VISION.md distingue soporte y fronteras pendientes,
orden de composición, pares de referencias y expectativas sintéticas derivadas
del texto. No son diagramas oficiales copiados ni se interpreta texto de cartas.

## Validación para 09 — 2026-11-16

La página oficial continúa enlazando Comprehensive Rulebook 2026-07-01. Se revisan
§10 (pp. 24–25), ocupación §13.2 (p. 35), movimiento por terreno y muros
§16.2a/16.3a/16.4a (pp. 39–40), altura y transición §16.5a/16.7b (pp. 41/43),
esquinas/adyacencia §16.8a/c (p. 44), bases §24.2b/d (pp. 69–70) y mejoras
§27.5a/b/e/f (p. 86). Se usa la regla actual de H sin costo adicional. La separación
con dado, IM exterior/destrucción, tamaños y otros efectos no resueltos no se dan
por aprobados. MATRIZ_MOVIMIENTO.md vincula M01–M27 y casos sintéticos derivados
con estos apartados; no los presenta como diagramas oficiales publicados.

## Validación para 10 — 2026-11-16

Se confirma en la página oficial el enlace a la edición 2026-07-01. El Entrenador
reutiliza los servicios y límites registrados en las matrices de 06–09; no adopta
reglas distintas según dificultad ni interpreta cartas. ENTRENADOR.md vincula los
24 IDs con sus conceptos/secciones. Las soluciones son literales de regresión y
se comparan con los motores en Dart puro y tests. Una divergencia o No evaluado
inhabilita autocorrección. Los casos son sintéticos originales derivados del
reglamento; no se copian ejemplos gráficos oficiales. Feedback en palabras propias
con referencias cortas. Texto personal libre se identifica como revisión manual.
