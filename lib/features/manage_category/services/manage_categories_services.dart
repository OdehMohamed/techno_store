import 'package:techno_store/core/services/auth_services.dart';
import 'package:techno_store/core/services/firebase_storage_services.dart';
import 'package:techno_store/core/services/firestore_services.dart';

class ManageCategoriesServices {
  final AuthServices _authServices = AuthServices();
  final FirestoreServices _firestoreServices = FirestoreServices.instance;
  final FirebaseStorageServices _firebaseStorageServices =
      FirebaseStorageServices.instance;
}
