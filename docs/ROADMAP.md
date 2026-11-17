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
Simulador y Árbitro se incorporaron en 06 y se retiraron en rc.4; el Editor conserva el análisis.
Alcance declarado y objetivos se incorporan en 07. Entrenador está disponible
desde 10. Movimiento tiene un perfil verificado desde 09; maniobras y excepciones
fuera de las matrices de capacidades permanecen pendientes.

Fuera de alcance: partidas completas, dados, daño, turnos, puntuación completa,
cuentas, backend, servicios de IA externos y funciones online.

Actualización posterior a 12: ajustes de edición solicitados por el usuario,
1.0.0-rc.2+15 en `codex/editor-quick-tools`. Paleta de terreno, altura propuesta 2
y colocación rápida de figuras; modos aún separados. Evidencia actual en ESTADO.md;
entrega 12 original archivada en ENTREGA_12.md. Aceptación nativa sigue pendiente.

Actualización rc.3: 1.0.0-rc.3+16, rama `codex/temporary-scenario-vision`.
Nueva apertura vacía/figuras desde A, biblioteca y progreso persistentes, y dictamen
inmediato sobre el mapa. Entrega rc.2 archivada en ENTREGA_RC2.md. Modos aún separados;
candidata con aceptación Android pendiente.

Actualización rc.4: **1.0.0-rc.4+17**, rama `codex/editor-transitions`.
Inicio conserva Editor y Entrenador. Se retiran Simulador/Árbitro y se mantienen
sus consultas y ensayos en Editor. Transiciones con dos triángulos numerados,
uno por casilla conectada; elevadas normales E2/E3. Sin nuevas reglas ni formatos.
Entrega rc.3 archivada en ENTREGA_RC3.md; aceptación Android pendiente.

Actualización rc.5: **1.0.0-rc.5+18**, rama `codex/editor-terrain-gestures`.
Inicio 10×10, Terrenos con cinco pinceles, E2/E3 por toque, transición por par,
borrado de alturas/transiciones y confirmación por segundo toque. Ficha con Targeting
plegable, sin permiso sobre bloqueado ni Other; visión igual limpia y dictamen solo
arriba. Ajuste automático del mapa mientras no haya cámara manual. Rc.4 archivada
en ENTREGA_RC4.md. Sin nuevas reglas/esquemas; aceptación Android pendiente.

Actualización rc.6: **1.0.0-rc.6+19**, rama `codex/editor-brush-teams`.
Personajes cambia de equipo por pares de toques; avisos verticales laterales de
cuatro segundos; Elevado por trazo mixto y Borrar todo por trazo. Deshacer/Rehacer
y cancelación/pinza conservados. Rc.5 archivada en ENTREGA_RC5.md. Sin nuevas reglas
ni formatos; aceptación Android pendiente.

Actualización actual: **1.0.0-rc.7+20**, rama `codex/upright-tool-hints`.
Aviso lateral con texto derecho, en columna de arriba hacia abajo, conservando
cuatro segundos y paso de gestos. Corrección de presentación; rc.6 archivada en
ENTREGA_RC6.md. Aceptación Android pendiente.