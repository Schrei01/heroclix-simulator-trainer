# Estado actual — TeamFight: GridLab

2026-11-18 (America/Bogota). **1.0.0-rc.10+23**, beta candidata debug.
Rama `codex/water-terrain`, base `4dd5196`.
Informe anterior: [ENTREGA_RC9.md](ENTREGA_RC9.md).

## Agua por trazo

- Editor → Terrenos → Agua: icono de gota, trazo libre con un dedo y vista previa
  azul. Al soltar aplica todas las casillas recorridas como una sola edición.
  También admite rectángulo con vista previa/confirmación.
- Azul con ondas, letra A y borde azul externo de la región, tanto en el tablero
  como en PNG. No depende solo del color. Leyenda de capas, leyenda PNG y Guía
  rápida incluyen Agua. La paleta reúne seis pinceles, con mínimo táctil de 48 px;
  se adapta en espacios estrechos y mantiene las opciones visibles.
- Conserva elevaciones/transiciones al pintar y permite figuras sobre agua.
  Deshacer/Rehacer, cancelación/segundo dedo, Despejado y Borrar todo por trazo
  reutilizan el flujo existente. Borrar limpia también la altura de la casilla.
- TerrainType.water y TerrainBrush.water. Los codecs guardan el tipo por nombre:
  biblioteca/JSON y snapshots de ejercicios lo conservan sin cambiar estructura.
  Una app anterior sin water rechaza ese escenario en lugar de perder el dato.
- Revisión de §16.6, página impresa 42, PDF oficial 07.01.2026: agua se considera
  despejado salvo efectos específicos. No añade bloqueo/H ni costo/parada. Se siguen
  aplicando restricciones independientes de muros, figuras y altura. Referencia
  W01/§16.6 en visión y §16.6 en pasos de agua sin una restricción prioritaria.
  Fuentes y contratos en [REGLAS.md](REGLAS.md). No se añaden poderes específicos.
- Conserva vencimiento **30/12/2026 00:00 Colombia** (2026-12-30T05:00:00Z), marca,
  firma y paquete. Sigue offline, sin nuevas dependencias ni permisos.

## Verificación ejecutada

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0, Windows.

| Comprobación | Resultado |
| --- | --- |
| dart format --output=none --set-exit-if-changed lib test tool | 160 archivos, 0 cambios |
| flutter --no-version-check analyze --no-pub | No issues found, 23,2 s |
| flutter --no-version-check test --no-pub --reporter expanded | **500 aprobadas**, 4 min 45 s |
| flutter test tool/preview_test.dart --no-pub --reporter expanded --plain-name water_ | **4 renders aprobados**, 10 s |
| ./tool/build_apk.ps1 | Correcto, Gradle 158,9 s; copia/hash válidos; 1 APK anterior eliminado |

Seis pruebas nuevas verifican trazo/altura/figuras/borrado e historial, cancelación
por gesto/segundo dedo, rectángulo confirmado, biblioteca y JSON con transición,
visión con agua en origen/interior/destino y movimiento entrando/cruzando/saliendo.
El test PNG existente ahora decodifica el resultado y comprueba el azul del agua.
Los tests de paleta recorren los seis pinceles con tamaño táctil y límites de
pantalla, también a 320×320/texto x3. La suite completa conserva cobertura previa,
incluidos vencimiento y formatos históricos.

Capturas revisadas en build/previews/water-terrain/: vertical, horizontal, compacto
con texto x3 y vista previa de trazo. Logs build/test-water-full.log,
build/analyze-water-final.log y build/render-water.log. No son pruebas Android.

## Pendiente en Android

Se conserva la decisión de continuar sin teléfono. Falta verificar actualización
encima, gestos reales, giro/TalkBack, selectores, rendimiento y vencimiento en ciclo
nativo. Recorrido de Agua en docs/ANDROID.md. Sigue siendo candidata debug; no se
atribuye instalación o aceptación nativa a las pruebas Flutter/Windows.

## APK entregable único

- build/releases/teamfight-gridlab-1.0.0-rc.10-debug.apk, **158917327 bytes**.
- SHA-256: `4A1591F7C3552F663575A1772986679DA8595306B87682B61A3F7FE20A8BF703`.
- Paquete com.valinor.heroclixtrainer, nombre TeamFight: GridLab, código 23;
  SDK mínimo 24, objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- El flujo oficial validó paquete/versión/firma y copia antes de retirar rc.9.
  Solo queda rc.10 en build/releases/; las salidas técnicas actuales permanecen
  en build/app/. No se modificó el script de generación ni se usó flutter clean.
- Instalar encima sin desinstalar para conservar datos de la beta anterior con
  igual firma. Firma debug; la publicación en Play sigue pendiente de preparación.
- Metadatos adicionales de aapt/apksigner en build/verification/water-terrain/;
  log de compilación en build/build-water.log. Sin INTERNET ni almacenamiento amplio.
