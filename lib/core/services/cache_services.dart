import 'package:shared_preferences/shared_preferences.dart';
import 'package:techno_store/core/model/user_data.dart';

class CacheServices {
  final _sharedPreferences = SharedPreferences.getInstance();

  Future<void> setString(String key, String value) async {
    final sharedPreferences = await _sharedPreferences;
    sharedPreferences.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final sharedPreferences = await _sharedPreferences;
    return sharedPreferences.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    final sharedPreferences = await _sharedPreferences;
    sharedPreferences.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final sharedPreferences = await _sharedPreferences;
    return sharedPreferences.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    final sharedPreferences = await _sharedPreferences;
    sharedPreferences.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final sharedPreferences = await _sharedPreferences;
    return sharedPreferences.getInt(key);
  }

  Future<void> setDouble(String key, double value) async {
    final sharedPreferences = await _sharedPreferences;
    sharedPreferences.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final sharedPreferences = await _sharedPreferences;
    return sharedPreferences.getDouble(key);
  }

  Future<void> setStringList(String key, List<String> value) async {
    final sharedPreferences = await _sharedPreferences;
    sharedPreferences.setStringList(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    final sharedPreferences = await _sharedPreferences;
    return sharedPreferences.getStringList(key);
  }

  Future<void> remove(String key) async {
    final sharedPreferences = await _sharedPreferences;
    sharedPreferences.remove(key);
  }

  Future<void> clear() async {
    final sharedPreferences = await _sharedPreferences;
    sharedPreferences.clear();
  }

  Future<UserData> getUserData() async {
    final sharedPreferences = await _sharedPreferences;
    final uid = sharedPreferences.getString('uid');
    final phoneNumber = sharedPreferences.getString('phoneNumber');
    final email = sharedPreferences.getString('email');
    final photoURL = sharedPreferences.getString('photoURL');
    final name = sharedPreferences.getString('name');
    final type = sharedPreferences.getInt('type');

    final userData = UserData(
      uid: uid!,
      phoneNumber: phoneNumber ?? '',
      email: email,
      photoURL: photoURL,
      name: name,
      type: type!,
    );
    return userData;
  }

  Future<void> saveUserData(UserData? userData) async {
    if (userData == null) return;

    final sharedPreferences = await _sharedPreferences;
    await sharedPreferences.setString('uid', userData.uid);
    await sharedPreferences.setString('phoneNumber', userData.phoneNumber);
    // await sharedPreferences.setString('email', userData.email);
    await sharedPreferences.setString('photoURL', userData.photoURL ?? '');
    await sharedPreferences.setString('name', userData.name ?? '');
    await sharedPreferences.setString('location', userData.location ?? '');
    await sharedPreferences.setString('nickname', userData.nickname ?? '');
    await sharedPreferences.setInt('type', userData.type);
  }
}
