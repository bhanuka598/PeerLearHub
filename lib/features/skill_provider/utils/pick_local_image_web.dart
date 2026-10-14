// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<({Uint8List bytes, String fileName})?> pickLocalImageBytes() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false
    ..style.display = 'none';

  final completer = Completer<({Uint8List bytes, String fileName})?>();

  input.onChange.listen((_) async {
    final file = input.files?.first;
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final result = reader.result;
    Uint8List? bytes;
    if (result is ByteBuffer) {
      bytes = Uint8List.view(result);
    } else if (result is Uint8List) {
      bytes = result;
    }

    if (!completer.isCompleted) {
      completer.complete(
        bytes == null || bytes.isEmpty
            ? null
            : (bytes: bytes, fileName: file.name),
      );
    }
  });

  input.addEventListener('cancel', (_) {
    if (!completer.isCompleted) completer.complete(null);
  });

  html.document.body?.append(input);
  input.click();

  try {
    return await completer.future;
  } finally {
    input.remove();
  }
}
