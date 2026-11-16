# Estado actual — etapa 08

2026-11-16 (America/Bogota). App **0.9.0+10**.
Repositorio privado: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama `codex/prompt-08`, sobre 07 (`d8cbff4`). Informe previo: [ENTREGA_07.md](ENTREGA_07.md).

## A. Operativo y preparado

- Alturas por casilla o región, niveles 1–40, bordes derivados y transiciones entre vecinos ortogonales de distinta altura. Cambiar altura conserva H/B; limpiar tipos de terreno conserva alturas y transiciones. Historial completo.
- Visión entre niveles iguales o distintos: borde, terreno, muros y figuras intermedias conforme al perfil verificado. Se conserva la geometría exacta y la menor restricción en vértices, incluida la regresión A1–D6/B4.
- Bases 1×1, 1×2/2×1, 2×2, 2×4/4×2 y 3×6/6×3, con ocupación completa y referencias automáticas/manuales. Objetivos compara distancia y visión desde el mismo par; hasta 324 pares para dos bases de 18 casillas.
- Cuatro IT independientes y persistentes en la ficha: Elevación, Obstaculizado, Bloqueado y Personajes. El registro explica componentes ignorados y restricciones aún activas.
- Laboratorio temporal identificado como HIPÓTESIS, sin alterar ficha ni JSON. Árbitro muestra par, perfil, capacidades y reglas por paso.
- Esquema 2: lee 1/2 y exporta 2. Conserva datos anteriores y copia exactamente el esquema 1 antes de reemplazarlo por primera vez. Fallar el respaldo impide sobrescribir. Abrir no modifica el original.
- Se conservan biblioteca, JSON/PNG, historial y modos anteriores. Caché acotada a 1024 pares por mundo/contexto; filtros/cámara no repiten visión. Movimiento y Entrenador siguen pendientes.

La [matriz de capacidades](MATRIZ_CAPACIDADES_VISION.md) distingue **SOPORTADAS / NO SOPORTADAS**, fuentes y contratos. Huella, tamaño y capacidades son datos independientes: una base grande no concede Great Size ni poderes.

## B. Archivos principales

- Dominio: `characters/vision_ability.dart`, `character.dart`, `terrain/terrain.dart`, `edge_wall.dart`, `rules/line_of_sight.dart`, `line_of_sight_service.dart`, `target_analysis_service.dart`.
- Aplicación: BoardSession, VisionAnalysis, TacticalAnalysis, ScenarioDocument, ScenarioCodec, LayerCodec y ScenarioRepository; FileDocumentStore para respaldos.
- Interfaz: ficha, nuevas `elevation_controls.dart`, informes de visión/árbitro, controles tácticos, EditorController, canvas y pintor.
- Pruebas: `advanced_vision_test.dart`, `advanced_state_test.dart`, `advanced_editor_test.dart`, `scenario_migration_test.dart`, contrato avanzado y fixture de esquema 1 generado por 07; regresiones actualizadas.
- Herramientas: `verify_advanced_vision.dart`, siete renders nuevos en preview_test. Pubspec 0.9.0+10 y documentación.

## C. Comandos y resultados reales

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0. Sin dependencias nuevas. Android minSdk 24, compile/target 36; configuración nativa conservada.

| Comando | Resultado final |
| --- | --- |
| `dart run tool/verify_vision.dart` | 25/25 contratos. |
| `dart run tool/verify_targets.dart` | 13/13 contratos. |
| `dart run tool/verify_advanced_vision.dart` | 16/16 contratos. |
| `dart format --output=none --set-exit-if-changed lib test tool` | 93 archivos, 0 cambios. |
| `flutter --no-version-check analyze --no-pub` | No issues found, 6,9 s. |
| `flutter --no-version-check test --no-pub --reporter expanded` | **275 aprobadas**, 122 s. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **44 renders aprobados**, 25 s. |
| `flutter --no-version-check build apk --debug --no-pub` | Correcto, Gradle 42,0 s. |
| `aapt dump badging` / `dump permissions` | 0.9.0/código 10, SDK 24/36; sin INTERNET ni almacenamiento amplio. |
| `apksigner verify --verbose --print-certs` | Verifies, firma v2 válida y certificado de desarrollo conservado. |

Se mantienen 238 pruebas anteriores y se añaden 37: 16 de dominio, 6 de estado, 6 de migración y 9 de interfaz. Migración probada con JSON real de 07 y archivos temporales del adaptador: respaldo una sola vez y protección del original ante fallos. UI en 320×568, 800×360 y 320×320 con texto al 300 %, manteniendo los errores de hit test. Siete renders nuevos revisados visualmente.

En ejecuciones intermedias se corrigieron selectores ambiguos, expectativas antiguas, acceso a controles de una barra virtualizada y helpers de prueba. Los renders detectaron un pie que mostraba el ancla en vez de la referencia elegida y números de transición sobre la línea: corregidos antes de repetir suite, renders y compilación. No quedan fallos en las ejecuciones finales.

### Rendimiento medido

PC Windows 10 Home 10.0.19045 x64, Intel Core i5-7200U a 2,50 GHz, 4 procesadores lógicos, 8 GB RAM. `dart run tool/benchmark_targets.dart --mixed`, Dart 3.14.0; figuras distribuidas, H/B y muros. 25 muestras sin caché en un proceso JIT y 100 cambios de filtro, sin suite Flutter simultánea.

| Medición | 20×20 / 40 figuras | 40×40 / 120 figuras |
| --- | --- | --- |
| Objetivos / casillas de terreno / muros | 39 / 40 / 40 | 119 / 80 / 80 |
| Primera llamada | 106,019 ms | 66,781 ms |
| Mediana | 11,223 ms | 55,583 ms |
| Percentil 95 / máximo | 51,369 / 67,228 ms | 75,038 / 80,863 ms |
| Cambio de filtro con caché, media | 0,00872 ms | 0,00928 ms |
| Cambio de alcance reutilizando visión | 0,814 ms | 1,297 ms |
| Llamadas de visión antes / después | 39 / 39 | 119 / 119 |

Es CPU del motor en PC, no FPS ni latencia Android. No mide el peor caso de 324 pares por objetivo.

Logs locales en `build/`: `vision-pure-08-final.log`, `targets-pure-08-final.log`, `advanced-pure-08-final.log`, `analyze-08-final.log`, `test-08-final.log`, `preview-08-final.log`, `build-08.log`, `performance-08.log`, `signature-08.log`. Renders en `build/previews/prompt-08/`: son Flutter, no capturas Android.

### APK definitivo

- `build/releases/heroclix-prompt-08-debug.apk`, **158249725 bytes** (150,92 MiB).
- SHA-256: `821F336B18C90F272992857486AB9795034094FFEE321A3B4665018354FE379B`.
- Paquete `com.valinor.heroclixtrainer`, versión 0.9.0, código 10.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Firma conservada: permite actualizar sobre entregas previas conservando datos. Esa instalación no se ejecutó en dispositivo para 08. No hay validación release.
- APK, logs, renders y PDF excluidos de Git; binarios anteriores preservados.

## D. Comprobar manualmente

1. Instalar sobre la versión anterior; abrir un escenario antiguo y guardarlo. Comprobar figuras/terreno y exportar JSON: esquema 2.
2. Editor → Alturas: aplicar nivel 2 a A1:B2 y añadir transición B1/C1. Cambiar altura, deshacer/rehacer; se conservan H/B y figuras.
3. Origen normal A1 elevado, destino D1 bajo: extender plataforma por B1 bloquea. Dar IT Elevación ignora altura. Añadir muro conserva bloqueo; IT Bloqueado ignora el muro. Revisar motivos en Árbitro.
4. Origen A1, destino de base 1×2 en B3/B4 y muro entre A2/B2: Visión automática elige B4. Objetivos con alcance 2 queda bloqueado; con 3 es visible. El informe distingue B3, a 2 pero bloqueado, y B4, a 3 despejado.
5. Activar laboratorio y probar capacidades: comprobar HIPÓTESIS. Ficha y JSON permanecen iguales; desactivar vuelve a las capacidades de ficha.
6. Declarar extremo Giant o IT Adyacente: No evaluado con motivo concreto. Un destino con IT no presta capacidades al origen.
7. Simulador/Árbitro → Elegir análisis: expandir registro; cambiar orientación y tamaño de texto. En Editor comprobar selección, borrado y deshacer.

## E. Limitaciones, supuestos y pendientes

- Extremos Normal y bases reconocidas a nivel uniforme. Tiny/Giant/Colossal como extremos, vuelo, bases mixtas y formatos no reconocidos no reciben aprobado. Los tamaños intermedios tienen solo el tratamiento de bloqueo de la matriz.
- IT Destruir bloqueado, IT Adyacente, poderes arbitrarios y condiciones no modeladas conservan No evaluado cuando afectan al perfil. No se editan transiciones al mismo nivel ni se interpreta texto de cartas.
- Distancia no es movimiento; visible y en alcance no garantiza ataque legal. Acciones, rutas, daño, turnos y Entrenador quedan fuera.
- Se conservan límites de versiones/ocupación incompatible y línea a sí mismo sobre H sin IT H. No evaluado no significa bloqueado.
- No se realizó recorrido nativo Android, prueba física, FPS ni build release de 08. Verificaciones nativas antiguas corresponden solo a sus entregas archivadas.

## F. Documentación y fuentes

Actualizados ROADMAP, DECISIONES, ESTADO, README, ARQUITECTURA, ANDROID, ESCENARIOS, REGLAS y matrices de visión/objetivos. Nueva matriz de capacidades; 07 archivada en ENTREGA_07.md.

Fuentes oficiales consultadas el 2026-11-16: reglamento 2026-07-01 y cuatro definiciones IT concordantes de la PAC 2023 enlazada por WizKids, detalladas en la matriz. Se conserva la edición declarada; no se transcribe el reglamento ni se incorpora el PDF a Git.

## G. Límite de etapa

**No se inició Prompt 09.** Movimiento requiere una nueva orden del usuario.
