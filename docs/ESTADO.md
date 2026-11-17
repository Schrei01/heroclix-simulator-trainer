# Estado actual — incrementos del Editor

2026-11-17 (America/Bogota). **1.0.0-rc.5+18**, candidata debug.
Rama `codex/editor-terrain-gestures`, sobre `53dc6df` (rc.4). Código: f17ccf2.
Informe anterior: [ENTREGA_RC4.md](ENTREGA_RC4.md).

## Cambios operativos

- Cada escenario nuevo empieza 10×10. Biblioteca/importación mantienen el tamaño
  guardado. Continúa la sesión temporal, con figuras nuevas desde A al reiniciar.
- Terrenos integra cinco opciones en el mismo lugar bajo el mapa: Bloqueado,
  Obstaculizado, Elevado, Transición, Despejado. Caben juntas en los tamaños probados;
  con poco espacio se muestran iconos con tooltip y etiquetas accesibles.
- Elevado: tocar suelo crea E2; cada toque siguiente sube un nivel, hasta E40.
  Despejado conserva elevación y transiciones. Coordenadas permite edición avanzada.
- Transición: tocar dos vecinos ortogonales de distinto nivel y sin muro compartido.
  Solo tras validar se dibujan los triángulos. Casilla repetida, diagonal, salto,
  igual nivel o muro muestran error sin edición parcial. Cambiar pincel limpia el
  primer extremo pendiente. Sin nuevas reglas ni ampliación de cobertura.
- Seleccionar: volver a tocar la misma casilla pregunta si quieres borrar; prioridad
  personaje, tipo de terreno, elevación. Las transiciones restantes también pueden
  borrarse. Cancelar conserva datos; confirmar modifica una capa y permite Deshacer.
- Borrar permite figura, terreno, elevación, transición y muro. Quitar terreno
  conserva alturas; quitar altura vuelve a suelo y retira transiciones que dejan
  de unir niveles distintos. Quitar transición conserva terreno y alturas.
- Ficha sin checkbox de estudio; se retira allowStudy de los comandos. Crear,
  duplicar, mover o editar hacia bloqueado y pintarlo bajo figuras se rechazan.
  Los documentos antiguos incompatibles se leen sin pérdida, con aviso para corregirlos.
- Improved Targeting se despliega como Movement. Se oculta Otra excepción en ambas
  listas, conservando sus IDs/datos heredados y el resultado No evaluado.
- Dictamen solo arriba del mapa; abajo quedan instrucciones y referencias. Elegir
  mismo origen/destino en Visión limpia extremos, selección, marcas y resultado.
  Distancia conserva la medición cero; el motor geométrico no cambia.
- La cámara conserva el ajuste automático al cambiar el espacio del mapa por las
  herramientas. Un zoom/pan manual conserva su centro/escala. Corrige A1 recortada
  al abrir Terrenos con el nuevo tablero 10×10.

## Verificación ejecutada

Flutter 3.50.0, Dart 3.14.0, material_ui 1.11.0, Windows. Sin dependencias, permisos
ni esquemas nuevos. No se presenta como aceptación en Android real.

| Comando | Resultado |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test tool` | 153 archivos, 0 cambios |
| `flutter --no-version-check analyze --no-pub` | No issues found, 3,9 s |
| `flutter --no-version-check test --no-pub --reporter expanded` | **473 aprobadas**, 226 s |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **94 renders aprobados**, 56 s |
| `flutter --no-version-check build apk --debug --no-pub` | Correcto; Gradle 55,2 s |
| `aapt dump badging` / `dump permissions` | 1.0.0-rc.5/código 18, SDK 24/36; sin INTERNET ni almacenamiento amplio |
| `apksigner verify --verbose --print-certs` | Verifies; firma v2 válida y mismo certificado |

Nuevo editor_increments_test: 14 casos con gestos reales de widgets, confirmación/
cancelación, prioridad y conservación de capas, E2/E3, cinco pares inválidos,
transiciones válidas/Deshacer, ficha, visión limpia y tres tamaños/escala al 300 %.
Las regresiones anteriores se conservan, actualizando los contratos de estudio y
visión iguales a los nuevos requisitos. Los casos geométricos/de límites 4×4 se
hacen explícitos en sus fixtures; el Editor y los nuevos casos usan 10×10 real.
Los tests de PNG/JSON siguen comprobando documentos antiguos, incluidos datos
incompatibles heredados; no se habilita crear esos datos desde la UI.

Renders en build/previews/editor-increments/: se mantienen los 87 anteriores y
se añaden siete (paleta vertical/horizontal/compacta, transición válida/errónea,
confirmación de borrado y Targeting expandido). Revisados visualmente; el caso
compacto es 320×320 con texto al 300 %. La navegación de previews apunta al botón
real visible, con advertencias de hit test fatales. No se ocultan fallos de render.
En altura extrema el mapa necesita zoom/pan para inspeccionar casillas; los cinco
terrenos y las herramientas siguen accesibles. Son capturas Flutter, no Android.

## APK

- `build/releases/heroclix-1.0.0-rc.5-debug.apk`, 158514269 bytes.
- SHA-256: `A08B647BC228BFA71BD3CE204A7CCAC54923BE32B4540E637A592E9642D5A3C5`.
- Copia archivada y salida estándar con el mismo hash; anteriores conservadas.
- Paquete `com.valinor.heroclixtrainer`, 1.0.0-rc.5/código 18, SDK mínimo 24/objetivo 36.
- Certificado SHA-256: `57081ee91137c216eff437a7c75ac5bb6f552bc29167e63370d85628fc82ac54`.
- Firma debug conservada. Instalar encima, sin desinstalar, para mantener biblioteca
  y progreso. Licencias NOTICES.Z comprobadas; binarios y claves fuera de Git.

## Pendientes y límites

Recorrido nativo actualizado en ANDROID.md: instalación, gestos, giro/texto, mismas
capas en PNG/JSON, biblioteca/progreso y nueva sesión tras cierre. Instalación,
selectores, TalkBack, radios apagadas, cierre real y rendimiento siguen pendientes.
Se mantiene la decisión del usuario de continuar sin teléfono. Sin claves release,
no se genera release ni se declara estable.

Las transiciones admitidas siguen siendo de altura, con los límites documentados;
no se añaden pasajes del mismo nivel ni reglas de marcadores durante set-up. Las
bases no pueden quedar repartidas entre alturas. Un borrado o incremento que lo
provocaría se rechaza y explica; puede editarse la región completa con Coordenadas.
No evaluado conserva incertidumbre y el dictamen no autoriza ataques completos.

README/README_FINAL, Guía/leyenda, arquitectura, decisiones, reglas, Android, hoja
de ruta y matriz de aceptación actualizados. AC21/23 adaptados; AC25–28 añadidos.
Rc.4 archivada en ENTREGA_RC4.md. Logs y capturas en build/, excluidos de Git.