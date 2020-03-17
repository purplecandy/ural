import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:folder_picker/folder_picker.dart';
import 'package:ural/utils/async.dart';
import 'package:workmanager/workmanager.dart';

import 'package:ural/controllers/image_handler.dart';
import 'package:ural/pages/textview.dart';
import 'package:ural/utils/parsers.dart';
import 'package:ural/urls.dart';
import 'package:ural/blocs/auth_bloc.dart';
import 'package:ural/models/screen_model.dart';

/// Handles Settings button events
void handleSettings(BuildContext context) async {
  final pref = await SharedPreferences.getInstance();
  String dir = pref.getString("ural_default_folder");
  showModalBottomSheet(
      context: context,
      builder: (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text(Auth().user.username),
                      subtitle: Text("Currently logged in as"),
                      trailing: IconButton(
                          icon: Icon(
                            Icons.exit_to_app,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            final Auth auth = Auth();
                            await auth.logout();
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/');
                          }),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.folder),
                      title: Text(dir),
                      subtitle: Text("Default directory"),
                      trailing: IconButton(
                          icon: Icon(Icons.add_box),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) => FolderPickerPage(
                                        action: (context, directory) async {
                                          setDefaultFolder(directory.path);
                                          Navigator.pop(context);
                                        },
                                        rootDirectory: Directory(
                                            "/storage/emulated/0/"))));
                          }),
                    ),
                  ),
                )
              ],
            ),
          ));
}

/// Gets called when manual-upload button called
void handleManualUpload(GlobalKey<ScaffoldState> scaffoldState,
    TextRecognizer textRecognizer) async {
  File image = await ImagePicker.pickImage(source: ImageSource.gallery);
  final resp =
      await syncImageToServer(image, textRecognizer, Auth().user.token);
  if (resp.state == ResponseStatus.success) {
    scaffoldState.currentState.showSnackBar(SnackBar(
      content: Text("Image uploaded successfully"),
      backgroundColor: Colors.greenAccent,
    ));
  } else {
    scaffoldState.currentState.showSnackBar(SnackBar(
      content: Text("Couldn't upload the image"),
      backgroundColor: Colors.redAccent,
    ));
  }
}

///Handle textView events
void handleTextView(BuildContext context, TextRecognizer textRecognizer) async {
  File image = await ImagePicker.pickImage(source: ImageSource.gallery);
  final blocks = await recognizeImage(image, textRecognizer, getBlocks: true);
  Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => TextView(
                textBlocks: blocks,
              )));
}

/// Handles textField or searchField queries
Future<List<ScreenModel>> handleTextField({
  String query,
  PageController pageController,
  BehaviorSubject<SearchStates> searchSubject,
}) async {
  List<ScreenModel> searchResults;
  pageController.nextPage(
      duration: Duration(milliseconds: 350),
      curve: Curves.fastLinearToSlowEaseIn);

  searchSubject.add(SearchStates.searching);

  String url = ApiUrls.root + ApiUrls.search + "?query=$query";
  try {
    final response = await http.get(url,
        headers: ApiUrls.authenticatedHeader(Auth().user.token));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      searchResults = parseModelFromJson(jsonData);
      if (searchResults.length > 0) {
        searchSubject.add(SearchStates.finished);
      } else {
        searchSubject.add(SearchStates.empty);
      }
    }
  } catch (e) {
    print(e);
  }
  return searchResults;
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

void setDefaultFolder(String path) async {
  final pref = await SharedPreferences.getInstance();
  pref.setString("ural_default_folder", path);
}

void startBackGroundJob() async {
  await Workmanager.registerPeriodicTask("uralfetchscreens", "ural_background",
      initialDelay: Duration(seconds: 5));
}
