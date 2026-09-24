import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../services/isar_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) => IsarService());

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return BookRepository(isarService);
});

class BookFilterState {
  final ReadingStatus? status;
  final String searchQuery;

  const BookFilterState({
    this.status,
    this.searchQuery = '',
  });

  BookFilterState copyWith({ReadingStatus? Function()? status, String? searchQuery}) {
    return BookFilterState(
      status: status != null ? status() : this.status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BookFilterNotifier extends Notifier<BookFilterState> {
  @override
  BookFilterState build() => const BookFilterState();

  void setStatus(ReadingStatus? status) {
    state = state.copyWith(status: () => status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final bookFilterProvider = NotifierProvider<BookFilterNotifier, BookFilterState>(
  BookFilterNotifier.new,
);

final booksStreamProvider = StreamProvider.autoDispose<List<Book>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  final filter = ref.watch(bookFilterProvider);

  return repository.watchBooks(
    status: filter.status,
    query: filter.searchQuery,
  );
});
