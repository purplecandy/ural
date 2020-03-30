import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ural/database.dart';
import 'package:ural/utils/async.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/models/tags_model.dart';

enum TagAction { create, fetch }
enum TagState { loading, completed }

class TagsBloc extends BlocBase implements ActionReceiver<TagAction> {
  ScreenshotListDatabase _slDB;
  StreamState<TagState, List<TagModel>> state;

  TagsBloc() {
    state = StreamState<TagState, List<TagModel>>(
        SubState<TagState, List<TagModel>>(TagState.loading, []));
  }

  void initializeDatabase(ScreenshotListDatabase db) {
    _slDB = db;
  }

  @override
  void dispose() {
    state.dispose();
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
      state.data = result.object;
      state.currentState = TagState.completed;
      state.notifyListeners();
    }
  }
}
