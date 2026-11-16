enum TeamPattern { solid, stripes, dots }

final class Team {
  factory Team({
    required String id,
    required String code,
    required String name,
    required int color,
    required TeamPattern pattern,
  }) {
    if (id.trim().isEmpty || code.trim().isEmpty) {
      throw ArgumentError('Equipo sin identidad.');
    }
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 40) {
      throw ArgumentError('El equipo necesita un nombre de 1 a 40 caracteres.');
    }
    if (color < 0xff000000 || color > 0xffffffff) {
      throw ArgumentError('El color debe ser opaco.');
    }
    return Team._(id, code, cleaned, color, pattern);
  }

  const Team._(this.id, this.code, this.name, this.color, this.pattern);
  static const blue = Team._(
    'team-1',
    'T1',
    'Azul',
    0xff64b5f6,
    TeamPattern.solid,
  );
  static const red = Team._(
    'team-2',
    'T2',
    'Rojo',
    0xffff8a80,
    TeamPattern.stripes,
  );

  final String id;
  final String code;
  final String name;
  final int color;
  final TeamPattern pattern;
}
