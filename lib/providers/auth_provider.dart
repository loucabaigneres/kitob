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
  }

  Future<void> linkAccount(String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.linkAccountWithEmail(email, password);
    });
    if (ref.mounted) state = result;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(email, password);
    });
    if (ref.mounted) state = result;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      final repository = ref.read(bookRepositoryProvider);

      await authService.signOut();
      await repository.clearLocalDatabase();
    });
    if (ref.mounted) state = result;
  }
}

final authActionProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
