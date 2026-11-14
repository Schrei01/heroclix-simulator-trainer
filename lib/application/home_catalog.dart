import '../domain/app_mode.dart';

/// Catálogo inmutable. Solo el editor tiene una ruta operativa en 01.
const homeModes = <AppMode>[
  AppMode.editor,
  AppMode.simulator,
  AppMode.trainer,
  AppMode.referee,
];

const availableModes = <AppMode>{AppMode.editor};
