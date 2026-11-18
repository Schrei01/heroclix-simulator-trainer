# TeamFight: GridLab

Aplicación Android Flutter/Dart, offline y en español. Versión **1.0.0-rc.11+24**.
La versión actual está en la rama `codex/indoor-movement-strokes` del repositorio privado
[Schrei01/heroclix-simulator-trainer](https://github.com/Schrei01/heroclix-simulator-trainer).

Desde rc.8 la marca visible es **TeamFight: GridLab**, con los iconos Android y el
símbolo aportados por el usuario. Conserva el identificador y los datos de la app.
Recursos y procedencia en [IDENTIDAD](docs/IDENTIDAD.md).

Desde rc.11, el selector **Indoor/Outdoor** de la barra aplica el tipo a todo el
mapa (al cambiar reinicia las zonas Indoor locales). Indoor completo lleva borde
amarillo. En Outdoor, **Terrenos → Indoor** pinta zonas independientes de obstáculos,
agua y altura. Se guardan en biblioteca, JSON y PNG. Movimiento abre directamente:
elige figura y toca pasos o traza desde ella; Confirma en la barra para moverla.

Desde rc.10, Terrenos incluye **Agua** por trazo o rectángulo: icono de gota,
azul con ondas y letra A. Conserva alturas, admite figuras y se guarda en biblioteca,
JSON y PNG. La paleta reúne seis pinceles. Según §16.6 de la edición implementada,
agua se considera despejado para visión/movimiento salvo efectos específicos.

Esta beta rc.11 vence el **30 de diciembre de 2026 a las 00:00, hora de Colombia**
(2026-12-30T05:00:00Z). Desde ese instante muestra «Versión de prueba finalizada»
y bloquea todas las pantallas, también al reanudar o si permanece abierta. Acerca de
muestra la fecha. No elimina biblioteca ni progreso. Usa el reloj del dispositivo:
no es una licencia validada por servidor y puede eludirse al alterar el reloj.
La futura edición de Play debe retirar expresamente este corte. Instalar una beta
anterior sin caducidad también queda fuera de este control local.

```powershell
git clone https://github.com/Schrei01/heroclix-simulator-trainer.git
cd heroclix-simulator-trainer
git switch codex/indoor-movement-strokes
```

## Qué existe

Editor con tablero 10×10 inicial, filas/columnas independientes de 2 a 40,
coordenadas A1…AN40, selección, zoom, pinza y pan. Figuras genéricas con identidad
estable, etiquetas A…Z, AA…, equipos con código/color/patrón y ficha editable.
Bases 1×1, 1×2, 2×2, 2×4 y 3×6, con rotaciones ortogonales y ocupación completa;
duplicar y borrar con confirmación. La huella y el tamaño de personaje son datos distintos.

La etapa 03 añade terreno despejado, obstaculizado y bloqueado; muros sobre bordes
internos; trazo y relleno rectangular con vista previa; borrado por capa y tres
limpiezas independientes. La leyenda usa letras, puntos, rayas y línea doble,
además del color. Figuras, terreno y muros tienen datos separados.

La etapa 04 añadió biblioteca local, recuperación automática de sesión, historial
de 100 operaciones, JSON versionado y PNG del tablero. La etapa 05 añade geometría
exacta. La etapa 06 incorpora visión reglamentaria básica en Editor, Simulador y
Árbitro, compartiendo escenario y motor. La etapa 07 añade distancias, comparación
con alcance declarado y consulta de objetivos. La etapa 08 incorpora alturas,
transiciones y cuatro mejoras de visión tipadas. La etapa 09 añade rutas de
movimiento verificadas, alternativas y comparación de posiciones. La etapa 10
añade Entrenador, ejercicios personales y progreso local. La etapa 11 incorpora
comparación de posiciones y métricas tácticas. Ataques completos siguen pendientes.

La etapa 12 integra cinco ejemplos locales, Guía rápida y Acerca de con cobertura
y licencias offline; corrige la exportación Android TXT y la selección táctica al
reutilizar caché. Es una **candidata**: falta la aceptación nativa, no se congela
1.0.0 estable. Instalación, recompilación y mantenimiento en [README_FINAL](README_FINAL.md).

Desde rc.3 cada apertura empieza con escenario vacío y figuras desde A. La escena
se conserva mientras siga abierta la app; **Guardar** en biblioteca permite conservarla
para abrirla manualmente después. El progreso del Entrenador sigue siendo persistente.
Al trazar entre dos figuras, el dictamen aparece directamente arriba del mapa.

Desde rc.4 se retiran los módulos Simulador y Árbitro. Inicio ofrece **Editor** y
**Entrenador**; las consultas, informes y ensayos están en las herramientas del Editor.
Las transiciones se distinguen por triángulos blancos numerados con borde rojo.

Desde rc.5 Terrenos reúne cinco pinceles, incluido Elevado (toques E2→E3…) y
Transición (dos vecinos de alturas distintas). Seleccionar permite confirmar
borrado con dos toques en la misma casilla; Borrar también retira alturas y
transiciones. No se permite crear o mover figuras sobre bloqueado ni pintarlo
bajo ellas. La ficha agrupa Improved Targeting y Movement en listas desplegables.

Desde rc.6 Elevado permite trazar: cada casilla sube un nivel desde el valor que
tenía al empezar, una sola vez aunque el trazo vuelva sobre ella. Borrar empieza
en Borrar todo y limpia todas las capas de las casillas recorridas; tocar una base
retira la figura completa. Un Deshacer recupera el trazo. En Personajes, dos toques
sobre una figura pasan al equipo siguiente y el último vuelve al primero. Los
avisos de herramienta aparecen verticalmente a la derecha del mapa durante 4 s.

En rc.7 el aviso se lee con el texto derecho, en una columna de arriba hacia abajo,
sin girar el teléfono. Mantiene su posición lateral y los cuatro segundos.

## Analizar y comparar posiciones

1. En **Editor → Analizar posición**, elige la figura activa y pulsa Analizar.
2. Consulta visibles, enemigos que la ven, alcance, líneas H/bloqueadas y amenazas
   conocidas. Cada métrica muestra definición, referencias y No evaluados.
3. Elige una casilla candidata del mapa o la lista: muestra ruta, costo y cambios
   frente a la posición actual. Las casillas representan anclas de la base;
   el validador comprueba toda su huella. No mueve la figura hasta confirmar.
4. Cambia prioridad: más visibles, menos líneas enemigas o menor movimiento.
   Solo ordena resultados completos de esta página; no declara la mejor jugada.
5. Compara sin mejoras soportadas del activo con la opción HIPÓTESIS. Conserva
   capacidades sin soporte como incertidumbre. Puedes cancelar o cambiar de página.
6. Crea un ejercicio de recorrido o de posición desde la comparación; aparece
   en el Entrenador con snapshot propio y solución verificada. Exporta el diagnóstico
   como TXT o PNG con etiquetas genéricas, sin nombres ni metadatos del escenario.

Se calculan 12 destinos por página y hasta 32 enemigos por posición. Los restantes
son No evaluados, nunca ceros. Detalles y límites: [ANALISIS_TACTICO](docs/ANALISIS_TACTICO.md).

## Practicar con el Entrenador

1. Inicio → **Entrenador**. Hay **24 ejercicios** en seis categorías y tres
   dificultades. Filtra y pulsa **Iniciar ejercicio**.
2. Responde por opciones, tocando una figura/casilla o trazando una ruta con
   casillas sucesivas. **Comprobar respuesta** muestra acierto/error, explicación
   del motor y referencias. Las pistas aparecen solo cuando las solicitas.
3. **Repetir ejercicio** prepara otra respuesta sin sumar un intento hasta
   comprobarla. **Revisar último intento** no recalifica ni altera estadísticas.
   **Practicar errores** filtra el último fallo elegible en esta edición.
4. **Progreso por categoría** muestra intentos, aciertos, porcentaje, completados y
   último intento. Las revisiones manuales no entran en el porcentaje automático.
   Reiniciar estadísticas pide confirmación y conserva ejercicios personales.
5. Guarda un escenario en la biblioteca del Editor. En Entrenador pulsa **+**,
   elige el escenario y define pregunta, opciones/pista y solución. Se copia el
   escenario; el original sigue igual. El motor verifica soluciones automáticas.
   Texto libre se identifica como **evaluación manual** y requiere guía del autor.

El tablero de práctica es independiente del Editor. Una edición diferente, una
solución que difiere del motor o un caso No evaluado inhabilita la autocorrección.
Detalles del banco, estadísticas, persistencia y límites: [ENTRENADOR](docs/ENTRENADOR.md).

## Ensayar movimiento

1. En **Editor → Movimiento**, elige la figura desde el informe o toca su casilla.
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

1. En Editor elige **Terrenos → Elevado**. Toca o traza para subir un nivel por
   casilla desde su valor inicial: suelo a E2, E2 a E3, hasta E40. Volver sobre una
   casilla sin soltar no vuelve a elevarla. **Coordenadas** abre el formulario avanzado:
   Indica una casilla o región y un nivel de 1 a 40. Sobre suelo el formulario
   propone nivel 2; al editar una elevación conserva su nivel actual. El suelo es nivel 1; las
   alturas muestran E2, E3… y bordes rojos. Las transiciones usan un triángulo blanco
   con borde rojo y nivel dentro de cada casilla conectada. Con **Terrenos → Transición**
   toca dos vecinos ortogonales de
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
5. El **informe de visión del Editor** muestra alturas, capacidades, excepciones aplicadas y el
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
5. Usa las herramientas del Editor para alternar Visión, Medir distancia y Mostrar
   objetivos. Para mover figuras libremente vuelve a Seleccionar.

Estados: en alcance con visión despejada, en alcance con visión obstaculizada,
visión bloqueada, fuera de alcance y no evaluado. Distancia, alcance y visión
se conservan como dimensiones independientes. **Visible y en alcance no significa
ataque legal.** El filtro de aliados no concede permiso de ataque.
Bases reconocidas y alturas se evalúan según el perfil de 08; formas o condiciones
sin soporte conservan dimensiones pendientes. Más detalles en [MATRIZ_DISTANCIAS_OBJETIVOS](docs/MATRIZ_DISTANCIAS_OBJETIVOS.md).
La consulta y sus superposiciones no se guardan ni se exportan en PNG; el alcance
editado sí pertenece al escenario, junto con capacidades, altura y transiciones.

## Consultar un dictamen de visión

1. Crea o abre un escenario con figuras en el Editor. En Línea de visión toca
   origen y destino: el dictamen aparece automáticamente en una franja sobre el mapa.
   Tócala para ver explicación y referencias; el informe también está en Opciones.
2. Todo el análisis está disponible en el Editor: visión, distancia, objetivos,
   movimiento y comparación de posiciones. Inicio conserva Editor y Entrenador.
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
- La escena actual es temporal: cambiar de sección o dejar la app en segundo plano
  conserva la sesión si sigue activa. Una nueva apertura empieza vacía y desde A.
  **Guardar** o **Guardar como** conserva el escenario en biblioteca; cambiar a otra
  escena pide confirmación si hay cambios sin guardar. La recuperación antigua no
  se abre ni se actualiza automáticamente.
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

Guarda en biblioteca antes de cerrar si deseas conservar la escena. Desinstalar elimina la biblioteca privada;
exporta JSON para conservar una copia externa. Detalles en [ESCENARIOS](docs/ESCENARIOS.md).

## Uso del Editor

1. **Abrir editor**. El botón de cuadrícula superior cambia filas y columnas.
   Reducir se rechaza si dejaría figuras, terreno o muros fuera de sus límites.
2. **Seleccionar** permite tocar una casilla o figura, arrastrar para pan y usar
   pinza o botones −/+ para zoom. Centrar mantiene el zoom; Ajustar encaja el mapa.
   Dos toques consecutivos en la misma casilla preguntan si quieres borrar: primero
   personaje, después tipo de terreno y luego elevación. Cancelar conserva todo.
3. **Personajes** y toque en vacío coloca una figura inmediatamente: nombre Figura,
   primer equipo, base 1×1, tamaño Normal, velocidad 6 y alcance 4, sin mejoras.
   Para cambiarla, selecciónala y pulsa el lápiz inferior; la lista superior también
   abre fichas. Nombre, equipo, posición, base, velocidad y alcance siguen editables.
   Cada colocación permite Deshacer/Rehacer y se conserva en la sesión abierta.
   En Personajes, dos toques sobre la misma figura cambian de equipo: T1, T2, T3…
   según los disponibles y volviendo al primero al terminar. No modifica su ficha.
4. Mantener pulsada una figura y arrastrar muestra destino ✓/×. Solo al soltar un
   destino válido se mueve. La ficha permite editar la coordenada como alternativa.
5. **Terrenos** muestra cinco iconos centrados al pie del mapa: Bloqueado,
   Obstaculizado, Elevado, Transición y Despejado. Tienen selección visible, nombre y ayuda al mantener
   pulsado; en poco espacio se muestran solo iconos con etiquetas accesibles.
   Elegir uno no pinta. Toca o arrastra en el mapa para pintar. La vista previa no modifica el mapa; el trazo completo
   se aplica al soltar. Se interpolan los eventos para evitar huecos en trazos rápidos.
6. Elige **Rellenar rectángulo**, arrastra entre dos casillas y pulsa **Aplicar
   terreno** o **Cancelar**. **Coordenadas** permite indicar inicio/fin sin arrastrar.
   Con poco espacio vertical, la confirmación usa un diálogo desplazable.
7. **Muros** permite Añadir/Borrar muro. Toca o traza cerca de un borde interno;
   cada trazo conserva la orientación del primer borde. No se admiten bordes externos.
   **Coordenadas** recibe dos casillas vecinas ortogonales que comparten el muro.
8. **Borrar elemento** comienza en **Borrar todo**: trazar limpia terreno, altura,
   figuras, muros y transiciones de las casillas recorridas, sin pedir confirmación.
   Una figura se retira completa al tocar su base. Un Deshacer recupera todo el
   trazo. También permite elegir figura, terreno, elevación, transición o muro.
   Borrar figura pide confirmación. Borrar terreno conserva altura; borrar elevación
   devuelve al suelo y retira las transiciones que dejan de unir niveles distintos.
   Borrar transición se aplica sobre su borde compartido y conserva la altura.
9. El menú superior ofrece **Leyenda y capas** y **Limpiar solo terreno/muros/figuras**.
   Cada limpieza pide confirmación y conserva las otras capas.

En Terrenos, Muros y Borrar, un dedo edita y dos dedos permiten navegar. Añadir un
segundo dedo o cancelar el gesto descarta la edición transitoria. Cambiar herramienta
u orientación cancela la previa. En mapas grandes, amplía para leer y tocar con precisión.
La barra de opciones de capa se desplaza horizontalmente en pantallas pequeñas.

## Posiciones y compatibilidad

No se permite crear, duplicar, mover o editar figuras hacia terreno bloqueado,
ni pintarlo bajo una figura. No hay checkbox ni confirmación para autorizarlo.
Las escenas antiguas conservan sus datos al abrirse: una incompatibilidad heredada
se marca con ! y debe corregirse moviendo la figura o limpiando el terreno.
Obstaculizado no elimina ni desplaza figuras. Las opciones antiguas Otra excepción
no se ofrecen en la ficha; sus datos heredados conservan No evaluado.

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
dart run tool/verify_training.dart
dart run tool/verify_tactics.dart
dart run tool/benchmark_targets.dart --mixed
dart run tool/benchmark_movement.dart
dart run tool/benchmark_tactics.dart
dart format --output=none --set-exit-if-changed lib test tool
flutter --no-version-check analyze
flutter --no-version-check test
flutter --no-version-check test tool/preview_test.dart
./tool/build_apk.ps1 | Format-List
```

`--no-version-check` evita una consulta de actualización del SDK; no cambia su
versión ni omite análisis o pruebas. Los renders se escriben en
`build/previews/teamfight-brand/`; son capturas Flutter, no de un dispositivo.

Preparación Android y firma release en [ANDROID.md](docs/ANDROID.md).
El APK debug y sus resultados/hash se registran en [ESTADO.md](docs/ESTADO.md).
No se incluyen binarios, credenciales ni claves en Git.

La generación con `tool/build_apk.ps1` conserva solo el APK entregable más reciente
en `build/releases/`. Primero compila, comprueba paquete/versión/firma y verifica
la copia; después elimina los APK anteriores. Si falla la compilación o la
validación, conserva los anteriores.
Las salidas técnicas actuales de Flutter/Gradle permanecen en `build/app/`.

## Organización y límites

- `lib/domain/board`: dimensiones, coordenadas y cámara en Dart puro.
- `lib/domain/characters`: figuras, equipos, huellas y ocupación.
- `lib/domain/terrain`: terreno, elevación, transiciones, muros y hit tests.
- `lib/domain/geometry`: fracciones exactas, segmentos y eventos de intersección.
- `lib/domain/rules`: perfil versionado de visión, observaciones y referencias.
- `lib/domain/movement`: validación de pasos, rutas, paradas y búsqueda verificada.
- `lib/domain/training`: ejercicios, correctores compartidos, banco y progreso.
- `lib/domain/tactics`: métricas, incertidumbre y comparación sobre snapshots.
- `lib/application/tactics`: cálculo segmentado en isolate y resumen público.
- `lib/presentation/tactics`: mapa, comparación, cancelación y exportación PNG.
- `lib/application/board`: sesión inmutable, comandos reversibles e historial acotado.
- `lib/application/scenarios`: documento, codec y repositorio de escenarios.
- `lib/application/training`: formato versionado y persistencia del Entrenador.
- `lib/infrastructure/local`: archivos privados y puente nativo Android.
- `lib/presentation/scenarios`: biblioteca, sesión temporal, acciones y render PNG.
- `lib/presentation/editor`: formularios, herramientas, vista previa y canvas por capas.
- `lib/presentation/vision`: controles e informes de análisis usados por el Editor.
- `lib/presentation/training`: banco, pregunta, respuesta y autor de ejercicios.
- `lib/application/examples` y `lib/presentation/examples`: catálogo local y copias protegidas.
- `lib/presentation/help`: guía, identidad de versión, cobertura y licencias locales.
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
[06 corregida](docs/ENTREGA_06_FIX.md), [07](docs/ENTREGA_07.md), [08](docs/ENTREGA_08.md), [09](docs/ENTREGA_09.md), [10](docs/ENTREGA_10.md), [11](docs/ENTREGA_11.md), [12](docs/ENTREGA_12.md), [rc.2](docs/ENTREGA_RC2.md).

Las etapas 00–12 están implementadas dentro del perfil documentado. La candidata
mantiene aceptación Android pendiente: [MATRIZ_ACEPTACION](docs/MATRIZ_ACEPTACION.md).
No se implementó una partida completa.
