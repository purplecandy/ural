import 'package:flutter/widgets.dart';

import 'package:ural/database/database.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/utils/file_utils.dart';

abstract class AbstractScreenshots<S, A>
    extends BlocBase<S, A, List<ScreenshotModel>> {
  AppDB appDB;

  AbstractScreenshots({@required S state})
      : super(state: state, object: List<ScreenshotModel>());

  /// Initialize database
  void initializeDatabase(AppDB db) {
    appDB = db;
  }

  Future<void> deleteItems(List<ScreenshotModel> models) async {
    List<int> hash = [];
    List<String> paths = [];

    for (var model in models) {
      hash.add(model.hash);
      paths.add(model.imagePath);
    }

    final result = List.from((await FileUtils.deleteFiles(paths)).values);

    for (var i = 0; i < hash.length; i++) {
      if (result[i]) ScreenshotsUtils.delete(appDB.db, hash[i]);
    }
  }
}
