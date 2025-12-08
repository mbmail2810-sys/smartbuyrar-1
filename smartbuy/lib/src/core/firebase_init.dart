import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smartbuy/firebase_options.dart';

Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // 🔥 Enables offline cache
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
