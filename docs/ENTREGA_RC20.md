# Entrega histórica rc.20 — TeamFight: GridLab

Informe archivado. La candidata vigente se describe en [ESTADO.md](ESTADO.md).

2026-11-25 (America/Bogota). **1.0.0-rc.20+33**, beta candidata debug.
Rama `codex/priority-seat-drag`, base `e434449` (PV y posiciones rc.19).
Informe anterior: [ENTREGA_RC19.md](ENTREGA_RC19.md).

## PV próximos y asientos por arrastre

- Grupo −/PV/+ centrado y limitado a 208 unidades para acercar los botones al total.
  Se conserva el tamaño 22 de PV y los objetivos táctiles de al menos 48 unidades.
- Antes de iniciar: mantener pulsada una celda de la vista de asientos y arrastrarla
  sobre otra para intercambiar. La vista muestra nombres e INICIA; conserva el
  ID seleccionado para empezar. La disposición resultante configura el orden
  antihorario cuando se crea la partida.
- Durante la partida: mantener el nombre y soltar sobre otro panel para intercambiar
  posiciones visuales. Conserva inicial, orden de juego ya establecido, pendientes,
  prioridad, revisión/eventos, identidad/color, PV, acciones y relojes. No pausa ni
  transfiere el reloj. Un toque corto sigue abriendo gestión.
- Tarjeta de arrastre y borde de destino. Soltar fuera cancela. Se valida grupo de
  arrastre/sesión, IDs y primer plano. Las posiciones siguen en memoria al salir/
  volver y se limpian al iniciar otra partida. Los diálogos toman la orientación
  actual, incluido el acceso desde el aviso de reloj agotado.

Alcance: [PRIORITY_PLAN.md](PRIORITY_PLAN.md). No cambia el motor ni se inicia etapa
4 o persistencia. Editor/Entrenador, dependencias, permisos y JSON no cambian.
La beta vence el 30/12/2026 a las 00:00 Colombia, según el reloj del dispositivo.

## Verificación

| Comprobación | Resultado |
| --- | --- |
| Focalizadas de Priority y renders | **246/246 aprobadas**, 1 min 31 s: 223 pruebas y 23 renders |
| Nuevas del arrastre | 22 aprobadas: 8 de controlador y 14 de widgets |
| Análisis completo | Sin incidencias |
| Formato lib/test/tool | 191 archivos, 0 cambios pendientes |
| ./tool/build_apk.ps1 | Correcto, Gradle 39,5 s; copia/hash válidos; 1 APK anterior eliminado |
| aapt / apksigner | Paquete/versión/SDK/firma v2 válidos; mismo certificado; sin INTERNET |

Pruebas nuevas: todos los pares en 2–6, snapshot/eventos/inicial preservados,
rechazo de sesión antigua/IDs/intercambio propio/segundo plano, ejemplo de tres y
reloj. Gestos reales para 2–6 en ambas orientaciones, inicial distinto del primer
asiento en configuración, cancelación, reapertura y orientación del aviso de reloj.
Se reutilizan controladores previos, geometría, PV/posiciones, estado activo,
configuración, relojes, teclado y dimensiones/texto ampliado. Revisión visual del
espaciado, intercambio y arrastre en curso. La última suite general completa fue
rc.16: 908/908 aprobadas; este incremento verifica Priority y análisis global.

Evidencia local: `build/verification/priority-seat-drag/`, con `targeted-final.log`,
`drag-final.log`, `analyze-final.log`, `format-check-final.log`, `apk-build.log`
y `previews/`.

## APK entregable único

- `build/releases/teamfight-gridlab-1.0.0-rc.20-debug.apk`, **159062879** bytes.
- SHA-256: `E842EBA1433BA682FB9286FB57594B5E7EA3327D5DAC21BCE325AB528FA0ACD1`.
- Paquete `com.valinor.heroclixtrainer`, nombre TeamFight: GridLab, código 33;
  SDK mínimo 24 y objetivo/compilación 36.
- Certificado SHA-256 conservado:
  `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- El script retiró rc.19 solo después de validar compilación y copia. No cambió
  el flujo de APK y no se utilizó flutter clean. Historial de código/informes en Git.

## Aceptación Android

Se mantiene la decisión de continuar sin teléfono. Queda pendiente instalar y
verificar físicamente gestos desde cada lado, desplazamiento, teclado, TalkBack y
actualización con datos anteriores. Recorrido en [ANDROID.md](ANDROID.md).
Instalar encima para conservar biblioteca/progreso.
