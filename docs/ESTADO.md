# Estado actual — TeamFight: GridLab

2026-11-18 (America/Bogota). **1.0.0-rc.11+24**, beta candidata debug.
Rama `codex/indoor-movement-strokes`, base `fe8b7ab`.
Informe anterior: [ENTREGA_RC10.md](ENTREGA_RC10.md).

## Indoor/Outdoor

- El selector de la barra sustituye el botón de estado del escenario. Sus opciones
  Indoor/Outdoor aplican el tipo al mapa completo y reinician marcas Indoor locales.
  Deshacer recupera el estado anterior. Información del escenario sigue en el menú.
- Indoor global se dibuja con borde amarillo del mapa. En Outdoor, el séptimo pincel
  Terrenos → Indoor pinta zonas por trazo o rectángulo, con contorno amarillo y letra I.
  Coexiste con bloqueado, obstaculizado, agua, alturas, figuras y transiciones.
- Despejado conserva Indoor y altura. Borrar Indoor solo retira marcas locales;
  Borrar todo limpia las capas locales de la casilla. El tipo global solo se cambia
  desde el selector. Se validan límites al reducir tablero y restaurar documentos.
- JSON escenario 4/capas 3 con environment/indoorCells. Lee escenarios 1/2/3 como
  Outdoor y conserva sus datos. Guardar crea primero una copia schema1/schema2/schema3;
  el adaptador real admite esos respaldos y no los muestra como escenarios. Si falla
  la copia, conserva el original. Versiones antiguas no admiten archivos del formato 4.
- Biblioteca, ejercicios, consultas y PNG comparten los mismos metadatos. Validación
  estricta de tipo, coordenadas canónicas únicas/dentro de límites y marcas locales
  vacías en Indoor global. Se comprueba el borde amarillo en píxeles de PNG exportado.

## Reglas y movimiento directo

- Revisión de la edición oficial 07.01.2026, §15.1a–c/15.2 y §27.5b–c. Indoor y
  amarillo no bloquean por sí mismos visión ni movimiento. Muros, bloqueo, altura
  y ocupación siguen operando. Un muro con algún lado Indoor se considera interior.
- IM Bloqueado exterior pasa a estar soportado: atraviesa B/muros Outdoor, no Indoor.
  IM Bloqueado conserva paso por ambos. Ninguno permite terminar sobre bloqueado.
  Visión incluye referencia M01/§15.1; recorrido indica el ámbito cuando corresponde.
  Fuentes/alcance en REGLAS.md y MATRIZ_MOVIMIENTO.md. No se implementan poderes libres.
- Movimiento entra sin diálogo ni selección automática. Primero se toca una figura;
  luego pasos o un trazo desde ella/último paso. Se interpolan solo los pasos del
  trazo, en orden, usando el mismo motor. Conserva el ancla de bases múltiples.
- La figura sigue en origen hasta Confirmar en la barra; la confirmación revalida
  contenido y aplica una operación reversible. Elegir otra figura/Cancelar/informe
  manual disponibles. Cancelar gesto o añadir otro dedo restaura ruta y efecto
  especial previos. Dos dedos navegan. No se guardan ensayos ni rutas transitorias.
- Paleta de siete pinceles, mínimo táctil de 48 px, distribución adaptable y etiquetas
  de una línea con ayuda/semántica completas. Corrección verificada al girar mientras
  se cierra una vista previa compacta. A 320×320 con texto x3 el espacio de mapa es
  muy reducido; las herramientas siguen accesibles. Capturas no son pruebas Android.

## Verificación ejecutada

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0, Windows.

| Comprobación | Resultado |
| --- | --- |
| dart format --output=none --set-exit-if-changed lib test tool | 161 archivos, 0 cambios |
| flutter --no-version-check analyze --no-pub | No issues found, 7,2 s |
| flutter --no-version-check test --no-pub --reporter expanded | **513 aprobadas**, 5 min 44 s |
| flutter test tool/preview_test.dart --no-pub --reporter expanded | **112 renders aprobados**, 2 min 11 s |
| ./tool/build_apk.ps1 | Correcto, Gradle 168,8 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt + apksigner | Identidad/versión/SDK/firma v2 correctos, mismo certificado; sin INTERNET |

Doce pruebas nuevas de Indoor/Movimiento: selector/Deshacer, capa Indoor y borrado,
JSON/migración/respaldo, datos inválidos, reglas de visión/movimiento y ámbito de
IM exterior, selección explícita, trazos/continuación/cambio de figura, cancelación,
base 2×2, diagonal bloqueada y conservación de efectos especiales. Una prueba PNG
nueva comprueba amarillo global/local sobre agua. Pruebas previas actualizadas al
formato 4 y a la apertura directa; adaptador de archivos real prueba respaldo 2/3.
Se conserva cobertura de vencimiento y de los formatos históricos.

Capturas revisadas en build/previews/indoor-movement/: Indoor completo, zonas,
compacto y movimiento directo vertical/horizontal. Logs finales:
build/test-indoor-verified.log, build/analyze-indoor-verified.log,
build/render-indoor-verified.log, build/build-indoor.log. Metadatos en
build/verification/indoor-movement/. No se atribuye aceptación nativa a Flutter.

## APK entregable único

- build/releases/teamfight-gridlab-1.0.0-rc.11-debug.apk, **158935067 bytes**.
- SHA-256: `920C63E06C71BB0BC1E19C6C79A7F53D0788013EA830C7A4EDD59B66C8384064`.
- Paquete com.valinor.heroclixtrainer, nombre TeamFight: GridLab, código 24;
  SDK mínimo 24, objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Instalar encima sin desinstalar para conservar datos de la beta anterior con
  igual firma. Se eliminó rc.10 después de validar rc.11. Las salidas técnicas
  actuales permanecen en build/app/; no se cambió el flujo ni se usó flutter clean.
- Mantiene vencimiento **30/12/2026 00:00 Colombia** (2026-12-30T05:00:00Z), reloj
  local y sus límites ya documentados. No se añaden permisos o dependencias.

## Pendiente en Android

Se mantiene la decisión de continuar sin teléfono. Falta verificar actualización
encima con biblioteca antigua, gestos/giro/TalkBack, selectores, rendimiento y
vencimiento en ciclo nativo. Recorrido en docs/ANDROID.md. La firma de producción y
publicación en Play requieren preparación por separado; sigue siendo candidata debug.
