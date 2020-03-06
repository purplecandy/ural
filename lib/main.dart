import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:folder_picker/folder_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ural/auth_bloc.dart';
import 'package:ural/image_handler.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/pages/home_body.dart';
import 'package:ural/urls.dart';
import 'package:ural/user_dialog.dart';
import 'package:ural/utils/async.dart';
import 'package:workmanager/workmanager.dart';
import 'textview.dart';
import 'auth_dialog.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:async';

enum SearchStates { searching, finished, empty }

Future<bool> uploadImagesToBackground() async {
  final pref = await SharedPreferences.getInstance();
  if (pref.containsKey("ural_default_folder")) {
    // final dir = Directory(pref.getString("ural_default_folder"));
    final dir = Directory("/storage/emulated/0/Pictures/Screenshots/");
    final token = pref.getString("uralToken");
    final textRecognizer = FirebaseVision.instance.textRecognizer();
    var config;
    if (pref.containsKey("ural_synced_config")) {
      config = json.decode(pref.getString("ural_synced_config"));
    } else {
      config = {};
    }
    int count = 0;
    List<FileSystemEntity> fileEntities = dir.listSync(recursive: true);

    for (FileSystemEntity entity in fileEntities) {
      if (entity is File) {
        if (count > 20) break;
        final result =
            await syncImageToServer(File(entity.path), textRecognizer, token);
        if (result.state == ResponseStatus.success) {
          config[entity.path.hashCode.toString()] = "";
          count++;
        }
      }
    }
    return true;
  }
  return false;
}

void callbackDispatcher() {
  print("CallBackDispacther RUNNING");
  Workmanager.executeTask((task, input) async {
    return await uploadImagesToBackground();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager.initialize(callbackDispatcher, isInDebugMode: true);
  runApp(App());
}

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFF424242),
        primaryColorLight: Color(0xFF6d6d6d),
        primaryColorDark: Color(0xFF1b1b1b),
        accentColor: Color(0xFFe91e63),
        scaffoldBackgroundColor: Color(0xFF6d6d6d),
        canvasColor: Color(0xFF1b1b1b),
        backgroundColor: Color(0xFF1b1b1b),
      ),
      routes: {"/": (context) => Home()},
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with AfterLayoutMixin {
  SearchStates searchStates = SearchStates.searching;
  List<ScreenModel> screenshots = [];
  List<ScreenModel> searchResults = [];
  File _image;
  final PageController _pageController = PageController();
  final _scaffold = GlobalKey<ScaffoldState>();
  final recognizer = FirebaseVision.instance.textRecognizer();
  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  Future<List<TextBlock>> recognizeImage() async {
    final fbImage = FirebaseVisionImage.fromFile(_image);
    final visionText = await recognizer.processImage(fbImage);
    return visionText.blocks;
  }

  Future<VisionText> getTextFromImage() async {
    final fbImage = FirebaseVisionImage.fromFile(_image);
    final visionText = await recognizer.processImage(fbImage);
    return visionText;
  }

  Future<void> handleUpload() async {
    if (_image != null) {
      img.Image image = img.decodeImage(_image.readAsBytesSync());
      img.Image thumbnail = img.copyResize(image, width: 120);
      Directory tempDir = await getTemporaryDirectory();
      String encoded;
      var path = _image.path.split("/").last;
      final filename = path.split(".")[0] + ".jpg";
      File(tempDir.path + '/' + filename)
        ..writeAsBytes(img.encodeJpg(thumbnail)).then((file) async {
          encoded = base64.encode(await file.readAsBytes());
          // encoded = file.readAsBytesSync().toString();
        });
      String url = ApiUrls.root + ApiUrls.images;
      String text;
      await getTextFromImage().then((obj) => text = obj.text);
      String payload = json.encode({
        "filename": filename,
        "thumbnail": encoded,
        "image_path": _image.path,
        "text": text,
        "short_text": "",
      });
      try {
        final response = await http.post(url,
            body: payload,
            headers: ApiUrls.authenticatedHeader(Auth().user.token));
        if (response.statusCode == 201) {
          print("Image uploaded successfully");
        } else {
          print(response.body);
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> getPermissionStatus() async {
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    if (permission == PermissionStatus.granted) {
    } else if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.unknown ||
        permission == PermissionStatus.restricted) {
      await PermissionHandler().requestPermissions([PermissionGroup.storage]);
      getPermissionStatus();
    }
  }

  void startBackGroundJob() async {
    await Workmanager.registerPeriodicTask(
        "uralfetchscreens", "ural_background",
        initialDelay: Duration(seconds: 5));
  }

  void setDefaultFolder(String path) async {
    final pref = await SharedPreferences.getInstance();
    pref.setString("ural_default_folder", path);
  }

  List<ScreenModel> parseModelFromJson(jsonData) {
    List<ScreenModel> temp = [];
    for (var item in jsonData) {
      ScreenModel model = ScreenModel.fromJson(item);
      temp.add(model);
    }
    return temp;
  }

  void getImagesList() async {
    String url = ApiUrls.root + ApiUrls.images;
    try {
      final response = await http.get(url,
          headers: ApiUrls.authenticatedHeader(Auth().user.token));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        setState(() {
          screenshots = parseModelFromJson(jsonData);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void afterFirstLayout(BuildContext context) async {
    final authState = await Auth().authenticate();
    if (authState.state == ResponseStatus.failed)
      await showDialog(
        context: context,
        child: AuthenticationDialog(),
        barrierDismissible: false,
      );
    await getPermissionStatus();
    getImagesList();
    startBackGroundJob();
  }

  void handleDirectory() async {
    final pref = await SharedPreferences.getInstance();
    final defaultDir = pref.getString("ural_default_folder");

    showDialog(
        context: context,
        child: AlertDialog(
          title: Text("Default Directory"),
          content: Text(defaultDir == null ? "NOT SET" : defaultDir),
          actions: <Widget>[
            FlatButton(
                onPressed: () => Navigator.pop(context), child: Text("Close")),
            FlatButton(
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
                              rootDirectory:
                                  Directory("/storage/emulated/0/"))));
                },
                child: Text("Change Folder")),
          ],
        ));
  }

  void handleSettings() async {
    print(await uploadImagesToBackground());
  }

  void handleManualUpload() {}
  void handleTextView() async {
    final blocks = await recognizeImage();
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => TextView(
                  textBlocks: blocks,
                )));
  }

  void handleTextField(String query) async {
    _pageController.nextPage(
        duration: Duration(milliseconds: 350),
        curve: Curves.fastLinearToSlowEaseIn);
    setState(() {
      searchStates = SearchStates.searching;
    });
    String url = ApiUrls.root + ApiUrls.search + "?query=$query";
    try {
      final response = await http.get(url,
          headers: ApiUrls.authenticatedHeader(Auth().user.token));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          searchResults = parseModelFromJson(jsonData);
          if (searchResults.length > 0) {
            searchStates = SearchStates.finished;
          } else {
            searchStates = SearchStates.empty;
          }
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Widget searchWidget() {
    switch (searchStates) {
      case SearchStates.finished:
        return HomeBody(
          screenshots: searchResults,
        );
        break;
      case SearchStates.empty:
        return Center(
          child: Text(
              "Couldn't find anything. Please trying typing something else"),
        );
        break;
      default:
        return Center(
          child: CircularProgressIndicator(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffold,
      body: NestedScrollView(
        headerSliverBuilder: (context, isBoxScroll) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            forceElevated: isBoxScroll,
            title: Container(height: 40, child: Text("Ural")),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                margin: EdgeInsets.only(top: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(8),
                      height: 110,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: Card(
                          child: ListTile(
                            title: TextField(
                              onSubmitted: (val) {
                                print(val.runtimeType);
                                handleTextField(val);
                              },
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText:
                                      "Type what you're looking for here"),
                            ),
                            trailing: IconButton(
                                icon: Icon(Icons.search), onPressed: null),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        children: <Widget>[
                          FloatingActionButton(
                            elevation: 0,
                            heroTag: null,
                            onPressed: () {
                              handleUpload();
                            },
                            child: Icon(Icons.file_upload),
                          ),
                          FloatingActionButton(
                            elevation: 0,
                            heroTag: null,
                            onPressed: () async {
                              var image = await ImagePicker.pickImage(
                                  source: ImageSource.gallery);
                              setState(() {
                                _image = image;
                              });
                              handleTextView();
                            },
                            child: Icon(Icons.text_fields),
                          ),
                          FloatingActionButton(
                            elevation: 0,
                            heroTag: null,
                            onPressed: () {
                              handleDirectory();
                            },
                            child: Icon(Icons.folder),
                          ),
                          FloatingActionButton(
                            heroTag: null,
                            elevation: 0,
                            child: Icon(Icons.settings),
                            onPressed: () {
                              handleSettings();
                            },
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            expandedHeight: 220,
          ),
        ],
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          // scrollDirection: Axis.vertical,
          children: <Widget>[
            screenshots.length > 0
                ? HomeBody(
                    screenshots: screenshots,
                  )
                : Material(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
            searchWidget(),
          ],
        ),
      ),
      floatingActionButton: Visibility(
          visible: (searchStates != SearchStates.searching),
          child: FloatingActionButton(
            heroTag: null,
            onPressed: () {
              _pageController.previousPage(
                  duration: Duration(milliseconds: 400), curve: Curves.easeIn);
            },
            child: Icon(Icons.grid_on),
          )),
    );
  }
}
