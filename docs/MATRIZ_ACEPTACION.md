# Aceptación final — 1.0.0-rc.1

Fecha: 2026-11-17. La ejecución automatizada es Flutter/Dart en Windows y archivos
locales reales o fallos inyectados explícitos. No equivale a un recorrido en Android.
Resultados completos y APK: ESTADO.md. No se declaran aprobados pasos nativos sin ejecutar.

| ID | Recorrido / condición | Evidencia automatizada | Android |
| --- | --- | --- | --- |
| AC01 | Inicio → Editor, Simulador, Árbitro y Entrenador; regresar conserva escena | final_acceptance_test: abre los cuatro modos con botón Atrás real | Pendiente |
| AC02 | Crear tablero, poner figuras y H, guardar y reabrir biblioteca | E2E crea 6×6 con A/B; FileDocumentStore real, nueva instancia y mismo ID | Pendiente |
| AC03 | Dictamen de visión con estado, motivo y referencias | E2E confirma H A1–D1; contratos de visión/capacidades y versiones sin soporte | Pendiente |
| AC04 | Medir y comparar alcance | E2E distancia 3, alcance declarado 4 y visión H desde par coherente | Pendiente |
| AC05 | Ensayar, confirmar y deshacer movimiento | E2E mueve A1→A2; movement_state/editor y tactics_state cubren confirmar/Deshacer/cancelar | Pendiente |
| AC06 | Convertir escena guardada en ejercicio y resolver | E2E copia snapshot personal, UI responde/comprueba, guarda un acierto y lo relee de disco | Pendiente |
| AC07 | Exportar y reimportar JSON | E2E escribe/lee archivo, decodifica e importa con identidad nueva; coordenadas conservadas | Selector pendiente |
| AC08 | Exportar PNG e intercambiar imagen | E2E renderiza, escribe, relee y decodifica PNG; dimensiones verificadas | Selector/Compartir pendientes |
| AC09 | Cerrar y restaurar datos | E2E destruye/recrea controladores y repositorios; escena, ejercicio y progreso conservados | Cierre forzado pendiente |
| AC10 | Escenarios 1/2, entrenamiento 1/2 y datos nuevos 3 | scenario_migration, movement_migration, training_codec y tactics_training: respaldo exacto y compatibilidad | Actualización pendiente |
| AC11 | Almacenamiento insuficiente | final_acceptance inyecta OSError 28: documento anterior intacto, mensaje de espacio y reintento | Disco lleno real no ejecutado |
| AC12 | JSON inválido/desconocido y fallo de proveedor | scenario_editor/codec/storage: no sustituye escena; error y recuperación | Proveedor nativo pendiente |
| AC13 | Bordes 2×2/40×40, figuras, zoom, giro | board/editor/characters, PNG 40×40, tácticas sin enemigos y con 35; gestos, límites y rotación de viewport | Rendimiento/tacto pendientes |
| AC14 | Vertical/horizontal y texto ampliado | Suite existente más guía/Acerca de a 360×800, 800×360 y 320×320 al 300 % | Orientación real pendiente |
| AC15 | Accesibilidad básica | androidTapTarget/labeledTapTarget/textContrast del inicio; cuatro estados con texto/icono y contraste ≥4,5:1 en ambas superficies | TalkBack pendiente |
| AC16 | Cinco ejemplos locales | Codec, identidad de copia y solución verificada; cancelar preserva escena y abrir copia conserva biblioteca anterior | Pendiente |
| AC17 | Acerca de y licencias | Versión contrastada con pubspec, fuente/cobertura/aviso; LicensePage real y recursos empaquetados | Lectura nativa pendiente |
| AC18 | Diagnóstico TXT/PNG sin nombres/metadatos | tactics_export/editor: resumen controlado, PNG decodificado; native TXT/MIME corregidos y compilados | Guardar TXT/PNG pendiente |
| AC19 | Funcionamiento sin internet | Sin INTERNET ni APIs de red en runtime; ejemplos, banco y licencias locales | Radios desactivadas pendiente |
| AC20 | APK verificable | Build debug, versión/código, permisos, firma y hash en ESTADO | Instalación pendiente |

El test E2E es `test/final_acceptance_test.dart`, caso «aceptación: crear, guardar,
reabrir, visión, alcance, mover, ejercicio, resolver, JSON y PNG». Invoca creación
y persistencia mediante controladores reales y responde en la UI del ejercicio;
no automatiza todos los formularios táctiles. Los formularios/gestos se cubren en
los tests de Editor, escenario, movimiento y Entrenador. No se presenta como una
prueba instrumental Android. JSON/PNG de evidencia en `build/verification/prompt-12/`.

## Intento nativo y bloqueo de estable

No había teléfono conectado. AVD disponible: Medium_Phone_API_37.0, imagen Google
APIs Play Store x86_64/API 37. WHPX instalado y utilizable en Windows 10 19045,
i5-7200U/8 GB. Arranque sin ventana/snapshot/audio, dos núcleos y 1536 MiB solicitados,
GPU swiftshader. ADB se mantuvo offline durante varios minutos; proceso QEMU llegó
a unos 2,88 GB de memoria residente. Se detuvo solo ese emulador, sin borrar datos
ni modificar configuración. Logs de arranque en build/verification/prompt-12/.
Esto es un fallo del intento de entorno, no una medición del rendimiento de la app.

El usuario indicó continuar sin teléfono. No se ejecutaron instalación, radios
desactivadas, cierre forzado, selectores, TalkBack ni FPS/tiempos en Android.
La versión continúa candidata; **no se congela v1.0.0 estable**. Release tampoco
se genera porque no se proporcionó configuración de firma.

## Procedimiento para cerrar aceptación nativa

1. Instalar encima de 11 con `adb install -r`, anotar fabricante/modelo y Android/API.
2. Desactivar Wi-Fi/datos. Ejecutar AC01–AC09 desde los controles de la app y usar
   almacenamiento del dispositivo para JSON/PNG/TXT. Comparar los datos después.
3. Esperar autoguardado, forzar cierre del paquete y abrir de nuevo. Verificar
   biblioteca, escenas, ejercicio personal y progreso; no borrar datos para probar.
4. Repetir escenas pequeñas/grandes, muchas figuras y bases, pinza y zoom extremos,
   orientación y texto al 300 %. Activar TalkBack y comprobar etiquetas/orden.
5. Medir arranque, navegación y análisis 40×40; registrar latencia, frames/problemas
   y carga. Usar un perfil adecuado para rendimiento; debug no demuestra FPS release.
6. Corregir fallos, ejecutar regresiones, regenerar APK y comprobar firma/hash.
   Solo con los criterios cerrados se puede promover a 1.0.0.
