/// IDs persistentes. No se interpreta texto libre de cartas.
enum VisionAbility {
  elevated('Elevación', '27.6a', true),
  hindering('Obstaculizado', '27.6b', true),
  blocking('Bloqueado y muros', '27.6c', true),
  characters('Personajes', '27.6e', true),
  destroyBlocking('Destruir bloqueado · sin soporte', '27.6d', false),
  adjacent('Ataque adyacente · sin soporte', '27.6f', false),
  other('Otra excepción · sin soporte', '19.3', false);

  const VisionAbility(this.label, this.section, this.supported);
  final String label, section;
  final bool supported;
}

enum FigureSize {
  normal,
  tiny,
  giant,
  colossal;

  String get label => switch (this) {
    normal => 'Normal',
    tiny => 'Pequeño',
    giant => 'Gigante',
    colossal => 'Colosal',
  };
}
