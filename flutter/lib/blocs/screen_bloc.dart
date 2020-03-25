import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'package:workmanager/workmanager.dart';

import 'package:ural/database.dart';
import 'package:ural/utils/async.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/models/screen_model.dart';

// I do not prefer the approach of passing data through streams
// The States represents the state of an entitiy
// Widgets rebuild itself according to state
enum RecentScreenStates { update, loading, done }
enum SearchStates { idle, searching, done, empty }

class ScreenBloc extends BlocBase {
  // database
  final ScreenshotListDatabase _slDB = ScreenshotListDatabase();

  final textRecognizer = FirebaseVision.instance.textRecognizer();

  List<ScreenshotModel> recentScreenshots = [];
  List<ScreenshotModel> searchResults = [];

  //manages search events
  final BehaviorSubject<SearchStates> _searchSubject =
      BehaviorSubject<SearchStates>.seeded(SearchStates.idle);

  // manages recent screens events
  final BehaviorSubject<RecentScreenStates> _rscreenSubject =
      BehaviorSubject<RecentScreenStates>.seeded(RecentScreenStates.loading);

  Observable<RecentScreenStates> get streamOfRecentScreens =>
      _rscreenSubject.stream;
  Observable<SearchStates> get streamofSearchResults => _searchSubject.stream;

  Future<void> initializeDatabase() async {
    await _slDB.initDB();
  }

  /// List all screenshots from the database
  void listAllScreens() async {
    recentScreenshots = await _slDB.list();
    //update the stream
    _rscreenSubject.add(RecentScreenStates.done);
  }

  Future<void> hardReset() async {
    await _slDB.reset();
  }

  /// Delete an Image from the database
  Future<void> delete(String path) async {
    await _slDB.delete(path.hashCode);
    //rebuild the recent screens
    listAllScreens();
  }

  /// Tells the workmanager to issue a new periodic task
  static void startBackGroundJob() async {
    await Workmanager.registerPeriodicTask(
        "uralfetchscreens", "ural_background",
        frequency: Duration(hours: 2), initialDelay: Duration(seconds: 1));
  }

  static void cancelBackGroundJob() async {
    await Workmanager.cancelByUniqueName("uralfetchscreens");
  }

  void handleBackgroundSync(GlobalKey<ScaffoldState> scaffold) async {
    final pref = await SharedPreferences.getInstance();
    // only thing prevents from background sync is an unset default folder
    if (pref.containsKey("ural_default_folder")) {
      startBackGroundJob();
      scaffold.currentState.showSnackBar(SnackBar(
        content: Text("Background sync has been initialized"),
        backgroundColor: Colors.greenAccent,
      ));
    } else {
      scaffold.currentState.showSnackBar(SnackBar(
        content: Text("No default directory set"),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  /// Handles textField or searchField queries
  Future<void> handleTextField(String query,
      {PageController pageController}) async {
    // if (pageController.page == 0) {
    //   pageController.nextPage(
    //       duration: Duration(milliseconds: 350),
    //       curve: Curves.fastLinearToSlowEaseIn);
    // }
    _searchSubject.add(SearchStates.searching);
    searchResults = await _slDB.find(query);
    if (searchResults.length > 0) {
      _searchSubject.add(SearchStates.done);
    } else {
      _searchSubject.add(SearchStates.empty);
    }
  }

  /// Gets called when manual-upload button called
  void handleManualUpload(GlobalKey<ScaffoldState> scaffoldState) async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    String text = await recognizeImage(image, getBlocks: false);
    ScreenshotModel model =
        ScreenshotModel(image.path.hashCode, image.path, text);

    final resp = await saveToDatabase(model);

    /// I don't want upload the same image twice
    if (resp.state == ResponseStatus.success) {
      scaffoldState.currentState.showSnackBar(SnackBar(
        content: Text("Image uploaded successfully"),
        backgroundColor: Colors.greenAccent,
      ));
      listAllScreens();
    } else {
      scaffoldState.currentState.showSnackBar(SnackBar(
        content: Text("Image already exist"),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  /// A future task that utilizes [AsyncResponse]
  /// If the image already exist throw an InsertionError
  Future<AsyncResponse> saveToDatabase(ScreenshotModel model) async {
    try {
      bool exist = await _slDB.exist(model.hash);
      if (!exist) {
        await _slDB.insert(model);
      } else {
        throw InsertionError(
            "Failed when trying to add model-hash: ${model.hash}");
      }
    } on InsertionError catch (e) {
      return AsyncResponse(ResponseStatus.failed, e.message);
    } catch (e) {
      print(e);
    }
    return AsyncResponse(ResponseStatus.success, null);
  }

  Future<dynamic> recognizeImage(File image, {bool getBlocks = false}) async {
    //parsed image
    final visionImage = FirebaseVisionImage.fromFile(image);
    //processing parsed image
    final visionText = await textRecognizer.processImage(visionImage);
    if (getBlocks) return visionText.blocks;
    //reutrn text
    return visionText.text;
  }

  void setDefaultFolder(String path) async {
    final pref = await SharedPreferences.getInstance();
    pref.setString("ural_default_folder", path);
  }

  void dispose() {
    _searchSubject.close();
    _rscreenSubject.close();
  }
}
