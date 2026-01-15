// Este archivo solo debe importarse en web
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

/// Descarga un archivo en web
String downloadFileWeb(List<int> fileBytes, String fileName) {
  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return 'Descargado: $fileName';
}


