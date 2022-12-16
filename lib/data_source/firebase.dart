import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDataSource {
  static final FirebaseDataSource instance = FirebaseDataSource._internal();
  late final FirebaseAuth firebaseAuth;
  // late final FirebaseFirestore firebaseFirestore;
  // late final FirebaseStorage firebaseStorage;

  factory FirebaseDataSource() {
    return instance;
  }

  FirebaseDataSource._internal() {
    firebaseAuth = FirebaseAuth.instance;
    // firebaseFirestore = FirebaseFirestore.instance;
    // firebaseStorage = FirebaseStorage.instance;
  }

  Future<void> signIn(String email, String password) async {
    try {
      await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .then((value) => print(value.user?.email));
    } catch (e, v) {
      print(e.toString() + "----->" + v.toString());
    }
  }

  void signOut() {
    print("jjnjnjnjnnjnjjnj");
    try {
      firebaseAuth.signOut();
    } catch (e, v) {
      print(e.toString() + "----->" + v.toString());
    }
  }
}
