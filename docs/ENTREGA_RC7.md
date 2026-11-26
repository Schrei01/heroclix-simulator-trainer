# Entrega rc.7 — aviso legible de arriba hacia abajo

2026-11-17 (America/Bogota). **1.0.0-rc.7+20**, candidata debug.
Rama `codex/upright-tool-hints`, sobre `24c66ca` (rc.6). Código: f99f8c3.
Informe anterior: [ENTREGA_RC6.md](ENTREGA_RC6.md).

## Corrección

La aclaración del usuario se aplica como columna lateral de texto derecho, leído
por líneas de arriba hacia abajo, sin rotación ni necesidad de girar el celular.
Las acciones se separan en bloques. El ancho se adapta entre 96 y 144 px y las
líneas visibles se limitan al alto disponible; semántica conserva el mensaje completo.

Mantiene posición derecha, cuatro segundos, renovación del aviso y paso de gestos.
No cambia cámara ni herramientas. Con altura extrema/texto ampliado puede abreviarse
visualmente. Sin cambios de reglas, documentos, dependencias ni permisos.

## Verificación ejecutada en esta corrección

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0, Windows.

| Comando | Resultado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | 155 archivos, 0 cambios |
| `flutter --no-version-check analyze --no-pub` | No issues found, 4,3 s |
| `flutter --no-version-check test --no-pub test/editor_brush_teams_test.dart --reporter expanded` | **12 aprobadas** |
| `flutter --no-version-check test --no-pub test/final_acceptance_test.dart --plain-name 'versión distribuida, perfil y pubspec coinciden' --reporter expanded` | **1 aprobada** |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **101 renders aprobados**, 48 s |
| `flutter --no-version-check build apk --debug --no-pub` | Correcto; Gradle 49,0 s |
| `aapt dump badging` / `dump permissions` | 1.0.0-rc.7/código 20, SDK 24/36; sin INTERNET ni almacenamiento amplio |
| `apksigner verify --verbose --print-certs` | Verifies; firma v2 válida, mismo certificado |

La prueba de ayuda comprueba ausencia de RotatedBox tanto en ancestros como dentro
del aviso, texto con ajuste en varias líneas, posición, duración/renovación y no
interceptar gestos ni cambiar cámara. Se repiten los demás casos afectados de equipos,
trazos y tamaños/escala. Las 485 pruebas completas corresponden a rc.6 y están en
ENTREGA_RC6.md; esta corrección ejecutó 13 casos y los renders completos.

Capturas en build/previews/upright-hints/: 101 renders con hit test fatal. Se revisa
visualmente texto derecho en vertical/horizontal y presentación compacta. Son
capturas Flutter, no Android. Logs en build/; metadatos del APK en
build/verification/upright-hints/, excluidos de Git.

## APK entregable

- `build/releases/heroclix-1.0.0-rc.7-debug.apk`, 158530269 bytes.
- SHA-256: `9A1F06ACFAFC29F3A060C2122D9E53F1DC8DC6FC41F2C61E7E950C2D32344A1E`.
- Copia archivada y salida estándar con el mismo hash; APK anteriores conservados.
- Paquete `com.valinor.heroclixtrainer`, 1.0.0-rc.7/código 20, SDK 24/36.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Firma debug conservada; instalar encima sin desinstalar para mantener biblioteca
  y progreso. NOTICES.Z comprobado; binarios y claves fuera de Git.

## Pendiente

Comprobar lectura del aviso en Android real, vertical/horizontal y texto ampliado.
Se mantiene la decisión previa de continuar sin teléfono. Instalación, TalkBack,
selectores, radios apagadas, ciclo de proceso y rendimiento siguen pendientes;
no se declara estable ni se genera release sin claves del propietario.

README/README_FINAL, arquitectura, decisiones, Android, matriz AC30 y hoja de ruta
actualizados. Rc.6 archivada en ENTREGA_RC6.md.
