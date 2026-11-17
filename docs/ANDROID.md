# Preparar, compilar e instalar en Android

Candidata actual: **1.0.0-rc.6+19**. Inicio contiene Editor y Entrenador; las consultas
y ensayos están en las herramientas del Editor. El recorrido vigente del Editor
está al final de este documento. Los apartados identificados por etapa describen
sus versiones históricas. Resultados efectivamente ejecutados: [ESTADO](ESTADO.md).

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
4. Comprobar nombre, español y las entradas Editor/Entrenador. Abrir Editor y editar
   un escenario; consultar visión en sus herramientas y practicar en Entrenador.
5. Girar vertical/horizontal y recorrer la pantalla. Repetir con texto ampliado
   en accesibilidad de Android y TalkBack; todas las entradas de modo deben abrir.
6. Deshabilitar Wi-Fi y datos. Guardar una escena en biblioteca y forzar cierre.
   Al abrir, comprobar escena vacía y figuras desde A; abrir manualmente el guardado.
   Comprobar progreso del Entrenador. Probar biblioteca y exportar/importar JSON
   con el selector nativo; exportar PNG y abrir Compartir (cancelar para la prueba).
7. Registrar resultados reales en ESTADO.md; las pruebas de widgets no sustituyen
   estas pruebas de dispositivo.

Los manifiestos de esta app no solicitan INTERNET, ni siquiera en debug/profile.
Esto limita conexiones al servicio VM de depuración/hot reload. Para comprobar
la interfaz se puede instalar el APK y abrirlo manualmente sin ese servicio.

## Release firmado con claves del propietario

Guía oficial: https://docs.flutter.dev/deployment/android#sign-the-app

No se proporcionó keystore release durante 00–12. Cuando el propietario prepare
la firma, debe custodiar la clave y contraseñas fuera del repositorio.
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

## Movimiento en dispositivo (09)

Instalar `build/releases/heroclix-prompt-09-debug.apk` (0.10.0+11) sobre la anterior.
El certificado se conserva; consultar ESTADO.md para distinguir procedimientos de
verificaciones efectivamente realizadas. No desinstalar si se quieren conservar datos.

Montar una figura normal A1, velocidad 4, muros A1/B1 y A2/B2. Simulador → Elegir
análisis → Movimiento reglamentario: elegir figura, Volver al tablero y tocar
A2, A3, B3, C2, C1 requiere cinco pasos y excede velocidad. Buscar destino C1
encuentra alternativa de cuatro pasos; su costo supera la distancia directa 2.
Seleccionarla deja la figura en A1; solo Confirmar la desplaza. Deshacer desde el
Editor restaura A1. Cancelar ensayo debe conservar A1 e historial.

Con enemigo D2, ruta A1/B1/C1 puede terminar en C1, pero continuar a D1 es inválido
por entrar en adyacencia. Si se comienza ya adyacente a un enemigo, sin IM Personajes
queda No evaluada por separación pendiente. IM Atravesar no concede separación.
En la ficha, declarar las cuatro mejoras por separado y comprobar sus límites.

Aplicar altura 2 a B1/C1: A1/B1 puede terminar; A1/B1/C1 no puede continuar salvo
transición A1/B1 o IM Elevación. H en B1 no cambia el costo. En el informe abrir
Pasos y reglas y Visión/alcance antes/después. Girar y ampliar texto al 300 %;
comprobar acceso a botones desplazando el informe. Las rutas no se guardan en JSON.

## Entrenador en dispositivo (10)

Instalar `build/releases/heroclix-prompt-10-debug.apk` (0.11.0+12) sobre la versión
anterior, conservando datos. Consultar ESTADO.md para verificaciones efectivamente
realizadas: estas instrucciones por sí solas no equivalen a pruebas nativas.

Inicio → Entrenador → iniciar un ejercicio de H. Elegir respuesta: antes de
Comprobar no debe aparecer solución ni cambiar progreso. Pedir pista es opcional.
Comprobar muestra acierto/error, solución, referencias y explicación del motor;
la vista entra al resultado. Repetir limpia la respuesta sin sumar otro intento.
Revisar el último intento desde el banco tampoco suma ni recalifica.

Probar tocar objetivo/casilla, ruta de velocidad exacta y rodeo entre muros.
Comprobar contadores por categoría, porcentaje y Practicar errores. Cerrar/reabrir
la app conserva progreso. El Editor debe conservar la escena inicial y su historial.

Guardar una escena en biblioteca. Entrenador → + → crear visión/distancia/alcance
ruta o texto manual. Solución automática errada debe impedir guardar; la manual
requiere guía y no genera un acierto automático. Reiniciar estadísticas exige
confirmación, borra intentos y conserva ejercicios personales. Probar orientaciones,
texto al 300 %, teclado y desplazamiento en formularios/resultados.

## Recorrido manual de 11

Instalar `build/releases/heroclix-prompt-11-debug.apk` (0.12.0+13) sobre la anterior,
sin desinstalar para conservar datos. Abrir escenarios y progreso de 10. Simulador
→ Elegir análisis → Analizar posición: elegir figura, analizar, seleccionar destino
y comprobar ruta, costo, métricas, diferencias y evidencia. Probar Cancelar: figura
intacta. Confirmar una ruta válida y Deshacer debe recuperar el origen.

Comparar prioridades, cambiar de página y activar HIPÓTESIS sin mejoras. Un poder
sin soporte debe conservar No evaluado. Añadir un muro en Editor obliga a recalcular;
zoom/cámara conservan resultados. En 40×40 comprobar progreso y cancelación.

Crear ambos ejercicios y practicarlos desde Entrenador. Exportar TXT/PNG usando
el selector nativo y comprobar etiquetas genéricas y límites del diagnóstico.
Rotar, ampliar texto al 300 % y cerrar/reabrir para comprobar persistencia.
Los tests Flutter, isolates, PNG y renders están verificados en Windows. Este
recorrido nativo, instalación física, FPS y variante release siguen sin verificar;
consultar evidencia concreta en ESTADO.md.

## Entrega candidata 12

APK debug: `build/releases/heroclix-1.0.0-rc.1-debug.apk`, build 14. Firma de desarrollo
conservada; instalar encima con `adb install -r`, sin desinstalar para no perder
escenarios/progreso. Instrucciones completas en ../README_FINAL.md y aceptación
en MATRIZ_ACEPTACION.md. Abrir Ejemplos locales/Guía rápida/Acerca de y licencias.
Exportar diagnóstico TXT además de JSON/PNG: el puente admite ahora ese tipo.

Se intentó arrancar Medium_Phone_API_37.0 con WHPX, dos núcleos, 1536 MiB solicitados
y GPU swiftshader, sin ventana/audio/snapshot. ADB quedó offline; no se instaló la
app. Se detuvo el emulador sin borrar datos. No hay teléfono y el usuario eligió
continuar sin uno. Se documentan pendientes; no se anuncia 1.0.0 estable ni FPS.
Una firma release diferente no actualiza el paquete debug: planificar conservación
de datos antes de cambiar de canal. Nunca desinstalar para resolver un conflicto
de firma sin haber conservado los datos necesarios.

## Actualización del Editor — 1.0.0-rc.2+15

APK actual: `build/releases/heroclix-1.0.0-rc.2-debug.apk`, misma firma y paquete,
para instalar encima sin desinstalar. En Editor → Terrenos probar los tres iconos
centrados bajo el mapa: seleccionar no debe pintar. Probar trazo y rectángulo,
Deshacer/Rehacer, giro y texto ampliado. Sobre suelo, Alturas debe proponer 2;
una altura existente 3 debe seguir mostrando 3 y aceptar volver a 1.

Personajes → casilla vacía debe colocar sin formulario con valores predeterminados.
Seleccionar y pulsar lápiz debe editar la misma figura. Colocar varias, deshacer,
rehacer y cerrar/reabrir con autoguardado. Bloqueado pide confirmación para estudio.
Estas interacciones están cubiertas por Flutter/renders en Windows; el recorrido
nativo continúa pendiente. Resultados y hash actuales en ESTADO.md.

## Sesión temporal y visión inmediata — 1.0.0-rc.3+16

APK de rc.3: `build/releases/heroclix-1.0.0-rc.3-debug.apk`, misma firma/paquete para
instalar encima sin desinstalar. La sesión de Editor ya no se recupera al abrir:
guarda en biblioteca lo que quieras conservar. Las figuras nuevas empiezan desde A
en cada apertura. Cambiar de sección y volver desde segundo plano conserva la
sesión si la instancia sigue activa; el progreso del Entrenador permanece guardado.

Para comprobarlo: llegar hasta AA, guardar una copia, cerrar completamente y abrir.
Debe aparecer mapa vacío; colocar una figura debe generar A. La copia de biblioteca
debe seguir disponible al abrirla manualmente. Repetir sin guardar y comprobar que
los cambios temporales no se recuperan. No borrar datos del paquete para probar.

En Línea de visión, elegir dos figuras debe mostrar inmediatamente el dictamen
sobre el mapa; tocarlo abre referencias. Probar despejada/H/B/No evaluada, borrar un
extremo, limpiar línea, giro y texto ampliado. Regresiones/archivos/controladores
verificados en Windows; cierre real, pausa Android, TalkBack y rendimiento siguen
pendientes de dispositivo.

## Editor y transiciones — candidata rc.4

APK: build/releases/heroclix-1.0.0-rc.4-debug.apk. Instalar encima con la misma
firma; no desinstalar para conservar biblioteca y progreso. Los apartados por
etapa anteriores describen aquellas versiones; la navegación vigente es esta:

1. Inicio contiene Editor y Entrenador; no debe ofrecer Simulador ni Árbitro.
2. Editor: crear dos figuras y consultar Visión, Distancia, Objetivos, Movimiento
   y Analizar posición desde sus herramientas. El dictamen aparece sobre el mapa.
3. En Alturas y transiciones, elevar B1 a 2 y añadir transición A1/B1. Comprobar
   triángulo de nivel 1 dentro de A1 y de nivel 2 dentro de B1. Repetir A2/A3 para
   la orientación horizontal y niveles 2/3. Una elevación sin transición conserva E2.
4. Probar Deshacer/Rehacer, retirar transición, Guardar/abrir y exportar JSON/PNG.
   Los símbolos deben coincidir en mapa y PNG y los niveles no deben cambiar.
5. Probar giro, texto al 300 %, mapa pequeño/grande y transición bajo una figura.
   Biblioteca, ejercicios/progreso y nueva sesión vacía deben conservar su comportamiento.

Pruebas Flutter/Windows y metadatos del APK en ESTADO.md. Instalación, interacción
Android, TalkBack y rendimiento siguen pendientes; se mantiene la decisión del
usuario de continuar sin teléfono. No se afirma aceptación nativa ni versión estable.

## Incrementos del Editor — candidata rc.5

APK: build/releases/heroclix-1.0.0-rc.5-debug.apk. Instalar encima, sin desinstalar.
Recorrido pendiente en dispositivo:

1. Nuevo escenario: 10×10. Abrir un guardado antiguo mantiene su tamaño original.
2. Terrenos: comprobar los cinco iconos, también con giro y texto ampliado.
   Elegir Elevado y tocar B2 crea E2; repetir crea E3. Pintar H y luego Despejado
   mantiene E3. Probar ajustes de zoom manual y ajuste automático al abrir barras.
3. Transición: tocar dos vecinos de alturas diferentes, sin muro compartido.
   Debe aparecer el par de triángulos. Igual casilla/nivel, diagonal, salto o muro
   deben anunciar error y no pintar. Cambiar pincel descarta el extremo pendiente.
4. Borrar: probar figura, terreno, elevación y transición; verificar otras capas y
   Deshacer/Rehacer. Para transición, tocar el borde compartido.
5. Seleccionar: tocar dos veces una casilla con figura/H/E2. Confirmar y comprobar
   prioridad personaje→terreno→elevación; Cancelar no elimina. Repetir en vacío.
6. Ficha: no hay permiso sobre bloqueado ni Otra excepción. Abrir Improved Targeting,
   marcar varias mejoras y guardar. Bloqueado rechaza colocar, mover y editar una
   figura, y pintar bajo ella; las bases completas también se validan.
7. Visión: dictamen solo arriba del mapa. Elegir origen igual a destino limpia
   línea, referencias y selección; después debe poder trazarse otra línea normal.
8. Biblioteca, escenarios JSON/PNG, Entrenador/progreso y nuevo arranque A siguen
   disponibles. Los datos antiguos incompatibles se conservan para corregirlos.

No ejecutado en Android: se mantiene la instrucción de continuar sin teléfono.
Capturas y tests Flutter/Windows no sustituyen instalación, TalkBack, selectores,
proceso real ni rendimiento. La entrega continúa candidata debug.

## Equipos y trazos — candidata actual 1.0.0-rc.6+19

APK: build/releases/heroclix-1.0.0-rc.6-debug.apk. Instalar encima sin desinstalar.
Recorrido todavía pendiente en dispositivo:

1. Personajes: colocar A (T1), tocar dos veces la figura existente y comprobar T2;
   otro par vuelve a T1. Crear un tercer equipo en la ficha y probar T1/T2/T3/T1.
   Verificar nombre, base, atributos, capacidades, ID/etiqueta y Deshacer/Rehacer.
2. Activar herramientas: ayuda vertical al lado derecho durante cuatro segundos.
   Probar giro/texto y cambiar de herramienta antes de que expire; debe renovarse.
   Tocar/arrastrar sobre el mapa sigue funcionando y la cámara no cambia por el aviso.
3. Elevar: montar una fila de niveles 1/2/3, trazar de un extremo al otro y volver
   sin levantar el dedo. La vista previa debe anunciar 2/3/4; al soltar se aplican
   una sola vez. Otro trazo vuelve a subir. H/B se conservan; probar Deshacer/Rehacer.
4. Probar una base múltiple: recorrer su región completa permite elevarla sin un
   estado intermedio inválido. Una región parcial o E40 debe rechazar atómicamente.
5. Borrar: al activarlo debe decir Borrar todo. Trazar sobre figuras, H/B, altura,
   muros y transiciones debe dejar esas casillas en suelo despejado. Una base tocada
   se elimina completa. Comprobar otras casillas intactas y recuperación con Deshacer.
6. Cancelar un trazo y añadir un segundo dedo no deben aplicar elevación ni borrado.
   Probar zoom/pan, trazos rápidos y un trazo vacío. El contador de figuras no se recicla.
7. Verificar biblioteca/JSON/PNG/progreso y cierre/nuevo arranque como en rc.5.

No ejecutado en Android: continúa la decisión de trabajar sin teléfono. Los tests,
capturas Flutter y metadatos del APK no sustituyen instalación, gestos nativos,
TalkBack, radios apagadas, selectores, ciclo de proceso ni rendimiento.