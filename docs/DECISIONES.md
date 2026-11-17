# Decisiones

## 2026-11-13 — Alcance y repositorio

- Repositorio inicial vacío, sin archivos de aplicación ni instrucciones AGENTS.md
  encontradas en la ruta de trabajo y sus ancestros.
- Se usa la raíz actual, sin un segundo proyecto anidado.
- Nombre técnico: `heroclix_simulator_trainer`; versión inicial `0.1.0+1`.
- Solo Android. La etapa 00 entrega inicio y base técnica; los cuatro modos
  permanecen deshabilitados. No se inicia 01 sin nueva orden.

## Arquitectura

- Flutter en presentación; dominio y puertos de aplicación en Dart puro.
- Sin gestor de estado externo: el catálogo del inicio es inmutable y no hay
  estado de escenario que gestionar todavía.
- Las carpetas de módulos futuros se documentan, sin implementar sus reglas.
- Persistencia intercambiable mediante `LocalDocumentStore`, sin adaptador en 00.
- Dependencias directas de producción: Flutter y `material_ui` oficial, con sus
  localizaciones. La extracción de Material del SDK en Flutter 3.50 obliga a usar
  el paquete independiente para evitar APIs obsoletas; no se silencian lints.
  Fuente: https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui
- Sin backend, login, telemetría, clientes de red ni paquetes de fuentes remotas.

## Diseño

- Tema original oscuro azul, acentos menta, iconos Material genéricos; sin
  personajes ni arte de marcas. El icono de launcher de la plantilla se sustituye
  por un recurso vectorial geométrico original.
- Español, estados futuros con texto e icono, semántica deshabilitada y sin
  manejadores de toque en las tarjetas.
- Diseño adaptable por ancho; alto natural de contenido y desplazamiento para
  tamaños reducidos y texto ampliado; sin bloqueo de orientación.

## Herramientas y Android

- No se encontraron Flutter, Dart, Android SDK ni adb al comenzar.
- Java encontrado: Oracle JDK 21.0.12.1; Git disponible.
- Flutter se prepara en `%USERPROFILE%\develop\flutter`, fuera del repositorio,
  sin cambiar permanentemente PATH ni instalar servicios del sistema.
- Se usa el canal stable verificado contra el índice oficial de releases.
- SDK Android mínimo/objetivo/compilación se heredan de Flutter, sin fijar números
  antiguos en Gradle. Los valores resueltos se registran en ESTADO.md.
- Application ID inicial configurable: `com.valinor.heroclixtrainer` mediante
  `android/gradle.properties`; namespace Kotlin estable por separado.
- La firma release se documenta con claves locales fuera del repositorio. No se
  generan claves, contraseñas ni un release firmado con claves debug.

### Reevaluación del SDK — 2026-11-13

Tras la instalación realizada por el usuario se confirmó la disponibilidad del
SDK, Command-line Tools, API 36, Build Tools 36.0.0 y NDK 28.2.13676358.
Se conserva el NDK declarado por Flutter y no se cambia a NDK 30 solo porque
también esté instalado. Flutter detecta el JBR OpenJDK 25.0.4 de Android Studio;
doctor ya no informa problemas y confirma licencias aceptadas. Falta completar
la compilación real y las pruebas de dispositivo para validar la entrega Android.
El intento de build quedó en la descarga de Gradle; la transferencia alternativa
desde la fuente oficial alcanzó el límite de 240 segundos antes de completarse.
No se cambian versiones del SDK o Gradle para ocultar este problema de descarga.

### Compilación Android completada — 2026-11-14

La conectividad volvió a responder. Se reanudó el ZIP parcial de Gradle y se
verificó contra su SHA-256 oficial antes de usarlo; no se cambió la configuración
DNS del sistema. `flutter pub get` y `flutter build apk --debug` completaron.
Se verificaron firma debug, identidad, niveles SDK y ausencia de INTERNET en el
APK generado. Los resultados y el hash del artefacto constan en ESTADO.md.

Como el equipo tiene 8 GiB de RAM, se redujeron los límites Gradle a 2 GiB de
heap y dos workers. El primer build completo pasó con esa configuración; no se
cambiaron versiones de Flutter, NDK, AGP, Kotlin o Gradle para conseguirlo.

La comprobación Android se hizo con la AVD existente en una sesión temporal de
solo lectura y sin snapshots. Se verificaron inicio, ambas orientaciones y
reinicio en modo avión. Ante la carga elevada del emulador se redujo su resolución
durante esa sesión; no se ajustó Windows ni se guardaron cambios de la AVD. Se
cerró el emulador al terminar. El rendimiento de esta prueba no representa el de
un teléfono físico; TalkBack y rendimiento real quedan pendientes.

## Control de versiones — 2026-11-14

- Repositorio privado: https://github.com/Schrei01/heroclix-simulator-trainer.
- Rama principal: `main`; se renombró la rama inicial sin commits `master`.
- La entrega 00 se organiza en commits de aplicación, pruebas y documentación.
- `.gitattributes` normaliza texto a LF y conserva CRLF para scripts `.bat`.
- Se conservan las exclusiones de build, cachés, rutas locales y material de
  firma. No se añade una licencia de distribución ni se crea un release en esta
  tarea de publicación del código.

## Fuente reglamentaria

La fuente y fecha objetivo se registran en REGLAS.md. En esta etapa no se ha
verificado ni implementado ninguna regla del juego.

## Etapa 01 — 2026-11-14

- La solicitud de ejecutar 01 autoriza continuar desde la base 00 validada.
- Se trabaja en `codex/prompt-01`, sobre el mismo repositorio; no se inicia 02.
- Versión de app: `0.2.0+2`. Solo Editor se habilita; los otros modos permanecen
  futuros y todas las herramientas de edición salvo Seleccionar siguen deshabilitadas.
- Dimensiones 2–40 por eje, 4×4 inicial. Columna desde A, después Z viene AA;
  fila desde 1. Los índices del modelo empiezan en cero.
- Cada celda mide 64 unidades de escena; esta es una convención de render,
  no una medida reglamentaria ni la resolución física del teléfono.
- Empates sobre líneas compartidas: derecha/abajo. Bordes externos derecho e
  inferior excluidos. Se corrige redondeo al entero dentro de 1e-9 de casilla.
- BoardSession inmutable centraliza tamaño, selección, visibilidad y cámara.
  La adaptación a ValueNotifier y matrices de Flutter queda en presentación.
- Zoom con pinza o botones, pan con un dedo, centrar sin cambiar escala y ajustar
  vista completa son operaciones distintas. El rango de escala es 0,02–6.
- Al girar se mantiene el punto central y el zoom. Volver al inicio no destruye
  la sesión. Cerrar el proceso sí la reinicia; guardar sigue reservado a 04.
- El teclado de los diálogos no redimensiona el canvas inferior. Los formularios
  manejan sus propios insets y scroll; abrirlos no modifica la cámara de la sesión.
  Se mantiene también el padding inferior del área segura cuando aparece el teclado;
  la regresión simula tanto viewInsets como el cambio de padding de Android.
- Cambiar tamaño preserva opciones de visualización, limpia selección y ajusta
  cámara. Si hay una selección se solicita confirmación explícita antes de perderla;
  cancelar o introducir valores inválidos conserva la sesión anterior completa.
- Se conserva el informe y APK de 00 como entrega histórica. No se agregan reglas,
  figuras, terreno, persistencia, historial ni dependencias externas en esta etapa.
- Entrega validada con 52 pruebas, análisis estático, cinco renders y APK debug
  firmado. En Android 17 se comprobó el recorrido offline hasta 40×40/AA20,
  giro y conservación al volver al inicio. El detalle, hash y límites del entorno
  constan en ESTADO.md. Se deja la rama de 01 para revisión, sin iniciar 02.

## Etapa 02 — 2026-11-14

- La orden del usuario autoriza continuar desde 01. Rama `codex/prompt-02`, app 0.3.0+3.
- BoardSession posee figuras, equipos y contadores monotónicos locales. IDs `figure-N`
  y etiquetas A…Z, AA… no se reciclan al borrar; editar conserva ambos. Nombres repetidos
  son válidos. La identidad no depende del índice de una lista.
- CharacterRepository inmutable deriva su índice de ocupación. Una sola función
  valida toda la huella y los límites, excluyendo el propio ID al mover/editar.
  Operaciones fallidas dejan el snapshot completo intacto.
- Bases 1×1 y 2×2 en UI; Footprint admite rectángulos extensibles en dominio.
  La 2×2 se ancla arriba a la izquierda y es representación de posición, no legalidad
  reglamentaria. No se modelan todavía reglas especiales de bases (08).
- Velocidad/alcance: enteros 0–99 como límite de entrada del producto, sin afirmar
  que todo valor sea una característica reglamentaria válida. Nombre: 1–80 caracteres.
- Azul/T1 liso y Rojo/T2 rayado iniciales. Equipos adicionales: nombre 1–40,
  código estable T3…, paleta opaca y patrón seleccionables; nombres de equipo únicos
  ignorando mayúsculas. El texto de código distingue equipos además del color.
- Toque selecciona; Personajes crea en vacío mediante formulario. Pulsación larga
  inicia arrastre de figura; pan rápido y pinza conservan la navegación. Preview
  transitoria en canvas, ✓/× y explicación; commit único al soltar con revalidación.
  Cancelar o añadir otro dedo descarta preview. Se conserva el desfase al tomar una
  celda secundaria de una base 2×2.
- Edición de posición y lista de figuras ofrecen alternativas accesibles al arrastre.
  Duplicar asigna identidad nueva al guardar; cancelar no crea una figura. Un equipo
  creado explícitamente permanece en la sesión aunque se cancele la ficha.
- Eliminar exige confirmación; historial/deshacer queda para 04. Los snapshots
  inmutables preparan esa etapa sin implementar un historial anticipadamente.
- Reducir dimensiones se rechaza si una base quedaría fuera; ampliar conserva todas
  las figuras. No se borran ni reubican silenciosamente.
- Sin dependencias nuevas, red en runtime, ataques, reglas ni funciones de 03.

## Etapa 03 — 2026-11-14

- Orden del usuario autoriza continuar desde 02. Rama `codex/prompt-03`, app 0.4.0+4.
- TerrainLayer, WallLayer y CharacterRepository son capas inmutables independientes.
  Despejado/elevación 0 es el valor implícito. Pintar despejado conserva la elevación
  preparada de la celda; Limpiar terreno reinicia toda su capa.
- CellTerrain incluye elevación entera 0–40 como límite provisional del producto.
  Sin controles ni interpretación de altura hasta 08.
- Muros internos de longitud una casilla, eje/vértice normalizados; ID h:col:fila
  o v:col:fila. Orden de casillas vecinas no cambia identidad. No se admiten muros
  externos; hit fuera del área devuelve null y la UI explica la restricción.
- Franja de toque 0,22 casillas; empates de distancia dentro de 1e-9 favorecen vertical.
  Un trazo bloquea la orientación del primer borde para no crear ramas en vértices.
- Terreno: un toque o trazo completo es una operación. La interpolación divide el
  segmento en todos sus cruces de cuadrícula, independiente de los eventos recibidos.
  El paso exacto por vértice no pinta las casillas cuyo interior no se atraviesa.
- Previa transitoria separada del escenario. Segundo dedo, cancelación, cambio de
  herramienta u orientación la descarta. Rectángulos requieren Aplicar o Cancelar;
  coordenadas dan una alternativa al gesto. Con viewport menor de 240 unidades,
  las acciones de previa usan diálogo desplazable para mantener accesibilidad.
- Un dedo edita en herramientas de capa; dos dedos navegan. Seleccionar mantiene
  el pan con un dedo y el arrastre largo de figuras. Pintar nunca arrastra figuras.
- Bloqueado ocupado: decisión explícita Cancelar/Conservar para estudio, sin pérdida
  de figuras. Conflictos derivados de terreno + ocupación, marcados con ! y texto
  accesible. Crear/editar sobre bloqueado requiere casilla de estudio explícita;
  arrastre ordinario lo rechaza y remite a la ficha. No es una evaluación de reglas.
- Borrar elemento elige figura o muro; terreno se cambia a despejado. Tres limpiezas
  independientes y confirmadas. Borrar/limpiar figuras no recicla sus IDs/etiquetas.
- BoardEdit conserva referencias de capas antes/después por operación completada;
  aplicar/revertir exige el estado esperado y dimensiones compatibles, preserva
  cámara y no recicla identidades. El controlador solo expone el último comando
  para preparar 04: no se implementa historial ni UI de deshacer.
- LayerCodec es un fragmento de capas con layerSchemaVersion 1 y orden determinista,
  validación de límites, tipos, duplicados e identidad de bordes. Solo memoria;
  no se ha definido el esquema completo ni guardado/importación/exportación de 04.
- Reducir tablero se rechaza si descartaría terreno o un muro dejaría de ser interno.
  Las capas no se recortan silenciosamente. Ampliar y mover cámara las conservan.
- H/puntos, B/rayas y muros de línea doble son indicadores independientes del color.
  La leyenda explica semántica, controles y límites. No se implementa visión.

## 2026-11-14 — Prompt 04

- Documento completo schemaVersion 1, validación cerrada y sin migración implícita.
  Referencia reglamentaria editable como metadato, sin motor de reglas. Formato,
  campos y límites documentados en ESCENARIOS.md.
- Biblioteca privada hasta 200 escenarios con identidad aleatoria independiente
  del nombre; nombres repetidos permitidos. Importar/duplicar/guardar como generan
  otra identidad. Guardar mantiene la actual. Eliminar pide confirmación.
- Recuperación working.json separada, versionada y escrita en cola por revisión;
  temporal + flush + rename. No se promete conservar una edición anterior a la
  confirmación del indicador. Un fallo mantiene el mundo y ofrece reintento.
- Recuperación futura/corrupta no se pisa automáticamente; reemplazo explícito la
  archiva antes. Documento incompatible en biblioteca exige Guardar como.
- Historial de 100 comandos completados con referencias inmutables, sin cámara,
  selección ni snapshots por píxel. Nuevo/abrir/importar/guardar como reinicia pilas.
  Undo/redo no recicla IDs. Borrar archivo de biblioteca no pertenece al historial.
- Puente Android propio por MethodChannel, sin paquetes nuevos: SAF para archivos,
  FileProvider de cache/exports para compartir, permiso de lectura temporal. Sin
  INTERNET ni permisos de almacenamiento amplios. Cancelar no cambia el tablero.
- PNG reusa painter sin controles; 2048 px por eje por defecto, 4096 opcional,
  coordenadas/leyenda independientes. Se informa el coste aproximado de 64 MiB
  crudos en 4K y el límite nativo de archivo PNG de 16 MiB.
- Pruebas incluyen reinicio de controladores, fallos y carreras de I/O, esquema
  desconocido, nombres iguales, 40×40 completo, navegación y PNG real. No se añade
  geometría ni funciones reglamentarias de Prompt 05.

## 2026-11-14 — Prompt 05

- Segmentos centro-a-centro en unidades lógicas con racionales normalizados.
  Igualdad/cortes/orden exactos, sin epsilon; doubles solo al proyectar al canvas.
- Separar CellPass (interior) de contacto terminal de vértice. Un vértice emite
  cuatro contactos de extremo de borde y las dos celdas solo de esquina; no se
  infieren cuatro cruces interiores ni efectos de muros.
- Secuencia determinista por t; cruces antes del intervalo que empieza allí.
  Igual origen/destino es un punto fijo explícito, sin contactos de borde.
- Extremo fijo o ligado a figura por ID y desplazamiento en su base. Borrado,
  cambio de base o dimensión que invalide la referencia retira resultado y avisa.
  Undo puede recuperarlo. 2×2 pide referencia explícita, evaluación completa en 08.
- Hasta 16 candidatas explícitas con identidades únicas; no se generan combinaciones
  de bases, se elige trayectoria ganadora ni se implementan reglas de 06/08.
- Inspección transitoria fuera del documento/historial: sin cambio de esquema 1,
  sin autoguardado de extremos, sin overlay de inspección en PNG del escenario.
  Cambiar de documento la limpia. Zoom/giro no alteran resultado exacto.
- Solo Editor incorpora la herramienta operativa. Simulador/Árbitro/Entrenador
  conservan entrada futura. Panel y superposiciones describen geometría sin emitir
  veredictos reglamentarios.
- Contratos del motor compartidos entre runner Dart puro y tests Flutter, con
  oráculo independiente de cajas abiertas para 2.916 pares de 6×9 y simetría de
  todos los pares de 4×4. Sin paquetes nuevos.

## 2026-11-16 — Prompt 06

- Perfil basado en el Comprehensive Rulebook 07.01.2026 enlazado por WizKids;
  se revisaron las páginas pertinentes y se creó MATRIZ_REGLAS_VISION.md.
- Una entrada pública LineOfSightService.evaluate en Dart puro, snapshot inmutable,
  contexto versionado y salida con explicaciones, eventos, referencias y causas.
- En vértices diagonales, comparar ambos lados incluyendo terreno, ocupación y
  muros incidentes; elegir el menos restrictivo. No confundir contacto con bloqueo.
- Despejada/obstaculizada permiten visión; bloqueada la impide; No evaluada conserva
  visibilidad desconocida. Ningún estado declara un ataque legal ni calcula alcance.
- Fronteras conservadoras documentadas: poderes/tamaños, alturas y bases múltiples
  relevantes, fuente remota, reglas de mapa, versión desconocida y casos ambiguos.
  La etiqueta SCOPE distingue esas decisiones de una regla oficial.
- Referencias a figuras siguen sus posiciones; invalidación también por terreno,
  muros, dimensiones, extremos y versión. Borrar un extremo retira el resultado.
- Simulador y Árbitro se habilitan para visión básica con el mismo escenario/motor;
  selección/navegación en su tablero y edición explícita mediante otra vista.
  Entrenador permanece futuro. No se inicia 07.
- Inspección, perfil declarado y superposiciones transitorios; esquema JSON 1
  sin modificaciones. La declaración de efectos se reinicia al cargar documento.
- Se corrigió competencia entre viewports de rutas cubiertas y activas. No se
  omiten avisos de hit test: controles probados a 300 % y en vistas pequeñas.

### Corrección 0.7.1+8 — vértices oblicuos

- Reporte del usuario: A1–D6, terreno bloqueado en B4, sin otras restricciones.
  El rechazo por pendiente distinta de 45° daba No evaluada aunque C3 estaba libre.
- Se reprodujo con R23 fallando antes de cambiar el servicio. Se elimina ese
  rechazo y se aplica §16.8b a cualquier paso exacto por una intersección.
  Su procedimiento no exige pendiente global de 45°; el párrafo introductorio
  16.8 no se usa para restringirlo. Se mantiene la edición 2026-07-01.
- El mismo segmento centro a centro y sus eventos exactos permanecen intactos;
  no se busca una ruta alternativa ni se ignoran obstáculos interiores.
- R17 se actualiza y R23–R25 comprueban el reporte, inversión de extremos,
  nueve pares de terrenos, 16 combinaciones de muros, figuras laterales y
  bloqueos interiores. Los límites de elevación/poderes/bases se mantienen.
- Versión Android 0.7.1, código 8, sin migración ni dependencias nuevas.

## 2026-11-16 — Prompt 07

- Edición 2026-07-01 conservada tras revisar enlace oficial y §11.3a–b. Distancia
  de casillas en ocho direcciones, empezando en cero. La fórmula del máximo de
  diferencias absolutas se deriva de ese conteo, no de la longitud del segmento.
- DistanceService y TargetAnalysisService en Dart puro. El segundo usa
  VisionEvaluator/LineOfSightService de 06 y conserva distancia, comparación de
  alcance y visión por separado, además de referencias y condiciones pendientes.
- El alcance editable sigue siendo el valor declarado de la figura; no se
  interpretan cartas/modificadores. Visible y en alcance no significa ataque legal.
- Consulta de todas las demás figuras, con filtro inicial Enemigas y opciones
  Aliadas/Todas. El filtro no decide qué objetivos permite un poder concreto.
- No evaluado tiene prioridad si alguna dimensión necesaria no está resuelta.
  Fuera de alcance tiene prioridad de lista sobre bloqueo, conservando el bloqueo
  en su dimensión y explicación. Bases múltiples en extremos no reciben distancia
  ni alcance completos; altura relevante mantiene pendiente la visión.
- Caché acotada a 256 pares del mismo mundo/contexto. El rango no modifica los
  obstáculos: editarlo reutiliza visión y actualiza comparaciones. Movimiento,
  terreno/muros, huellas, versión y condiciones invalidan la caché pertinente.
- Herramientas disponibles en Editor, Simulador y Árbitro; los dos últimos
  mantienen navegación/selección y edición explícita del escenario. Controles
  horizontales acotados al ancho disponible y filas compactas con informe completo
  para acceso al 300 %. Se conservan comprobaciones fatales de hit test.
- Consultas transitorias sin I/O, historial ni JSON; cambiar alcance usa el comando
  normal de edición, undo/redo y persistencia existentes. Esquema 1 sin migración.
- Rendimiento medido con Dart en el PC Windows del desarrollo; no se presentan
  esos tiempos como FPS ni mediciones Android. Detalle y equipo en ESTADO.md.
- 0.8.0+9, sin nuevas dependencias ni permisos. No se inicia 08.

## 2026-11-16 — Prompt 08

- Se conserva Comprehensive Rulebook 2026-07-01; §16.5/16.7, §24.2 y §27.6.
  La PAC oficial enlazada (2023) confirma las cuatro mejoras usadas; no se adoptan
  excepciones que requieren mapa indoor/outdoor o resolución de ataques.
- Composición independiente de nivel, H/B, muro y figura, seguida de restricciones
  por vértice. Cada mejora ignora solo su componente, con referencia y explicación.
- Huellas 1×1, 1×2/2×1, 2×2, 2×4/4×2 y 3×6/6×3; tamaño de personaje independiente.
  Se consultan pares, hasta 324. La distancia y visión de Objetivos proceden del
  mismo par. Visión automática no depende del alcance; inspección manual permanece.
- Normal como extremo; otros tamaños/capacidades no modeladas conservan SCOPE.
  El registro diferencia límites del producto de restricciones reglamentarias.
- Altura de casilla/región, bordes derivados y transición de altura canónica.
  El 0 legado sigue siendo alias del suelo 1, para no perder datos originales.
  Limpiar tipo conserva altura/transiciones; modificar nivel puede retirar las
  transiciones que ya no conectan alturas distintas. Historial por operación.
- Cuatro mejoras declaradas en ficha, conservadas por duplicado, movimiento y
  edición de alcance. Laboratorio explícito, temporal, sin modificar personaje/JSON.
- Esquema 2 con lectura de 1/2; respaldo exacto antes de reemplazar legado y sin
  escritura al abrir. Si el respaldo falla, el documento anterior se conserva.
- Caché incluye tamaño, capacidades y laboratorio, acotada a 1024 pares del mundo.
- Barra corta sin virtualización de sus botones: permite conservar accesibilidad
  y localizar controles al desplazarse. No se silencian hit tests. La revisión
  visual corrigió el pie para mostrar el par real y separó los números de transición.
- Se conserva el modo offline y la configuración Android, sin dependencias nuevas.
  Versión 0.9.0+10. No se inicia 09.

## 2026-11-16 — Prompt 09

- Se conserva la edición oficial 2026-07-01: §10.2/10.5/10.7/10.8, §13.2,
  §16.2a/16.3a/16.4a/16.5a/16.7b/16.8a/c, §24.2d y §27.5a/b/e/f.
  H no tiene costo adicional; cruzar altura obliga a terminar salvo excepción.
- MovementRulesService separa paso, traslación y ruta; RoutePlanner usa BFS de
  costo unitario. Reutiliza aristas/adyacencia por consulta y valida completa cada
  alternativa ofrecida. Hasta tres por distinto primer paso, ordenadas por costo.
  Ausencia de resultado no demuestra imposibilidad bajo poderes fuera del perfil.
- IM Elevación, Bloqueado, Personajes y Atravesar son independientes. Solo
  Personajes concede separación automática. La separación con dado queda
  No evaluada: no se inventa una tirada ni un éxito. No se añade permiso de acción.
- Bases: referencia fija en ancla superior izquierda, traslación sin giro y toda
  la huella comprobada. §24.2d admite maniobras más amplias; una restricción en
  otra parte que requiera otra referencia/giro queda No evaluada, no ilegalidad
  general. Destino sobre B/figura/muro, fuera o mixto normal sí es inválido.
- Perfil conservador con figuras Normal. Tamaños especiales, vuelo, destrucción,
  clasificación exterior y efectos arbitrarios conservan No evaluado. Mejoras de
  visión no conceden movimiento ni viceversa. Capacidades persistentes en ficha.
- Ensayo en memoria y snapshot inicial inmutable; comparaciones recalculan visión
  y alcance de la ficha en un snapshot futuro. Cancelar/reset no mueven; confirmar
  revalida el contenido actual y aplica un único comando reversible. Carga,
  edición o salida de herramienta limpian ensayo; cámara no escribe ni lo borra.
- Editor mantiene arrastre libre para montar escenas. Simulador ofrece Movimiento
  reglamentario; tocar allí construye ruta y no reposiciona libremente.
- Esquema 3, lectura 1/2/3, IM vacías al migrar. Copia exacta previa de esquema 1/2
  y working, fuera del índice. Fallo de respaldo protege original. Capas siguen 2.
- UI desplazable a texto ampliado, sin silenciar hit tests. Se acotó el encabezado
  del registro para poder abrirlo al 300 % en 320×320. No se crean dependencias,
  permisos ni solicitudes de red en runtime. Versión 0.10.0+11. No se inicia 10.

## 2026-11-16 — Prompt 10

- Se conserva edición 2026-07-01. No se añaden reglas de juego: todos los correctores
  delegan en servicios de 06–09 y validan la solución literal guardada antes de
  permitir autocorrección. No evaluado o edición distinta no cuentan como fallo.
- Banco curado v1 de 24 ejercicios, cuatro por categoría, tres dificultades y cinco
  tipos automáticos. Escenarios sintéticos originales, deterministas y testeables.
  No se presentan como mapas o ejemplos publicados por WizKids.
- ID estable más revisión y edición para progreso. Abrir una revisión muestra su
  feedback guardado, sin usar otro motor para recalificar respuestas antiguas.
  Las actualizaciones compatibles del banco conservan IDs y contadores.
- Intentos se registran solo al comprobar. Repetir, revisar y pedir pista no suman.
  Pistas no penalizan porcentaje; se conserva uso en último intento. Practicar
  errores usa último fallo elegible de la revisión/edición actual, no todo fallo
  histórico. Completado exige un acierto automático; manual se cuenta aparte.
- Respuesta textual manual requiere guía y no se puntúa automáticamente. Autor
  ofrece visión, distancia, alcance/visión, ruta o manual; valida soluciones antes
  de guardar. Tipos tocar objetivo/casilla se incluyen en el banco curado.
- Ensayo de aprendizaje con tablero y controlador separados: no cambia Editor,
  historial ni archivos de escenarios. Personal copia snapshot de biblioteca.
  La comparación sencilla no evalúa valor estratégico ni inicia 11.
- Persistencia privada separada bajo scenarios_v1/training_v1. Esquema entrenador
  2 lee 1/2, conserva copia exacta de 1 antes de escribir y protege futuro/corrupto.
  Compatibilidad 1 probada con datos sintéticos; no existía Entrenador publicado
  en 09. Escenarios siguen esquema 3. Sin dependencias ni permisos nuevos.
- 0.11.0+12. La revisión visual conserva la respuesta manual legible y el feedback
  entra automáticamente en vista al comprobar. No se inicia Prompt 11.

## 2026-11-16 — Prompt 11

- Mantener el perfil 2026-07-01 y una implementación por regla. Visibilidad cuenta
  H; alcance es independiente. Amenazas conocidas requieren línea y alcance en
  un mismo par, sin declarar ataque legal, mejor jugada ni probabilidad de victoria.
- Limitar a 12 destinos/página y 32 enemigos por posición, con progreso y worker
  separado. Omitidos son No evaluados; diferencias parciales no dan números exactos
  y resultados incompletos no reciben ranking categórico. Orden por página explícito.
- Caché de ocho páginas y de pares acotada por enemigo. Cambios de contenido,
  capacidades, versión o efectos limpian; prioridad/cámara conservan. Cancelar mata
  el isolate y descarta mensajes tardíos. No se requiere servicio externo.
- Snapshot hipotético inmutable. La comparación sin mejoras retira únicamente
  capacidades soportadas del activo; no borra poderes desconocidos para forzar un
  resultado. Confirmar revalida la ruta declarada y crea una operación reversible.
- Crear ejercicios de ruta/visibilidad mediante el corrector de 10, en isolate,
  con rutas literales guardadas y hasta cuatro posiciones. No se persisten fichas
  modificadas de laboratorio. Cancelar antes de guardar descarta la generación.
- Entrenamiento formato 3 lee 1/2/3 y respalda exactamente 1/2 antes de reemplazar.
  Escenarios siguen 3. Tests conservan ejercicios y contadores de 10 y protegen
  original ante fallo de respaldo. Banco curado v1 y sus 24 soluciones se conservan.
- TXT/PNG con datos controlados y etiquetas genéricas; no captura de pantalla con
  nombres ni metadatos. Sin nuevas dependencias, permisos ni red en runtime.
- 0.12.0+13; evidencia real y límites nativos en ESTADO.md. No se inicia Prompt 12.

## 2026-11-17 — Prompt 12

- Entrega candidata 1.0.0-rc.1+14. No congelar estable hasta comprobar instalación,
  restauración tras cierre, selectores, offline con radios apagadas y rendimiento
  en Android. Se intentó AVD API 37/WHPX: quedó offline y se detuvo sin borrar datos.
  El usuario indicó continuar sin teléfono; no se confunde Windows con Android.
- Conservar los cuatro modos/motor/datos y tema existente, añadiendo ayuda breve,
  cobertura/versiones y licencias locales en Acerca de. AppInfo se contrasta con
  pubspec y perfil; no se añade un plugin para consultar la versión.
- Cinco ejemplos originales reutilizan snapshots del banco verificado: H, vértice
  A1–D6, muro, elevación y rodeo. Vista previa independiente y copia con ID nuevo,
  protección de cambios y biblioteca conservada, sin sembrar datos al iniciar.
- Corregir incompatibilidad real de TXT en Android mediante MIME/extensión exactos;
  mantener 2 MiB para texto/JSON y 16 MiB para PNG. Sin permisos nuevos. Corregir
  esquema antiguo en detalles y selección de consulta individual desde caché.
- Matriz E2E explícita; test de archivos/controladores reales y respuesta en UI,
  migraciones/regresiones anteriores intactas. Fallo de espacio se inyecta como
  OSError 28 y comprueba documento anterior y recuperación, sin llenar el disco.
- Accesibilidad básica verificada con guías de objetivos táctiles/etiquetas/contraste
  y colores de estado ≥4,5:1. No implica validación TalkBack real. Ayudas adaptables
  y mapa siguen separados; no se añaden reglas, contenido oficial ni juego completo.
- Sin claves release suministradas; se conserva firma debug para actualizar las
  entregas anteriores y se documenta custodia/firma segura. No se usa debug como
  sustituto de release. APK, claves, logs y renders excluidos de Git.

## 2026-11-17 — Ajustes del Editor posteriores a 12

- Mantener separados Editor/Simulador/Árbitro mientras se ajusta la edición, según
  la petición del usuario. Sin nuevas reglas, esquemas ni permisos.
- Sustituir el desplegable del tipo de terreno por tres iconos al pie del mapa,
  centrados, con selección, tooltip y semántica. Reservar su espacio fuera del
  receptor de gestos para que elegir no pinte ni tape casillas. En altura escasa
  usar barra lateral y controles compactos accesibles, sin reducir el texto global.
- Proponer altura 2 sobre nivel 1; respetar alturas existentes y permitir volver
  manualmente a suelo. No cambiar nivel por defecto de las casillas ni documentos.
- Colocar Figura/primer equipo/base 1×1/Normal/velocidad 6/alcance 4 sin formulario;
  usar el mismo comando de creación, validación, historial y autoguardado. Edición
  posterior mediante la ficha existente. Bloqueado conserva confirmación de estudio.
- Ocultar la ayuda transitoria al colocar para dejar accesible el lápiz inferior.
- 1.0.0-rc.2+15 conserva firma debug; aceptación nativa sigue pendiente por decisión
  de continuar sin teléfono. No se promueve estable ni se unifican los modos.

## 2026-11-17 — Sesión temporal y dictamen sobre el mapa

- Petición del usuario: cerrar/reabrir empieza con escenario vacío y figuras desde
  A. Desactivar recuperación y escritura automáticas del escenario de trabajo por
  defecto, sin borrar archivos ni biblioteca. Navegación/segundo plano conservan
  la instancia viva. Guardar explícito y progreso del Entrenador siguen persistentes.
- Mantener APIs/formato de recuperación antigua con activación explícita en sus
  pruebas de compatibilidad. Añadir pruebas con la configuración de producción,
  AA→A, working no leído/escrito, biblioteca y progreso en disco real. No se da por
  probado el comportamiento Android a partir de una prueba de controladores.
- Habilitar visión al elegir la herramienta y mostrar el mismo dictamen en franja
  superior al completar extremos. Color/icono/texto y acceso directo a referencias;
  No evaluado conserva incertidumbre. Bases automáticas sin diálogo; referencia
  manual disponible mediante el control existente.
- Actualizar mensajes de Inicio/Guía/estado para no prometer autoguardado temporal.
  Error de Guardar permite reintentar guardado; los renders usan sesión temporal y
  el caso de fallo es ahora de guardado explícito, no autoguardado.
- 1.0.0-rc.3+16, misma firma debug; formatos/perfiles sin cambios. Sin unificar modos,
  sin partida completa ni promoción a estable mientras falte aceptación nativa.

## 2026-11-17 — Editor como espacio de análisis y transiciones

- Petición del usuario: retirar Simulador y Árbitro. Inicio y AppMode conservan
  Editor y Entrenador. Se elimina VisionScreen; informes y motores de visión,
  distancia, objetivos, movimiento y posiciones siguen en las herramientas del Editor.
  Esta decisión sustituye la separación de módulos registrada en entregas anteriores.
- Triángulo blanco con borde rojo y número de nivel dentro de cada casilla de
  transición; dos triángulos comparten base sobre el borde. Referencia gráfica:
  Comprehensive Rules 2026-07-01 §16.7, página impresa 43. Geometría dibujada por la
  app, sin copiar imágenes oficiales. Elevadas normales conservan E2/E3 y borde rojo.
- El PNG usa el mismo BoardPainter y añade explicación en su leyenda. Sin cambio
  de esquema, alturas, validación de transiciones ni reglas de movimiento/visión.
- Se migran las pruebas de las vistas retiradas a las herramientas del Editor,
  conservando consultas, informes, caché, movimiento y accesibilidad. Se corrige
  el desbordamiento con texto al 300 % usando herramientas laterales cuando falta altura.
- 1.0.0-rc.4+17, misma firma debug. Android real continúa pendiente por la decisión
  previa de continuar sin teléfono. Biblioteca y progreso conservados.
## 2026-11-17 — Incrementos del Editor rc.5

- Escenario nuevo 10×10; biblioteca/importación conservan dimensiones guardadas.
- Paleta única de cinco pinceles: Bloqueado, Obstaculizado, Elevado, Transición,
  Despejado. Sin selector Elevación separado en herramientas/menú. Elevado usa toques
  para subir un nivel (suelo→E2→E3, máximo E40); Coordenadas conserva edición avanzada.
  Despejado limpia el tipo y conserva alturas/transiciones. Cinco objetivos de al
  menos 48 px caben en los tamaños verificados, con nombres accesibles/tooltip.
- Transición selecciona dos vecinos ortogonales de distinto nivel y sin muro.
  Errores visibles y ninguna edición parcial. No se amplía cobertura de reglas.
- Dos toques consecutivos en la misma casilla con Seleccionar preguntan por borrado:
  personaje, tipo de terreno, elevación; las transiciones restantes pueden borrarse
  después. Confirmar afecta una capa; Cancelar conserva todo. Borrar incorpora tipo,
  elevación y transiciones además de figuras/muros; operaciones reversibles.
- Eliminar allowStudy de los comandos de creación/edición/pintura y de toda la UI.
  Bloqueado no admite nuevas figuras ni se pinta bajo ellas. La lectura heredada
  conserva datos con advertencia para corregirlos, sin eliminar escenarios guardados.
- Improved Targeting usa ExpansionTile como Movement, permitiendo varias mejoras.
  No se ofrecen las entradas Other de ninguna lista; se conservan sus IDs antiguos
  para leer documentos sin transformar incertidumbre en un resultado aprobado.
- Dictamen únicamente sobre el mapa. En Visión, mismos extremos limpian referencias,
  selección, traza y resultado; Distancia conserva su medición cero independiente.
- Si la cámara seguía ajustada automáticamente, cambia el ajuste al abrir barras;
  un zoom/pan manual conserva su centro y escala. Evita recortar A1 en 10×10.
- 1.0.0-rc.5+18, misma firma debug, sin dependencias/permisos/esquemas nuevos.
  Pruebas Flutter/Windows; aceptación Android sigue pendiente por decisión previa.
## 2026-11-17 — Equipos, avisos y trazos rc.6

- En Personajes, cada par de toques sobre una figura existente pasa al siguiente
  equipo de la lista disponible, volviendo al primero. Crear sigue usando el primer
  equipo; la colocación no cuenta como primer toque del cambio. Se conservan ID,
  etiqueta, posición, base, atributos y capacidades. Un cambio es una operación reversible.
- Sustituir la ayuda SnackBar de herramientas por una franja vertical a la derecha
  del mapa durante cuatro segundos. Es una superposición IgnorePointer, sin alterar
  el viewport/cámara. Un nuevo aviso reinicia la duración; el temporizador pertenece
  al widget y se cancela al destruirlo. Los errores de validación conservan sus avisos.
- Elevado comparte el trazo interpolado de terreno. LayerDraft conserva el pincel;
  las casillas únicas se elevan una vez desde su nivel al comenzar. Se previsualiza
  el nivel de destino; se confirma una sola operación al soltar. Validación de bases
  al final del conjunto, sin rechazar estados intermedios de una base completa.
  E40 o una base que quedaría entre niveles rechazan todo el trazo sin cambios parciales.
- Borrar entra siempre en Borrar todo. El trazo limpia tipos/alturas y bordes de
  muro/transición incidentes; retira figuras completas cuya base toca. El resto de
  las casillas, equipos y contadores se conserva. Sin diálogo para el trazo total;
  Deshacer lo recupera completo. Se mantienen las opciones explícitas de una capa.
- Trazo vacío sin operación en historial. Cancelar o añadir segundo dedo descarta
  la vista previa en elevación y borrado, con la misma política de pintura existente.
- 1.0.0-rc.6+19, sin nuevas reglas, esquemas, dependencias ni permisos. Firma debug
  conservada; aceptación nativa pendiente según decisión de continuar sin teléfono.
## 2026-11-17 — Lectura del aviso rc.7

- Aclaración del usuario: vertical significa texto derecho, leído en columna de
  arriba hacia abajo, sin girar el celular. Retirar RotatedBox y distribuir las
  acciones en bloques separados, con ajuste de líneas y ancho lateral adaptable.
- Mantener cuatro segundos, renovación, posición derecha, cámara y paso de gestos.
  Limitar líneas al alto disponible, conservando el mensaje completo en semántica.
- Corrección de presentación: 1.0.0-rc.7+20, misma firma debug y formatos. Pruebas
  afectadas y renders completos; aceptación nativa pendiente como antes.
## 2026-11-17 — TeamFight: GridLab rc.8

- Petición del usuario: aplicar los iconos del ZIP y renombrar la app a TeamFight:
  GridLab. AppInfo centraliza nombre/asset; Android usa app_name. Inicio, Acerca de,
  título y licencias actualizados. Se usan los PNG originales, con hashes contrastados.
- 25 PNG en cinco densidades y dos XML adaptables incluidos tal como se aportan;
  foreground/background/monochrome según el formato oficial de Android. Manifest
  con icon/roundIcon y vector genérico retirado. Asset Flutter 512×512; los dos
  archivos de Google Play preparados aparte en distribution/google-play/.
- Conservar applicationId, namespace, canales nativos, directorios privados y firma
  para permitir actualizar la instalación existente. El paquete Dart conserva su
  nombre técnico. Reglas, formatos, permisos y dependencias no cambian.
- LEEME del ZIP es referencia de recursos; la solicitud es implementar identidad.
  Se valida compilación incremental, conservando APK anteriores. Recursos y etiquetas
  compilados comprobados con aapt; firma/hash y PNG empaquetado verificados.
- 1.0.0-rc.8+21, candidata debug. Máscaras, tema, launcher/splash y actualización
  reales continúan pendientes según decisión previa de continuar sin teléfono.
## 2026-11-17 — Conservar únicamente el APK más reciente

- Petición explícita del usuario: eliminar las versiones anteriores al generar un
  nuevo APK. Sustituye la política previa de conservar entregas binarias históricas.
- Flujo oficial tool/build_apk.ps1: compilar, verificar paquete/versión/firma, copiar
  a nombre de entrega y comprobar SHA-256 antes de retirar los otros APK de
  build/releases/. El fallo conserva los anteriores. Sin cambios de aplicación ni versión.
- Limpieza acotada a archivos .apk de esa carpeta, con rutas absolutas verificadas,
  rechazo de enlaces de directorio y operaciones nativas de PowerShell. Se conservan
  otros archivos, carpetas, informes, datos y salidas técnicas actuales del compilador.
- AGENTS.md registra el procedimiento para futuras sesiones. Pruebas en una carpeta
  temporal aislada: fallo de compilación con APK previo válido, versión incorrecta,
  APK corrupto, publicación correcta y publicación repetida.