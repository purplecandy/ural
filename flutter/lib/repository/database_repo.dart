import 'package:ural/database.dart';
import 'package:ural/utils/bloc_provider.dart';

class DatabaseRepository extends Repository {
  ScreenshotListDatabase slDB = ScreenshotListDatabase();

  DatabaseRepository() {
    initializeDatabase();
  }

  /// Initialize database
  Future<void> initializeDatabase() async {
    await slDB.initDB();
    notifyListeners();
  }
}
