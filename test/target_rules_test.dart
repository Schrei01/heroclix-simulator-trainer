import 'package:flutter_test/flutter_test.dart';

import 'support/target_contract.dart';

void main() {
  for (final entry in targetCases().entries) {
    test(entry.key, entry.value);
  }
}
