# HeroClix Simulator & Trainer

Aplicación Android Flutter/Dart, offline y en español. Versión **0.10.0+11**.
La entrega 09 está en la rama `codex/prompt-09` del repositorio privado
[Schrei01/heroclix-simulator-trainer](https://github.com/Schrei01/heroclix-simulator-trainer).

```powershell
git clone https://github.com/Schrei01/heroclix-simulator-trainer.git
cd heroclix-simulator-trainer
git switch codex/prompt-09
```

## Qué existe

Editor con tablero 4×4 inicial, filas/columnas independientes de 2 a 40,
coordenadas A1…AN40, selección, zoom, pinza y pan. Figuras genéricas con identidad
estable, etiquetas A…Z, AA…, equipos con código/color/patrón y ficha editable.
Bases 1×1, 1×2, 2×2, 2×4 y 3×6, con rotaciones ortogonales y ocupación completa;
duplicar y borrar con confirmación. La huella y el tamaño de personaje son datos distintos.

La etapa 03 añade terreno despejado, obstaculizado y bloqueado; muros sobre bordes
internos; trazo y relleno rectangular con vista previa; borrado por capa y tres
limpiezas independientes. La leyenda usa letras, puntos, rayas y línea doble,
además del color. Figuras, terreno y muros tienen datos separados.

La etapa 04 añade biblioteca local, recuperación automática de sesión, historial
de 100 operaciones, JSON versionado y PNG del tablero. La etapa 05 añade geometría
exacta. La etapa 06 incorpora visión reglamentaria básica en Editor, Simulador y
Árbitro, compartiendo escenario y motor. La etapa 07 añade distancias, comparación
con alcance declarado y consulta de objetivos. La etapa 08 incorpora alturas,
transiciones y cuatro mejoras de visión tipadas. La etapa 09 añade rutas de
movimiento verificadas, alternativas y comparación de posiciones. Entrenador y
ataques completos siguen pendientes.

## Ensayar movimiento

1. En **Simulador → Elegir análisis → Movimiento reglamentario**, elige la figura
   desde el informe o toca su casilla. También está disponible en Editor.
2. Cierra el informe con **Volver al tablero** y toca casillas vecinas sucesivas.
   No se rellenan saltos. El camino numera pasos y superpone origen/destino de
   ensayo; la figura sigue en su posición inicial.
3. El informe muestra ruta válida, inválida o no evaluada, costo, presupuesto de
   velocidad declarada, motivo y regla de cada paso. H no añade costo; cruzar
   altura puede permitir entrar pero obligar a terminar. La separación con dado
   permanece No evaluada.
4. Introduce un destino y pulsa **Buscar alternativas verificadas**. Se ofrecen
   hasta tres rutas dentro del presupuesto, con costo y recorrido. Seleccionar
   una solo cambia el ensayo. **Visión y alcance antes / después** compara ambos
   snapshots usando los motores existentes.
5. **Confirmar movimiento** aplica únicamente una ruta válida y crea una operación
   de Deshacer/Rehacer. **Cancelar ensayo** o **Volver al inicio** permiten ensayar
   sin modificar la posición. Cerrar el informe conserva el ensayo en el tablero.
6. En la ficha, **Improved Movement** permite declarar Elevación, Bloqueado/muros,
   Personajes o Atravesar personajes. Actúan de forma independiente. Personajes
   concede separación automática; Atravesar sigue requiriendo separación.

Las bases usan traslación sin giro y ancla fija, comprobando toda la huella. Otras
maniobras, tamaños especiales y poderes sin soporte quedan No evaluados; consulta
[SOPORTADAS / NO SOPORTADAS de movimiento](docs/MATRIZ_MOVIMIENTO.md). El arrastre
libre del Editor sirve para montar escenarios y no valida una ruta reglamentaria.

## Alturas, bases y capacidades

1. En Editor abre **Alturas y transiciones** desde las herramientas o las opciones.
   Indica una casilla o región y un nivel de 1 a 40. El suelo es nivel 1; las
   alturas muestran E2, E3… y bordes. Añade transiciones entre dos vecinos de
   distinta altura sin muro compartido. Pintar altura conserva H/B; limpiar tipos
   de terreno conserva altura y transiciones. Hay Deshacer/Rehacer.
2. Selecciona una figura, pulsa el lápiz de la barra inferior y declara sus mejoras
   **Improved Targeting**: Elevación, Obstaculizado, Bloqueado/muros o Personajes.
   Cada una afecta solo a su componente. No se interpretan nombres ni cartas.
3. En **Dictamen de visión**, **Referencias automáticas** compara la base completa.
   El informe indica el par elegido y permite ver los demás. Al desactivarlo se
   inspecciona una referencia manual. Objetivos siempre compara alcance y visión
   desde el mismo par; no mezcla dos líneas diferentes para aprobar un objetivo.
4. **Laboratorio de capacidades** sustituye temporalmente las capacidades del origen
   para comparar resultados. La etiqueta HIPÓTESIS lo identifica; no cambia la
   ficha guardada y se limpia al abrir otra escena.
5. El **Modo árbitro** muestra alturas, capacidades, excepciones aplicadas y el
   registro por eventos. Otras capacidades/tamaños o formas sin soporte quedan
   pendientes. Revisa [SOPORTADAS / NO SOPORTADAS](docs/MATRIZ_CAPACIDADES_VISION.md).

La exportación JSON usa esquema 3 y abre también archivos de esquema 1/2. Antes de
reemplazar un documento antiguo se guarda una copia exacta privada; abrirlo no
lo sobrescribe. Los campos y capas anteriores se conservan.

## Medir distancia y consultar objetivos

1. En Editor elige **Medir distancia** (regla), toca origen y destino y consulta
   la cuenta en casillas. El botón **Distancia** abre referencias y diferencias
   opcionales de filas/columnas. Puedes medir entre casillas vacías.
2. Para objetivos selecciona una figura y pulsa **Mostrar objetivos** (radar).
   También puedes elegir el origen en la lista. Se muestran enemigas por defecto;
   cambia a Aliadas o Todas si quieres consultar otras figuras.
3. Cada fila indica distancia, alcance declarado y estado. **Editar alcance**
   modifica el dato de la figura, actualiza todos los resultados y permite deshacer.
4. Elegir un objetivo resalta su casilla, traza la línea y anota distancia/alcance.
   Pulsa el resumen para ver comparación, visión, explicación y reglas pendientes.
5. En Simulador y Árbitro usa **Elegir análisis** (controles de la barra superior)
   para alternar Visión, Medir distancia y Mostrar objetivos. No mueven figuras
   al tocar el tablero; para cambiar posiciones entra en Editar escenario.

Estados: en alcance con visión despejada, en alcance con visión obstaculizada,
visión bloqueada, fuera de alcance y no evaluado. Distancia, alcance y visión
se conservan como dimensiones independientes. **Visible y en alcance no significa
ataque legal.** El filtro de aliados no concede permiso de ataque.
Bases reconocidas y alturas se evalúan según el perfil de 08; formas o condiciones
sin soporte conservan dimensiones pendientes. Más detalles en [MATRIZ_DISTANCIAS_OBJETIVOS](docs/MATRIZ_DISTANCIAS_OBJETIVOS.md).
La consulta y sus superposiciones no se guardan ni se exportan en PNG; el alcance
editado sí pertenece al escenario, junto con capacidades, altura y transiciones.

## Consultar un dictamen de visión

1. Crea o abre un escenario con figuras en el Editor. En Línea de visión elige
   origen y destino y pulsa **Dictamen de visión**; también está en Opciones.
2. Desde Inicio, **Simulador** y **Árbitro** muestran el mismo escenario con un
   tablero que solo selecciona extremos y navega. **Editar escenario** abre el
   Editor y al volver conserva las referencias válidas.
3. El estado se muestra con texto, icono y color: verde/despejada,
   ámbar/obstaculizada, rojo/bloqueada y gris/no evaluada. Obstaculizada permite
   trazar visión; eso no declara que un ataque sea legal.
4. El informe explica causas y muestra **Registro y referencias**, con reglas,
   eventos consultados y elementos decisivos. Puedes ocultar sus resaltados.
5. El perfil cubre extremos de tamaño Normal, alturas, bases reconocidas y las
   cuatro mejoras declaradas de visión.
   Marca **Efectos especiales** si el caso requiere condiciones no modeladas.
   Tamaños de extremos sin soporte, versión desconocida y otros límites
   descritos en la matriz producen **No evaluado**.

En esquinas se comparan ambos lados, incluidas figuras y muros incidentes;
no se bloquea por tocar cualquier elemento aislado. Cambiar figuras, terreno,
muros, dimensiones o contexto actualiza el resultado. Borrar un extremo lo invalida.
Los nombres de las figuras no se interpretan como fichas oficiales ni poderes.
Este apoyo no sustituye una decisión oficial de torneo.

Fuentes, límites y casos esperados: [MATRIZ_REGLAS_VISION](docs/MATRIZ_REGLAS_VISION.md).

La revisión 0.7.1 corrige los cruces exactos por vértices de líneas oblicuas:
A1–D6 con B4 bloqueado y C3 libre da **despejada**. Se aplica el lado menos
restrictivo de §16.8b también cuando la pendiente no es de 45°.

## Inspeccionar una trayectoria

1. En la barra de herramientas desplazable elige **Línea de visión · Geometría**.
   Toca origen y destino, casillas o figuras. El asterisco indica el próximo extremo.
2. **Origen/Destino** permite elegir de nuevo uno. **Coordenadas / figuras** ofrece
   un formulario para coordenadas fijas o figuras que seguirán su posición.
   En inspección geométrica o referencia manual, una base múltiple permite elegir
   una casilla concreta. En Visión automática el motor compara las referencias.
3. **Inspeccionar geometría** muestra puntos exactos, tramos dentro de casillas y
   eventos ordenados. Azul/círculo: borde o interior; lila/rombo: vértice. Las dos
   casillas laterales tocadas solo en esquina llevan marcas sin relleno interior.
4. El inspector permite ocultar segmento/extremos, casillas y contactos. También
   se abre desde Opciones del tablero. La barra tiene Invertir y Limpiar.
5. Para mover figuras cambia a Seleccionar/Personajes o usa su ficha. La trayectoria
   ligada a una figura se recalcula; borrar un extremo retira el resultado y muestra
   error. Zoom y orientación no alteran la geometría. Dos dedos navegan sin elegir.

La inspección geométrica identifica contactos sin interpretar reglas. **Dictamen
de visión** aplica por separado el perfil reglamentario documentado de 06.
Los extremos y superposiciones son transitorios: no cambian JSON ni se exportan
en el PNG del escenario. Detalles matemáticos en [GEOMETRIA](docs/GEOMETRIA.md).

## Guardar e intercambiar escenarios

- El icono de carpeta abre la **Biblioteca local**. Permite abrir, crear, renombrar,
  duplicar, eliminar con confirmación y ordenar por nombre o última edición.
- El menú superior ofrece **Guardar**, **Guardar como**, nuevo, importar JSON,
  exportar/compartir JSON y exportar PNG. Guardar como crea otra identidad;
  dos escenarios pueden tener el mismo nombre. El ID corto distingue las copias.
- Cada edición lógica activa el autoguardado de la sesión actual. El indicador
  de estado permite consultar el resultado y reintentar un fallo. Guarda en la
  biblioteca para conservar varias versiones: cambiar de escenario sustituye la
  recuperación actual y pide confirmación si hay cambios fuera de la biblioteca.
- **Deshacer/Rehacer** está en la barra de herramientas desplazable. Incluye
  figuras, equipos, terreno, muros, limpiezas y dimensiones. Abrir, importar, nuevo
  o guardar como reinicia el historial. Cámara, selección y herramientas no entran.
- JSON legible de esquema 3, con lectura de 1/2, máximo 2 MiB; importar valida todo antes de sustituir
  el tablero y crea un ID nuevo. Una versión desconocida falla sin modificarlo.
- PNG usa el tablero completo, sin controles, con coordenadas/leyenda opcionales.
  Máximo 2048 px por eje por defecto o 4096 px con la opción de alta resolución.
  En mapas 40×40 conviene 4096 px; puede necesitar unos 64 MiB solo para la imagen.
- Android permite elegir el destino y compartir mediante su selector nativo.
  No necesita permisos de almacenamiento amplios, cuentas ni servidor. El destino
  elegido al compartir puede tener sus propios requisitos de red.

La recuperación se escribe de forma asíncrona: espera a que el indicador confirme
el autoguardado antes de forzar el cierre. Desinstalar elimina la biblioteca privada;
exporta JSON para conservar una copia externa. Detalles en [ESCENARIOS](docs/ESCENARIOS.md).

## Uso del Editor

1. **Abrir editor**. El botón de cuadrícula superior cambia filas y columnas.
   Reducir se rechaza si dejaría figuras, terreno o muros fuera de sus límites.
2. **Seleccionar** permite tocar una casilla o figura, arrastrar para pan y usar
   pinza o botones −/+ para zoom. Centrar mantiene el zoom; Ajustar encaja el mapa.
3. **Personajes** y toque en vacío abre la ficha. Nombre, equipo, posición, base,
   velocidad y alcance son editables. Velocidad/alcance: enteros 0–99 como datos.
   El lápiz inferior abre la ficha; la lista superior permite elegir cualquier figura.
4. Mantener pulsada una figura y arrastrar muestra destino ✓/×. Solo al soltar un
   destino válido se mueve. La ficha permite editar la coordenada como alternativa.
5. **Terrenos** muestra un selector D/Despejado, H/Obstaculizado o B/Bloqueado.
   Toca o arrastra para pintar. La vista previa no modifica el mapa; el trazo completo
   se aplica al soltar. Se interpolan los eventos para evitar huecos en trazos rápidos.
6. Elige **Rellenar rectángulo**, arrastra entre dos casillas y pulsa **Aplicar
   terreno** o **Cancelar**. **Coordenadas** permite indicar inicio/fin sin arrastrar.
   Con poco espacio vertical, la confirmación usa un diálogo desplazable.
7. **Muros** permite Añadir/Borrar muro. Toca o traza cerca de un borde interno;
   cada trazo conserva la orientación del primer borde. No se admiten bordes externos.
   **Coordenadas** recibe dos casillas vecinas ortogonales que comparten el muro.
8. **Borrar elemento** tiene un selector explícito de figura o muro. Borrar figura
   pide confirmación y no cambia terreno/muros. Para quitar terreno usa **Despejado**.
9. El menú superior ofrece **Leyenda y capas** y **Limpiar solo terreno/muros/figuras**.
   Cada limpieza pide confirmación y conserva las otras capas.

En Terrenos, Muros y Borrar, un dedo edita y dos dedos permiten navegar. Añadir un
segundo dedo o cancelar el gesto descarta la edición transitoria. Cambiar herramienta
u orientación cancela la previa. En mapas grandes, amplía para leer y tocar con precisión.
La barra de opciones de capa se desplaza horizontalmente en pantallas pequeñas.

## Posiciones para estudio

Pintar bloqueado bajo una figura ofrece **Cancelar** o **Conservar para estudio**.
Esta última mantiene la figura y marca cada casilla incompatible con **!**; no afirma
legalidad reglamentaria. También se requiere optar explícitamente por estudio en la
ficha si se crea o edita una figura sobre bloqueado. El arrastre ordinario rechaza
ese destino y remite a la ficha. Obstaculizado no elimina ni desplaza figuras.

Las bases se anclan arriba a la izquierda y la huella completa valida ocupación.
El editor admite colocación sobre un único nivel; las combinaciones que requieren
excepciones no modeladas permanecen pendientes. El 0 histórico de elevación se
conserva como alias interno del suelo (nivel oficial 1); el editor muestra 1–40.

## Ejecutar y verificar

```powershell
$env:Path = "$env:USERPROFILE\develop\flutter\bin;$env:Path"
flutter --no-version-check pub get
dart run tool/verify_geometry.dart
dart run tool/verify_vision.dart
dart run tool/verify_targets.dart
dart run tool/verify_advanced_vision.dart
dart run tool/verify_movement.dart
dart run tool/benchmark_targets.dart --mixed
dart run tool/benchmark_movement.dart
dart format --output=none --set-exit-if-changed lib test tool
flutter --no-version-check analyze
flutter --no-version-check test
flutter --no-version-check test tool/preview_test.dart
flutter --no-version-check build apk --debug
```

`--no-version-check` evita una consulta de actualización del SDK; no cambia su
versión ni omite análisis o pruebas. Los renders se escriben en
`build/previews/prompt-09/`; son capturas Flutter, no de un dispositivo.

Preparación Android y firma release en [ANDROID.md](docs/ANDROID.md).
El APK debug y sus resultados/hash se registran en [ESTADO.md](docs/ESTADO.md).
No se incluyen binarios, credenciales ni claves en Git.

## Organización y límites

- `lib/domain/board`: dimensiones, coordenadas y cámara en Dart puro.
- `lib/domain/characters`: figuras, equipos, huellas y ocupación.
- `lib/domain/terrain`: terreno, elevación, transiciones, muros y hit tests.
- `lib/domain/geometry`: fracciones exactas, segmentos y eventos de intersección.
- `lib/domain/rules`: perfil versionado de visión, observaciones y referencias.
- `lib/domain/movement`: validación de pasos, rutas, paradas y búsqueda verificada.
- `lib/application/board`: sesión inmutable, comandos reversibles e historial acotado.
- `lib/application/scenarios`: documento, codec y repositorio de escenarios.
- `lib/infrastructure/local`: archivos privados y puente nativo Android.
- `lib/presentation/scenarios`: biblioteca, autoguardado, acciones y render PNG.
- `lib/presentation/editor`: formularios, herramientas, vista previa y canvas por capas.
- `lib/presentation/vision`: informe y vistas de Simulador/Árbitro.
- `test`: contratos de dominio, gestos, confirmaciones, accesibilidad y regresiones.

`ScenarioCodec` define el documento completo con `schemaVersion: 3` y utiliza
`LayerCodec` para validar las capas. El formato externo se documenta con sus
límites; cámara, controles y borradores no forman parte del archivo.

Sin backend, cuentas, telemetría, fuentes remotas ni red en runtime. La instalación
de herramientas y compilación durante el desarrollo sí puede necesitar internet.

## Documentación

[ROADMAP](docs/ROADMAP.md), [DECISIONES](docs/DECISIONES.md),
[ARQUITECTURA](docs/ARQUITECTURA.md), [ESTADO](docs/ESTADO.md),
[REGLAS](docs/REGLAS.md) y [ANDROID](docs/ANDROID.md).
Informes anteriores: [00](docs/ENTREGA_00.md), [01](docs/ENTREGA_01.md),
[02](docs/ENTREGA_02.md), [03](docs/ENTREGA_03.md), [04](docs/ENTREGA_04.md),
[05](docs/ENTREGA_05.md), [06 inicial](docs/ENTREGA_06.md),
[06 corregida](docs/ENTREGA_06_FIX.md), [07](docs/ENTREGA_07.md), [08](docs/ENTREGA_08.md).

**No se inició Prompt 10.** Requiere una nueva orden tras revisar esta entrega.
