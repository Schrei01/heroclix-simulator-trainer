import '../domain/app_mode.dart';

/// Rutas operativas; cada modo comparte los servicios reglamentarios.
const homeModes = <AppMode>[
  AppMode.editor,
  AppMode.simulator,
  AppMode.trainer,
  AppMode.referee,
];

const availableModes = <AppMode>{
  AppMode.editor,
  AppMode.simulator,
  AppMode.referee,
  AppMode.trainer,
};
