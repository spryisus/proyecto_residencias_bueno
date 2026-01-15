// Stub para cuando dart:html no está disponible (móvil/desktop)

/// Stub que nunca se ejecuta en móvil/desktop
String downloadFileWeb(List<int> fileBytes, String fileName) {
  // Esta función nunca se llama en móvil/desktop porque kIsWeb se verifica antes
  throw UnsupportedError('downloadFileWeb solo está disponible en web');
}


