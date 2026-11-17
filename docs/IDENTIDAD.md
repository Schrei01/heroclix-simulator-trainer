# TeamFight: GridLab — identidad de la aplicación

Nombre visible: **TeamFight: GridLab**. AppInfo.name centraliza el nombre Flutter;
Android usa @string/app_name. Inicio y Acerca de muestran el símbolo del paquete
aportado, y la página de licencias usa el mismo nombre.

## Recursos originales

Origen: TeamFight_GridLab_PNGs_Android_PlayStore.zip, suministrado por el usuario.
SHA-256: 3BCC963DFF16B30ECE37941104569C31F8BEB867B85EA920805699A479AE1FAE.
Los PNG y XML de iconos se copian sin modificarlos. LEEME.txt se consulta como
referencia del paquete; el alcance solicitado es integrar los iconos y el nombre.

| Recurso Android | mdpi | hdpi | xhdpi | xxhdpi | xxxhdpi |
| --- | --- | --- | --- | --- | --- |
| ic_launcher / ic_launcher_round | 48 | 72 | 96 | 144 | 192 |
| foreground / background / monochrome | 108 | 162 | 216 | 324 | 432 |

Dimensiones en píxeles, imágenes cuadradas. Los 25 PNG están en las cinco carpetas
mipmap por densidad. Dos XML de mipmap-anydpi-v26 componen fondo, primer plano y
monocromo. AndroidManifest referencia @mipmap/ic_launcher y @mipmap/ic_launcher_round.
Se retira el antiguo vector genérico @drawable/app_icon, ya sin referencias.

La configuración sigue el [formato de iconos adaptables de Android](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).
Su aspecto con máscaras y temas concretos depende del launcher y se comprueba en
dispositivo. Recursos aportados de Google Play: distribution/google-play/. El
símbolo para Flutter está en assets/branding/gridlab_icon.png, 512×512.

## Compatibilidad de actualización

Se conserva applicationId com.valinor.heroclixtrainer, namespace, canales nativos,
directorios privados y firma. El nombre interno del paquete Dart también continúa
para conservar imports. La marca visible cambia sin crear otra app ni migrar datos.
Instalar encima sin desinstalar conserva biblioteca/progreso; la sesión temporal
mantiene el comportamiento documentado. No cambian reglas, formatos ni permisos.

La nueva candidata es 1.0.0-rc.8+21. APK y evidencia exacta en ESTADO.md. Pruebas
Flutter/Windows y recursos compilados comprobados; icono en launcher, máscaras,
temas, splash y actualización real continúan pendientes de Android por la decisión
previa de continuar sin teléfono.