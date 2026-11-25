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

Desde la etapa 1 de Priority, `domain/priority` contiene un motor independiente
para el formato personalizado de partidas físicas. Sus estados son inmutables;
`PriorityEngine` valida comandos y devuelve partida/eventos por transición. No
depende del tablero, Flutter, plataforma ni persistencia. Desde la etapa 2,
`presentation/priority` lo conecta a la navegación con un `PriorityController`
propiedad de `HeroClixApp`, que conserva la partida en memoria al salir/volver.
La UI envía comandos y consulta la validación del motor; no implementa consumos
ni circulación. Geometría/rotación de paneles, edición y protección de entradas
pertenecen a presentación. Contrato en `lib/domain/priority/README.md` y avance en
[PRIORITY_PLAN.md](PRIORITY_PLAN.md).

`domain/board` contiene BoardDimensions, CellCoordinate, BoardGeometry,
BoardCamera y ViewportSize. characters implementa figuras, equipos y ocupación.
terrain implementa terrenos, muros normalizados y geometría de edición. geometry
implementa intersecciones exactas en 05. rules incorpora visión básica en 06 y
distancias/objetivos en 07;
movement y training conservan documentación de alcance para etapas futuras.

## Estado y persistencia

El inicio usa un catálogo inmutable con Editor, Entrenador y Priority. `BoardSession`
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
LineOfSightService interpreta el perfil básico de 06. Editor y Entrenador
usan el mismo servicio. Las condiciones
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
Al soltar, LayerActions valida conflictos o confirma borrado y aplica una sola operación.
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

El Editor concentra edición y análisis en una instancia de EditorController y la
misma entrada evaluate. Simulador, Árbitro y su VisionScreen se retiraron en rc.4;
VisionControls y los motores siguen disponibles dentro del Editor.

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
de biblioteca. No se cambia el directorio privado existente. El Editor usa el
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
y comparación. BoardCanvas añade casillas al ensayo desde la herramienta Movimiento
del Editor; MovementPainter solo proyecta ruta numerada y las huellas original/final.
El arrastre libre del Editor es independiente de la validez reglamentaria.

ScenarioCodec exporta documento 3 y lee 1/2/3. Añade movementAbilities, preservadas
al mover, duplicar y editar alcance. ScenarioRepository respalda exactamente 1/2
antes del primer reemplazo; FileDocumentStore admite IDs schema1/schema2 validados.
LayerCodec mantiene esquema 2. No hay persistencia de rutas ni posiciones de ensayo.

## Entrenador en 10

Exercise, Answer, Evaluation, Feedback, SkillCategory, RuleSetVersion y progreso
son Dart puro. El banco curado versión 1 guarda 24 escenarios y soluciones
literales de regresión. ExerciseEvaluator delega en servicios de visión,
distancia, objetivos y movimiento, sin copiar reglas en widgets. Si la edición o
la solución no coinciden, o un servicio devuelve No evaluado, no autocorrige.

TrainingCodec/TrainingRepository almacenan snapshots personales y contadores en
un directorio privado separado. Documento de entrenamiento 2, lectura 1/2, copia
exacta del legado antes de reemplazar. Snapshots reutilizan ScenarioCodec 1/2/3.
No cambia el formato 3 del Editor. IDs/revisión/edición separan progreso y revisiones
antiguas; los resultados guardados no se recalifican al consultarlos.

TrainingController coordina lectura, comprobación y escritura serializada. Solo
confirmar una respuesta registra un intento; revisar, pista y repetir no escriben.
Un token impide duplicados de confirmación. Publica estado tras guardar; fallos
conservan el anterior. App espera escrituras en curso al pasar a segundo plano.

TrainingScreen filtra banco y progreso; ExerciseScreen controla respuestas y un
EditorController independiente sin workspace. BoardCanvas recibe un callback de
casilla y TrainingPainter neutro, sin reutilizar la escena abierta ni los diálogos
de visión. Tras comprobar, desplaza la vista al feedback y cierra el teclado.
PersonalExerciseDialog copia un escenario de biblioteca, recoge pregunta/opciones
pista/solución y verifica antes de guardar. Texto libre se declara manual.

La única comparación de posiciones de 10 es un predicado de ejercicio: un paso
legal con alcance y visión despejada. No se introducen métricas ni recomendaciones
tácticas de 11. Límites, banco y almacenamiento: ENTRENADOR.md.

## Análisis de posiciones en 11

TacticalAnalysisService y diagnósticos son Dart puro. Componen los servicios de
movimiento, distancia y visión mediante TargetAnalysisService. Separan visión
independiente de alcance de la consulta combinada que requiere un mismo par de
referencias. Cada métrica conserva conocidos/desconocidos y límites por edición.

PositionAnalysisController toma un snapshot inmutable del Editor y manda lotes de
12 destinos a un isolate con progreso por enemigo/posición. Cancelar mata el worker;
tokens de generación descartan mensajes tardíos. Caché de ocho páginas invalidada
por contenido, ficha, versión y efectos; cámara/prioridad no invalidan. El cálculo
limita a 32 enemigos y conserva omitidos como desconocidos. Resultados completos
se ordenan por prioridad transparente; incompletos quedan separados.

TacticalScreen usa cámara propia. El mapa representa anclas y la ruta valida toda
la huella. Confirmar revalida y aplica un solo comando con Deshacer. Comparar sin
mejoras soportadas del activo es una hipótesis; no modifica fichas ni elimina
incertidumbre por capacidades que no se saben evaluar.

AnalysisExerciseRequest y fábrica en isolate crean ejercicios con rutas guardadas,
verificados por ExerciseEvaluator antes de añadirlos al repositorio existente.
TrainingScope comparte el controlador del Entrenador con las rutas del analizador.
TrainingCodec pasa a esquema 3 y lee 1/2/3: candidateRoutes es opcional para legado.
Se respalda exactamente formato 1/2 antes de reemplazar y se conservan contadores.
El esquema de escenarios continúa 3; no se guardan métricas en la escena.

DiagnosticSummary y DiagnosticPng generan artefactos desde datos controlados,
remapeando etiquetas/equipos y sin nombres, IDs ni metadatos de la escena. PNG no
captura widgets. Reutiliza selector/compartir Android existente sin permisos nuevos.
Definiciones, límites y mediciones en ANALISIS_TACTICO.md.

## Consolidación en 12

AppInfo identifica versión/build y edición, contrastados con pubspec y el motor
en test. Inicio añade navegación a Guía rápida, Acerca de y catálogo original.
InformationScreen comparte estructura desplazable, anchura máxima y altura de
barra ajustada al texto. La página de licencias usa LicenseRegistry de Flutter
y los avisos empaquetados, sin servicios remotos.

LocalExample referencia escenas del banco curado ya verificado y crea documentos
con ID nuevo. La vista previa usa un EditorController independiente; abrir copia
pasa por la misma protección de cambios sin guardar que biblioteca/importación.
Se deshabilita durante recuperación/escritura y conserva escenas anteriores.
No se escribe el catálogo en biblioteca al arrancar ni se cambia esquema alguno.

El puente nativo verifica pares exactos MIME/extensión: JSON/PNG/TXT, con límites
2/16/2 MiB y nombres controlados. Se corrige el rechazo del resumen táctico TXT
de 11. Detalles de escenario muestran esquema vigente; caché táctica recupera
también selección de una consulta individual. No hay dependencias ni permisos nuevos.

La aceptación automatizada combina controladores y almacenamiento real con UI
de ejercicio, restauración e intercambio de archivos. La matriz separa esa prueba
del recorrido instrumental pendiente. Se mantiene 1.0.0-rc.1 sin afirmar aceptación
nativa ni rendimiento en Android; README_FINAL explica cómo cerrar esos criterios.

## Interacciones rápidas del Editor — rc.2

TerrainPalette sustituye el selector de tipo desplegable y ocupa una franja propia
centrada al pie del mapa, fuera del receptor de gestos. Usa configureLayers, sin
registrar una edición hasta pintar. En poco alto el Editor mueve herramientas a
la izquierda y compacta la barra de capas mediante iconos/tooltip accesibles.
No se superponen controles a las casillas ni se alteran formatos o reglas.

BoardCanvas coloca CharacterDraft con los valores predeterminados mediante el
saveCharacter existente, conservando validación/historial/autoguardado. La ficha
queda para edición posterior; sobre bloqueado se conserva confirmación de estudio.
La ayuda transitoria se retira al colocar para no interceptar el lápiz inferior.
ElevationDialog propone el nivel existente limitado inferiormente a 2; el usuario
puede escribir 1 para volver a suelo. La capa de terreno no cambia su valor inicial.

## Sesión temporal y dictamen inmediato — rc.3

WorkspaceController usa `persistWorkingSession: false` por defecto. Inicializar
prepara el documento en memoria sin leer ni escribir la recuperación antigua;
editar y pasar a segundo plano no guardan `working.json`. Nuevo EditorController
en cada apertura inicia BoardSession.initial con contador 1. Navegación y segundo
plano conservan la misma instancia; Guardar/Guardar como siguen escribiendo en la
biblioteca y el Entrenador conserva su repositorio persistente independiente.

La compatibilidad heredada de recuperación se mantiene con opt-in explícito para
sus pruebas de formatos/archivos. Las pruebas de producción usan el valor false,
incluido arranque tras AA y disco real. Se ignora el working antiguo sin borrarlo
ni modificar biblioteca. Reintentar guardado vuelve a ejecutar Guardar.

Activar la herramienta Visión habilita su evaluación. VisionVerdictBar presenta
el VisionEvaluation existente al completar extremos, con icono/color/texto y
semántica liveRegion; tocar abre el informe compartido. Se reserva una franja sobre
el mapa en Editor. No duplica reglas ni publica el resultado
anterior tras limpiar o invalidar extremos. Referencias automáticas son el valor
predeterminado; la inspección manual sigue disponible al desactivarlas.

## Editor y transiciones — rc.4

AppMode y HomeCatalog contienen solo editor/trainer. HomeScreen abre EditorScreen
o TrainingScreen; VisionScreen se elimina. Los servicios y controles de análisis
se reutilizan en EditorScreen. No hay datos persistidos de modos que migrar.

BoardPainter diferencia elevaciones normales (E2/E3) de transiciones (dos triángulos
blancos con borde rojo y sus niveles, uno dentro de cada casilla conectada).
BoardPngExporter reutiliza el painter; no cambia TerrainMap ni ScenarioCodec.
Los marcadores se derivan de los bordes de transición existentes. Las pruebas de
exportación decodifican píxeles de ambas orientaciones y verifican retirada y JSON.
El Editor coloca herramientas lateralmente cuando el área disponible es baja,
para conservar el mapa y evitar desbordamientos también en Distancia/Objetivos.

## Terrenos y gestos — rc.5

BoardDimensions.initial pasa a 10×10. La restauración sigue usando las dimensiones
del documento. ResizeViewport vuelve a ajustar únicamente una cámara que todavía
coincidía con el ajuste automático anterior; la cámara manual conserva centro/zoom.

TerrainBrush separa las cinco opciones de edición de TerrainType (tres tipos
persistidos). Elevado y Transición usan toques, no trazos: el primero incrementa
altura y el segundo guarda un extremo transitorio hasta validar el par. No se
serializan pinceles ni selecciones. EraseLayer añade terreno, elevación y transiciones.
LayerActions confirma borrado por segundo toque y aplica comandos a una sola capa.
Las validaciones de base multinivel y los errores atómicos siguen en BoardSession.

Los comandos de personajes y pintura dejan de aceptar allowStudy. Restore/codec
conservan escenas antiguas incompatibles para corregirlas; ninguna acción de creación
ofrece ese permiso. Se conservan IDs de capacidades antiguas, ocultando Other en
las listas de la ficha. Targeting usa el mismo patrón de expansión que Movement.

SetSightEndpoint limpia extremos/selección cuando coinciden en la herramienta
Visión. No cambia la geometría pura ni el conteo cero de Distancia. La barra de
cámara deja de repetir el dictamen: conserva referencias e instrucciones.
## Equipos y trazos — rc.6

CharacterDraft.withTeam conserva todos sus campos. BoardSession.cycleCharacterTeam
usa el orden de teams y el comando de edición existente. BoardCanvas cuenta pares
de toques solo en Personajes y sobre figuras existentes; arrastre, pinza y creación
limpian ese extremo transitorio. Un único equipo no modifica contenido ni historial.

LayerDraft incluye TerrainBrush. Elevado usa cellsAlong y un conjunto de casillas;
TerrainLayer.raiseElevations calcula cada destino desde la capa original y filtra
transiciones solo al finalizar. BoardSession comprueba entonces las bases completas.
BoardPainter presenta los niveles de destino sin mantener el badge antiguo debajo.
No hay mutaciones parciales durante los movimientos del puntero.

EraseLayer.all es el valor inicial y se restablece al activar Borrar. EraseCells
elimina las capas de las casillas tocadas, muros/transiciones incidentes y figuras
completas que tocan alguna. Conserva lo demás y devuelve la sesión original si no
hay contenido que quitar. El mismo historial agrupa cada trazo; las variantes de
borrado por capa siguen disponibles explícitamente.

ToolHint recibe un registro transitorio con identidad y texto del controlador.
Su widget posee un Timer de cuatro segundos, se renueva con identidad nueva y se
cancela al desmontar. Desde rc.7 se muestra sin rotación, en una columna de texto
derecho con ajuste de líneas y bloques. IgnorePointer lo ubica al borde derecho
sin cambiar geometría ni interceptar gestos. El alto limita las líneas visibles y
la semántica conserva el texto completo. No se persiste ni se exporta al PNG.

## Identidad TeamFight: GridLab — rc.8

AppInfo.name e iconAsset centralizan la marca Flutter. MaterialApp, HomeScreen,
AboutScreen y licencias los reutilizan. El recurso PNG está declarado en pubspec;
Home/Acerca de lo muestran como imagen decorativa junto al nombre accesible.

AndroidManifest usa app_name y mipmap/ic_launcher + ic_launcher_round. Los PNG por
densidad y XML anydpi-v26 componen la identidad normal/adaptable/monocromática.
El ID/namespace/canales no cambian, manteniendo la instalación y almacenamiento.
Detalles de origen y recursos en IDENTIDAD.md. Recursos de tienda separados del
bundle Flutter en distribution/google-play/; .kotlin generado excluido de Git.
