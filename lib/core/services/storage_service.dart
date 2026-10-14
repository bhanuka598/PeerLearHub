import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final StorageService instance = StorageService._();

  StorageService._();

  Future<String?> pickAndUploadDocument(String userId) async {
    // 1. Open the file picker
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      withData: true, // Needed for Web support
    );

    if (result == null || result.files.single.bytes == null) return null;

    final fileBytes = result.files.single.bytes!;
    final fileName = result.files.single.name;

    // 2. Upload to Firebase Storage
    final ref = FirebaseStorage.instance
        .ref()
        .child('verification_docs/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        
    await ref.putData(fileBytes);

    // 3. Get the real download URL
    return await ref.getDownloadURL();
  }
}
