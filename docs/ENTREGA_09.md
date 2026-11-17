# Entrega archivada — etapa 09

2026-11-16 (America/Bogota). App **0.10.0+11**.
Repositorio privado: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama `codex/prompt-09`, sobre 08 (`b184578`). Informe previo: [ENTREGA_08.md](ENTREGA_08.md).

## A. Operativo y preparado

- Herramienta Movimiento en Editor y en Simulador/Árbitro → Elegir análisis.
  Elegir figura y tocar casillas vecinas construye una ruta numerada; también
  permite añadir pasos por coordenada. Saltos no se rellenan automáticamente.
- Ruta válida, inválida o No evaluada, con costo, velocidad declarada disponible,
  restante, distancia directa separada, paso/casilla/regla y motivo preciso.
- Pasos en ocho direcciones; H sin costo adicional, B/muros, esquinas, ocupación,
  separación pendiente, entrada en adyacencia, alturas y transiciones verificadas.
  Cruzar altura puede ser un paso válido que obliga a terminar el movimiento.
- IM Elevación, Bloqueado, Personajes y Atravesar personajes tipadas en la ficha.
  Independientes de las mejoras de visión. Solo Personajes concede separación
  automática; no se suponen tiradas exitosas. Pasar no permite acabar ocupado.
- Bases reconocidas de 08 con orientación fija, ancla como referencia y todas sus
  partes comprobadas. Separación inicial desde toda la huella; los pasos y la
  parada durante el recorrido usan la referencia, según §24.2d.
- Búsqueda BFS de alternativas verificadas, costo ordenado y máximo tres rutas por
  distinto primer paso. No expande paradas obligatorias ni condiciones sin soporte.
  Si falla no afirma imposibilidad bajo poderes/maniobras fuera del perfil.
- Ensayo transitorio con origen y destino superpuestos. Cancelar o volver al
  inicio no mueve. Cerrar informe permite continuar en el tablero. Confirmar solo
  una ruta válida revalida el mundo y aplica un comando con Deshacer/Rehacer.
- Comparación antes/después de visión, distancia y alcance mediante los motores
  de 06–08 y un snapshot futuro independiente. La figura original permanece igual.
- Esquema 3, lectura 1/2/3, IM vacías al migrar y respaldos exactos previos de 1/2.
  No se guarda la ruta ni el ensayo. El arrastre del Editor sigue siendo libre
  para montar escenas, diferenciado del análisis reglamentario del Simulador.

La [matriz de movimiento](MATRIZ_MOVIMIENTO.md) distingue **SOPORTADAS / NO
SOPORTADAS**, fuentes y M01–M27. No se implementa un turno completo ni Entrenador.

## B. Archivos principales

- Dominio: `movement/movement.dart`, `movement_rules_service.dart`,
  `route_planner.dart`, `characters/movement_ability.dart`, CharacterDraft.
- Aplicación: `movement_analysis.dart`, integración en EditorController/BoardSession,
  ScenarioCodec/ScenarioDocument/ScenarioRepository y FileDocumentStore.
- Interfaz: `movement_controls.dart`, `movement_painter.dart`, BoardCanvas,
  EditorScreen, VisionScreen, HomeScreen, CharacterDialog y edición de alcance.
- Tests: movement_rules/state/migration/editor_test, contrato compartido
  `support/movement_contract.dart`; expectativas anteriores de esquema/herramienta
  actualizadas y pruebas anteriores conservadas.
- Herramientas: `verify_movement.dart`, `benchmark_movement.dart`, seis renders
  nuevos en preview_test. Pubspec 0.10.0+11 y documentación.

## C. Comandos y resultados reales

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0. Sin dependencias ni permisos nuevos.
Android minSdk 24, compile/target 36; configuración nativa conservada.

| Comando | Resultado final |
| --- | --- |
| `dart run tool/verify_vision.dart` | 25/25 contratos. |
| `dart run tool/verify_targets.dart` | 13/13 contratos. |
| `dart run tool/verify_advanced_vision.dart` | 16/16 contratos. |
| `dart run tool/verify_movement.dart` | 27/27 contratos. |
| `dart format --output=none --set-exit-if-changed lib test tool` | 107 archivos, 0 cambios; 1,20 s. |
| `flutter --no-version-check analyze --no-pub` | No issues found, 2,4 s. |
| `flutter --no-version-check test --no-pub --reporter expanded` | **321 aprobadas**, 127 s. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **50 renders aprobados**, 32 s; seis nuevos revisados visualmente. |
| `flutter --no-version-check build apk --debug --no-pub` | Correcto, Gradle 51,1 s. |
| `aapt dump badging` / `dump permissions` | 0.10.0/código 11, SDK 24/36; sin INTERNET ni almacenamiento amplio. |
| `apksigner verify --verbose --print-certs` | Verifies; firma v2 válida y mismo certificado. |

La suite conserva las 275 pruebas anteriores y añade 46: 27 de dominio, 6 de
estado, 5 de migración y 8 de interfaz. La migración usa archivos temporales reales
para comprobar schema2 y su exclusión del índice. Respaldo exacto antes de guardar,
protección ante fallo y conservación del envoltorio working también comprobados.
UI en 320×568, 800×360 y 320×320 con texto al 300 %, sin silenciar hit tests.
Los casos son sintéticos, derivados de los apartados oficiales de la matriz;
no se presentan como ejemplos gráficos oficiales publicados.

La primera suite completa falló por una expectativa antigua que exigía Movimiento
inhabilitado. Se actualizó para comprobar su disponibilidad. La primera prueba
UI al 300 % detectó un encabezado de registro más alto que el área visible: se
acotó su título, manteniendo el contenido completo al expandir. La revisión visual
corrigió fuente explícita del painter y separadores que la fuente de render no
representaba. Una regresión adicional verifica las dos reglas de referencia de
bases: separación desde toda la huella y pasos de su casilla elegida. También se
corrigió un fixture de benchmark que colocaba una figura sobre B. Esos fallos no
se omiten ni se presentan como resultados finales aprobados.

### Rendimiento medido

PC Windows 10 Home 10.0.19045 x64, Intel Core i5-7200U a 2,50 GHz, 4 procesadores
lógicos, 8 GB RAM. `dart run tool/benchmark_movement.dart`, Dart 3.14.0. Tableros
con 40 figuras aliadas, columna de B, pared larga y velocidad 99; cinco búsquedas
por tamaño en el mismo proceso JIT. Incluye revalidación de las alternativas.

| Medición | 20×20 | 40×40 |
| --- | --- | --- |
| Figuras / velocidad | 40 / 99 | 40 / 99 |
| Primera llamada | 81,428 ms | 68,456 ms |
| Mediana de cinco muestras | 31,567 ms | 68,456 ms |
| Máximo | 81,428 ms | 80,062 ms |
| Nodos inspeccionados | 1209 | 4575 |
| Costo de la alternativa más corta | 27 | 67 |

Es CPU del motor en PC, no FPS, latencia de UI ni medición Android. No mide el
peor caso de bases grandes o 1600 figuras. No se ejecuta con la suite Flutter en
paralelo para el resultado final.

Logs locales en `build/`: `movement-pure-09-final.log`, `vision-pure-09-final.log`,
`targets-pure-09-final.log`, `advanced-pure-09-final.log`, `format-09-check.log`,
`analyze-09-final.log`, `test-09-final.log`, `preview-09-final.log`, `build-09.log`,
`performance-09-final.log`, `signature-09.log`. Renders en `build/previews/prompt-09/`:
son Flutter, no capturas de Android. Se mantienen los renders de regresión previos.

### APK definitivo

- `build/releases/heroclix-prompt-09-debug.apk`, **158297285 bytes** (150,96 MiB).
- SHA-256: `8AD83A245C75C8FB6836DEFA944C9E32FBFCE440214C59299BBF407747AB08F1`.
- Paquete `com.valinor.heroclixtrainer`, versión 0.10.0, código 11.
- Certificado de desarrollo conservado; SHA-256 `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- La firma permite actualizar sobre entregas previas sin desinstalar. Esa
  instalación no se ha ejecutado en un dispositivo para 09. No hay validación release.
- APK, logs, renders y PDF fuera de Git; entregas binarias anteriores preservadas.

## D. Comprobar manualmente

1. Instalar el APK sobre la anterior, abrir un escenario 1/2 y verificar todos los
   datos antes/después de guardar. Exportar: esquema 3 con movementAbilities.
2. Crear figura normal A1, velocidad 3. Simulador → Movimiento reglamentario:
   elegir figura, cerrar informe y tocar B1, C1, D1. Tres pasos válidos y restante 0.
   Añadir D2 excede velocidad; quitar último paso restaura la ruta válida.
3. Cancelar ensayo conserva A1 e historial. Repetir y Confirmar desplaza a D1.
   Deshacer/Rehacer desde Editor restaura/aplica como una única operación.
4. Muros A1/B1 y A2/B2: A1/B1/C1 es inválida. Con velocidad 4, buscar C1 ofrece
   un rodeo legal de costo 4, superior a la distancia directa 2.
5. H en B1 no añade costo. B/muro bloquea salvo IM Bloqueado, que no permite
   terminar en B. Altura 2 en B1/C1: entrar B1 permite terminar, pero continuar C1
   exige transición A1/B1 o IM Elevación. Revisar regla/motivo de cada paso.
6. Enemigo D2: A1/B1/C1 puede terminar C1, pero no continuar D1. Enemigo adyacente
   al origen mantiene separación No evaluada sin IM Personajes. IM Atravesar sigue
   requiriendo separación inicial. Probar las capacidades de forma independiente.
7. Con destino enemigo D1 y muro B1/C1, ensayar A1/B2: comparación debe cambiar
   visión de bloqueada a despejada y distancia 3 a 2, sin desplazar la figura.
8. Probar base 2×2, límites, ocupación final, giro pendiente y tamaños especiales;
   leer distinción inválida/No evaluada. Girar y ampliar texto, abrir registro y
   confirmar/cancelar mediante controles desplazables.

## E. Limitaciones, supuestos y pendientes

- Figuras Normal, bases reconocidas, orientación y referencia fijas. §24.2d admite
  otras maniobras; el producto verifica un subconjunto conservador. Una parte que
  requiere otra referencia/giro queda No evaluada, no ilegalidad general.
- Separación con dado, tamaños especiales, vuelo, transporte, exterior, destrucción
  y efectos arbitrarios no se resuelven. Declarar otra capacidad/efecto conserva
  No evaluado. No se interpretan cartas ni se conceden mejoras por nombre o base.
- Velocidad declarada sin cálculo automático de modificadores. Ruta válida no
  valida una acción, ataque, turno ni dados/daño. Las comparaciones conservan los
  límites de visión/alcance de 08. Visible y en alcance no garantiza ataque legal.
- Hasta tres alternativas con distinto inicio; no es enumeración exhaustiva de
  todas las rutas. Ausencia de solución se acota a las reglas y presupuesto usados.
- `adb devices` no mostró dispositivos conectados. No se hizo recorrido Android,
  instalación física, FPS ni build release de 09. Las pruebas nativas anteriores
  corresponden exclusivamente a sus entregas archivadas.

## F. Documentación y fuentes

ROADMAP, DECISIONES, ESTADO, README, ARQUITECTURA, ESCENARIOS, ANDROID y REGLAS
actualizados. Nueva MATRIZ_MOVIMIENTO.md con reglas, contratos y soporte. 08
archivada en ENTREGA_08.md. Se conserva reglamento oficial 2026-07-01, revisado en
la página de WizKids el 2026-11-16, y el PDF de consulta local ya registrado.

## G. Límite de etapa

**No se inició Prompt 10.** Entrenador requiere una nueva orden del usuario.
