import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = _openDatabase();
  }

  Future<Isar> _openDatabase() async {
    final dir = await getApplicationDocumentsDirectory();

    if (Isar.getInstance() != null) {
      return Future.value(Isar.getInstance()!);
    }

    return await Isar.open(
      [BookSchema],
      directory: dir.path,
      inspector: true, // Enable Isar Inspector for debugging
    );
  }
}
