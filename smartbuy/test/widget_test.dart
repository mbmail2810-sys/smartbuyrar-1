// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartbuy/app.dart';
import 'package:smartbuy/src/providers/auth_providers.dart';
import 'package:smartbuy/src/services/auth_service.dart';

class MockAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  Stream<User?> idTokenChanges() => Stream.value(null);

  @override
  Future<UserCredential> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.initFlutter();
  });

  testWidgets('Shows SignInScreen when not authenticated', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService()),
        ],
        child: const SmartBuyApp(),
      ),
    );

    // Wait for all frames to settle.
    await tester.pumpAndSettle();

    // Verify that the SignInScreen is displayed.
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
