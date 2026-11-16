import 'dart:io';

import '../test/support/target_contract.dart';

void main() {
  var passed = 0;
  for (final entry in targetCases().entries) {
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
    '$passed/${targetCases().length} contratos de distancia/objetivos aprobados en Dart puro.',
  );
}
