/// Mejoras verificadas de §27.5; no conceden permisos para terminar ocupado.
enum MovementAbility {
  elevated('Elevación', '27.5a', true),
  blocking('Bloqueado y muros', '27.5b', true),
  characters('Personajes · separación automática', '27.5e', true),
  moveThrough('Atravesar personajes · requiere separación', '27.5f', true),
  outdoorBlocking('Bloqueado exterior', '27.5c', true),
  destroyBlocking('Destruir bloqueado y muros', '27.5d', true),
  other('Otra excepción de movimiento', 'SCOPE', false);

  const MovementAbility(this.label, this.section, this.supported);
  final String label, section;
  final bool supported;
}
