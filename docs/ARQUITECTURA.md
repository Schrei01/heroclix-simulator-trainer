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
terrain implementa terrenos, muros normalizados y geometría de edición. Los módulos geometry (intersecciones
de visión), rules, movement y training conservan documentación de alcance sin
implementar todavía sus funciones.

## Estado y persistencia

El inicio usa un catálogo inmutable; solo Editor está disponible. `BoardSession`
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
ScenarioRepository separa biblioteca de recuperación; ScenarioCodec valida el
documento completo de esquema 1. WorkspaceController serializa I/O y revisiones,
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

Terreno, muros y figuras tienen capas operativas desde 03. Las superposiciones
reglamentarias siguen futuras.
La cuadrícula y su selección no
se almacenan como si fueran terreno ni figuras.

## Motor futuro

Geometría emitirá intersecciones; reglas interpretará sus efectos; la UI
representará resultados estructurados. Editor, Simulador, Entrenador y Árbitro
consumirán los mismos servicios. Las condiciones no soportadas devolverán
«No evaluado». No existe dictamen reglamentario en esta etapa.

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

LayerCodec serializa solo un fragmento terreno/bordes, sin I/O. El documento de
escenario completo y el almacenamiento no están implementados en esta etapa.

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
