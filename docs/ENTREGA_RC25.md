# Estado actual — TeamFight: GridLab

2026-11-26 (America/Bogota). **1.0.0-rc.25+38**, beta candidata debug.
Rama `codex/priority-setup-selector`, base `6918fd4` (rc.24).
Informe anterior: [ENTREGA_RC24.md](ENTREGA_RC24.md).

## Preparar mesa con ayuda y selección en el diagrama

- Las explicaciones se reúnen en ⓘ arriba, dentro de un diálogo desplazable. El
  formulario conserva etiquetas, errores y el total funcional de acciones.
- Tocar un jugador del diagrama lo elige como inicial; borde dorado e INICIA lo
  identifican. La pulsación larga sigue moviendo asientos sin elegirlos por accidente.
- Dado al lado del diagrama: el icono gira y el resaltado recorre los jugadores en
  sentido horario durante 2,2 s, desacelera y termina en un jugador aleatorio.
  Se usa el API de sorteo del motor; el resultado no depende de los fotogramas.
- El sorteo no inicia la partida. Dado/Listo se bloquean mientras dura; otro toque,
  edición, arrastre, ayuda/menú, segundo plano o salida cancelan el efecto sin una
  selección tardía. Con movimiento reducido la misma elección es inmediata.
- Se retiran selector desplegable y botón textual de sorteo, conservando elección
  manual y sorteos consecutivos después de reorganizar jugadores.

Solo cambia presentación; el resto de Priority mantiene orden horario, reloj, PV,
historial, undo y guardado. Sin paquetes/permisos nuevos ni cambios del formato de
partidas o del flujo de APK. La beta conserva el corte 30/12/2026 00:00 Colombia
según el reloj del dispositivo. Detalles: [PRIORITY_PLAN.md](PRIORITY_PLAN.md).

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Pruebas nuevas de selección/sorteo | 20, incluidas en la ejecución final |
| Focalizadas de interfaz/gestos y renders | **240/240 aprobadas**, 2 min 31 s: 208 pruebas y 32 renders |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 205 archivos Dart, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 51,6 s; copia/hash verificados; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Cobertura: 2–6 jugadores, selección manual, resultado aleatorio sembrado, recorrido
por todos, tres sorteos después de reorganizar, ayuda/datos/gestos, errores visibles,
seis interrupciones y ausencia de callbacks tardíos, reducción de animaciones
inicial/durante, objetivos táctiles 48×48 sin solapamiento en 320×320/800×360 al
300 %. Se adaptan dos pruebas previas al nuevo selector. Se reutilizan pantalla,
cronómetros, PV, historial/guardado, toolbar, arrastre y geometría horaria.

Revisión visual de configuración limpia, ayuda única, sorteo en curso y elegido;
32 renders en ambas orientaciones con 2–6, teclado y texto ampliado en las pruebas.
La última regresión general completa sigue siendo rc.23 (1046 pruebas y 28 renders);
este incremento verifica la interfaz modificada y análisis global.

Evidencia local: `build/verification/priority-setup-selector/`:
`setup-final.log`, `targeted-final.log`, `analyze-final.log`, `format-check-final.log`,
`apk-build.log`, `apk-identity.log` y `previews/`.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.25-debug.apk`, **159149119** bytes.
- SHA-256: `C1829E7F948086310CA5A0D82A078A2D863C0999978DB8776F9CB21A70C5B7DA`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 38;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Solo queda rc.25. El script retiró rc.24 después de verificar la compilación y
  la copia; no cambió el flujo de APK ni se utilizó flutter clean.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Instalación/validación física,
TalkBack y rendimiento siguen pendientes. Recorrido en [ANDROID.md](ANDROID.md).
Instalar encima con la misma firma conserva biblioteca, progreso y partidas Priority.
