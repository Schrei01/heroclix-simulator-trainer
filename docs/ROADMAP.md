# Hoja de ruta

Se trabaja en este mismo repositorio. Cada etapa requiere revisión de su entrega
y una nueva orden antes de iniciar la siguiente. Estado al 2026-11-17.

| Etapa | Entrega | Estado |
| --- | --- | --- |
| 00 | Base Flutter, inicio, arquitectura, pruebas y documentación | Validada; continuación a 01 autorizada por el usuario |
| 01 | Tablero configurable, coordenadas, selección, zoom y desplazamiento | Validada; continuación a 02 autorizada por el usuario |
| 02 | Figuras genéricas, equipos y ocupación | Validada; continuación a 03 autorizada por el usuario |
| 03 | Terreno, muros y capas de edición | Validada; continuación a 04 autorizada por el usuario |
| 04 | Persistencia local, JSON/PNG y deshacer/rehacer | Validada; continuación a 05 autorizada por el usuario |
| 05 | Geometría exacta de segmentos e intersecciones | Validada; continuación a 06 autorizada por el usuario |
| 06 | Visión reglamentaria explicable y árbitro básico | Validada; continuación a 07 autorizada por el usuario; corrección 0.7.1 conservada |
| 07 | Distancias, alcance y análisis de objetivos | Validada; continuación a 08 autorizada por el usuario |
| 08 | Elevaciones, bases múltiples y capacidades verificadas | Validada; continuación a 09 autorizada por el usuario; informe en ENTREGA_08.md |
| 09 | Validación y búsqueda de rutas de movimiento | Validada; continuación a 10 autorizada por el usuario; informe en ENTREGA_09.md |
| 10 | Ejercicios, corrección y progreso local | Validada; continuación a 11 autorizada por el usuario; informe en ENTREGA_10.md |
| 11 | Comparación de posiciones y métricas tácticas | Validada; continuación a 12 autorizada por el usuario; informe en ENTREGA_11.md |
| 12 | Integración, accesibilidad, verificación y APK final | Implementada como 1.0.0-rc.1+14; APK debug y evidencia en ESTADO.md; aceptación nativa pendiente, sin congelar estable |

Editor se habilita en 01. El informe histórico de 00 se conserva en ENTREGA_00.md.
Simulador y Árbitro tienen visión básica desde 06 y comparten escenario con Editor.
Alcance declarado y objetivos se incorporan en 07. Entrenador está disponible
desde 10. Movimiento tiene un perfil verificado desde 09; maniobras y excepciones
fuera de las matrices de capacidades permanecen pendientes.

Fuera de alcance: partidas completas, dados, daño, turnos, puntuación completa,
cuentas, backend, servicios de IA externos y funciones online.

Actualización posterior a 12: ajustes de edición solicitados por el usuario,
1.0.0-rc.2+15 en `codex/editor-quick-tools`. Paleta de terreno, altura propuesta 2
y colocación rápida de figuras; modos aún separados. Evidencia actual en ESTADO.md;
entrega 12 original archivada en ENTREGA_12.md. Aceptación nativa sigue pendiente.
