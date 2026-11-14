import 'dart:io';

import '../test/support/geometry_contract.dart';

void main() {
  var passed = 0;
  for (final entry in geometryCases().entries) {
    try {
      entry.value();
      passed++;
      stdout.writeln('PASS ${entry.key}');
    } catch (error, stack) {
      stderr.writeln('FAIL ${entry.key}: $error\n$stack');
      exitCode = 1;
    }
  }
  stdout.writeln(
    '$passed/${geometryCases().length} contratos de geometría aprobados en Dart puro.',
  );
}
