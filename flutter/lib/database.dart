import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'dart:io';
import 'dart:async';
import 'package:ural/models/screen_model.dart';
import 'package:ural/utils/async.dart';

class InsertionError implements Exception {
  final message;
  InsertionError(this.message);
}

class ScreenshotListDatabase {
  /// col names
  final String hash = "hash", imagePath = "imagePath", text = "text";

  /// table name
  final String screenshotlist = "screenshotlist";
  final String vtable = "virtualscreenshotlist";
  static Database database;

  /// Initialize database
  Future<void> initDB() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'screenshotListDB.db');

    /// Opens the database if it exists
    /// else it creates new automatically
    database = await openDatabase(path, version: 1, onCreate: _createTables,
        onOpen: (db) async {
      print(await db.rawQuery('SELECT sqlite_version()'));
    });
  }

  Future _createTables(Database db, int version) async {
    //sql query for creating table
    // String sql = '''CREATE TABLE $screenshotlist(
    //   ${this.hash} INTEGER PRIMARY KEY,
    //   ${this.imagePath} TEXT,
    //   ${this.text} TEXT
    // )''';
    // await db.execute(sql);
    // print("Tables created successfully");

    ///sql query for virtual table for full-text-search
    String sql =
        '''CREATE VIRTUAL TABLE $vtable USING fts4($hash,$imagePath,$text)''';
    await db.execute(sql).then((val) {
      print("Virtual table created successfully");
    });

    ///setup triggers for updating FTS table
    // sql = '''CREATE TRIGGER t_one AFTER INSERT ON $screenshotlist BEGIN
    // INSERT INTO $vtable($hash,$text) VALUES (new.hash,new.text);
    // END;
    // ''';
    // await db.execute(sql).then((val) {
    //   print("Trigger created successfully");
    // });
  }

  Future<AsyncResponse> reset() async {
    try {
      await database.execute('DELETE FROM $vtable');
      AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      AsyncResponse(ResponseStatus.failed, null);
    }
    return AsyncResponse(ResponseStatus.unkown, null);
  }

  Future<void> delete(int hash) async {
    try {
      await database.rawQuery('DELETE FROM $vtable WHERE hash = $hash');
    } catch (e) {
      print(e);
    }
  }

  ///Check if image already exist
  Future<bool> exist(int hash) async {
    final records =
        await database.rawQuery('SELECT hash FROM $vtable WHERE hash = $hash');
    if (records == null) return false;
    if (records.length > 0) return true;
    return false;
  }

  /// Returns all screenshots
  Future<List<ScreenshotModel>> list() async {
    List<ScreenshotModel> screenshots = [];
    try {
      List<Map> records =
          await database.rawQuery("SELECT * FROM $vtable ORDER BY docid DESC");

      for (var record in records) {
        ScreenshotModel model = ScreenshotModel.fromMap(record);
        screenshots.add(model);
      }
    } catch (e) {
      print(e);
    }
    return screenshots;
  }

  Future<void> insert(ScreenshotModel model) async {
    await database.insert(vtable, model.toMap());
  }

  Future<List<ScreenshotModel>> find(String query) async {
    final String sql = 'SELECT * FROM $vtable WHERE $vtable MATCH "$query"';
    List<ScreenshotModel> screenshots = [];
    try {
      List<Map> records = await database.rawQuery(sql);
      for (var record in records) {
        print(record);
        ScreenshotModel model = ScreenshotModel.fromMap(record);
        screenshots.add(model);
      }
    } catch (e) {
      print(e);
    }
    return screenshots;
  }
}
