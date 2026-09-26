import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'books_provider.dart';

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.watchPendingSyncCount();
});

class SyncNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> syncNow() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(bookRepositoryProvider);
      await repository.triggerSync(user.uid);
    });

    if (ref.mounted) {
      state = result;
    }
  }
}

final syncActionProvider = AsyncNotifierProvider<SyncNotifier, void>(
  SyncNotifier.new,
);
