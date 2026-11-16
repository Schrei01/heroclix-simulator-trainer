import 'dart:io';

import '../test/support/vision_contract.dart';

void main() {
  var passed = 0;
  for (final entry in visionCases().entries) {
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
    '$passed/${visionCases().length} contratos de visión aprobados en Dart puro.',
  );
}
