import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  // Custom stream to handle both Firebase and Demo mode
  final StreamController<User?> _controller = StreamController<User?>.broadcast();
  static bool useMockMode = false;

  AuthService._internal() {
    // Listen to real Firebase changes
    _auth.authStateChanges().listen((user) {
      if (!useMockMode) {
        _controller.add(user);
      }
    });
  }

  Stream<User?> get authStateChanges => _controller.stream;

  User? get currentUser => useMockMode ? _MockUser() : _auth.currentUser;

  // Method to force enter Demo Mode
  void enterDemoMode() {
    useMockMode = true;
    _controller.add(_MockUser());
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (useMockMode) {
      enterDemoMode();
      return _MockUserCredential();
    }
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential creds = await _auth.signInWithCredential(credential);
        await _analytics.logLogin(loginMethod: 'google');
        return creds;
      }
    } catch (e) {
      if (e.toString().contains('configuration-not-found') || e.toString().contains('not-initialized')) {
        enterDemoMode();
        return _MockUserCredential();
      }
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (useMockMode) {
      enterDemoMode();
      return _MockUserCredential();
    }
    try {
      final UserCredential creds = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _analytics.logLogin(loginMethod: 'email');
      return creds;
    } catch (e) {
      if (e.toString().contains('configuration-not-found')) {
        enterDemoMode();
        return _MockUserCredential();
      }
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    if (useMockMode) {
      enterDemoMode();
      return _MockUserCredential();
    }
    try {
      final UserCredential creds = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _analytics.logSignUp(signUpMethod: 'email');
      return creds;
    } catch (e) {
      if (e.toString().contains('configuration-not-found')) {
        enterDemoMode();
        return _MockUserCredential();
      }
      rethrow;
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    if (useMockMode) {
      enterDemoMode();
      return _MockUserCredential();
    }
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      if (e.toString().contains('configuration-not-found')) {
        enterDemoMode();
        return _MockUserCredential();
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    useMockMode = false;
    await _googleSignIn.signOut();
    await _auth.signOut();
    _controller.add(null);
  }
}

// Minimal Mock User that satisfies snapshot.hasData check
class _MockUser implements User {
  @override
  String get uid => 'demo-user-id';
  @override
  String? get email => 'demo@fairlens.ai';
  @override
  String? get displayName => 'Demo User';
  @override
  bool get emailVerified => true;
  @override
  bool get isAnonymous => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock UserCredential to satisfy the return type
class _MockUserCredential implements UserCredential {
  @override
  User? get user => _MockUser();
  @override
  AuthCredential? get credential => null;
  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
