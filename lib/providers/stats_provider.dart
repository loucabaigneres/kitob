import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import 'books_provider.dart';

class LibraryStats {
  final int totalBooks;
  final int ownedCount;
  final int toReadCount;
  final int wishlistCount;
  final int totalPages;

  LibraryStats({
    required this.totalBooks,
    required this.ownedCount,
    required this.toReadCount,
    required this.wishlistCount,
    required this.totalPages,
  });
}

final allBooksStreamProvider = StreamProvider.autoDispose<List<Book>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.watchBooks();
});

final libraryStatsProvider = Provider.autoDispose<LibraryStats?>((ref) {
  final booksAsync = ref.watch(allBooksStreamProvider);

  return booksAsync.when(
    data: (books) {
      int owned = 0;
      int toRead = 0;
      int wishList = 0;
      int pages = 0;

      for (final book in books) {
        switch (book.status) {
          case ReadingStatus.owned:
            owned++;
            break;
          case ReadingStatus.toRead:
            toRead++;
            break;
          case ReadingStatus.wishlist:
            wishList++;
            break;
        }
        pages += book.pageCount ?? 0;
      }

      return LibraryStats(
        totalBooks: books.length,
        ownedCount: owned,
        toReadCount: toRead,
        wishlistCount: wishList,
        totalPages: pages,
      );
    },
    loading: () => null,
    error: (_, _) => null,
  );
});
