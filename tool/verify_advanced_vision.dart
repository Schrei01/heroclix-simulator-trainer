import 'dart:io';

import '../test/support/advanced_vision_contract.dart';

void main() {
  var passed = 0;
  for (final entry in advancedCases().entries) {
    try {
      entry.value();
      passed++;
      stdout.writeln('PASS ${entry.key}');
    } catch (e, s) {
      stderr.writeln('FAIL ${entry.key}: $e\n$s');
      exitCode = 1;
    }
  }
  stdout.writeln(
    '$passed/${advancedCases().length} contratos de elevación/bases/capacidades aprobados en Dart puro.',
  );
}
