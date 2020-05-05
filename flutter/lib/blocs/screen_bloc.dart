import 'package:fluttertoast/fluttertoast.dart';
import 'package:ural/models/tags_model.dart';

import 'package:ural/database.dart';
import 'package:ural/utils/async.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/utils/file_utils.dart';

abstract class AbstractScreenshots extends BlocBase<RecentScreenStates,
    RecentScreenAction, List<ScreenshotModel>> {
  AppDB _slDB;

  AbstractScreenshots()
      : super(
            state: RecentScreenStates.loading, object: List<ScreenshotModel>());

  /// Initialize database
  void initializeDatabase(AppDB db) {
    _slDB = db;
  }

  Future<void> _deleteItems(List<ScreenshotModel> models) async {
    List<int> hash = [];
    List<String> paths = [];

    for (var model in models) {
      hash.add(model.hash);
      paths.add(model.imagePath);
    }

    final result = List.from((await FileUtils.deleteFiles(paths)).values);

    for (var i = 0; i < hash.length; i++) {
      if (result[i]) ScreenshotsUtils.delete(_slDB.db, hash[i]);
    }
  }
}

enum RecentScreenStates { loading, done }
enum RecentScreenAction {
  /// Fetch all screenshots from the database
  fetch,

  /// Delete
  /// Require: `List<ScreenshotModel>:selected_models`
  delete,

  /// Require: `List<ScreenshotModel>:selected_models` , `TagModel: tag`
  remove
}

class RecentScreenBloc extends AbstractScreenshots {
  @override
  void dispatch(RecentScreenAction actionState,
      {Map<String, dynamic> data, VoidOnComplete onComplete}) async {
    switch (actionState) {
      case RecentScreenAction.fetch:
        _getAllScreens();
        break;
      case RecentScreenAction.delete:
        await _deleteItems(data["selected_models"]);
        break;
      default:
    }
    onComplete?.call();
  }

  /// List all screenshots from the database
  void _getAllScreens() async {
    updateState(RecentScreenStates.done, await ScreenshotsUtils.list(_slDB.db));
  }

  Future<bool> handleRemove(List<ScreenshotModel> selected) async {
    final resp = await ScreenshotsUtils.deleteMultiple(_slDB.db, selected);
    dispatch(RecentScreenAction.fetch);
    return resp.state == ResponseStatus.success;
  }

  void handleDeleteSuccess() {
    Fluttertoast.showToast(msg: "Screenshots deleted");
  }

  void handleDeleteError() {
    Fluttertoast.showToast(msg: "Couldn't delete screenshots");
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class TaggedScreenBloc extends AbstractScreenshots {
  TagModel model;

  void initializeModel(TagModel tagModel) {
    model = tagModel;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void dispatch(RecentScreenAction actionState,
      {Map<String, dynamic> data, VoidOnComplete onComplete}) async {
    switch (actionState) {
      case RecentScreenAction.fetch:
        _getAllScreens();
        break;
      case RecentScreenAction.delete:
        await _deleteItems(data["selected_models"]);
        break;
      case RecentScreenAction.remove:
        await _removeItems(data["selected_models"], data["tag"]);
        break;
      default:
    }
    if (onComplete != null) onComplete();
  }

  void _getAllScreens() async {
    final resp = await TagUtils.getScreensByTag(_slDB.db, model.id);
    if (resp.state == ResponseStatus.success) {
      updateState(RecentScreenStates.done, resp.object);
    }
  }

  Future<void> handleAdd(List<int> docIds) async {
    if (docIds != null) {
      for (var id in docIds) {
        await TagUtils.insert(_slDB.db, model.id, id);
      }
      dispatch(RecentScreenAction.fetch);
    }
  }

  Future<void> _removeItems(List<ScreenshotModel> models, TagModel tag) async {
    for (var model in models) {
      await TagUtils.deleteTaggedScreen(_slDB.db, tag.id, model.docId);
    }
  }
}
