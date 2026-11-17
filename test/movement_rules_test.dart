import 'package:flutter_test/flutter_test.dart';

import 'support/movement_contract.dart';

void main() {
  for (final entry in movementCases().entries) {
    test(entry.key, entry.value);
  }
}
