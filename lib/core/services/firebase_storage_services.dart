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
    final fileName = customFileName ?? const Uuid().v4();
    // Strip any trailing slash so a caller passing "folder/" can't produce a
    // "folder//file" path — the double slash is an empty path segment.
    final sanitizedFolderPath = folderPath.endsWith('/')
        ? folderPath.substring(0, folderPath.length - 1)
        : folderPath;
    final ref = _storage.ref().child('$sanitizedFolderPath/$fileName');

    // putFile and getDownloadURL are kept in separate try/catch blocks so a
    // failure log names exactly which operation (write vs. read) was denied.
    final TaskSnapshot uploadTask;
    try {
      if (kIsWeb) {
        uploadTask = await ref.putData(await file.readAsBytes());
      } else {
        uploadTask = await ref.putFile(file);
      }
    } catch (e) {
      debugPrint('putFile error: $e');
      return null;
    }

    try {
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('getDownloadURL error: $e');
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

  /// Deletes a single stored file identified by its download URL, used for
  /// cascade-deleting a device's images (see
  /// MaintenanceListServices.deleteDevice). Firebase Storage has no
  /// folder-delete primitive and the equivalent "list then delete each"
  /// approach requires a `list` permission that cannot be authorized for
  /// staff — staff detection needs a cross-service Firestore role lookup,
  /// which does not resolve during `list`-operation rule evaluation. So the
  /// cascade deletes each image by its already-known URL (an object-level
  /// `delete`, which cross-service rules do authorize) instead of listing.
  ///
  /// Unlike [deleteImageByUrl], this does NOT silently swallow errors — per
  /// the cascade's "no silent failures" requirement the caller must know if a
  /// deletion was incomplete so it can retry. The one exception is a file
  /// that's already gone (idempotency, so a retried cascade doesn't fail on
  /// the part that already succeeded).
  Future<void> deleteFileByUrl(String imageUrl) async {
    final ref = _storage.refFromURL(imageUrl);
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return; // Already deleted — not a failure, safe to retry.
      }
      rethrow;
    }
  }
}
