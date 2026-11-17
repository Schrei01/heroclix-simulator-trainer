# Estado actual — TeamFight: GridLab

2026-11-17 (America/Bogota). **1.0.0-rc.9+22**, beta candidata debug.
Rama `codex/beta-expiry-december-2026`, base `f0ec936`.
Informe anterior: [ENTREGA_RC8.md](ENTREGA_RC8.md).

## Vencimiento implementado

- Corte fijo al empezar el **30 de diciembre de 2026, 00:00 Colombia**:
  `2026-12-30T05:00:00Z`. BetaExpiration centraliza el instante y el texto.
- BetaAccessGate envuelve Navigator desde MaterialApp.builder. Al vencer, sustituye
  Inicio, Editor, Entrenador, rutas y diálogos por «Versión de prueba finalizada».
  Pide instalar una versión actualizada; todavía no existe ficha de Play para enlazar.
- Comprueba al arrancar y reanudar; temporizador de un minuto como máximo, con último
  control programado para el corte. Una sesión bloqueada no se reactiva al atrasar
  el reloj. Se cancela el temporizador y el observador al desmontar.
- Acerca de muestra la fecha. Biblioteca y progreso no se eliminan. Los APK previos
  sin esta función no adquieren caducidad retroactivamente.
- Usa el reloj del teléfono. Sin servidor ni validación de licencia; puede eludirse
  manipulando fecha/reiniciando. Continúa offline, sin permisos o dependencias nuevos.
- La futura edición oficial debe retirar expresamente este corte. Compilar con
  -Mode release no lo retira. No se modifica todavía la firma para Google Play.

## Verificación ejecutada

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0, Windows.

| Comprobación | Resultado |
| --- | --- |
| dart format --output=none --set-exit-if-changed lib test tool | 159 archivos, 0 cambios |
| flutter --no-version-check analyze --no-pub | No issues found, 94,9 s |
| flutter --no-version-check test --no-pub --reporter expanded | **494 aprobadas**, 5 min 18 s |
| flutter test tool/preview_test.dart --no-pub --reporter expanded | **103 renders aprobados**, 2 min 2 s |
| Renders finales --plain-name beta_expired | **2 aprobados**, con imagen precargada |
| ./tool/build_apk.ps1 | Compilación correcta, Gradle 236,3 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt badging/permissions + apksigner | Paquete, versión, SDK y firma v2 válidos; mismo certificado, sin INTERNET |

Las nueve pruebas nuevas cubren arranque vencido de HeroClixApp, frontera inclusiva
con UTC y otras zonas, contenido protegido sin construir, corte con ruta/diálogo,
Atrás, reanudación, reloj adelantado/atrasado, cancelación al desmontar y dos tamaños
con texto x3. Los recorridos funcionales y renders inyectan una fecha anterior al
corte para no depender de la fecha de ejecución; el arranque real usa DateTime.now.

Capturas revisadas vertical y horizontal en build/previews/beta-expiry/.
Logs: build/test-beta-expiry.log, build/analyze-beta-expiry.log,
build/render-beta-expiry.log, build/render-beta-expiry-final.log,
build/build-beta-expiry.log. Metadatos en build/verification/beta-expiry/.
No son pruebas Android reales.

## APK entregable único

- build/releases/teamfight-gridlab-1.0.0-rc.9-debug.apk, **158917063 bytes**.
- SHA-256: `67BA50665239E5EE7EF713800AA136909C432EDC9628408655794B0BA4DB7443`.
- Paquete com.valinor.heroclixtrainer, nombre TeamFight: GridLab, código 22.
  SDK mínimo 24, objetivo/compilación 36.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Se eliminó el entregable rc.8 después de validar rc.9. Las salidas técnicas
  actuales de Flutter/Gradle en build/app/ permanecen. Política en AGENTS.md.
- Instalar encima sin desinstalar para conservar biblioteca y progreso de la beta
  anterior con igual firma. Esta actualización no fuerza a usuarios de APK antiguos
  a instalarla. Preparar firma definitiva y distribución de Play por separado.

## Pendiente en Android

Se mantiene la autorización de continuar sin teléfono. Falta verificar instalación
encima, fecha manual/corte/reanudación reales, Atrás, giro/TalkBack, launcher y
recorridos nativos previos. Seguir docs/ANDROID.md; no se atribuyen estas pruebas
nativas a la verificación Flutter. Sigue siendo candidata debug, no release estable.
