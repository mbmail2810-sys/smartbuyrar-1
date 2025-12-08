// This is the auth_service.dart file.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Stream<User?> idTokenChanges() => _auth.idTokenChanges();

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Sign-in aborted by user');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    if (FirebaseAuth.instance.currentUser != null &&
        FirebaseAuth.instance.currentUser!.isAnonymous) {
      return await FirebaseAuth.instance.currentUser!
          .linkWithCredential(credential);
    } else {
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
