class UserInfo{

  static String? _userId;
  static String? _userName;
  static String? _userPhoto;
  static int? _userType;

  static String? get userId => _userId;
  static set userId(String? userId) => _userId = userId;

  static String? get userName => _userName;
  static set userName(String? userName) => _userName = userName;

  static String? get userPhoto => _userPhoto;
  static set userPhoto(String? userPhoto) => _userPhoto = userPhoto;

  static int? get userType => _userType;
  static set userType(int? userType) => _userType = userType;
}