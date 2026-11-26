/// Input syntax only. Action totals and game legality are checked by the engine.
String? priorityIntegerError(String? text) {
  final number = int.tryParse(text?.trim() ?? '');
  return number == null || number < 0
      ? 'Escribe un entero igual o mayor que cero.'
      : null;
}
