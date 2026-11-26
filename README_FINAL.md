# TeamFight: GridLab — 1.0.0-rc.20+33

Aplicación Android offline, en español, para construir escenarios, consultar reglas
implementadas y practicar. **Versión candidata, APK debug**: faltan las comprobaciones
nativas de aceptación y rendimiento descritas abajo. No se congela 1.0.0 estable.
Repositorio privado: [Schrei01/heroclix-simulator-trainer](https://github.com/Schrei01/heroclix-simulator-trainer),
rama `codex/priority-seat-drag`. Evidencia exacta y SHA-256 en [ESTADO](docs/ESTADO.md).

Nombre e iconos de Android, Inicio y Acerca de actualizados a TeamFight: GridLab.
La identidad técnica y firma se conservan para actualizar la instalación anterior.
Archivos de Google Play preparados en distribution/google-play/; [detalles de identidad](docs/IDENTIDAD.md).

Esta beta rc.20 vence el **30 de diciembre de 2026 a las 00:00, hora de Colombia**
(2026-12-30T05:00:00Z). Desde ese instante muestra «Versión de prueba finalizada»
y bloquea todas las pantallas, también al reanudar o si permanece abierta. Acerca de
muestra la fecha. No elimina biblioteca ni progreso. Usa el reloj del dispositivo:
no es una licencia validada por servidor y puede eludirse al alterar el reloj.
La futura edición de Play debe retirar expresamente este corte. Instalar una beta
anterior sin caducidad también queda fuera de este control local.

## Instalar y actualizar

El archivo generado se conserva en:

```text
build/releases/teamfight-gridlab-1.0.0-rc.20-debug.apk
```

1. Android 7.0/API 24 o superior. Copiar el APK al teléfono, abrirlo en Archivos
   y autorizar la instalación desde esa aplicación cuando Android lo solicite.
2. Para actualizar una versión anterior con esta misma firma, instalar encima,
   **sin desinstalar**. Se conservan archivos privados, escenarios guardados y progreso.
   Cambiar firma o applicationId impide esa actualización directa.
3. Alternativa con depuración USB autorizada y Android Platform Tools:

```powershell
adb devices -l
adb -s ID install -r build/releases/teamfight-gridlab-1.0.0-rc.20-debug.apk
adb -s ID shell am start -n com.valinor.heroclixtrainer/com.valinor.heroclix_simulator_trainer.MainActivity
```

La firma debug coincide con 00–11; instalación de esta candidata todavía no
verificada en Android. Antes de desinstalar, exportar escenas como JSON. La
desinstalación elimina progreso y ejercicios personales; su exportación todavía
no está implementada. PNG sirve para compartir una imagen, no para recuperar datos.

## Uso básico

Desde inicio, abre **Priority** para asistir una partida física del formato de
Valinor. Configura 2–6 jugadores, nombres, puntos de construcción comunes y
adicionales individuales; organiza asientos
con las flechas anterior/siguiente y elige o sortea al inicial. **Listo** abre la
mesa con paneles orientados hacia sus respectivos jugadores. Para 3 y 4 se usa
el mismo esquema de lados opuestos de 5 y 6. Los botones son rectangulares, con
esquinas de 6 píxeles. El borde dorado identifica quién puede intervenir;
ACTIVO y REACTIVO indican el papel de cada jugador. Se retiraron el rótulo
PRIORIDAD y la franja superior de ronda/turno para dar más espacio a la mesa.
ACTIVO aparece en negrilla, con punto y fondo del color del jugador. La luz sube
y baja dos veces al iniciar el turno (3,2 s) y queda fija después. Con animaciones
reducidas es fija desde el inicio. El borde dorado sigue indicando prioridad;
el indicador ACTIVO permanece en el dueño del turno durante las respuestas.

El activo usa ACTION/FREE/END TURN; los reactivos usan RESPONSE ACTION/RESPONSE
FREE/PASS cuando están habilitados. Los jugadores pulsan después de resolver sus
acciones físicas. Toca el contador disponibles/totales para editar adicionales:
el consumo anterior se conserva. END TURN restablece las acciones de todos.
Volver al inicio y regresar conserva la partida mientras la app siga abierta;
Nueva partida pide confirmación. Activa **Cronómetros individuales** en la
configuración y elige minutos completos. Solo corre el reloj de quien tiene prioridad.
Pausa/reanuda desde la barra; salir del módulo o volver de segundo plano exige
reanudar manualmente. Agotar tiempo pausa y muestra un aviso flotante temporal,
sin eliminar automáticamente; el reloj queda rojo a cero. **Ver** abre la gestión
del jugador. El aviso no reduce la mesa y desaparece a los 8 segundos.

La barra de cada jugador tiene **−/+** para restar/sumar 5 PV por toque y una
**calavera** para eliminar con confirmación. Cada toque muestra el cambio y
reinicia su difuminado de 3 segundos: +5, +10, +15… Al cambiar de signo comienza
un nuevo acumulado. Tras 3 segundos sin tocar desaparece; el total de PV se conserva
visible. La resta se desactiva si dejaría un total negativo. Admite pulsaciones rápidas.
En rc.19 los PV salen del contador de acciones y se centran entre −/+ al doble
de tamaño (22), en negrilla. Junto al nombre aparece la posición dentro de un
círculo: 1 y 2 dorados, 3 bronce y del 4 en adelante verde. La clasificación se
actualiza con cada ajuste y comparte posición en empates; conserva eliminados.
En rc.20 los botones −/+ quedan próximos al total. Para cambiar asientos, mantén
pulsado un asiento en la vista de configuración y suéltalo sobre otro: la marca
INICIA sigue al seleccionado y ese jugador empieza aunque cambie de lugar.
Durante la partida, hazlo desde el nombre hacia otro panel. Este intercambio
mueve las vistas y conserva el inicial y el orden de juego ya establecido,
incluidas respuestas pendientes, colores, PV, acciones y relojes. Soltar fuera
cancela. Las posiciones se conservan al salir y volver mientras la app siga abierta.
En rc.17 los botones de acción tienen más aire respecto al borde del panel y
«Aplicar puntos» está separado del campo anterior, con mayor espacio interior.

Toca el nombre o los tres puntos del panel para gestionar al jugador: sumar/restar
puntos, corregir el total, corregir tiempo o eliminar con confirmación. La corrección
del tiempo reemplaza el restante por minutos completos y deja la partida pausada;
confirma y reanuda. El campo propone redondear hacia arriba el tiempo restante.
La clasificación se abre
desde la barra y conserva a los eliminados y los empates. Un superviviente finaliza
la partida y abre la clasificación; no declara un ganador automático. Los puntos
se pueden corregir también al finalizar, sin reabrir el juego.
Historial, Deshacer y guardado de Priority siguen pendientes.
[Plan y pruebas](docs/PRIORITY_PLAN.md).

En la ficha, **IM Destruir bloqueado y muros** permite destruir lo que atraviesa.
El ensayo conserva el mapa original y muestra el plan; Confirmar aplica posición,
destrucción y escombros como una sola operación. B recorrido se convierte en debris
obstaculizado; el muro cruzado desaparece y deja debris en sus lados no bloqueados.
Se incluyen origen/destino según §10.4; el destino puede ser la casilla B que acaba
de destruirse, porque ahora es H. La elevación e Indoor se conservan.

**IM Bloqueado** y **Bloqueado exterior** no destruyen. Deshacer recupera posición,
terreno y muros. Borrar escombros retira solo el marcador y descubre el terreno
subyacente (por ejemplo, agua); B destruido queda despejado y el muro no reaparece.
Los debris se conservan en biblioteca/JSON/PNG. Las diagonales escogen el lado menos
restrictivo, prefiriendo menos destrucción y un desempate canónico visible en el
plan; no se destruyen automáticamente los cuatro lados de un vértice.

El selector **Indoor/Outdoor** sustituye el botón de estado del escenario en la
barra de herramientas. Cambiarlo aplica el tipo al mapa completo y reinicia las
marcas Indoor locales; Deshacer recupera el estado anterior. Indoor completo lleva
borde amarillo; en Outdoor puedes pintar zonas con **Terrenos → Indoor**. La marca
amarilla/I es independiente del terreno y la altura. Despejado los conserva;
Borrar Indoor retira solo la marca local y Borrar todo limpia la casilla.

Movimiento entra sin abrir el informe: primero toca una figura; después toca pasos
vecinos o arrastra desde ella (también puedes continuar desde el último paso).
El trazo rellena sus pasos intermedios y no cambia la posición original hasta
**Confirmar** en la barra. Dos dedos navegan y cancelan el trazo actual. Elegir otra
figura reinicia el ensayo; el dictamen abre el informe y sus opciones avanzadas.

Indoor por sí solo no cambia visión o costo de movimiento: el amarillo no es un
muro. Un muro que coincide con ese límite es Indoor. IM Bloqueado exterior ahora
distingue ambos ámbitos; IM Bloqueado conserva su alcance y nunca permite terminar
sobre bloqueado. Fuente: §15.1/27.5c en [REGLAS](docs/REGLAS.md).

Se escribe JSON de escenario versión 5 (capas 4), leyendo versiones 1–4. Los formatos
1–3 se interpretan como Outdoor, y 1–4 no tienen debris. Guardar una versión anterior
crea primero una copia schema1/schema2/schema3/schema4,
también con archivos reales. Los archivos nuevos no se pueden abrir con apps viejas.

| Entrada | Para qué sirve |
| --- | --- |
| Editor | Crear tablero 2–40 filas/columnas, figuras genéricas, equipos, terreno, muros y alturas; biblioteca y Deshacer |
| Entrenador | 24 ejercicios curados más personales; responder, comprobar, recibir explicación y conservar progreso |
| Priority | Mesa para 2–6 jugadores: turnos, prioridad, acciones, relojes opcionales, puntos, clasificación y eliminación |
| Ejemplos locales | Visión H, diagonal/vértice, muro, elevación y movimiento; previsualizar y abrir copia independiente |
| Guía rápida / Acerca de | Ayuda breve, versión, cobertura, fuente y licencias locales |

Un dedo usa la herramienta; dos dedos navegan. En mapas grandes amplía antes de
tocar. En horizontal las herramientas se desplazan para conservar el tablero.

En Editor, Personajes coloca al tocar una casilla vacía con valores predeterminados
(Figura, primer equipo, base 1×1, velocidad 6/alcance 4); seleccionar y pulsar el
lápiz permite editarlos después. Terrenos muestra siete iconos centrados bajo el
mapa: Bloqueado, Obstaculizado, Agua, Indoor, Elevado, Transición y Despejado. Agua se pinta
por trazo o rectángulo; muestra azul, ondas y letra A, conserva altura y permite
figuras. Se trata como despejado para visión y movimiento salvo efectos específicos
(§16.6). Borrar, Deshacer/Rehacer, biblioteca y JSON/PNG incluyen Agua. Elevado permite
trazar: suelo pasa a E2 y E2 a E3; cada casilla sube una vez por trazo desde su
altura inicial. Despejado conserva altura.
Transición espera dos vecinos ortogonales de niveles distintos y sin muro; anuncia
los errores. El suelo es nivel 1; Borrar permite retirar elevaciones y transiciones.
El Editor permite montar escenas con arrastre libre y validar rutas con Movimiento.
Ensayar no cambia posiciones hasta confirmar una ruta verificada.

Desde rc.4 Inicio contiene Editor y Entrenador. Visión, distancia, objetivos,
movimiento y comparación de posiciones se consultan desde las herramientas del
Editor. Las casillas de transición usan triángulos blancos con borde rojo y número
de nivel, uno a cada lado del borde compartido; las elevadas normales conservan E2/E3.

Desde rc.5 cada escenario nuevo empieza en 10×10; los guardados mantienen su tamaño.
Dos toques consecutivos en la misma casilla con Seleccionar preguntan si quieres
borrar personaje, terreno o elevación, en ese orden. La ficha ya no permite posiciones
sobre bloqueado, y también se rechaza pintarlo bajo figuras. Improved Targeting se
despliega como Movement; se retira la opción Otra excepción de ambas listas.
El dictamen aparece solo arriba del mapa. Origen y destino iguales limpian la visión.

Desde rc.6, dos toques sobre una figura con Personajes pasan al siguiente equipo
disponible y vuelven al primero al completar el ciclo. Los avisos de herramienta
aparecen verticalmente a la derecha del mapa durante cuatro segundos.
En rc.7 el texto queda derecho, distribuido en líneas de arriba hacia abajo.
Borrar empieza en Borrar todo: un trazo limpia todas las capas de las casillas
recorridas y retira las figuras completas que toca. Deshacer recupera todo el trazo.

H permite visión obstaculizada; B/muros pueden bloquear. «No evaluado» indica una
condición sin soporte o datos insuficientes, nunca permiso ni error automático.
Visión y alcance declarados no prueban que un ataque sea legal. El analizador
segmenta a 12 destinos/página y 32 enemigos: el resto permanece No evaluado.

Todo el contenido necesario está instalado: no requiere login, servidor o red.

Cada apertura empieza con un escenario vacío y las figuras desde A. La escena
temporal continúa al cambiar de sección o dejar la app en segundo plano si la
instancia sigue activa. **Guardar** en biblioteca permite abrirla manualmente en
otra sesión. Los guardados anteriores y el progreso del Entrenador se conservan;
el autoguardado antiguo del Editor deja de recuperarse y escribirse automáticamente.

En Línea de visión, elegir las dos figuras muestra el dictamen sobre el mapa sin
abrir menús. Tocar esa franja abre explicación/referencias. Conserva los estados
despejada, obstaculizada, bloqueada y No evaluada del mismo motor implementado.
Para usar archivos offline, elegir almacenamiento local en el selector Android;
proveedores externos del sistema pueden requerir conexión. El diagnóstico TXT/PNG
usa etiquetas genéricas. Exportar la escena completa sí conserva sus nombres.

## Implementado y pendiente

| Función | Estado |
| --- | --- |
| Editor y Entrenador, biblioteca, JSON/PNG y sesión temporal | Implementado; nuevo arranque vacío, biblioteca/progreso persistentes |
| Priority: configuración, mesa, turnos, prioridad, acciones, relojes, puntos y eliminación | Etapas 1–3 implementadas; partida en memoria, historial/Deshacer/guardado pendientes |
| Geometría, visión, alcance, alturas, mejoras tipadas y movimiento | Perfil parcial implementado, con reglas y No evaluados explícitos |
| Análisis de posiciones, hipótesis, ejercicios y diagnóstico TXT/PNG | Implementado; puente Android TXT corregido y compilado |
| Catálogo de cinco ejemplos, guía y Acerca de/licencias | Implementado y probado; recursos locales |
| Accesibilidad básica y adaptación vertical/horizontal | Pruebas de widgets, objetivos táctiles/etiquetas y contraste; falta TalkBack real |
| Instalación, nueva sesión tras cierre y selectores nativos | Pendiente de Android; equivalentes de archivos/controladores sí verificados |
| Offline con radios desactivadas y rendimiento Android/FPS | Pendiente de dispositivo/emulador funcional |
| APK release con firma del propietario | Preparado; sin claves suministradas, no generado |
| Congelar 1.0.0 estable | Pendiente de cerrar aceptación nativa; esta entrega es 1.0.0-rc.20 |
| Simular combates, dados, diales, daño y poderes de figuras | Fuera del alcance del proyecto |

## Dependencias y recompilación

Entorno usado: Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0; Android compile/target
36 y mínimo 24. JBR de Android Studio, AGP/Gradle y NDK registrados en el proyecto.
No se añaden dependencias para Priority. Las licencias empaquetadas se consultan sin
conexión en Acerca de → Licencias de dependencias.

```powershell
git switch codex/priority-seat-drag
$env:Path = "$env:USERPROFILE\develop\flutter\bin;$env:Path"
flutter --no-version-check pub get
dart format --output=none --set-exit-if-changed lib test tool
flutter --no-version-check analyze --no-pub
flutter --no-version-check test --no-pub --reporter expanded
flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded
./tool/build_apk.ps1 | Format-List
```

El script compila y valida el APK, comprueba su copia en `build/releases/` y elimina
los APK entregables anteriores de esa carpeta. **Solo queda el más reciente**.
Una compilación fallida o un APK inválido conserva los anteriores. Las salidas
técnicas actuales de Flutter/Gradle quedan en `build/app/`; no se usa `flutter clean`.
Para generar release: `./tool/build_apk.ps1 -Mode release`, con firma configurada.
Para validar/publicar un APK ya compilado: `./tool/build_apk.ps1 -SkipBuild`.
Compilar puede requerir internet para herramientas; la app instalada no lo necesita.
No tiene permiso INTERNET, por lo que el servicio VM/hot reload remoto no está
disponible: probar instalando el APK y abriéndolo normalmente.

Para release, crear y custodiar la keystore fuera del repositorio, con contraseñas
solicitadas de forma interactiva, y completar `android/key.properties` local.
Procedimiento en [ANDROID](docs/ANDROID.md). No se usa la clave debug como firma
release. Una firma nueva no puede actualizar el paquete debug existente; preparar
la conservación de datos antes de cambiar de canal. No hay contraseñas en Git.

## Mantener reglas y datos

Fuente primaria: [reglas oficiales de WizKids](https://wizkids.com/heroclix/gameplay/rules-format/),
consultada el 2026-11-17; sigue enlazando Comprehensive Rulebook **2026-07-01**.
La app implementa un subconjunto, sin actualización automática ni texto completo.
Herramienta de apoyo, no decisión oficial de torneo. Arte, mapas e iconos genéricos.

Para actualizar: verificar fuente/edición y secciones, registrar alcance y casos en
[REGLAS](docs/REGLAS.md) y sus matrices; modificar un único servicio de dominio;
añadir regresiones con expectativas explicadas; actualizar cobertura y versiones
de contexto/ejercicios; ejecutar contratos puros y toda la batería. Nunca dar por
aprobada una condición sin soporte. No recalificar silenciosamente intentos antiguos.

Escenarios exportan esquema 5 y leen 1/2/3/4/5; capas escriben 4 y leen 1/2/3/4. Entrenamiento exporta 3
y lee 1/2/3. Las migraciones conservan copia exacta del legado antes del primer
reemplazo y protegen el original si falla el respaldo. No cambian rutas privadas.
Antes de migrar, conservar proyecto, copia externa JSON y datos privados disponibles.

Para completar 1.0.0: ejecutar la [matriz de aceptación](docs/MATRIZ_ACEPTACION.md)
en Android, con radios desactivadas, reinstalación de actualización y restauración;
registrar modelo, API y rendimiento, corregir fallos y regenerar/verificar el APK.
Solo después cambiar versión y anunciar una entrega estable.
