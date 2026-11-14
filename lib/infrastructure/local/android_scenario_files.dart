import 'package:flutter/services.dart';

import '../../application/ports/scenario_files.dart';

final class AndroidScenarioFiles implements ScenarioFiles {
  static const channel = MethodChannel('com.valinor.heroclixtrainer/files');
  @override
  Future<String> privateDirectory() async =>
      (await channel.invokeMethod<String>('directory'))!;
  @override
  Future<PickedScenario?> pickJson() async {
    final result = await channel.invokeMapMethod<String, dynamic>('pickJson');
    if (result == null) return null;
    return PickedScenario(
      result['bytes'] as Uint8List,
      result['name'] as String,
    );
  }

  Map<String, Object> _arguments(Uint8List bytes, String name, String mime) => {
    'bytes': bytes,
    'name': name,
    'mime': mime,
  };
  @override
  Future<bool> saveFile(Uint8List bytes, String name, String mime) async =>
      await channel.invokeMethod<bool>(
        'saveFile',
        _arguments(bytes, name, mime),
      ) ??
      false;
  @override
  Future<void> shareFile(Uint8List bytes, String name, String mime) =>
      channel.invokeMethod<void>('shareFile', _arguments(bytes, name, mime));
}
