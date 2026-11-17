import 'package:flutter_test/flutter_test.dart';

import 'support/tactics_contract.dart';

void main() {
  for (final c in tacticsCases().entries) {
    test(c.key, c.value);
  }
}
