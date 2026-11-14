/// Identificadores estables, independientes del idioma y de Flutter.
enum AppMode {
  editor('editor'),
  simulator('simulator'),
  trainer('trainer'),
  referee('referee');

  const AppMode(this.id);

  final String id;

  /// Un identificador futuro o desconocido nunca selecciona otro modo.
  static AppMode? tryParse(String id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}
