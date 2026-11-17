# Entrega rc.4 — Editor y símbolos de transición

2026-11-17 (America/Bogota). **1.0.0-rc.4+17**, candidata debug.
Rama `codex/editor-transitions`, sobre `5960dde` (rc.3). Código: `c43c4d6`.
Informe anterior: [ENTREGA_RC3.md](ENTREGA_RC3.md).

## Cambios

- Inicio ofrece Editor y Entrenador. Se eliminan los modos Simulador/Árbitro y su
  VisionScreen. El Editor conserva visión, distancia, objetivos, movimiento y
  comparación de posiciones, sus informes, referencias y motores existentes.
- Cada casilla de transición muestra un triángulo blanco con borde rojo y su nivel;
  los dos comparten base sobre el borde conectado. Las elevadas normales conservan
  E2/E3 y bordes rojos. El mismo painter produce el mapa y el PNG; leyendas y Guía
  rápida explican la diferencia. Se revisó §16.7 del reglamento 2026-07-01, página 43.
- Sin reglas, dependencias, permisos ni esquemas nuevos. Se conservan alturas,
  biblioteca, JSON 1/2/3, ejercicios/progreso y sesión temporal con nuevo arranque A.
- Las herramientas pasan al lateral cuando falta altura, corrigiendo un desbordamiento
  en Objetivos/Distancia con pantalla 320×320 y texto al 300 %.

## Verificación

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0. Ejecución Flutter/Dart en Windows;
no sustituye pruebas de dispositivo Android.

| Comando | Resultado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | 152 archivos, 0 cambios |
| `flutter --no-version-check analyze --no-pub` | No issues found |
| `flutter --no-version-check test --no-pub --reporter expanded` | **459 aprobadas**, 188 s |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **87 renders aprobados**, 45 s |
| `flutter --no-version-check build apk --debug --no-pub` | Correcto; Gradle 77,7 s |
| `aapt dump badging` / `dump permissions` | 1.0.0-rc.4/código 17, SDK 24/36; sin INTERNET ni almacenamiento amplio |
| `apksigner verify --verbose --print-certs` | Verifies; firma v2 válida, certificado conservado |

Se trasladaron las pruebas de las vistas retiradas al Editor sin desactivarlas:
visión, referencia automática/manual, caché, alcance/objetivos, rutas, posiciones y
accesibilidad. Los dos casos nuevos de transition_symbol decodifican PNG reales:
marcador dentro de ambas casillas, orientaciones vertical/horizontal, retirada y
niveles/transiciones tras JSON. Se conserva la regresión A1–D6/B4.

Renders en `build/previews/editor-transitions/`: los anteriores se mantienen con
las vistas retiradas adaptadas al Editor, y se añaden tres transiciones con niveles
1/2/3 y elevadas E2 normales (400×900, 1000×700, 320×568). Revisión visual de estos
casos y de Inicio/Guía actualizados. Capturas Flutter, no Android. Logs en build/;
metadatos y PNG de evidencia en build/verification/editor-transitions/, fuera de Git.

## APK de esta candidata

- `build/releases/heroclix-1.0.0-rc.4-debug.apk`, 158513849 bytes.
- SHA-256: `F76F40487B1FE1489C2D2DEAC4A8377F3A01557CF77E543FA119B2C1626B4B85`.
- Copia archivada y salida estándar con el mismo hash; APK anteriores conservados.
- Paquete `com.valinor.heroclixtrainer`, versión 1.0.0-rc.4, código 17, SDK 24/36.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Firma debug conservada: instalar encima sin desinstalar para conservar biblioteca
  y progreso. Binarios y claves excluidos de Git; commits de código/documentación.

## Comprobar en Android

1. Instalar encima de la anterior; Inicio debe mostrar Editor y Entrenador.
2. En Editor, consultar visión, distancia, objetivos, movimiento y posiciones.
   Seleccionar Visión y tocar dos figuras debe dar dictamen encima del mapa.
3. Elevar B1 a 2 y crear transición A1/B1: triángulos 1/2 en sus casillas. Repetir
   verticalmente y entre niveles 2/3. Una elevada sin transición debe mantener E2.
4. Comprobar zoom/giro/texto ampliado, figuras sobre transición, Deshacer/Rehacer,
   retirar transición, guardar/abrir y exportar JSON/PNG con los mismos símbolos.
5. Verificar nueva sesión vacía/A tras cierre y biblioteca/progreso conservados.

Pendiente: instalación, interacción real, selectores, cierre/pausa del proceso,
TalkBack, radios desactivadas y rendimiento Android. Se mantiene la decisión previa
del usuario de continuar sin teléfono; no se repite el intento de emulador fallido.
Sin claves release suministradas, no se genera release ni se promueve a estable.

## Límites y documentación

Solo se representan las transiciones de altura ya admitidas: vecinos ortogonales,
distinto nivel, sin muro compartido. No se implementan pasajes del mismo nivel ni
nuevas excepciones de juego. El dictamen conserva No evaluado y no autoriza ataques.

README/README_FINAL, Guía, arquitectura, Android, decisiones, reglas, matrices y
hoja de ruta actualizados. Los informes históricos conservan el estado de sus
versiones. AC01/23 adaptados y AC24 añadido; rc.3 archivada en ENTREGA_RC3.md.
