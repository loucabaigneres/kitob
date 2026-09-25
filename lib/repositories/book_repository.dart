import 'package:isar_community/isar.dart';

import '../models/book.dart';
import '../services/isar_service.dart';

class BookRepository {
  final IsarService _isarService;

  BookRepository(this._isarService);

  Stream<List<Book>> watchBooks({ReadingStatus? status, String query = ''}) async* {
    final isar = await _isarService.db;

    QueryBuilder<Book, Book, QAfterFilterCondition> buildFilter() {
      var q = isar.books.filter().idGreaterThan(-1);

      if (status != null) {
        q = q.statusEqualTo(status);
      }

      if (query.isNotEmpty) {
        q = q.group(
          (group) => group
              .titleContains(query, caseSensitive: false)
              .or()
              .authorContains(query, caseSensitive: false)
        );
      }
      return q;
    }

    // Immediately yield the current list of books, then watch for changes and yield updated lists
    yield await buildFilter().sortByUpdatedAtDesc().findAll();
    await for (final _ in isar.books.watchLazy()) {
      yield await buildFilter().sortByUpdatedAtDesc().findAll();
    }
  }

  Future<void> saveBook(Book book) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.books.put(book);
    });
  }

  Future<void> deleteBook(Id id) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.books.delete(id);
    });
  }

  Future<Book?> getBookById(Id id) async {
    final isar = await _isarService.db;
    return await isar.books.get(id);
  }

  Future<Book?> findDuplicateBook({String? isbn, required String title, required String author}) async {
    final isar = await _isarService.db;

    if (isbn != null && isbn.isNotEmpty) {
      final matchByIsbn = await isar.books.filter().isbnEqualTo(isbn).findFirst();
      if (matchByIsbn != null) return matchByIsbn;
    }

    return await isar.books
        .filter()
        .titleEqualTo(title, caseSensitive: false)
        .and()
        .authorEqualTo(author, caseSensitive: false)
        .findFirst();
  }
}
