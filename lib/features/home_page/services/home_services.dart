import 'package:flutter/material.dart';
import 'package:techno_store/core/model/user_data.dart';
import 'package:techno_store/core/services/auth_services.dart';
import 'package:techno_store/core/services/cache_services.dart';
import 'package:techno_store/core/services/firestore_services.dart';

class HomeServices {
  final CacheServices _cacheServices = CacheServices();
  final FirestoreServices _firestoreServices = FirestoreServices.instance;
  final AuthServices _authServices = AuthServices();

  Future<UserData?> getUserData() async {
    final userId = _authServices.currentUser!.uid;
    final userIdFromCache = await _cacheServices.getString('uid');
    debugPrint('User ID from cache: $userIdFromCache');
    debugPrint('Current user ID: $userId');
    if (userIdFromCache != null && userIdFromCache == userId) {
      debugPrint('Fetching user data from cache for userId: $userId');
      return await _cacheServices.getUserData();
    }

    UserData? userData = await _firestoreServices.getUserData(userId);
    await _cacheServices.saveUserData(userData);
    return userData;
  }
}
