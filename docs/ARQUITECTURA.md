# Arquitectura

## Dependencias

`presentación → aplicación → dominio`. La infraestructura implementará los
puertos de aplicación. El punto de entrada compone las dependencias; el dominio
no importa Flutter, infraestructura ni plataforma.

| Ruta | Responsabilidad actual |
| --- | --- |
| `lib/main.dart` | Arranque Flutter |
| `lib/app.dart` | MaterialApp, idioma y tema |
| `lib/domain/` | Tipos puros, sin widgets ni acceso a plataforma |
| `lib/application/` | Catálogo del inicio y puertos de persistencia |
| `lib/presentation/` | Pantalla de inicio y tema |
| `lib/infrastructure/local/` | Reserva documentada para almacenamiento futuro |
| `android/` | Adaptación nativa, identidad y configuración de build |
| `test/` | Contratos de dominio y pruebas de widgets |

Los módulos de dominio previstos son board, characters, terrain, geometry,
rules, movement y training. Sus carpetas contienen documentación de alcance;
no implementan modelos futuros ni servicios vacíos que aparenten funcionar.

## Estado y persistencia

El inicio usa un catálogo inmutable. No existe todavía un escenario, cámara,
controlador global ni base de datos. Cuando se añada el escenario habrá una sola
fuente de verdad, con posiciones lógicas y operaciones atómicas de dominio.

`LocalDocumentStore` define un puerto independiente de Flutter para leer,
escribir y eliminar documentos locales. No tiene adaptador de producción en 00;
los fallos se comunicarán al consumidor y nunca destruirán la sesión activa.
Serialización, schemaVersion, migraciones e historial corresponden a 04.

## Motor futuro

Geometría emitirá intersecciones; reglas interpretará sus efectos; la UI
representará resultados estructurados. Editor, Simulador, Entrenador y Árbitro
consumirán los mismos servicios. Las condiciones no soportadas devolverán
«No evaluado». No existe dictamen reglamentario en esta etapa.

## Plataforma y red

Solo se genera Android. No se bloquean orientaciones. El diseño usa restricciones
de ancho, ajuste del texto y desplazamiento vertical. No hay clientes HTTP,
cuentas, telemetría, fuentes remotas ni assets descargados en runtime.
