import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:ural/config.dart';
import 'dart:io';
import 'dart:async';
import 'schemas.dart';

class InsertionError implements Exception {
  final message;
  InsertionError(this.message);
}

class AppDB {
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
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${Tags.table}'");

    if (tables.isEmpty) createTagsTable(db);

    tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${TaggedScreens.table}'");

    if (tables.isEmpty) createTagScreensTable(db);
  }

  Future _createTables(Database db, int version) async {
    ///sql query for virtual table for full-text-search
    await db.execute('PRAGMA foreign_keys = ON');

    String sql =
        '''CREATE VIRTUAL TABLE ${Screenshots.table} USING fts4(${Screenshots.hash},${Screenshots.imagePath},${Screenshots.text})''';
    await db.execute(sql).then((val) {
      print("Virtual table created successfully");
    });

    createTagsTable(db);

    createTagScreensTable(db);
  }

  Future<void> createTagsTable(Database db) async {
    String sql = '''
    CREATE TABLE ${Tags.table} (
      ${Tags.id} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      ${Tags.name} varchar(25) UNIQUE NOT NULL,
      ${Tags.color} INTEGER
    )
    ''';
    await db.execute(sql).then((val) {
      print("${Tags.table} table created successfully");
    });
  }

  Future<void> createTagScreensTable(Database db) async {
    String sql = '''
    CREATE TABLE ${TaggedScreens.table} (
      ${TaggedScreens.tid} INTEGER NOT NULL,
      ${TaggedScreens.docid} INTEGER NOT NULL,
      FOREIGN KEY (${TaggedScreens.tid}) REFERENCES ${Tags.table}(${Tags.id}) ON DELETE CASCADE,
      FOREIGN KEY (${TaggedScreens.docid}) REFERENCES ${Screenshots.table}(${Screenshots.docid}) ON DELETE CASCADE,
      CONSTRAINT combo UNIQUE (${TaggedScreens.tid},${TaggedScreens.docid})
    )''';

    await db.execute(sql).then((val) {
      print("${TaggedScreens.table} table created successfully");
    });
  }
}
