# Estado actual — TeamFight: GridLab

2026-11-17 (America/Bogota). **1.0.0-rc.8+21**, candidata debug.
Rama `codex/teamfight-gridlab-brand`, sobre `370d10e` (rc.7). Código: `ac6d1d3`.
Informe anterior: [ENTREGA_RC7.md](ENTREGA_RC7.md).

## Identidad aplicada

- Nombre visible **TeamFight: GridLab** en Android, título Flutter, Inicio,
  Acerca de y licencias. AppInfo.name centraliza el nombre de la interfaz.
- Iconos originales del ZIP aportado: 25 PNG de Android en cinco densidades y dos
  XML adaptables (normal/redondo) con fondo, primer plano y capa monocromática.
  Manifest usa @mipmap/ic_launcher y @mipmap/ic_launcher_round. Se retira el vector anterior.
- Inicio y Acerca de muestran el símbolo del paquete; asset Flutter 512×512
  incluido en pubspec. Se comprueba su hash dentro del APK frente al PNG original.
- Icono 512×512 y banner 1024×500 de Google Play preparados en distribution/google-play/.
  Procedencia, dimensiones y formato: [IDENTIDAD.md](IDENTIDAD.md).
- Se conservan applicationId com.valinor.heroclixtrainer, namespace/canales, firma,
  almacenamiento privado y paquete Dart. La marca cambia dentro de la misma app;
  biblioteca/progreso siguen en sus ubicaciones. Sin nuevas reglas, permisos,
  dependencias ni esquemas. Se ignora la caché generada android/.kotlin/.

## Verificación ejecutada

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0, Windows.

| Comando / comprobación | Resultado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | 155 archivos, 0 cambios |
| `flutter --no-version-check analyze --no-pub` | No issues found, 6,2 s |
| `flutter --no-version-check test --no-pub test/widget_test.dart test/final_acceptance_test.dart --reporter expanded` | **35 aprobadas**, 8 s |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **101 renders aprobados**, 46 s |
| `flutter --no-version-check build apk --debug --no-pub` | Correcto; Gradle 65,1 s |
| PNG/XML Android frente al ZIP | 27 recursos coinciden por SHA-256; dimensiones de PNG comprobadas |
| `aapt dump badging / permissions / resources / xmltree` | Nombre, versión/código, icon/roundIcon y capas background/foreground/monochrome compilados; SDK 24/36 |
| `apksigner verify --verbose --print-certs` | Verifies; firma v2 válida y mismo certificado |

WidgetTest comprueba nombre visible, título y símbolo, junto a navegación y 15
combinaciones de tamaño/escala. FinalAcceptance incluye versiones, E2E de archivos,
consultas, ejercicios, JSON/PNG, ejemplos, Acerca de/licencias y accesibilidad.
Se ejecutan los 35 casos afectados por Inicio/identidad; las 485 pruebas completas
previas pertenecen a rc.6, archivadas en ENTREGA_RC6.md, y no se atribuyen a esta entrega.

Capturas Flutter en build/previews/teamfight-brand/; revisados Inicio y Acerca de
con nombre y símbolo nuevos. Los 101 renders mantienen hit test fatal. Metadatos
originales en build/verification/brand-assets/ y compilados en
build/verification/teamfight-brand/. Logs/capturas fuera de Git. No son pruebas Android.

## APK entregable

- `build/releases/teamfight-gridlab-1.0.0-rc.8-debug.apk`, **158910079 bytes**.
- SHA-256: `E9898D2E102FB1FDB9F2FB3834BB65F7FECC9583F2B707F89CE003C1554B532F`.
- Copia archivada y salida estándar con el mismo hash; anteriores conservadas.
- Paquete com.valinor.heroclixtrainer, nombre TeamFight: GridLab, versión 1.0.0-rc.8,
  código 21, SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Firma debug conservada: instalar encima, sin desinstalar, para mantener biblioteca
  y progreso. NOTICES.Z y PNG de marca presentes en el APK. Sin INTERNET ni permiso
  de almacenamiento amplio; solo permiso privado de receptor generado.

## Comprobar en Android

1. Instalar encima: conserva datos. Verificar nombre e icono en launcher y Ajustes.
2. Revisar icono normal/redondo, máscaras del launcher y tema monocromático cuando
   esté disponible, además del arranque y aplicaciones recientes.
3. Abrir Inicio, Acerca de y licencias: TeamFight: GridLab, símbolo y rc.8/código 21.
   Probar giro/texto ampliado. Abrir biblioteca y progreso; continuar los recorridos del Editor.

Pendiente: actualización e iconos/máscaras/tema/splash en Android real, TalkBack,
selectores, radios apagadas, proceso y rendimiento. Se mantiene la decisión previa
de continuar sin teléfono. El APK sigue siendo candidata debug; la publicación
requiere completar aceptación y firma release. Los recursos de Google Play quedan
preparados en el repositorio.

README/README_FINAL, identidad, decisiones, Android, arquitectura, hoja de ruta y
matriz AC33 actualizados. Rc.7 archivada en ENTREGA_RC7.md.