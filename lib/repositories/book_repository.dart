import 'package:isar_community/isar.dart';

import '../models/book.dart';
import '../services/firestore_sync_service.dart';
import '../services/isar_service.dart';

class BookRepository {
  final IsarService _isarService;
  final FirestoreSyncService _syncService;

  BookRepository(this._isarService, this._syncService);

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

  Stream<Book?> watchBookById(Id id) async* {
    final isar = await _isarService.db;
    yield await isar.books.get(id);
    await for (final _ in isar.books.watchLazy()) {
      yield await isar.books.get(id);
    }
  }

  Future<void> saveBook(Book book) async {
    final isar = await _isarService.db;
    book.isSynced = false;
    book.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.books.put(book);
    });
  }

  Future<void> deleteBook(Id id, {String? userId}) async {
    final isar = await _isarService.db;
    final book = await isar.books.get(id);

    if (book != null) {
      final remoteId = book.remoteId;
      await isar.writeTxn(() async {
        await isar.books.delete(id);
      });

      if (userId != null && remoteId != null) {
        await _syncService.deleteRemoteBook(userId, remoteId);
      }
    }
  }

  Future<void> updateBookStatus(Id id, ReadingStatus status) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final book = await isar.books.get(id);
      if (book != null) {
        book.status = status;
        book.updatedAt = DateTime.now();
        book.isSynced = false;
        await isar.books.put(book);
      }
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

  Stream<int> watchPendingSyncCount() async* {
    final isar = await _isarService.db;
    yield await isar.books.filter().isSyncedEqualTo(false).count();
    await for (final _ in isar.books.watchLazy()) {
      yield await isar.books.filter().isSyncedEqualTo(false).count();
    }
  }

  Future<void> triggerSync(String userId) async {
    await _syncService.synchronize(userId);
  }

  Future<void> clearLocalDatabase() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.books.clear();
    });
  }
}
