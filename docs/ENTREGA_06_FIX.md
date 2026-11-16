# Entrega archivada — corrección de la etapa 06 (0.7.1+8)

2026-11-16 (America/Bogota). App **0.7.1+8**.
Rama: `codex/prompt-06` del repositorio privado
https://github.com/Schrei01/heroclix-simulator-trainer.
Informe de la primera entrega 06 (0.7.0+7): [ENTREGA_06](ENTREGA_06.md).

## A. Operativo y preparado

Se corrige el reporte del usuario: figuras normales en A1 y D6, terreno bloqueado
solo en B4. El motor devuelve **DESPEJADA**; B4 solo toca el vértice (2,3) y C3 es
el otro lado, libre. El registro muestra ambas alternativas y aplica §16.8b.
Antes, un rechazo por pendiente distinta de 45° devolvía No evaluada. R23 reprodujo
ese fallo antes de modificar el servicio; el log rojo se conserva localmente.

Se elimina ese rechazo y se reutiliza el mismo procedimiento de intersecciones,
con geometría exacta, terreno, figuras y muros incidentes. No se desvía la línea.
Si ambos lados bloquean, la línea queda bloqueada; si el menos restrictivo es H,
queda obstaculizada. Los obstáculos atravesados por el interior siguen contando.
Editor, Simulador y Árbitro reciben la corrección mediante el servicio compartido.
No se añade funcionalidad de 07 ni se amplían poderes/elevaciones/bases múltiples.

## B. Archivos principales

- `lib/domain/rules/line_of_sight_service.dart`: retirar la restricción de pendiente.
- `test/support/vision_contract.dart`: corregir R17 y añadir R23–R25.
- `tool/preview_test.dart`: render de A1–D6 con B4 bloqueado.
- `pubspec.yaml`: versión 0.7.1+8, sin dependencias nuevas.
- README, ANDROID, MATRIZ_REGLAS_VISION, REGLAS, ROADMAP, DECISIONES y este informe.
  ENTREGA_06 conserva los resultados de la primera entrega sin reescribirlos.

## C. Verificación real

| Comando | Resultado |
| --- | --- |
| `dart run tool/verify_vision.dart` antes del arreglo | R23 falla: No evaluada en lugar de despejada; 22/23 pasan. |
| `dart run tool/verify_vision.dart` después del arreglo | **25/25 contratos aprobados**. |
| `dart format --output=none --set-exit-if-changed lib test tool` | **75 archivos, 0 cambios**, 2,06 s. |
| `flutter --no-version-check analyze --no-pub` | **No issues found**, 67,3 s. |
| `flutter --no-version-check test --no-pub --reporter expanded` | **208 aprobadas**, 126 s. |
| `flutter --no-version-check test tool/preview_test.dart --no-pub --reporter expanded` | **31 renders aprobados**, 36 s. A1–D6/B4 revisado visualmente: línea verde y DESPEJADA. |
| `flutter --no-version-check build apk --debug --no-pub` | **Correcto**, 119,5 s. |
| `aapt dump badging` / `dump permissions` | 0.7.1/código 8, SDK 24/36, sin INTERNET ni almacenamiento amplio. |
| `apksigner verify --verbose --print-certs` | **Verifies**, v2 válida; mismo certificado que 0.7.0+7. |

R23 comprueba A1–D6 y el sentido inverso, el contacto puntual con B4 y la elección
de C3 en el registro. R24 compara los nueve pares de terreno de B4/C3, ambos
sentidos, figuras laterales, bloqueos interiores y el límite de elevación. R25
cubre los 16 subconjuntos de muros incidentes en ambos sentidos. R17 comprueba
una línea oblicua con varios vértices. Las expectativas proceden de §16.8b y están
registradas en [MATRIZ_REGLAS_VISION](MATRIZ_REGLAS_VISION.md).

Logs locales ignorados por Git: `build/vision-fix-red.log`, `vision-fix-green.log`,
`format-06-fix.log`, `analyze-06-fix.log`, `test-06-fix.log`, `preview-06-fix.log`
y `build-06-fix.log`, además de `signature-06-fix.log`. Los resultados nativos
de 0.7.0+7 están archivados en
ENTREGA_06 y no se presentan como un recorrido del APK 0.7.1+8.

### APK actualizado

- `build/releases/heroclix-prompt-06-fix-debug.apk`, versión 0.7.1, código 8.
- Tamaño: **158175501 bytes**.
- SHA-256: `F33F8E3C2242C52302B623391991F9FE1DDB8858AF2AFD3BF32A52AA84BAEFC2`.
- Se conserva `heroclix-prompt-06-debug.apk` de 0.7.0+7 sin sobrescribirlo.
- APK, logs, fixtures y renders quedan fuera de Git.

## D. Comprobación manual

1. Instalar la actualización sobre la app existente; no hace falta borrar datos.
2. Crear un tablero de al menos 4 columnas por 6 filas, figuras normales 1×1 en
   A1 y D6 y terreno bloqueado solo en B4. Desactivar Efectos especiales.
3. Consultar Dictamen de visión: **DESPEJADA**. Abrir Registro y referencias:
   B4 es el lado bloqueado y C3, el lado libre usado por §16.8b.
4. Añadir bloqueado en C3: **BLOQUEADA**. Cambiar C3 a H: **OBSTACULIZADA**.
5. Dejar C3 libre y añadir bloqueado en B3: **BLOQUEADA**, por cruce interior.
6. Invertir los extremos y comprobar el mismo resultado en estos ejemplos.

## E. Límites y pendientes

El perfil sigue limitado a figuras normales sin poderes y tablero plano.
Elevaciones/bases múltiples relevantes, efectos especiales declarados, versión
sin soporte, ocupación incompatible y clasificación a sí mismo sobre H siguen
No evaluadas. No se comprueban alcance ni legalidad completa de un ataque.
Sin migración JSON, permisos nuevos ni cambios del editor. No se ha realizado
un nuevo recorrido nativo de 0.7.1+8 ni una prueba de teléfono físico o release.

## F. Fuente y documentación

Se revisaron de nuevo la página oficial y el PDF 2026-07-01, §16.8b, página
impresa 44. El procedimiento de intersecciones no impone pendiente global de 45°;
la mención introductoria de diagonales en 16.8 se había convertido indebidamente
en una restricción del producto. Se conserva la misma edición de reglas.
Matriz, decisiones, guía Android y hoja de ruta actualizadas.

## G. Límite de etapa

**No se inició Prompt 07.** Esta revisión corrige el motor de visión de 06.
