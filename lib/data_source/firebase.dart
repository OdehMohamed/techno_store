import 'package:firebase_auth/firebase_auth.dart';
import 'package:techno_store/shared/message.dart';

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

  Future<void> signUp(String email, String password) async {
    try {
      await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) => print(value.user?.email));
    } catch (e, v) {
      Message.showErrorToastMessage(e.toString());
      print(e.toString() + "----->" + v.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e, v) {
      print(e.toString() + "----->" + v.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    print("rrrrrrrrrrrrrrrrrrr");
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email).onError((error, stackTrace) => print(error));
    } catch (e, v) {
      print(e.toString() + " -----> " + v.toString());
    }
  }
}
