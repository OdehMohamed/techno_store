// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserData {
  final String uid;
  final String phoneNumber;
  final String? location;
  final String? photoURL;
  final String? name;
  final String? nickname;
  final String? email;
  final int type;
  UserData({
    required this.uid,
    required this.phoneNumber,
    this.location,
    this.photoURL,
    this.name,
    this.nickname,
    this.email,
    this.type = 1,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'phoneNumber': phoneNumber,
      'location': location,
      'nickname': nickname,
      'email': email,
      'photoURL': photoURL,
      'name': name,
      'type': type,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map, [String? documentID]) {
    return UserData(
      uid: documentID ?? map['uid'] as String,
      // Staff accounts (created directly in Firestore, not through
      // completeUserProfile) have no phoneNumber field at all — phone is a
      // customer/phone-OTP concept. Default rather than crash; matches
      // completeUserProfile's own `?? ''` fallback for the same field.
      phoneNumber: map['phoneNumber'] != null ? map['phoneNumber'] as String : '',
      // location is declared nullable — read it as such. (Previously cast
      // to non-nullable String, crashing on any document without it, e.g.
      // any staff account.)
      location: map['location'] != null ? map['location'] as String : null,
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
    String? phoneNumber,
    String? location,
    String? nickname,
    String? photoURL,
    String? name,
    String? email,
    int? type,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      nickname: nickname ?? this.nickname,
      photoURL: photoURL ?? this.photoURL,
      name: name ?? this.name,
      email: email ?? this.email,
      type: type ?? this.type,
    );
  }
}
