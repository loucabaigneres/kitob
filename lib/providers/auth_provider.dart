import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

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
      await authService.signOut();
    });
    if (ref.mounted) state = result;
  }
}

final authActionProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
