import 'package:ural/database.dart';
import 'package:ural/pages/setup.dart';
import 'package:ural/utils/async.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/models/screen_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:folder_picker/folder_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:ural/pages/textview.dart';
import 'package:workmanager/workmanager.dart';

class ScreenBloc extends BlocBase {
  final ScreenshotListDatabase _slDB = ScreenshotListDatabase();

  final textRecognizer = FirebaseVision.instance.textRecognizer();

  List<ScreenshotModel> recentScreenshots = [];
  List<ScreenshotModel> searchResults = [];

  final BehaviorSubject<SearchStates> _searchSubject =
      BehaviorSubject<SearchStates>.seeded(SearchStates.searching);

  final BehaviorSubject<StreamEvents> _rscreenSubject =
      BehaviorSubject<StreamEvents>.seeded(StreamEvents.loading);

  Observable<StreamEvents> get streamOfRecentScreens => _rscreenSubject.stream;
  Observable<SearchStates> get streamofSearchResults => _searchSubject.stream;

  Future<void> initializeDatabase() async {
    await _slDB.initDB();
  }

  void listAllScreens() async {
    recentScreenshots = await _slDB.list();
    _rscreenSubject.add(StreamEvents.done);
  }

  Future<void> delete(String path) async {
    await _slDB.delete(path.hashCode);
    listAllScreens();
  }

  static void startBackGroundJob() async {
    await Workmanager.registerPeriodicTask(
        "uralfetchscreens", "ural_background",
        frequency: Duration(hours: 2), initialDelay: Duration(seconds: 5));
  }

  void handleBackgroundSync(GlobalKey<ScaffoldState> scaffold) async {
    final pref = await SharedPreferences.getInstance();
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
  Future<void> handleTextField({
    String query,
    PageController pageController,
  }) async {
    pageController.nextPage(
        duration: Duration(milliseconds: 350),
        curve: Curves.fastLinearToSlowEaseIn);

    _searchSubject.add(SearchStates.searching);
    searchResults = await _slDB.find(query);
    if (searchResults.length > 0) {
      _searchSubject.add(SearchStates.finished);
    } else {
      _searchSubject.add(SearchStates.empty);
    }
  }

  ///Handle textView events
  void handleTextView(BuildContext context) async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    final blocks = await recognizeImage(image, getBlocks: true);
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => TextView(
                  textBlocks: blocks,
                )));
  }

  /// Gets called when manual-upload button called
  void handleManualUpload(GlobalKey<ScaffoldState> scaffoldState) async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    String text = await recognizeImage(image, getBlocks: false);
    ScreenshotModel model =
        ScreenshotModel(image.path.hashCode, image.path, text);

    final resp = await saveToDatabase(model);

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

  /// Handles Settings button events
  void handleSettings(BuildContext context) async {
    showModalBottomSheet(
        context: context,
        builder: (context) => SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) => Setup()));
                          },
                          leading: Icon(Icons.build),
                          title: Text("Setup Ural"),
                          subtitle: Text("Configure Ural settings"),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: ListTile(
                            onTap: () async {
                              const url =
                                  "mailto:hellomr82k@gmail.com?subject=Feedback";
                              if (await canLaunch(url)) {
                                launch(url);
                              }
                            },
                            leading: Icon(Icons.person),
                            title: Text("Mohammed Nadeem"),
                            subtitle: Text("Author of Ural"),
                            trailing: Icon(
                              Icons.mail,
                              color: Colors.redAccent,
                            )),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: ListTile(
                          onTap: () async {
                            const url =
                                "https://play.google.com/store/apps/details?id=in.kibibyte.ural";
                            if (await canLaunch(url)) {
                              launch(url);
                            }
                          },
                          leading: Icon(Icons.rate_review),
                          title: Text("Rate and Review"),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: ListTile(
                          onTap: () async {
                            const url =
                                "https://github.com/purplecandy/ural/tree/master/flutter";
                            if (await canLaunch(url)) {
                              launch(url);
                            }
                          },
                          leading: Icon(Icons.archive),
                          title: Text("Github Repository"),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
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
