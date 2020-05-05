import 'package:ural/utils/async.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/models/tags_model.dart';
import 'dart:io';
import 'schemas.dart';

class TagUtils {
  static Future<AsyncResponse> create(
      Database db, String name, int color) async {
    try {
      await db.execute(
          "INSERT INTO ${Tags.table} ('${Tags.name}','${Tags.color}') VALUES ('$name',$color)");
      return AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }

  static Future<AsyncResponse> list(Database db) async {
    try {
      List results = await db.rawQuery("SELECT * FROM ${Tags.table}");
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

  static Future<AsyncResponse> delete(Database db, int id) async {
    try {
      String sql = 'DELETE FROM ${Tags.table} WHERE ${Tags.id} = $id';
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
          'UPDATE ${Tags.table} SET ${Tags.name} = "$newName",${Tags.color} = $newColor WHERE ${Tags.id} = $id';
      db.execute(sql);
      return AsyncResponse(ResponseStatus.success, "Deleted tag successfull");
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, e);
    }
  }
}

class TaggedScreensUtils {
  static Future<AsyncResponse> insert(Database db, int tagId, int docId) async {
    try {
      await db.rawInsert(
          "INSERT INTO ${TaggedScreens.table} ('${TaggedScreens.tid}','${TaggedScreens.docid}') VALUES($tagId,$docId)");
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
          """SELECT ${Screenshots.hash},${Screenshots.imagePath},${Screenshots.text},${Screenshots.docid} FROM ${Screenshots.table} WHERE ${Screenshots.docid} IN (SELECT ${Screenshots.docid} FROM ${TaggedScreens.table} WHERE ${TaggedScreens.tid}=$tagId)""";

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
          'DELETE FROM ${TaggedScreens.table} WHERE ${TaggedScreens.tid} = $tagId AND ${TaggedScreens.docid} = $docId';
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
          "SELECT ${TaggedScreens.docid} FROM ${TaggedScreens.table} WHERE ${TaggedScreens.tid}=$id");
    }

    return "SELECT * FROM ${Screenshots.table} WHERE ${Screenshots.docid} IN (" +
        (subSql.length > 1 ? subSql.join(" INTERSECT ") : subSql[0]) +
        ")";
  }
}

class ScreenshotsUtils {
  static Future<AsyncResponse> deleteAll(Database db) async {
    try {
      await db.execute('DELETE FROM ${Screenshots.table}');
      AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      AsyncResponse(ResponseStatus.failed, null);
    }
    return AsyncResponse(ResponseStatus.unkown, null);
  }

  static Future<void> delete(Database db, int hash) async {
    try {
      await db.rawQuery('DELETE FROM ${Screenshots.table} WHERE hash = $hash');
    } catch (e) {
      print(e);
    }
  }

  ///Check if image already exist
  static Future<bool> exist(Database db, int hash) async {
    final records = await db.rawQuery(
        'SELECT ${Screenshots.hash} FROM ${Screenshots.table} WHERE ${Screenshots.hash} = $hash');
    if (records == null) return false;
    if (records.length > 0) return true;
    return false;
  }

  /// Returns all screenshots
  static Future<List<ScreenshotModel>> list(Database db) async {
    List<ScreenshotModel> screenshots = [];
    try {
      List<Map> records = await db.rawQuery(
          "SELECT ${Screenshots.hash},${Screenshots.imagePath},${Screenshots.text},${Screenshots.docid} FROM ${Screenshots.table} ORDER BY ${Screenshots.docid} DESC");
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
    await db.insert(Screenshots.table, model.toMap());
  }

  static Future<List<ScreenshotModel>> find(Database db, String query,
      {Set<int> filter}) async {
    List<String> subSql = [];
    String filterSQL = "";
    if (filter != null) {
      for (var id in filter) {
        subSql.add(
            "SELECT ${TaggedScreens.docid} FROM ${TaggedScreens.table} WHERE ${TaggedScreens.tid}=$id");
      }
      if (subSql.isNotEmpty) {
        filterSQL = "AND ${Screenshots.docid} IN (" +
            (subSql.length > 1 ? subSql.join(" INTERSECT ") : subSql[0]) +
            ")";
      }
    }
    final String sql =
        'SELECT * FROM ${Screenshots.table} WHERE ${Screenshots.text} MATCH "$query*" $filterSQL';
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
            'DELETE FROM ${Screenshots.table} WHERE ${Screenshots.hash} = ${item.hash}';
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
