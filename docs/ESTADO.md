# Estado actual — etapa 12 / candidata

2026-11-17 (America/Bogota). App **1.0.0-rc.1+14**, APK **debug**.
Repositorio privado: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama `codex/prompt-12`, sobre 11 (`e0312a4`). Informe previo: [ENTREGA_11.md](ENTREGA_11.md).
**No se congela 1.0.0 estable:** falta aceptación nativa y rendimiento Android.

## A. Operativo y verificado

- Se conservan los cuatro modos reales, la escena compartida del Editor/Simulador/
  Árbitro y el snapshot independiente del Entrenador. Nueva prueba abre/regresa
  por los cuatro botones sin mutar figuras. Tema y navegación existentes conservados.
- Inicio incorpora Guía rápida, Ejemplos locales y Acerca de. Ayuda breve en español
  distingue Editor/Simulador, H/B/muros, visión, alcance y No evaluado, con edición
  y advertencia de apoyo. Todo el contenido necesario es local.
- Catálogo de cinco escenas originales, derivadas de soluciones ya verificadas:
  visión H, diagonal/vértice A1–D6/B4, muro, elevación intermedia y rodeo de movimiento.
  Previsualización con controlador propio; Abrir copia usa ID nuevo y protección
  de cambios sin guardar. Cancelar conserva escena; biblioteca original permanece.
  Apertura deshabilitada mientras se recupera/guarda. No se siembran archivos al iniciar.
- Acerca de muestra versión/build, edición 2026-07-01, fuente, cobertura/limitaciones,
  aviso de herramienta independiente y licencias de dependencias empaquetadas.
  Identidad AppInfo contrastada con pubspec y el motor; sin plugin adicional.
- Integración corregida: puente Android admite TXT de diagnóstico, validando pares
  MIME/extensión JSON/PNG/TXT y límites 2/16/2 MiB. Detalles de escenario muestran
  esquema 3. Reutilizar caché táctica individual conserva su selección.
- Aceptación automatizada completa: crear 6×6, figuras/H, guardar/reabrir en disco,
  visión y alcance, movimiento confirmado, copiar escena a ejercicio, responder y
  comprobar en UI, releer progreso y hacer intercambio JSON/PNG real.
- Accesibilidad básica: objetivos táctiles, etiquetas y contraste del Inicio;
  estados de visión con texto/iconos y contraste ≥4,5:1 sobre las dos superficies.
  Guía/Acerca de verificadas en vertical/horizontal y 320×320 al 300 %. No es prueba TalkBack.
- Persistencia/esquemas compatibles de 00–11 intactos. Fallo de espacio inyectado
  como OSError 28 conserva documento anterior y permite reintentar. Se conserva
  edición reglamentaria y una implementación por regla. Sin dependencias/permisos nuevos.

## B. Archivos principales

- `lib/domain/app_info.dart`: identidad/versiones contrastadas.
- `lib/application/examples/local_examples.dart`: catálogo y copias desde banco.
- `lib/presentation/examples/examples_screen.dart`: catálogo, vista previa y apertura.
- `lib/presentation/help/info_screen.dart`: estructura adaptable, guía y Acerca de/licencias.
- HomeScreen, ScenarioActions y PositionAnalysisController: integración y correcciones.
- MainActivity.kt: whitelist TXT/MIME y límites; pubspec 1.0.0-rc.1+14; exclusiones Git.
- `test/final_acceptance_test.dart`: 19 pruebas nuevas de aceptación, ejemplos,
  almacenamiento, navegación, accesibilidad y licencia; regresión de caché ampliada.
- `tool/preview_test.dart`: siete renders nuevos, evidencia de etapa 12.
- README_FINAL, MATRIZ_ACEPTACION y documentación actualizada; entrega 11 archivada.

## C. Comandos y resultados reales

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0; Windows 10 Home 19045,
i5-7200U, 8 GB, cuatro procesadores lógicos. Android minSdk 24, compile/target 36.
Se conserva configuración nativa y certificado de desarrollo.

| Comando | Resultado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | **148 archivos, 0 cambios**, 1,43 s. |
| `flutter --no-version-check analyze --no-pub` | **No issues found**, 3,1 s. |
| `flutter --no-version-check test --no-pub --reporter expanded` | **438 aprobadas**, 155 s. |
| `flutter --no-version-check test --no-pub test/final_acceptance_test.dart test/tactics_state_test.dart --reporter expanded` | **27 aprobadas**, 11 s, antes de la batería completa final. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **73 renders aprobados**, 36 s. |
| `flutter --no-version-check build apk --debug --no-pub` | **Correcto**, Gradle 94,1 s. |
| `aapt dump badging` / `dump permissions` | Versión 1.0.0-rc.1, código 14, SDK 24/36; sin INTERNET/almacenamiento amplio. |
| `apksigner verify --verbose --print-certs` | **Verifies**, firma v2 válida y mismo certificado. |
| Inspección de licencias empaquetadas | `assets/flutter_assets/NOTICES.Z` descomprimido: avisos de material_ui, Flutter y Dart presentes; 1364985 caracteres. |
| `adb devices -l` / intento AVD | Sin teléfono; emulador configurado API 37 quedó offline. Sin instalación ni recorrido nativo. |

438 = 419 pruebas anteriores + 19 nuevas. No se desactivó ninguna. Se ejecutan
contratos de los motores previos, migraciones 1/2/3, archivos, gestos, cancelación,
casos sin soporte, mapas 2×2/40×40, muchas figuras, zoom/giro, accesibilidad y UI.
La prueba E2E usa controladores/archivos reales y UI de respuesta; no automatiza
cada formulario ni sustituye las pruebas instrumentales Android. La matriz enlaza
los casos y separa pendientes nativos. Ejemplo de exposición: después de mover
A1→A2, H en B1 solo toca un vértice y el lado libre permite visión despejada.

Se corrigieron durante preparación de tests: constructor/const/import iniciales,
el helper Atrás para material_ui y la gestión del entorno asíncrono de archivos
reales; se cerraron handles semánticos y avisos de estilo del analyzer. Los resultados
finales de arriba incluyen las correcciones. No hay fallos ejecutables pendientes.

73 renders = 66 anteriores + Inicio horizontal, Acerca de, Acerca de compacto al
200 %, Guía, Catálogo, Vista previa de ejemplo y Licencias. Nuevas capturas revisadas
visualmente en `build/previews/prompt-12/`. Renders Flutter/Windows, no capturas Android.
E2E produce `build/verification/prompt-12/aceptacion.json` y `aceptacion.png`, PNG
escrito/releído/decodificado. Logs, imágenes y APK fuera de Git; entregas anteriores
preservadas. No se redistribuye el PDF oficial.

### Intento de entorno Android y rendimiento

AVD Medium_Phone_API_37.0 disponible, Google APIs Play Store x86_64/API 37, WHPX
instalado y utilizable. Se intentó arranque sin ventana/audio/snapshot, dos núcleos,
1536 MiB solicitados y GPU swiftshader. ADB quedó offline varios minutos; QEMU
alcanzó unos 2,88 GB residentes y se detuvo para no bloquear el resto del trabajo,
sin borrar datos ni cambiar el AVD. Logs emulator.out/err.log en verificación de 12.
No se obtuvo un dispositivo Android operativo ni se ejecutó allí la aplicación.
El usuario indicó **continuar sin teléfono**. No hay medidas FPS, tiempos de
arranque/análisis ni perfil de memoria de la app Android. La RAM anterior es del
intento del emulador, no del producto. Las mediciones CPU de 11 son históricas y
no se presentan como rendimiento Android de esta entrega.

### APK verificado

- Ruta: `build/releases/heroclix-1.0.0-rc.1-debug.apk`.
- Tamaño: **158512913 bytes** (151,17 MiB).
- SHA-256: `82636C72923BD14981A44515D5EC51375603EE2D57CAD4FF290995A016755D49`.
- Copia archivada y salida estándar tienen idéntico hash.
- Paquete `com.valinor.heroclixtrainer`, versión 1.0.0-rc.1, código 14.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Firma debug conservada, adecuada para actualizar encima de entregas anteriores;
  no se ejecutó esa instalación para 12. Sin keystore release suministrada, no
  se generó release ni se sustituyó su firma por debug.

## D. Comprobar en Android e instalar

1. Android 7/API 24 o superior. Copiar el APK, abrirlo en Archivos y autorizar ese
   origen cuando Android lo solicite; instalar encima, sin desinstalar. Alternativa:
   `adb -s ID install -r build/releases/heroclix-1.0.0-rc.1-debug.apk`.
2. Abrir los cuatro modos, comprobar biblioteca/progreso anteriores. Desactivar
   Wi-Fi/datos y ejecutar AC01–AC20 de MATRIZ_ACEPTACION usando almacenamiento local.
3. Inicio → Ejemplos locales → Ver ejemplo → Abrir copia: conservar original y
   advertir cambios sin guardar. Guía rápida y Acerca de/licencias deben funcionar offline.
4. Crear/guardar/reabrir escena, visión/alcance, movimiento confirmado y Deshacer;
   crear/resolver ejercicio y comprobar progreso. Exportar/importar JSON y PNG;
   exportar también resumen TXT desde Analizar posición.
5. Esperar autoguardado, forzar cierre y reabrir; comprobar restauración. Girar,
   ampliar texto al 300 %, TalkBack, mapas 2×2/40×40 y muchas figuras. Registrar
   modelo/API y métricas/problemas de rendimiento antes de promover estable.

Estos pasos nativos **no están ejecutados**. Guía completa de instalación,
recompilación y actualización de reglas: [README_FINAL](../README_FINAL.md).

## E. Características y pendientes

| Característica | Implementado/verificado | Pendiente |
| --- | --- | --- |
| Editor, Simulador, Entrenador y Árbitro | Navegación real, datos/motores compartidos y snapshots de práctica | Recorrido nativo |
| Biblioteca, autoguardado, JSON/PNG y formatos compatibles | Archivos reales, migraciones y recuperación entre controladores | Cierre forzado y selectores Android |
| Visión, alcance, alturas, mejoras y movimiento | Perfil parcial versionado y referencias; No evaluados explícitos | Reglas/poderes fuera de matrices |
| Tácticas, hipótesis y ejercicios desde análisis | Comparaciones, rutas, persistencia y UI verificadas | Rendimiento Android |
| Guía, cinco ejemplos y Acerca de/licencias | Locales, copias protegidas, versión/cobertura visibles | TalkBack/lectura nativa |
| Offline | Sin INTERNET ni clientes de red en runtime; contenido local empaquetado | Radios apagadas en Android |
| Diagnóstico TXT/PNG | Integración y privacidad probadas; puente TXT compilado | Selector nativo TXT |
| APK | Debug candidato generado, firma/permisos/hash comprobados | Instalación; release del propietario |
| Versión estable 1.0.0 | No congelada | Cerrar aceptación nativa de la matriz |
| Partida completa | Fuera de alcance | Dados, diales, daño, turnos y victoria no implementados |

Se conservan los límites de 06–11: velocidades/alcances declarados, traslación sin
giro, tamaños/capacidades soportados y separación sin dados. El analizador limita
12 destinos/página y 32 enemigos por posición; omitidos son No evaluados, sin ranking
categórico de parciales. Personales máximo 50/2 MiB y sin exportación del banco.
No hay cuentas, backend, IA externa ni telemetría. Una clave release distinta no
actualiza debug directamente; planificar conservación de datos antes de cambiar firma.

## F. Documentación y control de versiones

README_FINAL y MATRIZ_ACEPTACION nuevos; README, ROADMAP, DECISIONES, ARQUITECTURA,
ANDROID, ESCENARIOS, REGLAS y ESTADO actualizados. Informe anterior en ENTREGA_11.
Fuente oficial consultada 2026-11-17, misma edición 2026-07-01; no se añade regla.
Exclusiones cubren APK/AAB, claves/keystores, configuración local y evidencias.
Implementación y documentación en commits separados de `codex/prompt-12`.

## G. Límite de entrega

Etapas 00–12 implementadas dentro del perfil documentado. **Entrega candidata,
sin congelar 1.0.0 estable**, con pendientes nativos enumerados. No se implementan
funciones de partida completa ni se da por ejecutada una prueba de dispositivo.
