# HeroClix Simulator & Trainer

Aplicación Android Flutter/Dart, offline y en español. Versión **0.4.0+4**.
La entrega 03 está en la rama `codex/prompt-03` del repositorio privado
[Schrei01/heroclix-simulator-trainer](https://github.com/Schrei01/heroclix-simulator-trainer).

```powershell
git clone https://github.com/Schrei01/heroclix-simulator-trainer.git
cd heroclix-simulator-trainer
git switch codex/prompt-03
```

## Qué existe

Editor con tablero 4×4 inicial, filas/columnas independientes de 2 a 40,
coordenadas A1…AN40, selección, zoom, pinza y pan. Figuras genéricas con identidad
estable, etiquetas A…Z, AA…, equipos con código/color/patrón y ficha editable.
Bases 1×1/2×2 con ocupación completa validada; duplicar y borrar con confirmación.

La etapa 03 añade terreno despejado, obstaculizado y bloqueado; muros sobre bordes
internos; trazo y relleno rectangular con vista previa; borrado por capa y tres
limpiezas independientes. La leyenda usa letras, puntos, rayas y línea doble,
además del color. Figuras, terreno y muros tienen datos separados.

Simulador, Entrenador y Árbitro permanecen futuros. No hay evaluación reglamentaria,
ataques, rutas, visión, guardado ni historial/deshacer. El escenario se conserva al
girar o volver al inicio durante la sesión; cerrar el proceso lo pierde.

## Uso del Editor

1. **Abrir editor**. El botón de cuadrícula superior cambia filas y columnas.
   Reducir se rechaza si dejaría figuras, terreno o muros fuera de sus límites.
2. **Seleccionar** permite tocar una casilla o figura, arrastrar para pan y usar
   pinza o botones −/+ para zoom. Centrar mantiene el zoom; Ajustar encaja el mapa.
3. **Personajes** y toque en vacío abre la ficha. Nombre, equipo, posición, base,
   velocidad y alcance son editables. Velocidad/alcance: enteros 0–99 como datos.
   El lápiz inferior abre la ficha; la lista superior permite elegir cualquier figura.
4. Mantener pulsada una figura y arrastrar muestra destino ✓/×. Solo al soltar un
   destino válido se mueve. La ficha permite editar la coordenada como alternativa.
5. **Terrenos** muestra un selector D/Despejado, H/Obstaculizado o B/Bloqueado.
   Toca o arrastra para pintar. La vista previa no modifica el mapa; el trazo completo
   se aplica al soltar. Se interpolan los eventos para evitar huecos en trazos rápidos.
6. Elige **Rellenar rectángulo**, arrastra entre dos casillas y pulsa **Aplicar
   terreno** o **Cancelar**. **Coordenadas** permite indicar inicio/fin sin arrastrar.
   Con poco espacio vertical, la confirmación usa un diálogo desplazable.
7. **Muros** permite Añadir/Borrar muro. Toca o traza cerca de un borde interno;
   cada trazo conserva la orientación del primer borde. No se admiten bordes externos.
   **Coordenadas** recibe dos casillas vecinas ortogonales que comparten el muro.
8. **Borrar elemento** tiene un selector explícito de figura o muro. Borrar figura
   pide confirmación y no cambia terreno/muros. Para quitar terreno usa **Despejado**.
9. El menú superior ofrece **Leyenda y capas** y **Limpiar solo terreno/muros/figuras**.
   Cada limpieza pide confirmación y conserva las otras capas.

En Terrenos, Muros y Borrar, un dedo edita y dos dedos permiten navegar. Añadir un
segundo dedo o cancelar el gesto descarta la edición transitoria. Cambiar herramienta
u orientación cancela la previa. En mapas grandes, amplía para leer y tocar con precisión.
La barra de opciones de capa se desplaza horizontalmente en pantallas pequeñas.

## Posiciones para estudio

Pintar bloqueado bajo una figura ofrece **Cancelar** o **Conservar para estudio**.
Esta última mantiene la figura y marca cada casilla incompatible con **!**; no afirma
legalidad reglamentaria. También se requiere optar explícitamente por estudio en la
ficha si se crea o edita una figura sobre bloqueado. El arrastre ordinario rechaza
ese destino y remite a la ficha. Obstaculizado no elimina ni desplaza figuras.

La base 2×2 se ancla arriba a la izquierda. Es representación de posición, no
legalidad reglamentaria. Elevación está preparada como dato 0–40 en dominio;
no existe editor ni análisis de altura en esta etapa.

## Ejecutar y verificar

```powershell
$env:Path = "$env:USERPROFILE\develop\flutter\bin;$env:Path"
flutter --no-version-check pub get
dart format --output=none --set-exit-if-changed lib test tool
flutter --no-version-check analyze
flutter --no-version-check test
flutter --no-version-check test tool/preview_test.dart
flutter --no-version-check build apk --debug
```

`--no-version-check` evita una consulta de actualización del SDK; no cambia su
versión ni omite análisis o pruebas. Los renders se escriben en
`build/previews/prompt-03/`; son capturas Flutter, no de un dispositivo.

Preparación Android y firma release en [ANDROID.md](docs/ANDROID.md).
El APK debug y sus resultados/hash se registran en [ESTADO.md](docs/ESTADO.md).
No se incluyen binarios, credenciales ni claves en Git.

## Organización y límites

- `lib/domain/board`: dimensiones, coordenadas y cámara en Dart puro.
- `lib/domain/characters`: figuras, equipos, huellas y ocupación.
- `lib/domain/terrain`: terreno, elevación preparada, muros normalizados y hit tests.
- `lib/application/board`: sesión inmutable, comandos reversibles y fragmento de capas.
- `lib/presentation/editor`: formularios, herramientas, vista previa y canvas por capas.
- `test`: contratos de dominio, gestos, confirmaciones, accesibilidad y regresiones.

El fragmento `LayerCodec` serializa terreno/bordes en memoria con
`layerSchemaVersion: 1`. No es un archivo de escenario ni una función de importar,
exportar o guardar. `BoardEdit` permite aplicar/revertir una operación terminada;
no existe historial en UI. Ambas piezas preparan 04 dentro del alcance de 03.

Sin backend, cuentas, telemetría, fuentes remotas ni red en runtime. La instalación
de herramientas y compilación durante el desarrollo sí puede necesitar internet.

## Documentación

[ROADMAP](docs/ROADMAP.md), [DECISIONES](docs/DECISIONES.md),
[ARQUITECTURA](docs/ARQUITECTURA.md), [ESTADO](docs/ESTADO.md),
[REGLAS](docs/REGLAS.md) y [ANDROID](docs/ANDROID.md).
Informes anteriores: [00](docs/ENTREGA_00.md), [01](docs/ENTREGA_01.md),
[02](docs/ENTREGA_02.md).

**No se inició Prompt 04.** Requiere una nueva orden tras revisar esta entrega.
