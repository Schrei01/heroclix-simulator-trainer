# HeroClix Simulator & Trainer — 1.0.0-rc.1+14

Aplicación Android offline, en español, para construir escenarios, consultar reglas
implementadas y practicar. **Versión candidata, APK debug**: faltan las comprobaciones
nativas de aceptación y rendimiento descritas abajo. No se congela 1.0.0 estable.
Repositorio privado: [Schrei01/heroclix-simulator-trainer](https://github.com/Schrei01/heroclix-simulator-trainer),
rama `codex/prompt-12`. Evidencia exacta y SHA-256 en [ESTADO](docs/ESTADO.md).

## Instalar y actualizar

El archivo generado se conserva en:

```text
build/releases/heroclix-1.0.0-rc.1-debug.apk
```

1. Android 7.0/API 24 o superior. Copiar el APK al teléfono, abrirlo en Archivos
   y autorizar la instalación desde esa aplicación cuando Android lo solicite.
2. Para actualizar una versión anterior con esta misma firma, instalar encima,
   **sin desinstalar**. Se conservan archivos privados, escenarios y progreso.
   Cambiar firma o applicationId impide esa actualización directa.
3. Alternativa con depuración USB autorizada y Android Platform Tools:

```powershell
adb devices -l
adb -s ID install -r build/releases/heroclix-1.0.0-rc.1-debug.apk
adb -s ID shell am start -n com.valinor.heroclixtrainer/com.valinor.heroclix_simulator_trainer.MainActivity
```

La firma debug coincide con 00–11; instalación de esta candidata todavía no
verificada en Android. Antes de desinstalar, exportar escenas como JSON. La
desinstalación elimina progreso y ejercicios personales; su exportación todavía
no está implementada. PNG sirve para compartir una imagen, no para recuperar datos.

## Uso básico

| Entrada | Para qué sirve |
| --- | --- |
| Editor | Crear tablero 2–40 filas/columnas, figuras genéricas, equipos, terreno, muros y alturas; biblioteca y Deshacer |
| Simulador | Medir, consultar visión/objetivos, ensayar rutas y comparar posiciones de la misma escena |
| Entrenador | 24 ejercicios curados más personales; responder, comprobar, recibir explicación y conservar progreso |
| Árbitro | Consultar el dictamen y sus motivos/referencias; no reemplaza una decisión oficial |
| Ejemplos locales | Visión H, diagonal/vértice, muro, elevación y movimiento; previsualizar y abrir copia independiente |
| Guía rápida / Acerca de | Ayuda breve, versión, cobertura, fuente y licencias locales |

Un dedo usa la herramienta; dos dedos navegan. En mapas grandes amplía antes de
tocar. En horizontal las herramientas se desplazan para conservar el tablero.
El Editor monta escenas con arrastre libre; el Simulador valida el movimiento.
Ensayar no cambia posiciones hasta confirmar una ruta verificada.

H permite visión obstaculizada; B/muros pueden bloquear. «No evaluado» indica una
condición sin soporte o datos insuficientes, nunca permiso ni error automático.
Visión y alcance declarados no prueban que un ataque sea legal. El analizador
segmenta a 12 destinos/página y 32 enemigos: el resto permanece No evaluado.

Todo el contenido necesario está instalado: no requiere login, servidor o red.
Para usar archivos offline, elegir almacenamiento local en el selector Android;
proveedores externos del sistema pueden requerir conexión. El diagnóstico TXT/PNG
usa etiquetas genéricas. Exportar la escena completa sí conserva sus nombres.

## Implementado y pendiente

| Función | Estado |
| --- | --- |
| Cuatro modos, biblioteca, JSON/PNG y recuperación de sesión | Implementado y cubierto por pruebas Flutter/archivos en Windows |
| Geometría, visión, alcance, alturas, mejoras tipadas y movimiento | Perfil parcial implementado, con reglas y No evaluados explícitos |
| Análisis de posiciones, hipótesis, ejercicios y diagnóstico TXT/PNG | Implementado; puente Android TXT corregido y compilado |
| Catálogo de cinco ejemplos, guía y Acerca de/licencias | Implementado y probado; recursos locales |
| Accesibilidad básica y adaptación vertical/horizontal | Pruebas de widgets, objetivos táctiles/etiquetas y contraste; falta TalkBack real |
| Instalación, cierre forzado/restauración y selectores nativos | Pendiente de Android; equivalentes de archivos/controladores sí verificados |
| Offline con radios desactivadas y rendimiento Android/FPS | Pendiente de dispositivo/emulador funcional |
| APK release con firma del propietario | Preparado; sin claves suministradas, no generado |
| Congelar 1.0.0 estable | Pendiente de cerrar aceptación nativa; esta entrega es 1.0.0-rc.1 |
| Partida completa, dados, diales, daño y victoria | Fuera del alcance del proyecto |

## Dependencias y recompilación

Entorno usado: Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0; Android compile/target
36 y mínimo 24. JBR de Android Studio, AGP/Gradle y NDK registrados en el proyecto.
No se añaden dependencias para 12. Las licencias empaquetadas se consultan sin
conexión en Acerca de → Licencias de dependencias.

```powershell
git switch codex/prompt-12
$env:Path = "$env:USERPROFILE\develop\flutter\bin;$env:Path"
flutter --no-version-check pub get
dart format --output=none --set-exit-if-changed lib test tool
flutter --no-version-check analyze --no-pub
flutter --no-version-check test --no-pub --reporter expanded
flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded
flutter --no-version-check build apk --debug --no-pub
```

El build escribe `build/app/outputs/flutter-apk/app-debug.apk`; copiarlo al nombre
de entrega después de comprobar versión/firma/hash. No ejecutar `flutter clean`
si se necesitan conservar los APK/evidencias ignorados de entregas anteriores.
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

Escenarios exportan esquema 3 y leen 1/2/3; capas siguen 2. Entrenamiento exporta 3
y lee 1/2/3. Las migraciones conservan copia exacta del legado antes del primer
reemplazo y protegen el original si falla el respaldo. No cambian rutas privadas.
Antes de migrar, conservar proyecto, copia externa JSON y datos privados disponibles.

Para completar 1.0.0: ejecutar la [matriz de aceptación](docs/MATRIZ_ACEPTACION.md)
en Android, con radios desactivadas, reinstalación de actualización y restauración;
registrar modelo, API y rendimiento, corregir fallos y regenerar/verificar el APK.
Solo después cambiar versión y anunciar una entrega estable.
