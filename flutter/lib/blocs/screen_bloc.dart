import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ural/models/tags_model.dart';

import 'package:ural/prefrences.dart';
import 'package:ural/database.dart';
import 'package:ural/utils/async.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/models/screen_model.dart';

// I do not prefer the approach of passing data through streams
// The States represents the state of an entitiy
// Widgets rebuild itself according to state

abstract class AbstractScreenshots extends BlocBase
    implements ActionReceiver<RecentScreenAction> {
  ScreenshotListDatabase _slDB;
  StreamState<RecentScreenStates, List<ScreenshotModel>> state;

  /// Initialize database
  void initializeDatabase(ScreenshotListDatabase db) {
    _slDB = db;
  }
}

enum RecentScreenStates { loading, done }
enum RecentScreenAction {
  /// Get all screenshots again
  fetch
}

class RecentScreenBloc extends AbstractScreenshots {
  // ScreenshotListDatabase _slDB;
  // StreamState<RecentScreenStates, List<ScreenshotModel>> state;

  RecentScreenBloc() {
    state = StreamState<RecentScreenStates, List<ScreenshotModel>>(
        SubState<RecentScreenStates, List<ScreenshotModel>>(
            RecentScreenStates.loading, List<ScreenshotModel>()));
  }

  @override
  void dispatch(RecentScreenAction actionState, [Map<String, dynamic> data]) {
    switch (actionState) {
      case RecentScreenAction.fetch:
        _getAllScreens();
        break;
      default:
    }
  }

  /// List all screenshots from the database
  void _getAllScreens() async {
    //update the data
    state.data = await _slDB.list();
    //update the state
    state.currentState = RecentScreenStates.done;
    //notifiy listeners
    state.notifyListeners();
  }

  Future<bool> handleRemove(List<ScreenshotModel> selected) async {
    final resp = await _slDB.removeBatch(selected);
    dispatch(RecentScreenAction.fetch);
    return resp.state == ResponseStatus.success;
  }

  void handleDeleteSuccess() {
    Fluttertoast.showToast(msg: "Screenshots deleted");
  }

  void handleDeleteError() {
    Fluttertoast.showToast(msg: "Couldn't delete screenshots");
  }

  void dispose() {
    state.dispose();
  }
}

class TaggedScreenBloc extends AbstractScreenshots {
  TagModel model;
  TaggedScreenBloc() {
    state = StreamState<RecentScreenStates, List<ScreenshotModel>>(
        SubState<RecentScreenStates, List<ScreenshotModel>>(
            RecentScreenStates.loading, List<ScreenshotModel>()));
  }

  void initializeModel(TagModel tagModel) {
    model = tagModel;
  }

  @override
  void dispose() {
    state.dispose();
  }

  @override
  void dispatch(RecentScreenAction actionState, [Map<String, dynamic> data]) {
    switch (actionState) {
      case RecentScreenAction.fetch:
        _getAllScreens();
        break;
      default:
    }
  }

  void _getAllScreens() async {
    final resp = await TagUtils.getScreensByTag(_slDB.db, model.id);
    if (resp.state == ResponseStatus.success) {
      state.data = resp.object;
      state.currentState = RecentScreenStates.done;
      state.notifyListeners();
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
}

enum SearchStates { idle, searching, done, empty }
enum SearchAction { fetch, reset }

class SearchScreenBloc extends BlocBase
    implements ActionReceiver<SearchAction> {
  ScreenshotListDatabase _slDB;
  StreamState<SearchStates, List<ScreenshotModel>> state;

  SearchScreenBloc() {
    state = StreamState<SearchStates, List<ScreenshotModel>>(
        SubState<SearchStates, List<ScreenshotModel>>(
            SearchStates.idle, List<ScreenshotModel>()));
  }

  /// Initialize database
  void initializeDatabase(ScreenshotListDatabase db) {
    _slDB = db;
  }

  @override
  void dispose() {
    state.dispose();
  }

  @override
  void dispatch(SearchAction actionState, [Map<String, dynamic> data]) {
    switch (actionState) {
      case SearchAction.fetch:
        _find(data["query"], data["ural_pref"]);
        break;
      case SearchAction.reset:
        state.currentState = SearchStates.idle;
        break;

      default:
    }
  }

  // int count = 0;
  void _find(String query, UralPrefrences prefrences) async {
    state.currentState = SearchStates.searching;
    state.notifyListeners();

    _slDB.find(query).then((screenshots) {
      if (screenshots.length > 0) {
        state.currentState = SearchStates.done;
        prefrences.updateRecentSearches(query);
      } else {
        state.currentState = SearchStates.empty;
      }
      state.data = screenshots;
      state.notifyListeners();
      // count++;
      // print("COUNT - $count");
    });
  }
}

enum SearchFieldState { change, reset, recent }

class SearchFieldBloc extends BlocBase
    implements ActionReceiver<SearchFieldState> {
  TextEditingController _fieldController;
  String _previousValue = "";

  StreamState<SearchFieldState, String> state;

  SearchFieldBloc() {
    state = StreamState<SearchFieldState, String>(
        SubState<SearchFieldState, String>(SearchFieldState.reset, ""));
  }

  void initialize(TextEditingController controller) {
    _fieldController = controller;
    _fieldController.addListener(handleTextField);
  }

  @override
  void dispatch(SearchFieldState actionState, [Map<String, dynamic> data]) {
    switch (actionState) {
      case SearchFieldState.change:
        state.data = _fieldController.text;
        state.currentState = SearchFieldState.change;
        state.notifyListeners();
        break;
      case SearchFieldState.reset:
        state.data = _fieldController.text;
        state.currentState = SearchFieldState.reset;
        state.notifyListeners();
        break;
      case SearchFieldState.recent:
        _recentSearch(data["recent_query"]);
        break;
      default:
    }
  }

  @override
  void dispose() {
    state.dispose();
  }

  void handleTextField() {
    if (_fieldController.text.length == 0) {
      dispatch(SearchFieldState.reset);
    } else {
      if (_previousValue != _fieldController.text) {
        dispatch(SearchFieldState.change);
        _previousValue = _fieldController.text;
      }
    }
  }

  void _recentSearch(String query) {
    _fieldController.text = query;
    state.data = query;
    state.currentState = SearchFieldState.change;
    state.notifyListeners();
  }

  String getText() => _fieldController.text;
}

enum SelectionStates { contains, empty, modified }
enum SelectionAction { add, remove, reset }

class ScreenSelectionBloc extends BlocBase
    implements ActionReceiver<SelectionAction> {
  StreamState<SelectionStates, Map<int, ScreenshotModel>> state;

  ScreenSelectionBloc() {
    state = StreamState<SelectionStates, Map<int, ScreenshotModel>>(
        SubState(SelectionStates.empty, {}));
  }

  @override
  void dispatch(SelectionAction actionState, [Map<String, dynamic> data]) {
    switch (actionState) {
      case SelectionAction.add:
        _addItem(data["model"]);
        break;
      case SelectionAction.remove:
        _removeItem(data["hash"]);
        break;
      case SelectionAction.reset:
        _reset();
        break;
      default:
    }
  }

  @override
  void dispose() {
    state.dispose();
  }

  void _addItem(ScreenshotModel model) {
    state.data[model.hash] = model;
    state.currentState = SelectionStates.contains;
    state.notifyListeners();
  }

  void _removeItem(int hash) {
    if (state.data.containsKey(hash)) {
      state.data.remove(hash);
      if (state.data.keys.isEmpty) {
        state.currentState = SelectionStates.empty;
      } else {
        state.currentState = SelectionStates.modified;
      }
      state.notifyListeners();
    }
  }

  void _reset() {
    state.data = {};
    state.currentState = SelectionStates.empty;
    state.notifyListeners();
  }
}

// class ScreenBloc extends BlocBase {
//   // database
//   final ScreenshotListDatabase _slDB = ScreenshotListDatabase();

//   final textRecognizer = FirebaseVision.instance.textRecognizer();

//   List<ScreenshotModel> recentScreenshots = [];
//   List<ScreenshotModel> searchResults = [];

//   //manages search events
//   final BehaviorSubject<SearchStates> _searchSubject =
//       BehaviorSubject<SearchStates>.seeded(SearchStates.idle);

//   // manages recent screens events
//   final BehaviorSubject<RecentScreenStates> _rscreenSubject =
//       BehaviorSubject<RecentScreenStates>.seeded(RecentScreenStates.loading);

//   Observable<RecentScreenStates> get streamOfRecentScreens =>
//       _rscreenSubject.stream;
//   Observable<SearchStates> get streamofSearchResults => _searchSubject.stream;

//   Future<void> initializeDatabase() async {
//     await _slDB.initDB();
//   }

//   /// List all screenshots from the database
//   void listAllScreens() async {
//     recentScreenshots = await _slDB.list();
//     //update the stream
//     _rscreenSubject.add(RecentScreenStates.done);
//   }

//   Future<void> hardReset() async {
//     await _slDB.reset();
//   }

//   /// Delete an Image from the database
//   Future<void> delete(String path) async {
//     await _slDB.delete(path.hashCode);
//     //rebuild the recent screens
//     listAllScreens();
//   }

/// Tells the workmanager to issue a new periodic task
// static void startBackGroundJob() async {
//   await Workmanager.registerPeriodicTask(
//       "uralfetchscreens", "ural_background",
//       frequency: Duration(hours: 2), initialDelay: Duration(seconds: 1));
// }

// static void cancelBackGroundJob() async {
//   await Workmanager.cancelByUniqueName("uralfetchscreens");
// }

// void handleBackgroundSync(GlobalKey<ScaffoldState> scaffold) async {
//   final pref = await SharedPreferences.getInstance();
//   // only thing prevents from background sync is an unset default folder
//   if (pref.containsKey("ural_default_folder")) {
//     startBackGroundJob();
//     scaffold.currentState.showSnackBar(SnackBar(
//       content: Text("Background sync has been initialized"),
//       backgroundColor: Colors.greenAccent,
//     ));
//   } else {
//     scaffold.currentState.showSnackBar(SnackBar(
//       content: Text("No default directory set"),
//       backgroundColor: Colors.redAccent,
//     ));
//   }
// }

/// Handles textField or searchField queries
// Future<void> handleTextField(String query,
//     {PageController pageController}) async {
//   // if (pageController.page == 0) {
//   //   pageController.nextPage(
//   //       duration: Duration(milliseconds: 350),
//   //       curve: Curves.fastLinearToSlowEaseIn);
//   // }
//   _searchSubject.add(SearchStates.searching);
//   searchResults = await _slDB.find(query);
//   if (searchResults.length > 0) {
//     _searchSubject.add(SearchStates.done);
//   } else {
//     _searchSubject.add(SearchStates.empty);
//   }
// }

/// Gets called when manual-upload button called
//   void handleManualUpload(GlobalKey<ScaffoldState> scaffoldState) async {
//     File image = await ImagePicker.pickImage(source: ImageSource.gallery);
//     String text = await recognizeImage(image, getBlocks: false);
//     ScreenshotModel model =
//         ScreenshotModel(image.path.hashCode, image.path, text);

//     final resp = await saveToDatabase(model);

//     /// I don't want upload the same image twice
//     if (resp.state == ResponseStatus.success) {
//       scaffoldState.currentState.showSnackBar(SnackBar(
//         content: Text("Image uploaded successfully"),
//         backgroundColor: Colors.greenAccent,
//       ));
//       listAllScreens();
//     } else {
//       scaffoldState.currentState.showSnackBar(SnackBar(
//         content: Text("Image already exist"),
//         backgroundColor: Colors.redAccent,
//       ));
//     }
//   }

//   /// A future task that utilizes [AsyncResponse]
//   /// If the image already exist throw an InsertionError
//   Future<AsyncResponse> saveToDatabase(ScreenshotModel model) async {
//     try {
//       bool exist = await _slDB.exist(model.hash);
//       if (!exist) {
//         await _slDB.insert(model);
//       } else {
//         throw InsertionError(
//             "Failed when trying to add model-hash: ${model.hash}");
//       }
//     } on InsertionError catch (e) {
//       return AsyncResponse(ResponseStatus.failed, e.message);
//     } catch (e) {
//       print(e);
//     }
//     return AsyncResponse(ResponseStatus.success, null);
//   }

//   Future<dynamic> recognizeImage(File image, {bool getBlocks = false}) async {
//     //parsed image
//     final visionImage = FirebaseVisionImage.fromFile(image);
//     //processing parsed image
//     final visionText = await textRecognizer.processImage(visionImage);
//     if (getBlocks) return visionText.blocks;
//     //reutrn text
//     return visionText.text;
//   }

//   void setDefaultFolder(String path) async {
//     final pref = await SharedPreferences.getInstance();
//     pref.setString("ural_default_folder", path);
//   }

//   void dispose() {
//     _searchSubject.close();
//     _rscreenSubject.close();
//   }
// }
