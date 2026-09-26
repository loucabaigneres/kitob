import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar_community/isar.dart';

import '../models/book.dart';
import 'isar_service.dart';

class FirestoreSyncService {
  final FirebaseFirestore _firestore;
  final IsarService _isarService;

  FirestoreSyncService(this._isarService, [FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  CollectionReference<Map<String, dynamic>> _userBooksCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('books');
  }

  Future<void> synchronize(String userId) async {
    final isar = await _isarService.db;
    final booksRef = _userBooksCollection(userId);

    // Push phase: Local changes to Firestore
    final unsyncedBooks = await isar.books.filter().isSyncedEqualTo(false).findAll();

    for (final book in unsyncedBooks) {
      DocumentReference<Map<String, dynamic>> docRef;

      if (book.remoteId == null || book.remoteId!.isEmpty) {
        docRef = booksRef.doc();
        book.remoteId = docRef.id;
      } else {
        docRef = booksRef.doc(book.remoteId);
      }

      final payload = _bookToFirestore(book);

      // Write to Firestore with merge option to avoid overwriting existing fields
      await docRef.set(payload, SetOptions(merge: true));

      await isar.writeTxn(() async {
        book.isSynced = true;
        await isar.books.put(book);
      });
    }

    // Pull phase: Firestore changes to local
    final remoteSnapshot = await booksRef.get();

    for (final doc in remoteSnapshot.docs) {
      final remoteData = doc.data();
      final remoteId = doc.id;
      final remoteUpdatedAt = (remoteData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      // Find if this book already exists locally by remoteId
      final localBook = await isar.books.filter().remoteIdEqualTo(remoteId).findFirst();

      if (localBook == null) {
        // Book doesn't exist locally: insert it
        final newBook = _firestoreToBook(remoteData, remoteId);
        await isar.writeTxn(() async {
          await isar.books.put(newBook);
        });
      } else if (remoteUpdatedAt.isAfter(localBook.updatedAt)) {
        // Remote is newer: update local copy
        final updatedBook = _applyRemoteData(localBook, remoteData);
        await isar.writeTxn(() async {
          await isar.books.put(updatedBook);
        });
      }
    }
  }

  Future<void> deleteRemoteBook(String userId, String remoteId) async {
    try {
      await _userBooksCollection(userId).doc(remoteId).delete();
    } catch (_) {
      // Ignored: will not fail offline
    }
  }

  Map<String, dynamic> _bookToFirestore(Book book) {
    return {
      'remoteId': book.remoteId,
      'title': book.title,
      'author': book.author,
      'volumeNumber': book.volumeNumber,
      'isbn': book.isbn,
      'coverUrl': book.coverUrl,
      'publisher': book.publisher,
      'pageCount': book.pageCount,
      'synopsis': book.synopsis,
      'status': book.status.name,
      'createdAt': Timestamp.fromDate(book.createdAt),
      'updatedAt': Timestamp.fromDate(book.updatedAt),
    };
  }

  Book _firestoreToBook(Map<String, dynamic> data, String remoteId) {
    final statusString = data['status'] as String? ?? 'owned';
    final status = ReadingStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => ReadingStatus.owned,
    );

    return Book()
      ..remoteId = remoteId
      ..title = data['title'] as String? ?? 'Titre inconnu'
      ..author = data['author'] as String? ?? 'Auteur inconnu'
      ..volumeNumber = data['volumeNumber'] as int?
      ..isbn = data['isbn'] as String?
      ..coverUrl = data['coverUrl'] as String?
      ..publisher = data['publisher'] as String?
      ..pageCount = data['pageCount'] as int?
      ..synopsis = data['synopsis'] as String?
      ..status = status
      ..createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ..updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now()
      ..isSynced = true;
  }

  Book _applyRemoteData(Book target, Map<String, dynamic> data) {
    final statusString = data['status'] as String? ?? 'owned';
    target.status = ReadingStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => ReadingStatus.owned,
    );
    target.title = data['title'] as String? ?? target.title;
    target.author = data['author'] as String? ?? target.author;
    target.volumeNumber = data['volumeNumber'] as int?;
    target.isbn = data['isbn'] as String? ?? target.isbn;
    target.coverUrl = data['coverUrl'] as String?;
    target.publisher = data['publisher'] as String?;
    target.pageCount = data['pageCount'] as int?;
    target.synopsis = data['synopsis'] as String?;
    target.updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? target.updatedAt;
    target.isSynced = true;
    return target;
  }
}
