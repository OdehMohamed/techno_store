import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageServices {
  FirebaseStorageServices._();

  static final instance = FirebaseStorageServices._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file and return its download URL
  Future<String?> uploadFile({
    required File file,
    required String folderPath, // Example: "Images/users"
    String? customFileName, // Optional: provide your own filename
  }) async {
    try {
      final fileName = customFileName ?? const Uuid().v4();
      final ref = _storage.ref().child('$folderPath/$fileName');
      final TaskSnapshot uploadTask;
      if (kIsWeb) {
        uploadTask = await ref.putData(await file.readAsBytes());
      } else {
        uploadTask = await ref.putFile(file);
      }

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  /// Get download URL of a file by its path
  Future<String?> getDownloadURL({required String filePath}) async {
    try {
      final ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Get URL error: $e');
      return null;
    }
  }

  /// Delete a file from storage using its full path
  Future<void> deleteFileByPath({required String filePath}) async {
    try {
      final ref = _storage.ref().child(filePath);
      await ref.delete();
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  /// Delete a file from storage using its download URL
  Future<void> deleteImageByUrl({required String imageUrl}) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Delete by URL error: $e');
    }
  }
}
