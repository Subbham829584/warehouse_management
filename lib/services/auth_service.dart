import 'package:firebase_auth/firebase_auth.dart';
import 'package:warehouse_management/core/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper over FirebaseAuth with friendly error messages.
/// NEVER store passwords anywhere — Firebase Auth handles credentials.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String get email => _auth.currentUser?.email ?? 'unknown';

  Future<void> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    await _touchProfile(cred.user);
  }

  Future<void> signUp(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = cred.user;
    if (user == null) return;
    if (name.trim().isNotEmpty) await user.updateDisplayName(name.trim());
    await _db.collection(AppConstants.usersCol).doc(user.uid).set({
      'uid': user.uid,
      'displayName': name.trim().isEmpty ? 'User' : name.trim(),
      'email': email.trim(),
      'role': 'staff', // promote to 'admin' manually / via Cloud Function
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      // merge: WarehouseBootstrap may already have written warehouseId.
    }, SetOptions(merge: true));
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  Future<void> _touchProfile(User? u) async {
    if (u == null) return;
    try {
      await _db.collection(AppConstants.usersCol).doc(u.uid).set(
          {'lastLogin': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (_) {/* non-critical */}
  }

  /// Converts Firebase error codes into messages a human can act on.
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'Password is too weak. Use 8+ characters.';
        case 'too-many-requests':
          return 'Too many attempts. Try again in a few minutes.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'operation-not-allowed':
        case 'configuration-not-found':
          return 'Email/Password sign-in is not enabled in Firebase Console.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
