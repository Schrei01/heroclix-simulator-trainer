import 'package:flutter_test/flutter_test.dart';

import 'support/geometry_contract.dart';

void main() {
  for (final entry in geometryCases().entries) {
    test(entry.key, entry.value);
  }
}
