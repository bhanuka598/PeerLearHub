import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<({Uint8List bytes, String fileName})?> pickLocalImageBytes() async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.single;
  var bytes = file.bytes;
  if ((bytes == null || bytes.isEmpty) && file.path != null) {
    bytes = await File(file.path!).readAsBytes();
  }
  if (bytes == null || bytes.isEmpty) return null;
  return (bytes: bytes, fileName: file.name);
}
