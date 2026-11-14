# Arquitectura

## Dependencias

`presentación → aplicación → dominio`. La infraestructura implementará los
puertos de aplicación. El punto de entrada compone las dependencias; el dominio
no importa Flutter, infraestructura ni plataforma.

| Ruta | Responsabilidad actual |
| --- | --- |
| `lib/main.dart` | Arranque Flutter |
| `lib/app.dart` | MaterialApp, idioma y tema |
| `lib/domain/` | Tipos puros, sin widgets ni acceso a plataforma |
| `lib/application/` | Catálogo, sesión inmutable de tablero y puertos de persistencia |
| `lib/presentation/` | Inicio, Editor, adaptación de gestos/cámara y tema |
| `lib/infrastructure/local/` | Reserva documentada para almacenamiento futuro |
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
sesión a widgets. HeroClixApp lo posee y lo destruye al salir de la app: la sesión
se conserva al volver al inicio y al girar, pero no tras cerrar el proceso.

InteractiveViewer usa una TransformationController como proyección de la cámara.
Sus cambios se convierten a BoardCamera; los botones modifican BoardSession y el
adaptador sincroniza la matriz sin bucles de notificación. No hay dos cámaras
independientes que decidan la selección.

El viewport se actualiza después del layout. Al redimensionar se conserva el
punto lógico central y el zoom; «Ajustar» encaja el mapa completo. La selección
siempre es CellCoordinate, nunca un Offset o píxel de pantalla.

`LocalDocumentStore` define un puerto independiente de Flutter para leer,
escribir y eliminar documentos locales. No tiene adaptador de producción en 00;
los fallos se comunicarán al consumidor y nunca destruirán la sesión activa.
El documento completo, su schemaVersion, migraciones e historial corresponden a 04;
LayerCodec prepara en 03 un fragmento versionado de terreno y bordes en memoria.

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
código de equipo, patrón y resaltado de selección. Terreno/muros siguen reservados.

## Edición de capas en 03

BoardSession centraliza política de conflictos, pintura y limpieza por capa.
BoardEdit guarda estados de capas inmutables antes/después de una operación y
puede aplicar/revertir sin restaurar cámara; la UI aún no presenta historial.
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
