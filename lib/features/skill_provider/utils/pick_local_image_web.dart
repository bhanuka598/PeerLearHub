// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<({Uint8List bytes, String fileName})?> pickLocalImageBytes() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;

  // Mobile browsers block a programmatic click on display:none inputs.
  // Keep the control in the document, but visually clip it.
  input.style
    ..position = 'fixed'
    ..left = '0'
    ..top = '0'
    ..width = '1px'
    ..height = '1px'
    ..opacity = '0'
    ..border = '0'
    ..padding = '0'
    ..margin = '0'
    ..overflow = 'hidden';

  final completer = Completer<({Uint8List bytes, String fileName})?>();
  var selectionStarted = false;
  final openedAt = DateTime.now();

  input.onChange.listen((_) async {
    selectionStarted = true;
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

  final focusSub = html.window.onFocus.listen((_) {
    if (DateTime.now().difference(openedAt) < const Duration(milliseconds: 400)) {
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!completer.isCompleted && !selectionStarted) {
        completer.complete(null);
      }
    });
  });

  html.document.body?.append(input);
  input.click();

  try {
    return await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => null,
    );
  } finally {
    await focusSub.cancel();
    input.remove();
  }
}
