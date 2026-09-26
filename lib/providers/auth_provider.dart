import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import 'books_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    final authService = ref.read(authServiceProvider);
    await authService.ensureAnonymousUser();
  }

  Future<void> _executeAuth(Future<void> Function(AuthService service) action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await action(authService);
    });
    if (ref.mounted) {
      state = result;
    }
  }

  Future<void> linkAccount(String email, String password) =>
      _executeAuth((s) => s.linkAccountWithEmail(email, password));
  
  Future<void> signIn(String email, String password) =>
      _executeAuth((s) => s.signInWithEmail(email, password));

  Future<void> signOut() => _executeAuth((s) async {
  final repo = ref.read(bookRepositoryProvider);
  await s.signOut(onBeforeSignOut: repo.clearLocalDatabase);
});
}

final authActionProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
