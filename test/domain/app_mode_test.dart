import 'package:flutter_test/flutter_test.dart';
import 'package:heroclix_simulator_trainer/domain/app_mode.dart';

void main() {
  test('los identificadores conservan la identidad de todos los modos', () {
    expect(AppMode.values.map((mode) => mode.id).toSet(), hasLength(4));
    for (final mode in AppMode.values) {
      expect(AppMode.tryParse(mode.id), same(mode));
    }
  });

  test('un modo desconocido no abre accidentalmente otro modo', () {
    expect(AppMode.tryParse(''), isNull);
    expect(AppMode.tryParse('modo-futuro'), isNull);
    expect(AppMode.tryParse('EDITOR'), isNull);
  });
}
