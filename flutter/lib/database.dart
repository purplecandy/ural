import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'dart:io';
import 'dart:async';
import 'package:ural/models/screen_model.dart';
import 'package:ural/models/tags_model.dart';
import 'package:ural/utils/async.dart';

class InsertionError implements Exception {
  final message;
  InsertionError(this.message);
}

class ScreenshotListDatabase {
  /// col names
  final String hash = "hash", imagePath = "imagePath", text = "text";

  /// table name
  static final String screenshotlist = "screenshotlist";
  static final String vtable = "virtualscreenshotlist";
  static final String tags = "tags";
  static final String taggedScreens = "tagged_screens";

  static Database database;
  Database get db => database;

  static final ScreenshotListDatabase _instance = ScreenshotListDatabase._();
  factory ScreenshotListDatabase() => _instance;
  ScreenshotListDatabase._();

  /// Initialize database
  Future<void> initDB() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'screenshotListDB.db');

    /// Opens the database if it exists
    /// else it creates new automatically
    database = await openDatabase(path,
        version: 1, onCreate: _createTables, onOpen: _onOpen);
  }

  Future _onOpen(Database db) async {
    List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tags'");

    if (tables.isEmpty) createTagsTable(db);

    tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$taggedScreens'");

    if (tables.isEmpty) createTagScreensTable(db);
  }

  Future _createTables(Database db, int version) async {
    ///sql query for virtual table for full-text-search
    await db.execute('PRAGMA foreign_keys = ON');

    String sql =
        '''CREATE VIRTUAL TABLE $vtable USING fts4($hash,$imagePath,$text)''';
    await db.execute(sql).then((val) {
      print("Virtual table created successfully");
    });

    createTagsTable(db);

    createTagScreensTable(db);
  }

  Future<void> createTagsTable(Database db) async {
    String sql = '''
    CREATE TABLE $tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      name varchar(25) UNIQUE NOT NULL,
      color INTEGER
    )
    ''';
    await db.execute(sql).then((val) {
      print("$tags table created successfully");
    });
  }

  Future<void> createTagScreensTable(Database db) async {
    String sql = '''
    CREATE TABLE $taggedScreens (
      tid INTEGER NOT NULL,
      docid INTEGER NOT NULL,
      FOREIGN KEY (tid) REFERENCES $tags(id) ON DELETE CASCADE,
      FOREIGN KEY (docid) REFERENCES $vtable(docid) ON DELETE CASCADE,
      CONSTRAINT combo UNIQUE (tid,docid)
    )''';

    await db.execute(sql).then((val) {
      print("$taggedScreens table created successfully");
    });
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

class TagUtils {
  static Future<AsyncResponse> create(
      Database db, String name, int color) async {
    try {
      await db.execute(
          "INSERT INTO ${ScreenshotListDatabase.tags} ('name','color') VALUES ('$name',$color)");
      return AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }

  static Future<AsyncResponse> getTags(Database db) async {
    try {
      List results =
          await db.rawQuery("SELECT * FROM ${ScreenshotListDatabase.tags}");
      if (results.length > 0) {
        List<TagModel> tags = [];
        for (var item in results) {
          TagModel model = TagModel.fromMap(item);
          tags.add(model);
        }
        return AsyncResponse(ResponseStatus.success, tags);
      }
      return AsyncResponse(ResponseStatus.success, results);
    } catch (e) {
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }

  static Future<AsyncResponse> getScreensByTag(Database db, int tagId) async {
    try {
      if (tagId == null) throw Exception("tagId is null");
      String sql =
          """SELECT * FROM ${ScreenshotListDatabase.vtable} WHERE docid IN (
        SELECT docid FROM ${ScreenshotListDatabase.taggedScreens} WHERE tid=$tagId
        )""";
      List results = await db.rawQuery(sql) ?? [];
      if (results.length > 0) {
        List<ScreenshotModel> screens = [];
        for (var item in results) {
          ScreenshotModel model = ScreenshotModel.fromMap(item);
          screens.add(model);
        }
        return AsyncResponse(ResponseStatus.success, screens);
      }
      return AsyncResponse(ResponseStatus.success, results);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }

  static Future<AsyncResponse> filter(Database db, List<int> ids) async {
    try {
      if (ids.isEmpty) throw Exception("ids not provided");
      String sql = _generateSQL(ids);
      List results = await db.rawQuery(sql);
      if (results.length > 0) {
        List<ScreenshotModel> screens = [];
        for (var item in results) {
          ScreenshotModel model = ScreenshotModel.fromMap(item);
          screens.add(model);
        }
        return AsyncResponse(ResponseStatus.success, screens);
      }
      return AsyncResponse(ResponseStatus.success, results);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }

  static String _generateSQL(List<int> ids) {
    // get tagIds
    // parse Ids into sql queries
    List<String> subSql = [];
    for (int id in ids) {
      subSql.add(
          "SELECT docid FROM ${ScreenshotListDatabase.taggedScreens} WHERE tid=$id");
    }

    return "SELECT * FROM ${ScreenshotListDatabase.screenshotlist} WHERE docid IN (" +
        (subSql.length > 1 ? subSql.join(" INTERSECT ") : subSql[0]) +
        ")";
  }
}
