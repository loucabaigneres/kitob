import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.userChanges();
  User? get currentUser => _auth.currentUser;

  // Ensures an anonymous user session exists at startup.
  Future<User> ensureAnonymousUser() async {
    final existingUser = _auth.currentUser;
    if (existingUser != null) {
      return existingUser;
    } else {
      final credential = await _auth.signInAnonymously();
      return credential.user!;
    }
  }

  // Converts an anonymous account into an email/password account without losing the UID
  Future<void> linkAccountWithEmail(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur actif à associer.');
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password
    );

    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
        await _auth.signInWithCredential(credential);
      } else {
        rethrow;
      }
    }
    await _auth.currentUser?.reload();
  }

  // Sign in with an existing email and password
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _auth.currentUser?.reload();
  }
  Future<void> signOut() async {
    await _auth.signOut();
    // Ensure that the user is signed in anonymously after signing out
    await _auth.signInAnonymously();
  }
}
