import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:ural/widgets/all.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/pages/setup.dart';
import 'package:ural/pages/textview.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
              HelpFuctionWidget(),
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

  void onSubmitTF() => _bloc.handleTextField(
      query: searchQuery.trim(), pageController: _pageController);

  /// Handles Settings button events
  void handleSettings() async {
    showModalBottomSheet(
        context: context,
        builder: (context) => SingleChildScrollView(
              child: SettingsModalWidget(),
            ));
  }

  ///Handle textView events
  void handleTextView() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    final blocks = await _bloc.recognizeImage(image, getBlocks: true);
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => TextView(
                  textBlocks: blocks,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return SingleBlocProvider<ScreenBloc>(
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
                      handleSettings();
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
                                  onChanged: (val) {
                                    searchQuery = val;
                                  },
                                  onSubmitted: (val) {
                                    onSubmitTF();
                                  },
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText:
                                          "Type what you're looking for here"),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.search),
                                  onPressed: onSubmitTF,
                                )),
                          ),
                        ),
                      ),
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
                    StreamBuilder<RecentScreenStates>(
                      stream: _bloc.streamOfRecentScreens,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data == RecentScreenStates.loading) {
                            return Material(
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else {
                            if (_bloc.recentScreenshots.length > 0) {
                              return HomeBodyWidget(
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
                            return HomeBodyWidget(
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
                                "Looking for a screenshot? Just try searchin what was inside it.",
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
                handleTextView();
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
