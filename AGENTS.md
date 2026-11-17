# APK entregables

- Genera el APK con `./tool/build_apk.ps1` (debug) o `./tool/build_apk.ps1 -Mode release`.
- Conserva únicamente el APK entregable más reciente en `build/releases/`.
  El script compila, verifica paquete/versión/firma y comprueba la copia antes de
  eliminar los APK anteriores de esa carpeta. Si falla la compilación o la
  validación, conserva los anteriores.
- Esta petición del usuario sustituye la política antigua de archivar todos los
  APK. Los informes históricos y el código siguen disponibles en Git.
- No uses `flutter clean` para esta limpieza ni borres otros archivos o carpetas.
  Las salidas técnicas actuales de Flutter/Gradle pueden mantenerse en `build/app/`.
- Si modificas el flujo de APK, ejecuta `./tool/test_apk_workflow.ps1`.
