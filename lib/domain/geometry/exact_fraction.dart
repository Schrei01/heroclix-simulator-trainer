/// Racional normalizado. La geometría de tableros 2..40 no usa coma flotante.
final class ExactFraction implements Comparable<ExactFraction> {
  factory ExactFraction(int numerator, [int denominator = 1]) {
    if (denominator == 0) throw ArgumentError('Denominador cero.');
    if (denominator < 0) {
      numerator = -numerator;
      denominator = -denominator;
    }
    final divisor = numerator.gcd(denominator);
    return ExactFraction._(numerator ~/ divisor, denominator ~/ divisor);
  }
  const ExactFraction._(this.numerator, this.denominator);
  static const zero = ExactFraction._(0, 1);
  static const one = ExactFraction._(1, 1);
  final int numerator, denominator;
  ExactFraction operator +(ExactFraction b) => ExactFraction(
    numerator * b.denominator + b.numerator * denominator,
    denominator * b.denominator,
  );
  ExactFraction operator -(ExactFraction b) => ExactFraction(
    numerator * b.denominator - b.numerator * denominator,
    denominator * b.denominator,
  );
  ExactFraction operator *(ExactFraction b) =>
      ExactFraction(numerator * b.numerator, denominator * b.denominator);
  ExactFraction operator /(ExactFraction b) =>
      ExactFraction(numerator * b.denominator, denominator * b.numerator);
  bool get isInteger => denominator == 1;
  int get floor =>
      numerator ~/ denominator -
      (numerator < 0 && numerator % denominator != 0 ? 1 : 0);
  double toDouble() => numerator / denominator;
  @override
  int compareTo(ExactFraction other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);
  @override
  bool operator ==(Object other) =>
      other is ExactFraction &&
      numerator == other.numerator &&
      denominator == other.denominator;
  @override
  int get hashCode => Object.hash(numerator, denominator);
  @override
  String toString() =>
      denominator == 1 ? '$numerator' : '$numerator/$denominator';
}
