import 'package:isar_community/isar.dart';

part 'book.g.dart';

enum ReadingStatus {
  owned,
  toRead,
  wishlist,
}

@collection
class Book {
  Id id = Isar.autoIncrement;

  @Index()
  String? remoteId;

  late String title;
  late String author;
  int? volumeNumber;

  @Index()
  String? isbn;

  String? coverUrl;
  String? localCoverPath;
  String? publisher;
  int? pageCount;

  String? synopsis;

  @Enumerated(EnumType.name)
  ReadingStatus status = ReadingStatus.owned;

  late DateTime createdAt;
  late DateTime updatedAt;

  // Indicate synchronization to the Cloud
  bool isSynced = false;
}
