# HeroClix Simulator & Trainer

Aplicación Android Flutter/Dart, offline y en español. Versión inicial
`0.1.0+1`. Se desarrolla por etapas en este mismo repositorio.

## Repositorio

Repositorio privado: [Schrei01/heroclix-simulator-trainer](https://github.com/Schrei01/heroclix-simulator-trainer).
Rama principal: `main`. Para clonarlo necesitas una cuenta con acceso:

```powershell
git clone https://github.com/Schrei01/heroclix-simulator-trainer.git
cd heroclix-simulator-trainer
```

## Qué existe

La etapa 00 prepara el arranque, una pantalla de inicio adaptable con tema
original y las entradas **Editor**, **Simulador**, **Entrenador** y **Árbitro**.
Las cuatro muestran **Próximamente**, están deshabilitadas y no tienen navegación.

No hay tablero, personajes, reglas, escenarios guardados ni ejercicios en esta
entrega. Las carpetas de esos módulos y el puerto de almacenamiento solo preparan
la arquitectura. Consultar [estado real y verificación](docs/ESTADO.md).

Validación local del 2026-11-14: análisis estático y 18 pruebas correctos;
APK debug generado e instalado en un emulador Android 17, con inicio comprobado
en ambas orientaciones y sin conectividad. Los detalles y límites constan en
ESTADO.md; no se ha iniciado la etapa 01.

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

- `lib/domain`: Dart puro; tipos comunes y módulos futuros documentados.
- `lib/application`: catálogo inmutable y puertos locales.
- `lib/presentation`: inicio y tema Flutter.
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

Ninguna regla oficial está implementada en 00. Se usarán explicaciones propias,
fuentes verificadas y «No evaluado» ante casos no soportados. El producto será
una herramienta de apoyo, no una decisión oficial de torneo.

La siguiente etapa es 01, tablero interactivo; requiere revisión de 00 y nueva
orden. No se inicia automáticamente.
