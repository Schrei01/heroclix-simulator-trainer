/// Input syntax only. Action totals and game legality are checked by the engine.
String? priorityIntegerError(String? text) {
  final number = int.tryParse(text?.trim() ?? '');
  return number == null || number < 0
      ? 'Escribe un entero igual o mayor que cero.'
      : null;
}

Duration? priorityDurationInput(
  String minutes,
  String seconds, {
  bool allowZero = false,
}) {
  final m = BigInt.tryParse(minutes.trim());
  final s = BigInt.tryParse(seconds.trim());
  if (m == null ||
      s == null ||
      m.isNegative ||
      s.isNegative ||
      s >= BigInt.from(60)) {
    return null;
  }
  final micros = (m * BigInt.from(60) + s) * BigInt.from(1000000);
  if ((!allowZero && micros == BigInt.zero) ||
      micros > BigInt.from(0x7fffffffffffffff)) {
    return null;
  }
  return Duration(microseconds: micros.toInt());
}

String priorityTimeLabel(Duration time, {bool roundUp = true}) {
  final seconds =
      time.inSeconds + (roundUp && time.inMicroseconds % 1000000 != 0 ? 1 : 0);
  String pad(int n) => '$n'.padLeft(2, '0');
  final minutes = pad(seconds ~/ 60 % 60);
  final tail = pad(seconds % 60);
  return seconds >= 3600
      ? '${pad(seconds ~/ 3600)}:$minutes:$tail'
      : '$minutes:$tail';
}

int priorityWholeMinutes(Duration time) =>
    time.inMinutes +
    (time.inMicroseconds % Duration.microsecondsPerMinute == 0 ? 0 : 1);
