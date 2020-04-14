import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:ural/utils/bloc_provider.dart';
import 'dart:convert';

import 'package:ural/utils/file_utils.dart';

class SavedDirectory {
  final String path, itemsCount;
  SavedDirectory(this.path, this.itemsCount);

  factory SavedDirectory.fromJson(Map<String, String> json) =>
      SavedDirectory(json["path"], json["itemsCount"]);

  String toString() => json.encode({"path": path, "items_count": itemsCount});
  Map<String, dynamic> toMap() => {"path": path, "items_count": itemsCount};
}

class UralPrefrences extends ChangeNotifier {
  // static final UralPrefrences _instance = UralPrefrences._();
  // factory UralPrefrences() => _instance;
  // UralPrefrences._();

  bool get initialized => _preferences != null;

  UralPrefrences() {
    getInstance();
  }

  SharedPreferences _preferences;
  final String directoryKey = "ural_settings_directories";
  final String syncStatusKey = "ural_settings_sync_status";
  final String initialSetupKey = "ural_settings_initial_setup";
  final String recentSearchesKey = "ural_settings_recent_search";
  static Directory thumbsDir;

  Future<void> getInstance() async {
    _preferences = await SharedPreferences.getInstance();
    getApplicationDocumentsDirectory().then((dir) {
      final cache = Directory(dir.path + '/thumbs');
      if (!cache.existsSync()) cache.createSync();
      thumbsDir = cache;
      notifyListeners();
    });
  }

  // void removeKey(String key) async => await SharedPreferences.getInstance()
  //   ..remove(key);
  void removeKey(String key) => _preferences.remove(key);

  String encodeJson(var object) {
    String result = json.encode(object);
    var bytes = utf8.encode(result);
    var base64Str = base64.encode(bytes);
    return base64Str;
  }

  String decodeJsonString(String base64Str) {
    var bytes = base64.decode(base64Str);
    String result = utf8.decode(bytes);
    return result;
  }

  List<String> getRecentSearches() {
    if (_preferences.containsKey(recentSearchesKey)) {
      return _preferences.getString(recentSearchesKey).split(":");
    }
    return [];
  }

  void updateRecentSearches(String query) {
    if (_preferences.containsKey(recentSearchesKey)) {
      List<String> searches =
          _preferences.getString(recentSearchesKey).split(":");
      if (searches.length < 5) {
        searches.add(query);
        _preferences.setString(recentSearchesKey, searches.join(":"));
      } else {
        var temp = searches.sublist(1);
        temp.add(query);
        _preferences.setString(recentSearchesKey, temp.join(":"));
      }
    } else {
      _preferences.setString(recentSearchesKey, query);
    }
  }

  Future<void> findAndSaveDirectories() async {
    //finds internal and external storage list
    final List<Directory> dirs = await FileUtils.getStorageList();

    //list for screenshot directories
    List<String> paths = List<String>();

    RegExp reg = RegExp(r"\w*Screenshot(s?)$", caseSensitive: true);

    //loop in each storage
    for (var dir in dirs) {
      List<FileSystemEntity> entities =
          Directory(dir.path).listSync(recursive: true);

      //identify each entity is actually a screenshot folder
      for (var item in entities) {
        if (item is Directory) {
          if (reg.hasMatch(item.path)) paths.add(item.path);
        }
      }
    }
    //save directories
    setDirectories(paths);
  }

  Future<void> setDirectories(List<String> directories) async {
    if (directories.length > 0) {
      String serialized = directories.join(":");
      await _preferences.setString(directoryKey, serialized);
    }
  }

  List<String> getDirectories() {
    return _preferences.getString(directoryKey).split(":");
  }

  void removeDirectory(String path) {
    final List<String> dirs = getDirectories();
    for (int i = 0; i < dirs.length; i++) {
      if (dirs[i].hashCode == path.hashCode) {
        dirs.removeAt(i);
        break;
      }
    }
    setDirectories(dirs);
  }

  bool getSyncStatus() {
    if (_preferences.containsKey(syncStatusKey)) {
      return _preferences.getBool(syncStatusKey);
    }
    return false;
  }

  void setSyncStatus(bool status) {
    _preferences.setBool(syncStatusKey, status);
  }

  bool getInitalSetupStatus() {
    if (_preferences.containsKey(initialSetupKey)) {
      return _preferences.getBool(initialSetupKey);
    }
    return false;
  }

  void setInitialSetupStatus(bool status) {
    _preferences.setBool(initialSetupKey, status);
  }
}

Future<List<String>> findDirectories(List<Directory> dirs) async {
  // finds internal and external storage list
  // final List<Directory> dirs = await FileUtils.getStorageList();

  //list for screenshot directories
  List<String> paths = List<String>();

  RegExp reg = RegExp(r"\w*Screenshot(s?)$", caseSensitive: true);
  //loop in each storage
  for (var dir in dirs) {
    List<FileSystemEntity> entities =
        Directory(dir.path).listSync(recursive: true);

    //identify each entity is actually a screenshot folder
    for (var item in entities) {
      if (item is Directory) {
        //add to path if match exist
        if (reg.hasMatch(item.path)) paths.add(item.path);
      }
    }
  }
  return paths;
  //save directories
  // if(paths.length > 0){
  //   SharedPreferences preferences = await SharedPreferences.getInstance();
  //   String serialized = paths.join(":");
  //   preferences.setString("ural_settings_directories", serialized);
  // }
}

Future<int> calculate(int value) async {
  // this runs on another isolate
  return value * 2;
}
