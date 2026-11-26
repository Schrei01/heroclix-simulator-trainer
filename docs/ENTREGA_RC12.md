# Entrega archivada — TeamFight: GridLab rc.12

Informe histórico. La entrega vigente está en [ESTADO.md](ESTADO.md); los APK
anteriores se sustituyen al validar un nuevo entregable.

2026-11-18 (America/Bogota). **1.0.0-rc.12+25**, beta candidata debug.
Rama `codex/movement-destruction`, base `9d272e6`.
Informe anterior: [ENTREGA_RC11.md](ENTREGA_RC11.md).

## Destrucción confirmada

- IM Destruir bloqueado y muros (§27.5d) pasa a estar soportada. IM Bloqueado e
  IM Bloqueado exterior normales siguen permitiendo atravesar sin destruir.
- La ruta se simula por pasos sobre una copia: B atravesado se destruye y genera
  debris H; un muro se retira y genera debris en ambos lados salvo B que continúe
  intacto. Se mantienen elevación e Indoor y se consideran los cambios en pasos
  posteriores, aterrizaje, adyacencia y comparación futura de visión/alcance.
- El destino forma parte de lo atravesado (§10.4): puede terminar en la casilla B
  recién destruida porque ya es H, si cumple las demás restricciones. El reposicionado
  libre sigue impidiendo poner personajes en B intacto. El perfil de base/altura,
  separación, velocidad y poderes no soportados conserva sus comprobaciones.
- El escenario real permanece intacto durante ensayo/búsqueda. Barra e informe
  enumeran cambios previstos. Confirmar revalida y aplica posición/capas juntas en
  una operación; Deshacer/Rehacer recupera posición, B, muros y marcadores. Una ruta
  inválida/cancelada, un efecto sin soporte o escenario modificado no aplica el plan.
- Db/piedras identifica debris y funciona como H para visión/movimiento. Es un marcador
  separado del tipo base: retirar debris sobre agua recupera agua; B destruido queda
  despejado y el muro no reaparece. Borrar escombros solo retira ese marcador;
  Borrar todo limpia todas las capas locales. Cambiar altura o Indoor conserva debris.
- Se corrige Borrar todo en una casilla con solo Indoor/debris sin terreno base.
  Retirar un marcador no puede descubrir B bajo una figura mediante edición.
- En diagonal se conserva el lado menos restrictivo, luego menor destrucción y un
  desempate canónico visible en el plan. No se destruyen todos los laterales por
  contacto con el vértice. No hay selector manual de laterales equivalentes todavía.
- Búsqueda de destrucción: estado incluye obstáculos destruidos y límite de 4096
  prefijos; solo devuelve rutas completas revalidadas y avisa si se alcanza el límite.
  Un prefijo no es confirmable. El buscador anterior se conserva para otras figuras.
- Revisión oficial 07.01.2026: §10.4–5/16.8a/16.9a–c/17.14d/27.5b–d. Alcance y
  decisiones en REGLAS.md y MATRIZ_MOVIMIENTO.md. No se modelan objetos portables,
  marcadores de poderes con retirada/vencimiento ni acciones CLOSE/RANGE Destroy.

## Guardado y compatibilidad

- JSON escenario 5/capas 4 añade debrisCells, separadas del terreno base, con
  coordenadas canónicas, únicas y dentro de límites. Lee escenarios 1–4 sin debris,
  conservando terreno, Indoor, personajes, capacidades y alturas.
- Guardar una versión anterior hace primero respaldo schema1/schema2/schema3/schema4,
  también working. Adaptador real y prueba de migración cubren versiones 2/3/4;
  las pruebas de 1 se conservan. Un fallo de copia preserva el original.
- Biblioteca, ejercicios, consultas, diagnósticos y PNG comparten los mismos datos.
  Las versiones antiguas no admiten formato 5; no se eliminan campos para fingirlo.
- Se conserva marca, paquete, firma y vencimiento 30/12/2026 00:00 Colombia. Sigue
  offline, sin nuevas dependencias ni permisos. El vencimiento usa el reloj local.

## Verificación ejecutada

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0, Windows.

| Comprobación | Resultado |
| --- | --- |
| dart format --output=none --set-exit-if-changed lib test tool | 162 archivos, 0 cambios |
| flutter --no-version-check analyze --no-pub | No issues found, 9,4 s |
| flutter --no-version-check test --no-pub --reporter expanded | **533 aprobadas**, 5 min 12 s |
| flutter test tool/preview_test.dart --no-pub --reporter expanded | **116 renders aprobados**, 2 min 10 s |
| ./tool/build_apk.ps1 | Correcto, Gradle 143,5 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt + apksigner | Identidad/versión/SDK/firma v2 válidos, mismo certificado; sin INTERNET |

Veinte pruebas nuevas cubren diferencia IM normal/destructiva, B de destino, muros,
vecinos B intactos, altura/Indoor, diagonales libres y con obstáculos, base 2×2,
bucles, rutas inválidas/efectos sin soporte, búsqueda, aplicación atómica/Deshacer,
visión futura, retirada de debris sobre agua, JSON inválido/ida-vuelta, confirmación
por trazo, cero pasos/quitar paso, edición que invalida plan, altura sobre marcador y
borrado de capas locales puras. Los contratos M19/M20 mantienen invalidez de destinos
ilegales antes del No evaluado de otra parte de base. Formatos y pruebas previos se
actualizan al esquema 5, sin cambiar sus expectativas reglamentarias ordinarias.

Capturas revisadas en build/previews/movement-destruction/: antes/después de
confirmar, informe y compacto, más recorridos previos. Logs finales:
build/test-destruction-full.log, build/analyze-destruction-final.log,
build/render-destruction.log y build/build-destruction.log.
Metadatos en build/verification/movement-destruction/. No son pruebas Android.

## APK entregable único

- build/releases/teamfight-gridlab-1.0.0-rc.12-debug.apk, **158947015 bytes**.
- SHA-256: `6BA886945582740491C370BC9139002D1452BD5FF622E1FBF555420FCDABE140`.
- Paquete com.valinor.heroclixtrainer, nombre TeamFight: GridLab, código 25;
  SDK mínimo 24, objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Instalar encima sin desinstalar para conservar datos de la beta anterior con igual
  firma. Rc.11 se eliminó solo después de validar rc.12. Las salidas técnicas actuales
  permanecen en build/app/; no se modificó el flujo de APK ni se usó flutter clean.

## Pendiente en Android

Se mantiene la decisión de continuar sin teléfono. Falta verificar actualización
con biblioteca antigua, destrucción por gestos reales, giro/TalkBack, selectores,
rendimiento y vencimiento nativo. Recorrido en docs/ANDROID.md. La preparación de
firma/publicación de Play queda aparte; continúa candidata debug, no release estable.
