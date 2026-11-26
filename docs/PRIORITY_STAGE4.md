# Priority: historial, Deshacer y partidas locales

2026-11-26. Etapa 4, rc.22+35, ampliada en rc.23 con orden dinámico de asientos.
Se conserva el motor de las etapas 1–3 y la mesa
existente. No se implementan sonidos, vibración, mantener pantalla encendida,
exportación, sincronización ni otras funciones de etapas posteriores.

## Uso

El menú ⋮ de Priority contiene Historial, Deshacer, Finalizar partida y Partidas
guardadas. Historial dispone también de un botón Deshacer para operaciones
consecutivas. Cada registro muestra fecha/hora local, jugador, ronda/turno y los
eventos producidos. La prioridad se registra aunque cambie automáticamente.

Una operación incluye el comando y todos sus efectos: consumo, pases automáticos,
avance de prioridad, cambio de turno y finalización por eliminación. Deshacer
restaura el estado anterior completo y los asientos visuales, sin reanudar relojes.
Se puede deshacer una eliminación/finalización. Se retienen los registros originales
con la marca Deshecho y un registro adicional de reversión. El resumen cuenta solo
operaciones vigentes. Pausar, reanudar, recuperar y los eventos automáticos de reloj
son auditables, pero no añaden pasos a la pila; el inicio tampoco se deshace.

La recuperación conserva fase subyacente ACTION/FREE, ventana parcial de respuesta,
activo/prioridad, pendientes de turno/ronda, acciones base/adicionales/consumidas,
PV, eliminación, tiempos restantes/consumidos, inicial y asientos. Fuerza pausa si
hay relojes y la partida sigue en curso. No descuenta el lapso fuera de la app.
Sin cronómetros no impone una pausa artificial. Recuperar o deshacer aumenta la
revisión para rechazar callbacks anteriores y limpia el bloqueo de doble toque.

Nueva partida y cambiar a una guardada requieren confirmación si hay otra abierta;
se archiva la actual antes de sustituirla. La biblioteca permite consultar cualquier
resumen/historial sin modificarlo y continuar las partidas en curso. Descartar una
guardada requiere confirmación; la abierta no se puede borrar. Finalizar requiere
confirmación global y conserva clasificación por PV con empates, estado individual,
ACTION/RESPONSE ACTION/FREE/RESPONSE FREE/PASS voluntario y automático, tiempos
consumidos, rondas, turnos e historial. No inventa un ganador por supervivencia.

## Persistencia y errores

- `main.dart` inyecta `PriorityRepository` sobre `FileDocumentStore`, dentro de
  `priority_v1/` del directorio privado Android ya existente. Sin dependencias,
  permisos ni comunicaciones de red nuevos. Editor y Entrenador mantienen sus datos.
- Formato Priority 2, compatible con 1: configuración única, snapshot, asientos, historial y pila
  completa de checkpoints. El codec de dominio es Dart puro y valida transiciones
  estructurales antes de aceptar un archivo; no permite reconstruir estados arbitrarios.
  `order` conserva el ciclo horario actual en cada snapshot. La migración de formato
  1 adopta las posiciones guardadas para el orden actual y todos los checkpoints,
  conservando activo/prioridad, los pendientes y la pausa tras recuperar o deshacer.
- Se solicita guardado tras cada operación aceptada. Una cola serializada combina
  escrituras pendientes sin perder operaciones del estado más reciente. Ticks de
  reloj solicitan checkpoint cada segundo, sin llenar el historial por segundo.
- Cada archivo usa temporal, flush y rename. Antes de sustituir `working.json` se
  conserva una copia anterior conocida válida. Ante truncamiento/corrupción del
  principal, se recupera esa copia y se avisa que debe revisarse: puede faltar la
  última operación. No es una transacción multiarchivo ni garantiza recuperar datos
  que Android no alcanzó a escribir antes de un corte abrupto.
- Checksum FNV-1a para detectar corrupción accidental, sin finalidad criptográfica.
  Esquemas futuros bloquean la carga y no se sobrescriben. Una partida archivada
  ilegible se omite de la lista con aviso; su archivo se conserva.
- Si falla un guardado, el estado sigue en memoria y aparece Reintentar. Nueva
  partida/cambio de partida no sustituyen la abierta hasta guardarla. Una lectura
  inicial fallida no habilita crear una partida encima de datos desconocidos.
- Límites explícitos: 32 MiB por documento, 100000 registros/checkpoints y 10000
  documentos en la carpeta Priority. No se recorta el historial silenciosamente;
  al superar capacidad se informa un error de guardado y se mantiene en memoria.
- Salir del módulo o pasar a segundo plano liquida/pausa el reloj y solicita flush.
  El guardado es local al dispositivo; desinstalar/borrar datos elimina las partidas.
  Esta etapa no incluye exportación de partidas Priority.

## Verificación

Antes del incremento: 201 pruebas del motor/controladores de etapas anteriores
aprobadas. Se añaden 81 pruebas: 64 unitarias/de aplicación, 3 de integración con
archivos reales y 14 de interfaz/ciclo de vida. Incluyen 2–6 jugadores con/sin reloj
y ambas ventanas, 4000 roundtrips de transiciones, undo consecutivo de operaciones
mixtas, reinicios, callbacks obsoletos, fallos de E/S, copia de recuperación y formatos
corruptos/futuros. La interfaz se prueba también a 320×320 y texto 300 %.

Los renders Flutter se amplían de 23 a 27: historial con reversión, mesa pausada tras
Undo, biblioteca y resumen guardado. Las pruebas de archivos crean una carpeta
temporal dedicada y eliminan individualmente solo sus archivos. No usan red.

Resultados definitivos, APK y límites de aceptación Android: [ESTADO](ESTADO.md).
