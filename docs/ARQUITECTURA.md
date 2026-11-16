# Arquitectura

## Dependencias

`presentación → aplicación → dominio`. La infraestructura implementa los
puertos de aplicación. El punto de entrada compone las dependencias; el dominio
no importa Flutter, infraestructura ni plataforma.

| Ruta | Responsabilidad actual |
| --- | --- |
| `lib/main.dart` | Composición de archivos Android, repositorio, workspace y editor |
| `lib/app.dart` | MaterialApp, idioma y tema |
| `lib/domain/` | Tipos puros, sin widgets ni acceso a plataforma |
| `lib/application/` | Catálogo, sesión inmutable de tablero y puertos de persistencia |
| `lib/presentation/` | Inicio, Editor, adaptación de gestos/cámara y tema |
| `lib/infrastructure/local/` | FileDocumentStore y AndroidScenarioFiles |
| `android/` | Adaptación nativa, identidad y configuración de build |
| `test/` | Contratos de dominio y pruebas de widgets |

`domain/board` contiene BoardDimensions, CellCoordinate, BoardGeometry,
BoardCamera y ViewportSize. characters implementa figuras, equipos y ocupación.
terrain implementa terrenos, muros normalizados y geometría de edición. geometry
implementa intersecciones exactas en 05. rules incorpora visión básica en 06 y
distancias/objetivos en 07;
movement y training conservan documentación de alcance para etapas futuras.

## Estado y persistencia

El inicio usa un catálogo inmutable; Editor, Simulador y Árbitro están disponibles. `BoardSession`
es la única fuente de verdad del tablero: dimensiones, selección, cámara,
viewport, opciones de visualización, figuras, equipos, terreno y muros. Es inmutable y no importa Flutter.

`EditorController` es un ValueNotifier de presentación que adapta cambios de
sesión a widgets. HeroClixApp lo posee y lo destruye al salir de la app. Desde 04,
WorkspaceController autoguarda las ediciones lógicas y recupera el documento al
arrancar. Cámara, selección y preferencias de vista permanecen solo en memoria.

InteractiveViewer usa una TransformationController como proyección de la cámara.
Sus cambios se convierten a BoardCamera; los botones modifican BoardSession y el
adaptador sincroniza la matriz sin bucles de notificación. No hay dos cámaras
independientes que decidan la selección.

El viewport se actualiza después del layout. Al redimensionar se conserva el
punto lógico central y el zoom; «Ajustar» encaja el mapa completo. La selección
siempre es CellCoordinate, nunca un Offset o píxel de pantalla.

`LocalDocumentStore` define leer/escribir/eliminar/listar. FileDocumentStore
implementa archivos privados con límites y reemplazo mediante temporal/rename.
ScenarioRepository separa biblioteca de recuperación; ScenarioCodec valida
documentos 1/2/3 y exporta esquema 3. WorkspaceController serializa I/O y revisiones,
conserva la sesión ante fallos y publica una nueva solo después de protegerla.
LayerCodec sigue validando terreno/bordes como parte del documento completo.

## Render y gestos en 01

BoardPainter dibuja una superficie, líneas por fila/columna, rótulos de ejes y
una selección. No crea un widget por casilla: el mapa 40×40 sigue usando un solo
CustomPaint aislado por RepaintBoundary. Cambiar la matriz de cámara no vuelve
a calcular la geometría ni la selección en los widgets.

El hit test usa BoardGeometry tras invertir la cámara. Una pinza o desplazamiento
que supera el umbral táctil no produce selección; un gesto con varios punteros
queda bloqueado para selección hasta un nuevo toque. Es independiente del zoom.

Terreno, muros y figuras tienen capas operativas desde 03. En 06 se añaden
superposiciones del dictamen básico y sus causas.
La cuadrícula y su selección no
se almacenan como si fueran terreno ni figuras.

## Motor compartido

Geometría ya emite intersecciones exactas y la UI representa sus resultados.
LineOfSightService interpreta el perfil básico de 06. Editor, Simulador y Árbitro
usan el mismo servicio; Entrenador lo reutilizará más adelante. Las condiciones
fuera de cobertura devuelven «No evaluado». No se decide la legalidad de un ataque.

## Plataforma y red

Solo se genera Android. No se bloquean orientaciones. El diseño usa restricciones
de ancho, ajuste del texto y desplazamiento vertical. No hay clientes HTTP,
cuentas, telemetría, fuentes remotas ni assets descargados en runtime.

## Figuras y ocupación en 02

BoardSession incluye CharacterRepository, equipos y selección por ID. El repositorio
solo devuelve nuevas colecciones después de validar, y mantiene ocupación derivada
para todas las celdas de cada Footprint. CharacterDraft separa datos editables de la
identidad/etiqueta estable de Character. No importa Flutter.

La presentación recoge formularios y llama al controlador; nunca decide ocupación.
El arrastre conserva el mundo hasta soltar: FigureDragPreview vive únicamente en
BoardCanvas, usa validatePlacement y se pinta como superposición. Se revalida el
movimiento al confirmar. Las figuras se pintan tras cuadrícula/coordenadas, con
código de equipo, patrón y resaltado de selección. Terreno/muros se integran en 03.

## Edición de capas en 03

BoardSession centraliza política de conflictos, pintura y limpieza por capa.
BoardEdit guarda estados de capas inmutables antes/después de una operación y
puede aplicar/revertir sin restaurar cámara; en 04 EditorHistory conserva 100
operaciones y el controlador expone deshacer/rehacer.
LayerDraft es un borrador transitorio en un ValueNotifier separado de la sesión:
no hay una mutación del escenario por cada píxel del arrastre.

BoardCanvas usa punteros para capturar un trazo y cancelar al añadir otro dedo.
EditingGeometry convierte puntos mediante la cámara y evita huecos entre eventos.
Al soltar, LayerActions confirma conflictos o borrado y aplica una sola operación.
Los rectángulos esperan confirmación explícita; coordenadas ofrecen el mismo flujo.
BoardPainter dibuja terreno, cuadrícula, figuras, muros, advertencias y previas.
Las advertencias de estudio se derivan de las capas; no son reglas de HeroClix.

LayerCodec serializa un fragmento terreno/bordes, sin I/O propio. Desde 04 ese
fragmento se integra en el documento completo y el almacenamiento local.

## Persistencia e intercambio en 04

ScenarioDocument contiene identidad, nombre, referencia reglamentaria y fechas,
además del mundo lógico. Los detalles del esquema y políticas están en
[ESCENARIOS.md](ESCENARIOS.md). Todos los tipos de documento/codec/repositorio y
puertos siguen fuera de Flutter. WorkspaceController coordina en presentación
los callbacks de sesión, estado sucio, recuperación e I/O; no duplica el mundo.

EditorController registra solo cambios de contenido: camera/selección/previas no
ensucian el documento ni generan historial. Un gesto confirmado genera un comando.
BoardSession.restoreContent preserva contadores monotónicos; cargar otra escena
limpia historial y ajusta cámara. No hay pila persistida ni snapshots por píxel.

ScenarioFiles es un puerto para selección, exportación y compartir. Android lo
implementa por MethodChannel, SAF y FileProvider de alcance limitado; los tests
sustituyen ese puerto. BoardPngExporter reutiliza BoardPainter con PictureRecorder,
sin widgets ni cámara de pantalla. Los renders de verificación usan un store en
memoria; main de producción siempre compone archivos privados reales.

## Geometría exacta en 05

SightGeometry y ExactFraction pertenecen al dominio. Reciben dimensiones,
SightPath y WallLayer y devuelven eventos/intervalos inmutables con coordenadas
racionales. No conocen cámara, Flutter, archivo, terrenos ni interpretación de
reglas. SightPath/traceCandidates prepara varias candidatas explícitas.

SightProbe pertenece a aplicación: resuelve extremos fijos o ligados por ID a una
figura y casilla relativa de su base. EditorController lo recalcula antes de
notificar cambios de mundo; caché por dimensiones, personajes y muros evita
repetir geometría en zoom, selección o terreno. No entra en BoardSession guardado,
JSON ni historial. Cargar otro documento limpia referencias y resultado.

SightPainter es foregroundPainter del canvas. Solo proyecta fracciones a unidades
de escena y dibuja tramos/contactos ya calculados, sin repetir intersecciones.
El exportador PNG conserva BoardPainter de 04 y excluye esta inspección transitoria.
SightControls adapta selección, formulario de referencias y panel de eventos.
El algoritmo, límites y convenciones están en GEOMETRIA.md.

## Visión reglamentaria básica en 06

LineOfSightService implementa VisionEvaluator en Dart puro. VisionSnapshot copia
la colección de figuras y conserva capas inmutables; VisionContext identifica la
edición y condiciones especiales. La salida incluye estado, canSee trivalente,
traza geométrica, observaciones por evento, reglas y elementos decisivos.
La geometría no cambia: el servicio consume SightGeometry, sin replicar cortes.

VisionAnalysis coordina la caché del resultado en aplicación. Comparte extremos
de SightProbe y se invalida por dimensiones, figuras, terreno, muros o contexto.
Cámara, selección y resaltados no recomputan las reglas. El cambio de versión de
metadatos también invalida aunque las capas sean idénticas. Cargar otra escena
limpia referencias, resultado y declaración de efectos; no cambia el esquema JSON.

Editor, Simulador y Árbitro usan la misma instancia de EditorController y la misma
entrada evaluate. VisionScreen es una vista de selección/navegación con acceso
explícito a Editor. Una vista de lectura cubierta no modifica el viewport compartido:
se evita que dos rutas alternen tamaños y provoquen cuadros de render continuos.

VisionControls muestra dictamen y registro; SightPainter solo proyecta el resultado,
colorea la línea y resalta causas. No decide reglas en widgets. La inspección
geométrica sigue separada y PNG continúa excluyendo análisis transitorio.
La matriz documenta las referencias, decisiones y fronteras de soporte.

## Distancia y objetivos en 07

DistanceService aplica el conteo de §11.3a entre casillas. TargetAnalysisService
combina esa distancia, el alcance declarado y el mismo VisionEvaluator de 06.
TargetEvaluation conserva dimensiones independientes, categoría de consulta,
restricciones comprobadas/pendientes y referencias. No produce permiso de ataque.

TacticalAnalysis es estado transitorio en aplicación, coordinado por el mismo
EditorController. Cambios del mundo, extremos, alcance, versión o condiciones
actualizan resultados; cámara y selección no escriben ni invalidan el mundo.
En 07, TacticalVisionCache limitaba a 256 pares del mismo mundo/contexto. Compara las
figuras mediante registros tipados de identidad, posición, huella, equipo y etiqueta;
rango/nombre no afectan los obstáculos. Cambiarlos reutiliza visión y recalcula
distancia/comparación/lista. El filtro también reutiliza resultados.

Las herramientas distance/targets se habilitan en Editor. VisionScreen las ofrece
mediante Elegir análisis con el mismo controlador. TacticalControls representa
resultados ya calculados; editar alcance pasa por saveCharacter y el historial.
SightPainter proyecta anotación y contorno del objetivo; no calcula distancia ni
alcance. El exportador PNG usa BoardPainter y excluye análisis transitorios.
En 07 se conservó el esquema JSON 1. Al cargar se limpian origen, objetivo, filtro y caché.

## Elevación, referencias y capacidades en 08

CellTerrain mantiene tipo y elevación separados; `level` interpreta el 0 legado
como suelo 1. TerrainLayer añade transiciones canónicas entre vecinos. Los bordes
de altura se derivan de niveles, sin guardarlos como muros. Editar altura conserva
tipo; limpiar tipo conserva altura y transiciones. Historial y validación usan
las mismas capas inmutables. La edición de región copia el mapa una vez.

CharacterDraft guarda VisionAbility tipadas y FigureSize independiente de Footprint.
Se conservan al mover, duplicar, editar alcance y serializar. El motor consume
las cuatro mejoras verificadas; otras condiciones generan SCOPE. El laboratorio
es una sustitución inmutable de capacidades en VisionContext, transitoria.

LineOfSightService compone terreno, nivel, ocupación y capacidades antes de evaluar
cada lado de un vértice. Registra exclusiones y restricciones activas. Geometría
permanece sin reglas. TargetAnalysisService consulta pares de huella (hasta 324),
usando una referencia común para distancia/visión. VisionAnalysis puede buscar
una línea visible sin depender de alcance; en Objetivos recibe el resultado del
par coherente elegido por TacticalAnalysis. Canvas y pie muestran esa traza real.

La caché tipada incorpora capacidades, tamaño y contexto de laboratorio; máximo
1024 pares de un mundo. Cámara/filtro y cambios de rango conservan visión cuando
los obstáculos no cambian. No se calcula en los widgets ni en el painter.

ScenarioCodec/LayerCodec exportan esquema 2 y leen 1/2. La lectura no modifica el
archivo. ScenarioRepository conserva bytes anteriores antes de reemplazar un
esquema 1; FileDocumentStore acepta solo IDs de respaldo validados y los excluye
de biblioteca. No se cambia el directorio privado existente. Modo árbitro usa el
informe compartido con pares, reglas, eventos y modificaciones.

## Movimiento en 09

MovementRulesService implementa paso, traslación de base y validación de ruta en
Dart puro. La ruta contiene coordenadas lógicas, origen incluido; eventos registran
paso, casilla, regla y motivo. Distingue paso permitido, parada obligatoria,
invalidez y condición sin soporte. La velocidad declarada es el presupuesto.

RoutePlanner realiza búsquedas BFS por primer paso, con costo 1 y memoización de
aristas/adyacencia dentro de la consulta. No expande estados que deben terminar.
Los destinos ilegales pueden ser prefijos transitables con la mejora correcta.
Cada alternativa se valida otra vez como ruta completa antes de ofrecerse.

MovementAnalysis conserva snapshot original, ruta, resultado, alternativas y
comparaciones antes/después. Usa TargetAnalysisService/LineOfSightService de
06–08 sobre un mundo futuro separado; no escribe. EditorController invalida por
cambio de contenido y revalida al confirmar; aplica moveCharacter mediante el
historial existente. Cancelar/reset no hacen operaciones de contenido.

MovementToolbar/MovementDialog muestran estado, presupuesto, motivos, capacidades
y comparación. BoardCanvas añade casillas al ensayo incluso en Simulador de
lectura; MovementPainter solo proyecta ruta numerada y las huellas original/final.
El arrastre libre del Editor es independiente de la validez reglamentaria.

ScenarioCodec exporta documento 3 y lee 1/2/3. Añade movementAbilities, preservadas
al mover, duplicar y editar alcance. ScenarioRepository respalda exactamente 1/2
antes del primer reemplazo; FileDocumentStore admite IDs schema1/schema2 validados.
LayerCodec mantiene esquema 2. No hay persistencia de rutas ni posiciones de ensayo.
