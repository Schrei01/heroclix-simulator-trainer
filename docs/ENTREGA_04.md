# Entrega archivada — etapa 04

2026-11-14 (America/Bogota). App **0.5.0+5**.
Repositorio: https://github.com/Schrei01/heroclix-simulator-trainer.
Rama: `codex/prompt-04`, sobre etapa 03 (`551be78`).
Informes archivados: [00](ENTREGA_00.md), [01](ENTREGA_01.md),
[02](ENTREGA_02.md), [03](ENTREGA_03.md).

**04 implementada: análisis limpio, 139 pruebas, 16 renders, APK firmado y
recorrido Android offline verificados. Pendiente revisión del usuario.**

## A. Operativo y preparado

- Biblioteca local con nuevo, guardar, guardar como, abrir, renombrar, duplicar,
  eliminar con confirmación y ordenar por nombre/última edición. Nombres repetidos
  distinguidos por ID; límite de 200 escenarios.
- Documento completo de esquema 1: dimensiones, figuras/equipos, terreno, muros,
  identidad, nombre, referencia reglamentaria y fechas. JSON legible determinista,
  importación estricta de hasta 2 MiB con nueva identidad.
- Autoguardado de sesión actual, recuperación tras reiniciar, indicador/reintento,
  cola de escritura y aviso antes de sustituir cambios fuera de biblioteca.
  Fallos de I/O conservan el tablero; versiones futuras fallan sin sobrescribirlas.
- Deshacer/rehacer de 100 operaciones lógicas: figuras, equipos, dimensiones,
  terreno, muros y limpiezas. Un trazo confirmado es una operación. Cargar/nuevo/
  importar/guardar como vacía historial; cámara/selección quedan fuera.
- PNG completo sin controles, coordenadas/leyenda opcionales, máximo 2048/4096 px
  por eje; exportar JSON/PNG y compartir con mecanismos nativos Android sin servidor.
- Estructura futura: referencia reglamentaria y elevación como datos. No se emiten
  diagnósticos ni se implementa geometría de visión, movimiento o ataques.

## B. Archivos principales

- `lib/application/scenarios/`: ScenarioDocument, ScenarioCodec, ScenarioRepository.
- `lib/application/board/board_edit.dart`, `board_session.dart`: historial/restauración.
- `lib/application/ports/local_document_store.dart`, `scenario_files.dart`.
- `lib/infrastructure/local/`: FileDocumentStore y AndroidScenarioFiles.
- `lib/presentation/scenarios/`: workspace, biblioteca, formularios, acciones y PNG.
- EditorController, EditorScreen, main/app/home; MainActivity.kt, manifest y
  `android/app/src/main/res/xml/export_paths.xml`.
- Cinco suites `test/scenario_*_test.dart`, fakes de test y `tool/preview_test.dart`.
- README, ARQUITECTURA, ANDROID, ROADMAP, DECISIONES, ESCENARIOS y este informe.

## C. Comandos y resultados reales

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0. Sin dependencias Dart nuevas.
Android minSdk 24, compile/target 36, NDK 28.2.13676358, AGP 9.3.1,
Gradle 9.5.0, Kotlin 2.4.20 y Android Studio JBR 25.

| Comando | Resultado |
| --- | --- |
| `dart format lib test tool` | Formato correcto |
| `flutter --no-version-check analyze` | **No issues found**, 4,4 s |
| `flutter --no-version-check test --no-pub --reporter expanded` | **139 aprobadas**, 66 s |
| `flutter --no-version-check test tool/preview_test.dart --no-pub` | **16 renders aprobados**, 12 s; revisados visualmente |
| `flutter --no-version-check build apk --debug` | **Correcto**, build final 25,0 s |
| `aapt dump badging` / `dump permissions` | 0.5.0/código 5, SDK 24/36, sin INTERNET ni permisos amplios de almacenamiento |
| `apksigner verify --verbose` | **Verifies**, firma debug APK v2 válida |
| `adb install -r --no-incremental` | **Success**, APK definitivo instalado en Android 17/API 37 |
| Recorrido nativo sin conexión | Reinicio, biblioteca, JSON ida/vuelta, PNG, compartir, historial y aviso verificados |

Las 33 pruebas añadidas son 4 de codec, 2 de historial, 12 de almacenamiento,
3 de PNG y 12 de UI; se mantienen las 106 anteriores. Incluyen roundtrip completo,
ID/campos/versiones/coordenadas inválidos, tamaño/profundidad JSON, biblioteca con
nombres iguales y ordenación, fallo de escritura/lectura, carrera entre guardar y
editar, recuperación desconocida archivada, copia de biblioteca perdida, límites
40×40 con 1600 figuras/3120 muros/1600 terrenos y PNG real 4×4 y 40×40 a 2K/4K.
Pruebas de UI a 320×568, 800×360 y 320×320 con texto al 300 %, además de regresiones.

Durante la verificación se corrigieron una devolución de Future desde setState
al refrescar biblioteca y una espera de PNG que mezclaba reloj falso y callback
real. El estado ocupado usa un indicador estático mientras espera el selector.
Los resultados anteriores corresponden a las ejecuciones corregidas.

Logs locales: `build/test-04-final.log`, `analyze-04-final.log`, `preview-04-final.log`,
`build-04-final.log`; renders Flutter en `build/previews/prompt-04/` y PNG reales
exportados por tests en `build/verification/prompt-04/`. No son capturas de Android.

### APK definitivo

- Local: `build/releases/heroclix-prompt-04-debug.apk`.
- Salida estándar: `build/app/outputs/flutter-apk/app-debug.apk`.
- Tamaño: **158101709 bytes (150,78 MiB)**.
- SHA-256: `4493D18F0814520826E1FD2C62E0463AC0C23940F0DF8F21239AD6E1CCA78F5A`.
- APK/evidencias excluidos de Git; se conservan entregas anteriores.

### Recorrido Android ejecutado

AVD Medium_Phone_API_37.0, Android 17/API 37, 540×1200, instancia temporal
sin ventana, sin snapshots y read-only. Modo avión **1**, Wi-Fi **0**, confirmados
antes y después. Se instaló el APK definitivo, sin usar hot reload.

- Crear figura A/T1 en A1 y Guardar como Entrenamiento04. Aplicar obstaculizado
  a A2–D2 por Coordenadas. Esperar autoguardado, detener proceso y reabrir:
  comparación del documento completo antes/después **idéntica**, figura y terreno
  visibles; historial reiniciado.
- Guardar biblioteca, exportar JSON a Descargas con CREATE_DOCUMENT e importar
  ese archivo con OPEN_DOCUMENT. Se verificó **ID nuevo** e igualdad de dimensiones,
  equipos, figuras, terreno, muros y contadores. Biblioteca muestra dos filas del
  mismo nombre con IDs diferentes.
- Exportar PNG con coordenadas/leyenda mediante selector de destino; extraer y
  revisar la imagen real: figura y cuatro terrenos, sin controles de la app.
- Compartir JSON abre selector nativo con nombre del archivo y destinos. Se
  canceló sin enviar a personas o servicios; no se afirma entrega a destinatario.
- Pintar A3: **5 terrenos → Deshacer: 4 → Rehacer: 5**, verificando escritura
  terminada y capturas. En una lectura anterior inmediata se obtuvo el archivo
  previo a completarse la cola; se repitió esperando al indicador de autoguardado.
- Nuevo escenario con cambios: aviso de cambios fuera de biblioteca; Cancelar
  conserva el mapa. El emulador se cerró al terminar.

Evidencias locales en `build/verification/prompt-04/`: `recuperado_editor.png`,
`export_android.json`, `import_android.json`, `export_android.png`,
`biblioteca_nombres_iguales.png`, `compartir_nativo.png`, `deshacer.png`,
`rehacer.png`, `aviso_cambios.png`, documentos de recuperación y `app_android.log`.
Estas capturas sí proceden de Android. La primera captura denominada recuperado
todavía mostraba Inicio durante la transición; la válida del editor es la indicada.

El arranque frío tardó **182 s**. System UI mostró aviso de lentitud; se atendió
Wait. UI Automator produjo lecturas sin raíz que se descartaron y repitieron;
no se usó XML obsoleto. Se detuvieron servicios de fondo solo en el guest temporal.
No es una medición de rendimiento en teléfono físico.

El log limitado al PID de la app no contiene FATAL EXCEPTION, Unhandled Exception,
RenderFlex ni E/flutter. Registra el servicio HTTP de Dart VM debug que no pudo
abrir 127.0.0.1 por ausencia deliberada de INTERNET; edición y archivos funcionan.
Las validaciones corruptas, límites, fallos de disco, 40×40 y los otros comandos
de biblioteca se comprobaron mediante dominio/almacenamiento/widgets; no se
presentan como casos repetidos en el emulador.

## D. Comprobar manualmente

1. Instalar APK y abrir Editor sin conexión. Crear figuras, terreno y muro.
2. Menú → Guardar como, introducir nombre y referencia. Carpeta → comprobar fila.
   Duplicar con el mismo nombre; deben existir dos identidades independientes.
3. Editar/mover/pintar, deshacer y rehacer. Cambiar dimensiones; deshacer revierte
   contenido. Editar después de deshacer descarta la rama de rehacer.
4. Esperar indicador de autoguardado al día, forzar cierre y reabrir. Mundo y nombre
   deben recuperarse; historial queda vacío. Girar/zoom no altera lo guardado.
5. Exportar JSON al destino elegido, nuevo escenario, importar ese JSON. Comprobar
   equivalencia lógica e ID nuevo. Archivo corrupto debe mostrar error y retener mapa.
6. Exportar PNG 4×4 y mapa grande con/sin coordenadas y leyenda. Abrir la imagen:
   tablero completo sin controles. Probar alta resolución y cancelar selector.
7. Compartir JSON/PNG: debe abrir selector nativo. Cancelar no pierde el tablero.
8. Renombrar, ordenar, eliminar primero cancelando y luego confirmando. Si se
   elimina el activo, sigue como borrador. Nuevo/abrir con cambios muestra aviso.

## E. Limitaciones, supuestos y pendientes

- Solo Android y almacenamiento privado local; desinstalar elimina biblioteca.
  Exportar JSON es la copia externa. Sin sincronización, backend ni cuenta.
- Autoguardado asíncrono: una muerte inmediata antes de confirmarse puede perder
  ediciones pendientes. No se promete resistencia absoluta ante fallo físico/disco.
- Esquema 1 cerrado, sin migraciones previas; futuro/desconocido falla de forma
  controlada. Recuperación dañada se conserva/archiva antes de reemplazarla.
- Historial máximo 100, no persistido; borrar biblioteca no tiene deshacer.
  Se retienen estructuras inmutables por comando, no un snapshot por píxel.
- Cámara/selección/preferencias de vista no se guardan. Contadores no se reciclan.
- Límites: 200 escenarios, 32 equipos, 2 MiB JSON; PNG máximo 4096 px por eje
  y 16 MiB comprimido en puente nativo. 4K puede requerir 64 MiB crudos adicionales.
- Sin motor reglamentario; referencia de reglas no implica implementación.
  No se permite solapar figuras; estudio sobre bloqueado conserva advertencia !.
- No se probó teléfono físico ni APK release firmado con clave del usuario.

## F. Documentación

ROADMAP, DECISIONES y ESTADO actualizados. README explica biblioteca/intercambio,
ANDROID recorrido vigente, ARQUITECTURA separación de responsabilidades y
ESCENARIOS campos, límites, recuperación e historial. Entrega 03 archivada.

## G. Límite de etapa

**No se inició Prompt 05.** Requiere nueva orden tras revisar esta entrega.
