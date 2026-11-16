import 'package:flutter_test/flutter_test.dart';

import 'support/vision_contract.dart';

void main() {
  for (final entry in visionCases().entries) {
    test(entry.key, entry.value);
  }
}
