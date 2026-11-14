/// Puerto para futuros adaptadores locales. No realiza I/O en las etapas 00–01.
///
/// Los IDs son opacos: el adaptador deberá validarlos y no interpretarlos como
/// rutas arbitrarias. Las operaciones fallidas deberán comunicar el error sin
/// modificar el documento anterior. La escritura deberá ser atómica.
abstract interface class LocalDocumentStore {
  Future<String?> read(String id);

  Future<void> write(String id, String document);

  Future<void> delete(String id);
}
