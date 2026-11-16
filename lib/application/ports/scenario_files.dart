import 'dart:typed_data';

final class PickedScenario {
  const PickedScenario(this.bytes, this.name);
  final Uint8List bytes;
  final String name;
}

abstract interface class ScenarioFiles {
  Future<String> privateDirectory();
  Future<PickedScenario?> pickJson();
  Future<bool> saveFile(Uint8List bytes, String name, String mime);
  Future<void> shareFile(Uint8List bytes, String name, String mime);
}
