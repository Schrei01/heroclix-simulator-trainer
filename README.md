# HeroClix Simulator & Trainer

Aplicación Android Flutter/Dart, offline y en español. Versión inicial
`0.2.0+2`. Se desarrolla por etapas en este mismo repositorio.

## Repositorio

Repositorio privado: [Schrei01/heroclix-simulator-trainer](https://github.com/Schrei01/heroclix-simulator-trainer).
Rama principal: `main`. Para clonarlo necesitas una cuenta con acceso:

```powershell
git clone https://github.com/Schrei01/heroclix-simulator-trainer.git
cd heroclix-simulator-trainer
```

La entrega 01 está en `codex/prompt-01` para revisión. Después de clonar, usa
`git switch codex/prompt-01` para trabajar con esa entrega.

## Qué existe

La etapa 01 añade el **Editor**: cuadrícula inicial 4×4, filas y columnas
independientes de 2 a 40, selección A1…AN40, zoom con pinza/botones,
desplazamiento, centrar/ajustar y opciones de cuadrícula/coordenadas. Las celdas
son cuadradas. En horizontal las herramientas están a la izquierda.

Solo **Seleccionar** está activa. Personajes, terrenos, muros, visión, distancia,
movimiento y borrar son futuros. **Simulador**, **Entrenador** y **Árbitro**
permanecen deshabilitados. No hay reglas del juego, guardado ni ejercicios.

El tablero se conserva al girar o volver al inicio durante la misma sesión.
Cerrar la aplicación pierde esa sesión; persistencia e historial corresponden a 04.
El informe de 00 se conserva en [ENTREGA_00.md](docs/ENTREGA_00.md).
Consultar [estado real y verificación](docs/ESTADO.md) para los resultados actuales.

Validación de 01: **52 pruebas**, análisis estático y cinco renders correctos;
APK debug generado, firmado e instalado en Android 17. Se comprobó offline
selección, navegación, giro y configuración hasta 40×40.

## Uso del Editor

1. Pulsa **Abrir editor**. El icono de cuadrícula de la barra superior permite
   introducir filas y columnas por separado, por ejemplo 8 y 12.
2. Toca una casilla para seleccionarla; toca la misma para deseleccionar. La
   coordenada aparece abajo. Un toque fuera de la cuadrícula limpia selección.
3. Arrastra para desplazar o usa dos dedos para ampliar. Los botones **−** y **+**
   ofrecen zoom sin gestos; sus ayudas indican el porcentaje actual.
4. **Centrar** mantiene el zoom; **Ajustar** restablece la vista del tablero completo.
5. El menú de opciones muestra/oculta cuadrícula y coordenadas o limpia selección.
   Cambiar dimensiones con una selección requiere confirmación y permite cancelar.

En un borde compartido se selecciona derecha/abajo; el borde exterior derecho o
inferior queda fuera. En mapas grandes, amplía para leer rótulos y tocar con precisión.

## Ejecutar

En PowerShell, desde la raíz del proyecto:

```powershell
$env:Path = "$env:USERPROFILE\develop\flutter\bin;$env:Path"
flutter --version
flutter pub get
flutter analyze
flutter test
flutter devices
```

Para compilar e instalar en Android, preparar primero Android SDK según
[docs/ANDROID.md](docs/ANDROID.md). Ese documento incluye instrucciones de debug,
firma release y verificación manual. No se incluyen claves ni credenciales.

Formato y comprobación sin modificar archivos:

```powershell
dart format lib test
dart format --output=none --set-exit-if-changed lib test tool
```

Para renderizar capturas de revisión sin dispositivo Android:

```powershell
flutter test tool/preview_test.dart
```

Se guardan en `build/previews/`. Son renders de Flutter, no capturas tomadas en
un teléfono. No se incluyen como evidencia de una instalación Android.

Las versiones efectivamente encontradas, resultados de los comandos y pruebas
no realizadas se registran en [docs/ESTADO.md](docs/ESTADO.md). `pubspec.lock`
conserva la resolución de dependencias de esta aplicación.

## Organización

- `lib/domain`: Dart puro; dimensiones, coordenadas, geometría de tablero y cámara.
- `lib/application`: sesión inmutable, catálogo y puertos locales.
- `lib/presentation`: inicio, Editor, gestos y tema Flutter.
- `lib/infrastructure`: ubicación de adaptadores futuros.
- `android`: adaptación de plataforma e identidad configurable.
- `test`: contratos de dominio y comportamiento del inicio.

La aplicación no usa backend, login, telemetría, APIs, fuentes remotas ni
dependencias de red en runtime. Descargar Flutter, paquetes o herramientas de
compilación durante el desarrollo sí puede requerir internet.

## Documentación

- [ROADMAP](docs/ROADMAP.md): las 13 etapas y orden de ejecución.
- [ARQUITECTURA](docs/ARQUITECTURA.md): capas y dependencias.
- [DECISIONES](docs/DECISIONES.md): decisiones y supuestos.
- [ESTADO](docs/ESTADO.md): implementado frente a verificado.
- [REGLAS](docs/REGLAS.md): fuentes oficiales y método de validación futuro.
- [ANDROID](docs/ANDROID.md): herramientas, APK y firma.

Ninguna regla oficial está implementada en 01. Se usarán explicaciones propias,
fuentes verificadas y «No evaluado» ante casos no soportados. El producto será
una herramienta de apoyo, no una decisión oficial de torneo.

La siguiente etapa es 02, figuras y equipos; requiere revisión de 01 y nueva
orden. No se inicia automáticamente.
