import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:techno_store/core/model/user_data.dart';
import 'package:techno_store/core/utils/firestore_api_path.dart';

class FirestoreServices {
  FirestoreServices._();

  static final instance = FirestoreServices._();

  final _fireStore = FirebaseFirestore.instance;

  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final reference = _fireStore.doc(path);
    debugPrint('Request Data: $data');
    await reference.set(data);
  }

  Future<void> deleteData({required String path}) async {
    final reference = _fireStore.doc(path);
    debugPrint('Path: $path');
    await reference.delete();
  }

  Stream<T> documentsStream<T>({
    required String path,
    required T Function(Map<String, dynamic>? data, String documentId) builder,
  }) {
    final reference = _fireStore.doc(path);
    final snapshots = reference.snapshots();
    return snapshots.map((snapshot) => builder(snapshot.data(), snapshot.id));
  }

  Stream<List<T>> collectionsStream<T>({
    required String path,
    required T Function(Map<String, dynamic>? data, String documentId) builder,
    Query Function(Query query)? queryBuilder,
    int Function(T lhs, T rhs)? sort,
  }) {
    Query query = _fireStore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshots = query.snapshots();
    return snapshots.map((snapshot) {
      final result = snapshot.docs
          .map(
            (snapshot) => builder(
              snapshot.data() as Map<String, dynamic>,
              snapshot.id,
            ),
          )
          .where((value) => value != null)
          .toList();
      if (sort != null) {
        result.sort(sort);
      }
      return result;
    });
  }

  Future<T> getDocument<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentID) builder,
  }) async {
    final reference = _fireStore.doc(path);
    final snapshot = await reference.get();
    return builder(snapshot.data() as Map<String, dynamic>, snapshot.id);
  }

  /// Like [getDocument], but returns null instead of throwing when the
  /// document doesn't exist. Use this when the caller needs to distinguish
  /// "document is missing" from "document has this data" (e.g. deciding
  /// whether a profile already exists before writing to it).
  Future<Map<String, dynamic>?> getDocumentOrNull({
    required String path,
  }) async {
    final reference = _fireStore.doc(path);
    final snapshot = await reference.get();
    return snapshot.data();
  }

  Future<List<T>> getCollection<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) builder,
    Query Function(Query query)? queryBuilder,
    int Function(T lhs, T rhs)? sort,
  }) async {
    Query query = _fireStore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshots = await query.get();
    final result = snapshots.docs
        .map((snapshot) =>
            builder(snapshot.data() as Map<String, dynamic>, snapshot.id))
        .where((value) => value != null)
        .toList();
    if (sort != null) {
      result.sort(sort);
    }
    return result;
  }

  Future<UserData?> getUserData(String userId) async {
    return getDocument<UserData>(
      path: FirestoreApiPath.user(userId),
      builder: (data, documentID) => UserData.fromMap(data, documentID),
    );
  }

  Future<void> saveUserData(UserData userData) async {
    // Writes only the user profile document. Staff lifecycle status
    // (users/{uid}/meta/staffStatus) is a separate, staff-only concept —
    // deliberately NOT written from the client: the deployed Firestore
    // rules deny all client writes under users/{uid}/meta, and the only
    // write path is setStaffStatus (functions/index.js), per ADR-004's
    // Staff Status Architecture Pass. See AuthCubit's staff sign-in path
    // for how an absent/unreadable status document is treated (fails
    // closed — never assumed active).
    await setData(
      path: FirestoreApiPath.user(userData.uid),
      data: userData.toMap(),
    );
  }
}
