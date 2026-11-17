/// Corte fijo de esta beta: 30/12/2026 00:00 en Colombia (UTC-5).
/// Depende del reloj del dispositivo; no es una validación de licencia remota.
abstract final class BetaExpiration {
  static final deadline = DateTime.utc(2026, 12, 30, 5);
  static const label = '30 de diciembre de 2026 a las 00:00 (hora de Colombia)';

  static bool hasExpired(DateTime now) => !now.isBefore(deadline);
}
