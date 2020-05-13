import 'package:fluttertoast/fluttertoast.dart';

import 'package:ural/blocs/abstract_screens.dart';
import 'package:ural/models/tags_model.dart';
import 'package:ural/database/database.dart';
import 'package:ural/utils/async.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/models/screen_model.dart';

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

class RecentScreenBloc
    extends AbstractScreenshots<RecentScreenStates, RecentScreenAction> {
  RecentScreenBloc() : super(state: RecentScreenStates.loading);

  @override
  void dispatch(RecentScreenAction actionState,
      {Map<String, dynamic> data, VoidOnComplete onComplete}) async {
    switch (actionState) {
      case RecentScreenAction.fetch:
        _getAllScreens();
        break;
      case RecentScreenAction.delete:
        await deleteItems(data["selected_models"]);
        _updateDeleted(data["selected_models"]);
        break;
      default:
    }
    onComplete?.call();
  }

  /// List all screenshots from the database
  void _getAllScreens() async {
    updateState(RecentScreenStates.done, await ScreenshotsUtils.list(appDB.db));
  }

  Future<bool> handleRemove(List<ScreenshotModel> selected) async {
    final resp = await ScreenshotsUtils.deleteMultiple(appDB.db, selected);
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

  void _updateDeleted(List<ScreenshotModel> models) {
    event.object.removeWhere((element) => models.contains(element));
    updateState(RecentScreenStates.done, event.object);
  }
}

class TaggedScreenBloc
    extends AbstractScreenshots<RecentScreenStates, RecentScreenAction> {
  TaggedScreenBloc() : super(state: RecentScreenStates.loading);
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
        await deleteItems(data["selected_models"]);
        _updateDeleted(data["selected_models"]);
        break;
      case RecentScreenAction.remove:
        await _removeItems(data["selected_models"], data["tag"]);
        break;
      default:
    }
    if (onComplete != null) onComplete();
  }

  void _getAllScreens() async {
    final resp = await TaggedScreensUtils.list(appDB.db, model.id);
    if (resp.state == ResponseStatus.success) {
      updateState(RecentScreenStates.done, resp.object);
    }
  }

  Future<void> handleAdd(List<int> docIds) async {
    if (docIds != null) {
      for (var id in docIds) {
        await TaggedScreensUtils.insert(appDB.db, model.id, id);
      }
      dispatch(RecentScreenAction.fetch);
    }
  }

  Future<void> _removeItems(List<ScreenshotModel> models, TagModel tag) async {
    for (var model in models) {
      await TaggedScreensUtils.delete(appDB.db, tag.id, model.docId);
    }
  }

  void _updateDeleted(List<ScreenshotModel> models) {
    event.object.removeWhere((element) => models.contains(element));
    updateState(RecentScreenStates.done, event.object);
  }
}
