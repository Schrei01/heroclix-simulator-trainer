# Escenarios e intercambio — esquema 3 (lectura de 1/2/3)

Introducido en 04 y ampliado en 08–09, app 0.10.0+11. Formato UTF-8 JSON legible, máximo
2 MiB, profundidad máxima 16 y 20.000 contenedores antes de decodificar.
Se rechazan campos desconocidos/incompletos, tipos incorrectos, coordenadas fuera
del tablero, identidades duplicadas, figuras solapadas y versiones desconocidas.
No se modifica el tablero hasta validar y escribir su recuperación completa.

## Campos del documento

| Campo | Contenido |
| --- | --- |
| `schemaVersion` | Entero 3 al exportar; importa también 1/2 mediante migración compatible |
| `metadata` | `id`, `name`, `rulesVersion`, `createdAt`, `modifiedAt` |
| `board` | `rows`, `columns`: enteros independientes 2–40 |
| `teams` | Lista de `id`, `code`, `name`, `color`, `pattern` |
| `characters` | Lista de `id`, `label`, `name`, `teamId`, `position`, `footprint`, `speed`, `range`, `visionAbilities`, `size`, `movementAbilities` |
| `terrain` | Lista de `cell`, `type`, `elevation`; 0 histórico es alias del suelo 1 |
| `walls` | Lista de `id`, `axis`, `column`, `row`; solo bordes internos unitarios |
| `transitions` | Lista de `axis`, `column`, `row`, con vecinos internos de altura distinta y sin muro compartido |
| `counters` | `nextCharacter`, `nextTeam`: identidad siguiente, sin reutilización |

El ID de escenario tiene forma `s-` seguida de 32 dígitos hexadecimales aleatorios.
Nombre: 1–80 unidades UTF-16, recortado. Referencia reglamentaria: 1–40, por
defecto `2026-07-01`; es metadato, no certifica reglas implementadas. Fechas UTC
ISO 8601 canónicas, creación no posterior a modificación. Exportar no cambia fechas.

Equipos: 1–32, nombres únicos de hasta 40 unidades, `team-N`/`TN`, color entero
ARGB opaco (0xff000000–0xffffffff) y patrón `solid`, `stripes` o `dots`.
Figuras: `figure-N`, etiqueta derivada
de N (A…Z, AA…), nombre hasta 80, equipo existente, coordenada A1…AN40,
`footprint: {width, height}` con enteros 1–40; formatos soportados en la matriz
de capacidades. Otros formatos se preservan sin evaluarlos. Velocidad/alcance: 0–99.
Se valida toda la huella; no puede salir del tablero ni solapar otra figura.
Los contadores deben superar cualquier ID existente; máximo 1.000.000.000.

Terreno: `clear`, `hindering`, `blocking`; elevación entera 0–40. El editor muestra
el nivel efectivo 1–40. Tipo, nivel y transiciones son propiedades independientes.
`visionAbilities` usa IDs tipados, únicos y conocidos; `size` es `normal`, `tiny`,
`giant` o `colossal`. Tamaño y huella no se infieren uno del otro. Las condiciones
sin interpretación soportada se conservan como datos y producen No evaluado.
Muros: eje `horizontal`/`vertical`, ID canónico `h:columna:fila` o `v:columna:fila`,
índices desde cero. LayerCodec valida los límites y no permite duplicar bordes.
El orden exportado es determinista; la cámara, selección, herramientas, previas
y el historial no pertenecen al documento. Tampoco se serializa el laboratorio.

## Migración 1/2 a 3

Abrir un esquema 1/2 no modifica su archivo. Se conservan sus campos/capas;
1 recibe capacidades de visión vacías, tamaño Normal y transiciones vacías.
1/2 reciben `movementAbilities` vacías. Antes de su primer reemplazo se escribe
una copia exacta `schema1-ID.json` o `schema2-ID.json` (también `working`),
fuera del índice de biblioteca. Un fallo del respaldo impide sobrescribir el
antiguo. Esas copias usan IDs validados en el mismo directorio privado; no son
rutas proporcionadas por el usuario. Pruebas con un JSON real de 07 y con el
adaptador de archivos en disco: `test/scenario_migration_test.dart` y
`test/movement_migration_test.dart`. Las capas mantienen `layerSchemaVersion: 2`.
Ruta, alternativas, snapshot de comparación y ensayo de movimiento no se serializan.

`movementAbilities` es una lista sin duplicados: `elevated`, `blocking`,
`characters`, `moveThrough`, `outdoorBlocking`, `destroyBlocking`, `other`.
Las tres últimas se conservan como datos sin soporte reglamentario completo.
Edición de alcance, duplicado y movimiento conservan todas las capacidades.

## Biblioteca y recuperación

La producción compone FileDocumentStore con el directorio privado Android
`files/scenarios_v1`. Cada escenario vive en `<id>.json`; máximo 200 en biblioteca.
Los nombres visibles no son rutas y se permiten repetidos entre escenarios.
IDs/rutas se validan y se rechazan enlaces simbólicos al archivo de destino.
La escritura usa temporal en el mismo directorio, flush y rename; los temporales
se limpian. Un fallo se muestra y conserva el estado activo en memoria.

`working.json` usa un envoltorio separado de hasta 3 MiB con campos exactos
`workspaceSchemaVersion: 1`, `document`, `dirty` y `saved`. Las escrituras se
serializan; cada cambio lógico programa autoguardado, agrupando los pendientes.
La revisión impide marcar guardada una edición posterior a la copia escrita.
Se solicita flush al pasar a segundo plano. El indicador confirma qué revisión
está protegida; un cierre forzado antes de esa confirmación puede perder lo último.

Al arrancar se recupera el documento completo. Si falta su copia de biblioteca,
se conserva como borrador pendiente. Una recuperación dañada o de versión futura
no se sobrescribe automáticamente: se informa y bloquea ese autoguardado. Al
reemplazarla explícitamente se archiva su texto en `recovery-s-<id>.json`; si
no se puede archivar, la sustitución falla. Un archivo de biblioteca incompatible
no se sobreescribe con Guardar; se ofrece usar Guardar como.

Guardar conserva identidad. Guardar como/duplicar/importar generan otra identidad;
importar no altera el original externo. Eliminar biblioteca pide confirmación y no
tiene deshacer; si estaba abierto mantiene el tablero como borrador. No existe
sincronización. Desinstalar borra estos datos privados; JSON externo sirve de copia.

## Historial

100 operaciones confirmadas, referencias a estructuras inmutables antes/después.
Un trazo es una operación completa, sin snapshots por píxel. Incluye figuras,
equipos, dimensiones, terreno, muros y limpiezas. Editar tras deshacer descarta redo.
No incluye cámara, selección ni herramientas. Undo/redo conserva contadores máximos,
limpia selección y mantiene cámara salvo ajuste al cambiar dimensiones. Abrir,
nuevo, importar o Guardar como vacía ambas pilas; el historial no sobrevive reinicios.

## Archivos Android y PNG

Storage Access Framework usa OPEN_DOCUMENT/CREATE_DOCUMENT, sin permisos de
almacenamiento amplios. La app admite JSON hasta 2 MiB y PNG hasta 16 MiB en el
puente nativo. Cancelar el selector deja el tablero intacto. FileProvider comparte
solo `cache/exports` mediante URI content y permiso temporal de lectura; iniciar
el selector no demuestra que el usuario haya enviado el archivo. La caché de
exportaciones mayores de 24 h se depura al compartir de nuevo.

PNG reutiliza BoardPainter fuera de pantalla, sin selección, controles o previas,
ignorando zoom. Coordenadas y leyenda opcionales. Máximo por eje 2048 px por defecto
o 4096 px, escala máxima 2; no se deforma la proporción. Un lienzo 4096² necesita
aproximadamente 64 MiB crudos, además del estado y compresión. En 40×40 las etiquetas
pequeñas requieren ampliar la imagen; no es una exportación vectorial.

Referencias primarias de la integración:
[Android SAF](https://developer.android.com/training/data-storage/shared/documents-files),
[FileProvider](https://developer.android.com/reference/androidx/core/content/FileProvider),
[Dart File.rename](https://api.dart.dev/dart-io/File/rename.html).

## Copias para Entrenador (10)

Convertir desde la biblioteca copia el snapshot a almacenamiento separado; no
modifica el documento del Editor. Entrenamiento tiene formato propio versionado,
descrito en ENTRENADOR.md, e incluye escenarios mediante el mismo ScenarioCodec.
Esquema de escenario continúa 3. Progreso, pistas y respuestas no se insertan en
el JSON de escenarios ni aparecen como archivos de biblioteca.

En 11 los diagnósticos, caché e hipótesis siguen siendo transitorios. Confirmar
una ruta cambia únicamente la posición mediante el historial existente. Crear
ejercicio copia la escena y rutas al formato 3 del Entrenador; no añade campos al
JSON de escenarios. TXT/PNG de diagnóstico son salidas separadas con datos genéricos,
distintas de exportar el escenario completo con sus nombres. Véase ANALISIS_TACTICO.md.
