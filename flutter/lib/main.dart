import 'package:after_layout/after_layout.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/database.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/pages/setup.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:io';
import 'dart:async';

import 'package:ural/pages/home_body.dart';
import 'package:ural/utils/async.dart';

Future<bool> uploadImagesInBackground() async {
  final pref = await SharedPreferences.getInstance();
  if (pref.containsKey("ural_default_folder")) {
    final dir = Directory(pref.getString("ural_default_folder"));
    final textRecognizer = FirebaseVision.instance.textRecognizer();
    final ScreenshotListDatabase _slDB = ScreenshotListDatabase();
    await _slDB.initDB();
    try {
      List<FileSystemEntity> fileEntities = dir.listSync(recursive: true);
      for (FileSystemEntity entity in fileEntities) {
        if (entity is File) {
          //identify if the file is an image format
          String ext =
              entity.path.substring(entity.path.length - 3, entity.path.length);
          if (["jpg", "png"].contains(ext)) {
            /// Check if the image already exist
            final bool exist = await _slDB.exist(entity.path.hashCode);

            /// Skip if true
            if (exist) continue;
            final visionImage = FirebaseVisionImage.fromFile(entity);
            String text = "";
            await textRecognizer.processImage(visionImage).then((vt) {
              text = vt.text;
            });
            ScreenshotModel model =
                ScreenshotModel(entity.path.hashCode, entity.path, text);
            _slDB.insert(model);
            print("Success uploaded");
          }
        }
      }
      return true;
    } catch (e) {
      print("Exception from background task: $e");
      return false;
    }
  }
  return false;
}

void callbackDispatcher() {
  print("CallBackDispacther RUNNING");
  Workmanager.executeTask((task, input) async {
    return await uploadImagesInBackground();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager.initialize(callbackDispatcher, isInDebugMode: false);

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
  ScreenBloc _bloc = ScreenBloc();

  final PageController _pageController = PageController();
  final _scaffold = GlobalKey<ScaffoldState>();
  final recognizer = FirebaseVision.instance.textRecognizer();
  String searchQuery = "";
  int currentTab = 0;

  bool intial = false;

  @override
  void initState() {
    super.initState();
    startup();
  }

  void startup() async {
    intialSetup();
    //gotta wait for database to get initialized
    await _bloc.initializeDatabase();
    //then lazily load all the screens
    _bloc.listAllScreens();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) async {
    // await getPermissionStatus();
  }

  void refresh() {
    _scaffold.currentState.showSnackBar(SnackBar(
        content: Text(
      "Refreshing...",
    )));
    _bloc.listAllScreens();
  }

  Future<void> intialSetup() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      intial = pref.containsKey("ural_initial_setup");
    });
    if (intial == false) {
      Navigator.push(
          context,
          MaterialPageRoute(
              fullscreenDialog: true, builder: (context) => Setup()));
    }
  }

  Widget intialSetupWidget() {
    return Material(
      child: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "Guide",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              HelpFuction(),
              Container(
                padding: EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "How Ural works?",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Card(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: Text(
                          "1",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.red),
                        ),
                        title: Text("Sync/Upload your images"),
                      ),
                      Divider(),
                      ListTile(
                        leading: Text(
                          "2",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.purple),
                        ),
                        title: Text(
                            "Get your screenshot by searching the content of your screenshot"),
                      )
                    ],
                  ),
                ),
              ),
              FlatButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.pinkAccent, width: 1)),
                  textColor: Colors.white,
                  onPressed: () async {
                    const url = "https://youtu.be/a-diWDZX2vM";
                    if (await canLaunch(url)) {
                      launch(url);
                    }
                  },
                  child: Text("Watch Demo on YT")),
              Container(
                padding: EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "FAQs",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              FaqsWidget(),
              FlatButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.pinkAccent, width: 1)),
                  textColor: Colors.white,
                  onPressed: () async {
                    setState(() {
                      intial = true;
                    });
                  },
                  child: Text("Close")),
              SizedBox(
                height: 40,
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaticBloc<ScreenBloc>(
      bloc: _bloc,
      child: Scaffold(
        key: _scaffold,
        body: NestedScrollView(
          headerSliverBuilder: (context, isBoxScroll) => [
            SliverAppBar(
              leading: null,
              actions: <Widget>[
                IconButton(icon: Icon(Icons.refresh), onPressed: refresh),
                IconButton(
                    icon: Icon(Icons.help_outline),
                    onPressed: () {
                      setState(() {
                        intial = false;
                      });
                    }),
                IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      _bloc.handleSettings(context);
                    })
              ],
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
                                onSubmitted: (val) async {
                                  searchQuery = val;
                                  _bloc.handleTextField(
                                      query: searchQuery,
                                      pageController: _pageController);
                                },
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        "Type what you're looking for here"),
                              ),
                              trailing: IconButton(
                                  icon: Icon(Icons.search),
                                  onPressed: () {
                                    _bloc.handleTextField(
                                        query: searchQuery,
                                        pageController: _pageController);
                                  }),
                            ),
                          ),
                        ),
                      ),
                      // Container(
                      //   width: MediaQuery.of(context).size.width * 0.8,
                      //   child: Wrap(
                      //     alignment: WrapAlignment.spaceEvenly,
                      //     children: <Widget>[
                      //       FloatingActionButton(
                      //         elevation: 0,
                      //         heroTag: null,
                      //         onPressed: () {
                      //           _bloc.handleManualUpload(_scaffold);
                      //         },
                      //         child: Icon(Icons.file_upload),
                      //       ),
                      //       FloatingActionButton(
                      //         elevation: 0,
                      //         heroTag: null,
                      //         onPressed: () async {
                      //           _bloc.handleTextView(context);
                      //         },
                      //         child: Icon(Icons.text_fields),
                      //       ),
                      //       FloatingActionButton(
                      //         elevation: 0,
                      //         heroTag: null,
                      //         onPressed: () {
                      //           _bloc.handleBackgroundSync(_scaffold);
                      //         },
                      //         child: Icon(Icons.sync),
                      //       ),
                      //       FloatingActionButton(
                      //         heroTag: null,
                      //         elevation: 0,
                      //         child: Icon(Icons.settings),
                      //         onPressed: () {
                      //           _bloc.handleSettings(context);
                      //         },
                      //       )
                      //     ],
                      //   ),
                      // )
                    ],
                  ),
                ),
              ),
              expandedHeight: 150,
            ),
          ],
          body: !intial
              ? intialSetupWidget()
              : PageView(
                  onPageChanged: (index) {
                    setState(() {
                      currentTab = index;
                    });
                  },
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    StreamBuilder<StreamEvents>(
                      stream: _bloc.streamOfRecentScreens,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data == StreamEvents.loading) {
                            return Material(
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else {
                            if (_bloc.recentScreenshots.length > 0) {
                              return HomeBody(
                                title: "Recent Screenshots",
                                screenshots: _bloc.recentScreenshots,
                              );
                            } else {
                              return Material(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      "You don't have any screenshots synced.",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    SizedBox(
                                      height: 40,
                                    ),
                                    FlatButton(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            side: BorderSide(
                                                color: Colors.pinkAccent,
                                                width: 1)),
                                        textColor: Colors.white,
                                        onPressed: () {
                                          refresh();
                                        },
                                        child: Text("Refresh"))
                                  ],
                                ),
                              );
                            }
                          }
                        }
                        return Container();
                      },
                    ),
                    StreamBuilder<SearchStates>(
                      stream: _bloc.streamofSearchResults,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data == SearchStates.finished) {
                            return HomeBody(
                              title: "Search results",
                              screenshots: _bloc.searchResults,
                            );
                          }
                          if (snapshot.data == SearchStates.empty) {
                            return Material(
                              child: Center(
                                child: Text(
                                  "Couldn't find anything. Please trying typing something else",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }
                        }
                        return Material(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                "Looking for a screenshot? Just try typing what was inside it above.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton(
              backgroundColor: Colors.deepPurpleAccent,
              mini: true,
              elevation: 9,
              heroTag: null,
              onPressed: () {
                _bloc.handleManualUpload(_scaffold);
              },
              child: Icon(Icons.file_upload),
            ),
            SizedBox(
              width: 10,
            ),
            FloatingActionButton(
              backgroundColor: Colors.deepPurpleAccent,
              mini: true,
              elevation: 9,
              heroTag: null,
              onPressed: () async {
                _bloc.handleTextView(context);
              },
              child: Icon(Icons.text_fields),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentTab,
            onTap: (index) {
              _pageController.animateToPage(index,
                  duration: Duration(milliseconds: 250), curve: Curves.easeIn);
              setState(() {
                currentTab = index;
              });
            },
            selectedItemColor: Colors.pinkAccent,
            unselectedItemColor: Colors.white,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_on), title: Text("Home")),
              BottomNavigationBarItem(
                  icon: Icon(Icons.search), title: Text("Search"))
            ]),
      ),
    );
  }
}

class HelpFuction extends StatelessWidget {
  const HelpFuction({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(Icons.file_upload),
                title: Text("Manual Upload"),
                subtitle:
                    Text("Want to just save a screenshot? Do a manual upload"),
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(Icons.text_fields),
                title: Text("Text View"),
                subtitle: Text(
                    "You this when you just want to extract the text from an image"),
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text(
                  "Settings",
                ),
                subtitle: Text(
                    "Here you can modfiy your setting and reconfigure Ural"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QA {
  final String question, answer;
  QA(this.question, this.answer);
}

class FaqsWidget extends StatelessWidget {
  final List<QA> faqs = [
    QA("I can't see my images?",
        "First make sure your default directory contains screenshots.\n\nIt takes sometimes to automatically sync.\n\nTry re-configuring Ural from settings."),
    QA("Can't grant permission",
        "Please close the app and re try. If it still doesn't work give permissions manually from settings."),
    QA("How frequent are background syncs?", "Every 2 hours"),
    QA("I can't upload an image",
        "Make sure you have configured Ural properly. Incase you're getting an error then the image already exist."),
    QA("It won't recognize text properly",
        "It depends on things like quality of image, what fonts are used etc. T"),
    QA("What languages are currently supported?",
        "English but you can try if it works"),
    QA("My search results are empty", "Try different search queries."),
    QA("Is Ural making copies of my screenshots?",
        "No, Ural only links your screenshots available on your device")
  ];
  FaqsWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: ListView.builder(
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          itemCount: faqs.length,
          itemBuilder: (context, index) => ExpansionTile(
            title: Text(faqs[index].question),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(faqs[index].answer),
              )
            ],
          ),
        ),
      ),
    );
  }
}
