// ignore_for_file: avoid_print
import '../test/support/tactics_contract.dart';

void main() {
  var passed = 0;
  for (final c in tacticsCases().entries) {
    c.value();
    print('OK ${c.key}');
    passed++;
  }
  print(
    '$passed/${tacticsCases().length} contratos de análisis táctico aprobados.',
  );
}
