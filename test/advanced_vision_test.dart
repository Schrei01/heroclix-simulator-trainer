import 'package:flutter_test/flutter_test.dart';

import 'support/advanced_vision_contract.dart';

void main() {
  for (final entry in advancedCases().entries) {
    test(entry.key, entry.value);
  }
}
