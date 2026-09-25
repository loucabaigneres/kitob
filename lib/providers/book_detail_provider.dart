import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../models/book.dart';
import 'books_provider.dart';

final bookStreamProvider = StreamProvider.autoDispose.family<Book?, Id>((ref, id) {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.watchBookById(id);
});

class BookDetailNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateStatus(Id id, ReadingStatus newStatus) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(bookRepositoryProvider);
      await repository.updateBookStatus(id, newStatus);
    });

    if (ref.mounted) {
      state = result;
    }
  }

  Future<void> deleteBook(Id id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(bookRepositoryProvider);
      await repository.deleteBook(id);
    });

    if (ref.mounted) {
      state = result;
    }
  }
}

final bookDetailActionProvider = AsyncNotifierProvider.autoDispose<BookDetailNotifier, void>(
  BookDetailNotifier.new,
);
