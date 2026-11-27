# Estado actual — TeamFight: GridLab

2026-11-27 (America/Bogota). **1.0.0-rc.27+40**, beta candidata debug.
Rama `codex/priority-quiet-table`, base `3a89c8d` (rc.26).
Informe anterior: [ENTREGA_RC26.md](ENTREGA_RC26.md).

## Mesa sin letreros temporales

- La mesa Priority no genera avisos inferiores al deshacer, recuperar o agotar
  tiempo. Los controles tampoco muestran etiquetas al mantener pulsado o con hover.
- El agotamiento conserva el reloj rojo a cero y pausa la partida. La gestión del
  jugador sigue accesible desde su nombre para corregir tiempo y reanudar.
- La recuperación y la advertencia de copia anterior válida se consultan en
  Historial. Los errores de biblioteca aparecen en la propia lista con reintento;
  los errores de guardado conservan su panel. No se silencian errores.
- Los botones conservan nombres accesibles explícitos para lectores de pantalla,
  incluidos los iconos de barra, PV, calavera y contador de acciones.
- Se conservan las confirmaciones de eliminar/finalizar, las ayudas de Preparar
  mesa y el acumulado temporal de PV junto a su contador solicitado previamente.
- Finalizar manualmente sigue guardando y regresando a Preparar mesa sin resumen.

Sin cambios de motor, reglas, cronómetros, persistencia/formato, Editor o Entrenador,
paquetes, permisos ni flujo de APK. La beta mantiene el corte 30/12/2026 00:00 Colombia
según el reloj del dispositivo. Detalles: [PRIORITY_PLAN.md](PRIORITY_PLAN.md).

## Verificación

Se añaden seis pruebas: secuencia de acciones/respuestas/pases/PV/Deshacer,
pulsación larga y hover sin etiquetas, recuperación normal y desde copia válida,
nombres accesibles y error de consulta visible con reintento. Se adaptan las pruebas
de agotamiento/orientación para abrir gestión desde el nombre y comprobar ausencia
de SnackBar. Se añade un render de Deshacer sin letrero y se revisan visualmente
las capturas de este estado y del reloj agotado.

| Comprobación | Resultado |
| --- | --- |
| Pruebas nuevas | 6/6 aprobadas, 10 s |
| Regresión focalizada final + renders | **272/272 aprobadas**, 3 min 12 s: 237 pruebas y 35 renders |
| Análisis completo | Sin incidencias, 9,2 s |
| Formato lib/test/tool | 207 archivos Dart, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 50,9 s; copia/hash verificados; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

La última regresión general completa sigue siendo rc.23: 1046 pruebas y 28 renders.
Este incremento verifica la interfaz, recuperación y controles de Priority mediante
regresión focalizada y análisis global; no se afirma una nueva ejecución general.

Evidencia local: `build/verification/priority-quiet-table/`: `quiet-verified.log`,
`targeted-verified.log`, `analyze-final.log`, `format-check-final.log`, `apk-build.log`,
`apk-identity.log` y `previews/`.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.27-debug.apk`, **159145363** bytes.
- SHA-256: `82AF72509983D59D11E8638A2065E5BE20934FE92384F7ABC260F1D17D91A045`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 40;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Solo queda rc.27. El script retiró rc.26 después de verificar la compilación y
  la copia; no cambió el flujo de APK ni se utilizó flutter clean.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Instalación/validación física,
TalkBack y rendimiento siguen pendientes. Recorrido en [ANDROID.md](ANDROID.md).
Instalar encima con la misma firma conserva biblioteca, progreso y partidas Priority.
