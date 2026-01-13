// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserData {
  final String uid;
  final String? location;
  final String? photoURL;
  final String? name;
  final String? nickname;
  final String? email;
  final bool isActivated;
  final int type;
  UserData({
    required this.uid,
    this.location,
    this.photoURL,
    this.name,
    this.nickname,
    this.email,
    this.isActivated = false,
    this.type = 1,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'location': location,
      'nickname': nickname,
      'email': email,
      'photoURL': photoURL,
      'name': name,
      'type': type,
    };
  }

  Map<String, dynamic> metaToMap() {
    return <String, dynamic>{
      'isActivated': isActivated,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map, [String? documentID]) {
    return UserData(
      uid: documentID ?? map['uid'] as String,
      location: map['location'] as String,
      nickname: map['nickname'] != null ? map['nickname'] as String : null,
      photoURL: map['photoURL'] != null ? map['photoURL'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      type: map['type'] != null ? map['type'] as int : 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserData.fromJson(String source) =>
      UserData.fromMap(json.decode(source) as Map<String, dynamic>);

  UserData copyWith({
    String? uid,
    String? location,
    String? nickname,
    String? photoURL,
    String? name,
    String? email,
    bool? isActivated,
    int? type,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      location: location ?? this.location,
      nickname: nickname ?? this.nickname,
      photoURL: photoURL ?? this.photoURL,
      name: name ?? this.name,
      email: email ?? this.email,
      isActivated: isActivated ?? this.isActivated,
      type: type ?? this.type,
    );
  }
}
