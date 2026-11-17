// ignore_for_file: avoid_print
import '../test/support/movement_contract.dart';

void main() {
  var passed = 0;
  for (final c in movementCases().entries) {
    c.value();
    passed++;
    print('OK ${c.key}');
  }
  print('$passed/${movementCases().length} contratos de movimiento aprobados.');
}
