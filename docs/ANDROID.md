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
4. Comprobar nombre, español y Editor operativo. Desde la etapa 06, Simulador y
   Árbitro permiten consultar visión básica; Entrenador sigue «Próximamente».
   Abrir Editor y editar un escenario.
5. Girar vertical/horizontal y recorrer la pantalla. Repetir con texto ampliado
   en accesibilidad de Android y TalkBack; solo Entrenador se anuncia deshabilitado.
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

## Geometría en el dispositivo (05)

En Editor, desplazar la barra hasta Línea de visión · Geometría. Elegir A1 y D4,
abrir Inspeccionar y revisar los tres vértices. Probar formulario, ocultar las
capas, invertir extremos, cambiar zoom/orientación y editar una figura usada como
extremo. Un muro tocado se informa geométricamente, sin resolver reglas. El
procedimiento y resultados efectivos de cada entrega están en ESTADO.md.

## Dictámenes de visión en el dispositivo (06)

Instalar `build/releases/heroclix-prompt-06-fix-debug.apk` (0.7.1+8). En Editor crear
figuras normales en A1 y D1, seleccionar sus extremos y abrir Dictamen de visión.
Comprobar despejada; H en B1 debe producir obstaculizada, y B o muro atravesado,
bloqueada. Desde Inicio abrir Árbitro y comprobar el mismo escenario con navegación
y selección; Editar escenario permite volver a modificar el mundo.

Abrir Registro y referencias, revisar las causas resaltadas y activar Efectos
especiales: el resultado debe ser No evaluado. La evaluación no comprueba alcance
ni legalidad completa del ataque. Las condiciones sin soporte y la tabla de casos
con secciones oficiales están en [MATRIZ_REGLAS_VISION](MATRIZ_REGLAS_VISION.md).
El recorrido realmente ejecutado, sus capturas y las interrupciones de System UI
del emulador están registrados en [ESTADO](ESTADO.md); no equivalen a prueba en
teléfono físico ni a una instalación release.

Regresión 0.7.1: tablero de al menos 4 columnas por 6 filas; figuras normales en
A1 y D6, bloqueado solo en B4, sin efectos especiales. Debe mostrar DESPEJADA;
el registro compara B4 y C3. Añadir bloqueado en C3 debe producir BLOQUEADA y
cambiarlo a obstaculizado, OBSTACULIZADA. Conservar B4 y poner bloqueado en B3
también bloquea, porque B3 sí se atraviesa. Esta revisión no cambia el formato
de escenarios ni requiere borrar datos de la app.

## Distancias y objetivos en el dispositivo (07)

Instalar `build/releases/heroclix-prompt-07-debug.apk` (0.8.0+9) sobre la versión
anterior, sin borrar datos. En Editor usar Medir distancia y tocar A1/D6: cuenta
5 casillas. El botón Distancia abre diferencias opcionales de filas/columnas y
la referencia de conteo. No requiere que las casillas tengan figuras.

Crear una figura normal en A1 con alcance 3 y otra en D1. Seleccionar A1 y usar
Mostrar objetivos: D1 debe estar dentro y con visión despejada. Cambiar alcance
a 2 debe clasificarla fuera; deshacer restaura 3. H en B1 produce obstaculizada;
B o muro cruzado, bloqueada. Consultar detalle y referencias al elegir una fila.

En Simulador/Árbitro, abrir Elegir análisis en la barra superior y alternar entre
Visión, Medir distancia y Mostrar objetivos. Comprobar selección del origen desde
la lista, filtros Enemigas/Aliadas/Todas, objetivo resaltado y regreso a Editor.
No se valida un ataque completo. En la entrega 07 una base 2×2 relevante mantenía
dimensiones pendientes; el soporte añadido en 08 se describe abajo. Consultar ESTADO.md para distinguir
estas instrucciones de los recorridos efectivamente realizados.

## Elevaciones, bases y mejoras (08)

Instalar `build/releases/heroclix-prompt-08-debug.apk` (0.9.0+10) sin desinstalar.
Abrir un escenario de 0.8 y comprobar figuras, terreno, muros y alcance antes de
editar. La lectura no sobrescribe; los guardados nuevos usan esquema 2 con copia
exacta previa de los archivos de esquema 1.

En Editor, Alturas y transiciones permite casilla/región y nivel 1–40. Probar A1/B2
como región elevada 2 y una transición B1/C1, con C1 en suelo. Revisar números,
borde, undo/redo y PNG. Limpiar tipo de terreno debe conservar esos niveles.

En la ficha declarar una mejora de visión y comparar su obstáculo con otro tipo.
En Dictamen activar Laboratorio, cambiar una mejora y comprobar HIPÓTESIS; la
ficha guardada debe permanecer igual. Restablecer desactivando Laboratorio.

Con origen A1 y objetivo de base 1×2 anclada en B3, muro entre A2/B2 y alcance 2,
Visión automática puede ver B4, pero Objetivos no debe aprobar: la referencia B3
está bloqueada y B4 queda a distancia 3. Subir alcance a 3 permite el par B4.
El Árbitro muestra pares y registro. Este procedimiento debe contrastarse con los
resultados efectivamente ejecutados en ESTADO.md; no equivale a una prueba física.
