import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ural/database.dart';
import 'package:ural/utils/async.dart';
// import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/models/tags_model.dart';

enum TagAction {
  /// Create a new tag with a name and color code
  ///
  /// Requires: `String:name`, `int:color`
  create,

  /// Fetch all tags from the database
  fetch
}
enum TagState { loading, completed }

class TagsBloc extends BlocBase<TagState, TagAction, List<TagModel>> {
  ScreenshotListDatabase _slDB;
  TagsBloc() : super(state: TagState.loading, object: []);

  void initializeDatabase(ScreenshotListDatabase db) {
    _slDB = db;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void dispatch(TagAction actionState, [Map<String, dynamic> data]) {
    switch (actionState) {
      case TagAction.fetch:
        _getTags();
        break;
      case TagAction.create:
        _createTag(data["name"], data["color"]);
        break;
      default:
    }
  }

  void _createTag(String name, int color) async {
    final resp = await TagUtils.create(_slDB.db, name, color);
    if (resp.state == ResponseStatus.success) {
      _getTags();
    } else {
      if (resp.object.message.contains("2067")) {
        Fluttertoast.showToast(
            msg: "Tag already exist",
            backgroundColor: Colors.red,
            textColor: Colors.white);
      }
    }
  }

  void _getTags() async {
    final result = await TagUtils.getTags(_slDB.db);
    if (result.state == ResponseStatus.success) {
      updateState(TagState.completed, result.object);
    }
  }
}
