import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Get FirebaseAuth instance
  FirebaseAuth get auth => _auth;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Store session token securely
      await _storeSessionToken(credential.user!);
      
      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store session token securely
      await _storeSessionToken(credential.user!);

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in aborted');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Store session token securely
      await _storeSessionToken(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        _secureStorage.delete(key: 'session_token'),
      ]);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Store session token securely
  Future<void> _storeSessionToken(User user) async {
    try {
      final token = await user.getIdToken();
      if (token != null) {
        final hashedToken = sha256.convert(utf8.encode(token)).toString();
        await _secureStorage.write(key: 'session_token', value: hashedToken);
      }
    } catch (e) {
      print('Error storing session token: $e');
    }
  }

  // Handle authentication exceptions
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with this email.');
        case 'wrong-password':
          return Exception('Wrong password provided.');
        case 'email-already-in-use':
          return Exception('An account already exists with this email.');
        case 'invalid-email':
          return Exception('The email address is invalid.');
        case 'weak-password':
          return Exception('The password provided is too weak.');
        case 'user-disabled':
          return Exception('This user account has been disabled.');
        case 'too-many-requests':
          return Exception('Too many attempts. Please try again later.');
        case 'operation-not-allowed':
          return Exception('This operation is not allowed.');
        case 'network-request-failed':
          return Exception('Network error. Please check your connection.');
        default:
          return Exception('An error occurred: ${e.message}');
      }
    }
    return Exception('An unexpected error occurred: $e');
  }

  // Verify session token
  Future<bool> verifySessionToken() async {
    try {
      final storedToken = await _secureStorage.read(key: 'session_token');
      if (storedToken == null) return false;

      final user = currentUser;
      if (user == null) return false;

      final currentToken = await user.getIdToken();
      if (currentToken != null) {
        final hashedCurrentToken = sha256.convert(utf8.encode(currentToken)).toString();
        return storedToken == hashedCurrentToken;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
} 