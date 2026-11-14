# Preparar, compilar e instalar en Android

## Herramientas

Flutter estable está en `%USERPROFILE%\develop\flutter`. Para usarlo en una
terminal PowerShell nueva sin modificar el PATH global:

```powershell
$env:Path = "$env:USERPROFILE\develop\flutter\bin;$env:Path"
flutter --version
flutter doctor -v
```

Instalar Android Studio y su SDK siguiendo la guía oficial:
https://docs.flutter.dev/platform-integration/android/setup

En SDK Manager instalar la plataforma y Build Tools compatibles con el Flutter
registrado en ESTADO.md, Platform Tools, Command-line Tools y el NDK que solicita
la plantilla. Añadir un emulador solo si se va a utilizar. Revisar y aceptar
personalmente las licencias con `flutter doctor --android-licenses`.

Si Flutter no detecta el SDK:

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor -v
```

No versionar `android/local.properties`: contiene rutas propias del equipo.
`minSdk`, `targetSdk`, `compileSdk` y `ndkVersion` se heredan del SDK Flutter.
El applicationId se cambia con `appId` en `android/gradle.properties`, antes de
distribuir la primera app. Cambiarlo posteriormente crea otra identidad Android.

## Verificar y generar debug

Desde la raíz:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
Get-Item -LiteralPath '.\build\app\outputs\flutter-apk\app-debug.apk'
```

La ruta anterior es la salida esperada, no evidencia de un APK generado. Consultar
ESTADO.md para saber qué se ejecutó realmente.

## Verificación manual

1. Conectar un teléfono con depuración USB autorizada o arrancar un emulador.
2. Ejecutar `flutter devices` y anotar ID, modelo y versión Android.
3. Instalar con `adb -s ID install -r build/app/outputs/flutter-apk/app-debug.apk`
   y abrir la app desde el launcher.
4. Comprobar nombre, español y Editor operativo. Simulador, Entrenador y Árbitro
   siguen deshabilitados como «Próximamente». Abrir Editor y editar un escenario.
5. Girar vertical/horizontal y recorrer la pantalla. Repetir con texto ampliado
   en accesibilidad de Android y TalkBack; los modos se anuncian deshabilitados.
6. Deshabilitar Wi-Fi y datos. Esperar confirmación de autoguardado, forzar cierre,
   reabrir Editor y comprobar contenido. Probar biblioteca y exportar/importar JSON
   con el selector nativo; exportar PNG y abrir Compartir (cancelar para la prueba).
7. Registrar resultados reales en ESTADO.md; las pruebas de widgets no sustituyen
   estas pruebas de dispositivo.

Los manifiestos de esta app no solicitan INTERNET, ni siquiera en debug/profile.
Esto limita conexiones al servicio VM de depuración/hot reload. Para comprobar
la interfaz se puede instalar el APK y abrirlo manualmente sin ese servicio.

## Release firmado en una etapa posterior

Guía oficial: https://docs.flutter.dev/deployment/android#sign-the-app

No se necesita ni se crea una keystore en la etapa 00. Cuando el propietario
prepare la firma, debe custodiar la clave y contraseñas fuera del repositorio.
Ejemplo para crear una keystore con contraseñas solicitadas interactivamente:

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\heroclix-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copiar `android/key.properties.example` a `android/key.properties` y completar
las cuatro propiedades con datos reales locales. Para `storeFile`, usar ruta
absoluta con `/` en Windows. No guardar secretos en scripts, historial de comandos
ni repositorio. Mantener una copia segura de la keystore.

La configuración Gradle carga exclusivamente la firma release proporcionada.
Si falta, detiene las tareas release con un mensaje explícito.

```powershell
flutter build apk --release
Get-Item -LiteralPath '.\build\app\outputs\flutter-apk\app-release.apk'
```

Antes de distribuir, verificar la firma con `apksigner verify --verbose` de
Android Build Tools, instalar y repetir pruebas offline y de orientación.
No se anuncia release, firma o instalación exitosa sin ejecutar esos pasos.
