import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? '825686175806-rhu9g0t8imadpoo3brids43a5bgb28lh.apps.googleusercontent.com' : null,
  );

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
    if (kIsWeb) {
      return await _signInWithGoogleWeb();
    } else {
      return await _signInWithGoogleNative();
    }
  }

  Future<UserCredential> _signInWithGoogleWeb() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    
    if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
      return await _auth.currentUser!.linkWithPopup(googleProvider);
    } else {
      return await _auth.signInWithPopup(googleProvider);
    }
  }

  Future<UserCredential> _signInWithGoogleNative() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Sign-in aborted by user');
    }
    
    final googleAuth = await googleUser.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
      return await _auth.currentUser!.linkWithCredential(credential);
    } else {
      return await _auth.signInWithCredential(credential);
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }
}
