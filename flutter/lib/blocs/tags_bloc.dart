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
  fetch,

  /// Requires: `int:index`,`TagModel:model`
  update,

  /// Delete the tag
  /// Requires: `int:index`,`TagModel:model`
  delete
}
enum TagState { loading, completed }

class TagsBloc extends BlocBase<TagState, TagAction, List<TagModel>> {
  AppDB _slDB;
  TagsBloc() : super(state: TagState.loading, object: []);

  void initializeDatabase(AppDB db) {
    _slDB = db;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void dispatch(TagAction actionState,
      {Map<String, dynamic> data, VoidOnComplete onComplete}) {
    switch (actionState) {
      case TagAction.fetch:
        _getTags();
        break;
      case TagAction.create:
        _createTag(data["name"], data["color"]);
        break;
      case TagAction.update:
        _updateTag(data["index"], data["model"]);
        break;
      case TagAction.delete:
        _deleteTag(data["index"], data["model"]);
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
    final result = await TagUtils.list(_slDB.db);
    if (result.state == ResponseStatus.success) {
      updateState(TagState.completed, result.object);
    }
  }

  void _updateTag(int index, TagModel model) async {
    final result =
        await TagUtils.update(_slDB.db, model.id, model.name, model.colorCode);
    if (result.state == ResponseStatus.success) {
      event.object[index] = model;
      updateState(TagState.completed, event.object);
    }
  }

  void _deleteTag(int index, TagModel model) async {
    final result = await TagUtils.delete(_slDB.db, model.id);
    if (result.state == ResponseStatus.success) {
      event.object.removeAt(index);
      updateState(TagState.completed, event.object);
    }
  }
}
