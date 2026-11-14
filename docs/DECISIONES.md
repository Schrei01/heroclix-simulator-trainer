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
