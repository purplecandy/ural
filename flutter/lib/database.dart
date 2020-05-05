import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:ural/config.dart';
import 'dart:io';
import 'dart:async';
import 'package:ural/models/screen_model.dart';
import 'package:ural/models/tags_model.dart';
import 'package:ural/utils/async.dart';

class InsertionError implements Exception {
  final message;
  InsertionError(this.message);
}

class _Screenshots {
  static const String docid = "docid",
      hash = "hash",
      imagePath = "imagePath",
      text = "text",
      table = "virtualscreenshotlist";

  // @override
  // String toString()=>table;
}

class _Tags {
  static const String id = "id", name = "name", color = "color", table = "tags";
}

class _TaggedScreens {
  static const String tid = "tid", docid = "docid", table = "tagged_screens";
}

class AppDB {
  /// col names
  // final String hash = "hash", imagePath = "imagePath", text = "text";

  /// table name
  // static final String screenshotlist = "screenshotlist";
  // static final String vtable = "virtualscreenshotlist";
  // static final String tags = "tags";
  // static final String taggedScreens = "tagged_screens";

  static Database database;
  Database get db => database;

  static final AppDB _instance = AppDB._();
  factory AppDB() => _instance;
  AppDB._();

  /// Initialize database
  Future<void> initDB() async {
    Directory directory;
    String path;
    if ($debugMode) {
      path = "/storage/emulated/0/screenshotListDB.db";
    } else {
      directory = await getApplicationDocumentsDirectory();
      path = join(directory.path, 'screenshotListDB.db');
    }
    // File(path).copySync('/storage/emulated/0/screenshotListDB.db');
    // print("COPIED");

    /// Opens the database if it exists
    /// else it creates new automatically
    database = await openDatabase(path,
        version: 1, onCreate: _createTables, onOpen: _onOpen);
  }

  Future _onOpen(Database db) async {
    List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${_Tags.table}'");

    if (tables.isEmpty) createTagsTable(db);

    tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${_TaggedScreens.table}'");

    if (tables.isEmpty) createTagScreensTable(db);
  }

  Future _createTables(Database db, int version) async {
    ///sql query for virtual table for full-text-search
    await db.execute('PRAGMA foreign_keys = ON');

    String sql =
        '''CREATE VIRTUAL TABLE ${_Screenshots.table} USING fts4(${_Screenshots.hash},${_Screenshots.imagePath},${_Screenshots.text})''';
    await db.execute(sql).then((val) {
      print("Virtual table created successfully");
    });

    createTagsTable(db);

    createTagScreensTable(db);
  }

  Future<void> createTagsTable(Database db) async {
    String sql = '''
    CREATE TABLE ${_Tags.table} (
      ${_Tags.id} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      ${_Tags.name} varchar(25) UNIQUE NOT NULL,
      ${_Tags.color} INTEGER
    )
    ''';
    await db.execute(sql).then((val) {
      print("${_Tags.table} table created successfully");
    });
  }

  Future<void> createTagScreensTable(Database db) async {
    String sql = '''
    CREATE TABLE ${_TaggedScreens.table} (
      ${_TaggedScreens.tid} INTEGER NOT NULL,
      ${_TaggedScreens.docid} INTEGER NOT NULL,
      FOREIGN KEY (${_TaggedScreens.tid}) REFERENCES ${_Tags.table}(${_Tags.id}) ON DELETE CASCADE,
      FOREIGN KEY (${_TaggedScreens.docid}) REFERENCES ${_Screenshots.table}(${_Screenshots.docid}) ON DELETE CASCADE,
      CONSTRAINT combo UNIQUE (${_TaggedScreens.tid},${_TaggedScreens.docid})
    )''';

    await db.execute(sql).then((val) {
      print("${_TaggedScreens.table} table created successfully");
    });
  }

  Future<AsyncResponse> reset() async {
    try {
      await database.execute('DELETE FROM ${_Screenshots.table}');
      AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      AsyncResponse(ResponseStatus.failed, null);
    }
    return AsyncResponse(ResponseStatus.unkown, null);
  }

  Future<void> delete(int hash) async {
    try {
      await database
          .rawQuery('DELETE FROM ${_Screenshots.table} WHERE hash = $hash');
    } catch (e) {
      print(e);
    }
  }

  ///Check if image already exist
  Future<bool> exist(int hash) async {
    final records = await database.rawQuery(
        'SELECT ${_Screenshots.hash} FROM ${_Screenshots.table} WHERE ${_Screenshots.hash} = $hash');
    if (records == null) return false;
    if (records.length > 0) return true;
    return false;
  }

  /// Returns all screenshots
  Future<List<ScreenshotModel>> list() async {
    List<ScreenshotModel> screenshots = [];
    try {
      List<Map> records = await database.rawQuery(
          "SELECT ${_Screenshots.hash},${_Screenshots.imagePath},${_Screenshots.text},${_Screenshots.docid} FROM ${_Screenshots.table} ORDER BY ${_Screenshots.docid} DESC");
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
    await database.insert(_Screenshots.table, model.toMap());
  }

  Future<List<ScreenshotModel>> find(String query, {Set<int> filter}) async {
    List<String> subSql = [];
    String filterSQL = "";
    if (filter != null) {
      for (var id in filter) {
        subSql.add(
            "SELECT ${_TaggedScreens.docid} FROM ${_TaggedScreens.table} WHERE ${_TaggedScreens.tid}=$id");
      }
      if (subSql.isNotEmpty) {
        filterSQL = "AND ${_Screenshots.docid} IN (" +
            (subSql.length > 1 ? subSql.join(" INTERSECT ") : subSql[0]) +
            ")";
      }
    }
    final String sql =
        'SELECT * FROM ${_Screenshots.table} WHERE ${_Screenshots.text} MATCH "$query*" $filterSQL';
    List<ScreenshotModel> screenshots = [];
    try {
      List<Map> records = await database.rawQuery(sql);
      // print("");
      // print(records);
      for (var record in records) {
        // print(record);
        ScreenshotModel model = ScreenshotModel.fromMap(record);
        screenshots.add(model);
      }
    } catch (e) {
      print(e);
    }
    return screenshots;
  }

  Future<AsyncResponse> removeBatch(List<ScreenshotModel> screens,
      {

      /// true - if you want to delete the files too
      bool rmfile = false}) async {
    try {
      for (var item in screens) {
        String sql =
            'DELETE FROM ${_Screenshots.table} WHERE ${_Screenshots.hash} = ${item.hash}';
        await database.execute(sql);
        if (rmfile) File(item.imagePath).delete();
      }
      return AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }
}

class TagUtils {
  static Future<AsyncResponse> create(
      Database db, String name, int color) async {
    try {
      await db.execute(
          "INSERT INTO ${_Tags.table} ('${_Tags.name}','${_Tags.color}') VALUES ('$name',$color)");
      return AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }

  static Future<AsyncResponse> insert(Database db, int tagId, int docId) async {
    try {
      await db.rawInsert(
          "INSERT INTO ${_TaggedScreens.table} ('${_TaggedScreens.tid}','${_TaggedScreens.docid}') VALUES($tagId,$docId)");
      return AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, null);
    }
  }

  static Future<AsyncResponse> getTags(Database db) async {
    try {
      List results = await db.rawQuery("SELECT * FROM ${_Tags.table}");
      List<TagModel> tags = [];
      if (results.length > 0) {
        for (var item in results) {
          TagModel model = TagModel.fromMap(item);
          tags.add(model);
        }
      }
      return AsyncResponse(ResponseStatus.success, tags);
    } catch (e) {
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }

  static Future<AsyncResponse> getScreensByTag(Database db, int tagId) async {
    try {
      /// col names
      // final String hash = "hash", imagePath = "imagePath", text = "text";
      if (tagId == null) throw Exception("tagId is null");
      String sql =
          """SELECT ${_Screenshots.hash},${_Screenshots.imagePath},${_Screenshots.text},${_Screenshots.docid} FROM ${_Screenshots.table} WHERE ${_Screenshots.docid} IN (SELECT ${_Screenshots.docid} FROM ${_TaggedScreens.table} WHERE ${_TaggedScreens.tid}=$tagId)""";

      List<Map> results = await db.rawQuery(sql);
      List<ScreenshotModel> screens = [];
      if (results.length > 0) {
        for (var item in results) {
          ScreenshotModel model = ScreenshotModel.fromMap(item);
          screens.add(model);
        }
        return AsyncResponse(ResponseStatus.success, screens);
      }
      return AsyncResponse(ResponseStatus.success, screens);
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

  static Future<AsyncResponse> delete(Database db, int id) async {
    try {
      String sql = 'DELETE FROM ${_Tags.table} WHERE ${_Tags.id} = $id';
      db.execute(sql);
      return AsyncResponse(ResponseStatus.success, "Deleted tag successfull");
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }

  static Future<AsyncResponse> update(
      Database db, int id, String newName, int newColor) async {
    try {
      newName.trim();
      String sql =
          'UPDATE ${_Tags.table} SET ${_Tags.name} = "$newName",${_Tags.color} = $newColor WHERE ${_Tags.id} = $id';
      db.execute(sql);
      return AsyncResponse(ResponseStatus.success, "Deleted tag successfull");
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }

  static Future<AsyncResponse> deleteTaggedScreen(
      Database db, int tagId, int docId) async {
    try {
      String sql =
          'DELETE FROM ${_TaggedScreens.table} WHERE ${_TaggedScreens.tid} = $tagId AND ${_TaggedScreens.docid} = $docId';
      db.execute(sql);
      return AsyncResponse(
          ResponseStatus.success, "Tagged Screen deleted successfull");
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
          "SELECT ${_TaggedScreens.docid} FROM ${_TaggedScreens.table} WHERE ${_TaggedScreens.tid}=$id");
    }

    return "SELECT * FROM ${_Screenshots.table} WHERE ${_Screenshots.docid} IN (" +
        (subSql.length > 1 ? subSql.join(" INTERSECT ") : subSql[0]) +
        ")";
  }
}

class TaggedScreensUtils {
  static Future<AsyncResponse> insert(Database db, int tagId, int docId) async {
    try {
      await db.rawInsert(
          "INSERT INTO ${_TaggedScreens.table} ('${_TaggedScreens.tid}','${_TaggedScreens.docid}') VALUES($tagId,$docId)");
      return AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, null);
    }
  }

  static Future<AsyncResponse> list(Database db, int tagId) async {
    try {
      /// col names
      // final String hash = "hash", imagePath = "imagePath", text = "text";
      if (tagId == null) throw Exception("tagId is null");
      String sql =
          """SELECT ${_Screenshots.hash},${_Screenshots.imagePath},${_Screenshots.text},${_Screenshots.docid} FROM ${_Screenshots.table} WHERE ${_Screenshots.docid} IN (SELECT ${_Screenshots.docid} FROM ${_TaggedScreens.table} WHERE ${_TaggedScreens.tid}=$tagId)""";

      List<Map> results = await db.rawQuery(sql);
      List<ScreenshotModel> screens = [];
      if (results.length > 0) {
        for (var item in results) {
          ScreenshotModel model = ScreenshotModel.fromMap(item);
          screens.add(model);
        }
        return AsyncResponse(ResponseStatus.success, screens);
      }
      return AsyncResponse(ResponseStatus.success, screens);
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

  static Future<AsyncResponse> delete(Database db, int tagId, int docId) async {
    try {
      String sql =
          'DELETE FROM ${_TaggedScreens.table} WHERE ${_TaggedScreens.tid} = $tagId AND ${_TaggedScreens.docid} = $docId';
      db.execute(sql);
      return AsyncResponse(
          ResponseStatus.success, "Tagged Screen deleted successfull");
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
          "SELECT ${_TaggedScreens.docid} FROM ${_TaggedScreens.table} WHERE ${_TaggedScreens.tid}=$id");
    }

    return "SELECT * FROM ${_Screenshots.table} WHERE ${_Screenshots.docid} IN (" +
        (subSql.length > 1 ? subSql.join(" INTERSECT ") : subSql[0]) +
        ")";
  }
}

class ScreenshotsUtils {
  static Future<AsyncResponse> deleteAll(Database db) async {
    try {
      await db.execute('DELETE FROM ${_Screenshots.table}');
      AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      AsyncResponse(ResponseStatus.failed, null);
    }
    return AsyncResponse(ResponseStatus.unkown, null);
  }

  static Future<void> delete(Database db, int hash) async {
    try {
      await db.rawQuery('DELETE FROM ${_Screenshots.table} WHERE hash = $hash');
    } catch (e) {
      print(e);
    }
  }

  ///Check if image already exist
  static Future<bool> exist(Database db, int hash) async {
    final records = await db.rawQuery(
        'SELECT ${_Screenshots.hash} FROM ${_Screenshots.table} WHERE ${_Screenshots.hash} = $hash');
    if (records == null) return false;
    if (records.length > 0) return true;
    return false;
  }

  /// Returns all screenshots
  static Future<List<ScreenshotModel>> list(Database db) async {
    List<ScreenshotModel> screenshots = [];
    try {
      List<Map> records = await db.rawQuery(
          "SELECT ${_Screenshots.hash},${_Screenshots.imagePath},${_Screenshots.text},${_Screenshots.docid} FROM ${_Screenshots.table} ORDER BY ${_Screenshots.docid} DESC");
      for (var record in records) {
        ScreenshotModel model = ScreenshotModel.fromMap(record);
        screenshots.add(model);
      }
    } catch (e) {
      print(e);
    }
    return screenshots;
  }

  static Future<void> insert(Database db, ScreenshotModel model) async {
    await db.insert(_Screenshots.table, model.toMap());
  }

  static Future<List<ScreenshotModel>> find(Database db, String query,
      {Set<int> filter}) async {
    List<String> subSql = [];
    String filterSQL = "";
    if (filter != null) {
      for (var id in filter) {
        subSql.add(
            "SELECT ${_TaggedScreens.docid} FROM ${_TaggedScreens.table} WHERE ${_TaggedScreens.tid}=$id");
      }
      if (subSql.isNotEmpty) {
        filterSQL = "AND ${_Screenshots.docid} IN (" +
            (subSql.length > 1 ? subSql.join(" INTERSECT ") : subSql[0]) +
            ")";
      }
    }
    final String sql =
        'SELECT * FROM ${_Screenshots.table} WHERE ${_Screenshots.text} MATCH "$query*" $filterSQL';
    List<ScreenshotModel> screenshots = [];
    try {
      List<Map> records = await db.rawQuery(sql);
      // print("");
      // print(records);
      for (var record in records) {
        // print(record);
        ScreenshotModel model = ScreenshotModel.fromMap(record);
        screenshots.add(model);
      }
    } catch (e) {
      print(e);
    }
    return screenshots;
  }

  static Future<AsyncResponse> deleteMultiple(
      Database db, List<ScreenshotModel> screens,
      {

      /// true - if you want to delete the files too
      bool rmfile = false}) async {
    try {
      for (var item in screens) {
        String sql =
            'DELETE FROM ${_Screenshots.table} WHERE ${_Screenshots.hash} = ${item.hash}';
        await db.execute(sql);
        if (rmfile) File(item.imagePath).delete();
      }
      return AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }
}
