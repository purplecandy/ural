import 'package:flutter/material.dart';
import 'package:ural/database.dart';
// import 'package:ural/utils/bloc_provider.dart';

class DatabaseRepository extends ChangeNotifier {
  AppDB slDB = AppDB();

  DatabaseRepository() {
    initializeDatabase();
  }

  /// Initialize database
  Future<void> initializeDatabase() async {
    await slDB.initDB();
    notifyListeners();
  }

  Future<void> hardReset() async => await slDB.reset();
}
