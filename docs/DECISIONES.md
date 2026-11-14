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
