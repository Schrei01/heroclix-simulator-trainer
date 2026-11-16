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
