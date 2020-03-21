import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:ural/widgets/all.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/pages/setup.dart';
import 'package:ural/pages/textview.dart';
import 'package:ural/widgets/search_body.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  ScreenBloc _bloc = ScreenBloc();
  TabController _tabController;
  final PageController _pageController = PageController();
  final _scaffold = GlobalKey<ScaffoldState>();
  final recognizer = FirebaseVision.instance.textRecognizer();
  final FocusNode focusNode = FocusNode();
  String searchQuery = "";
  int currentTab = 0;

  bool intial = false;
  bool searchStack = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    startup();
  }

  void startup() async {
    intialSetup();
    //gotta wait for database to get initialized
    await _bloc.initializeDatabase();
    //then lazily load all the screens
    _bloc.listAllScreens();
    focusNode.addListener(() {
      if (focusNode.hasPrimaryFocus) {
        setState(() {
          searchStack = true;
        });
      }
    });
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

  void onSubmitTF() => _bloc.handleTextField(searchQuery.trim());

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
    return WillPopScope(
      onWillPop: () async {
        focusNode.unfocus();
        setState(() {
          searchStack = false;
        });
        return false;
      },
      child: SingleBlocProvider<ScreenBloc>(
        bloc: _bloc,
        child: Scaffold(
            key: _scaffold,
            body: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: <Widget>[
                  Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: HomeBodyWidget(),
                  ),
                  Visibility(
                    visible: searchStack,
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.yellow,
                      child: SearchBodyWidget(),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 50,
                    child: Material(
                      elevation: 20,
                      color: Colors.transparent,
                      child: Container(
                        height: 40,
                        width: MediaQuery.of(context).size.width * 0.8,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: TextField(
                          focusNode: focusNode,
                          onChanged: (val) {
                            searchQuery = val;
                          },
                          onEditingComplete: () {
                            print("IM CLOSING");
                          },
                          onSubmitted: (val) {
                            onSubmitTF();
                          },
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              hintText: "Type what you're looking for here"),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.25,
                    bottom: 40,
                    child: Material(
                      elevation: 10,
                      color: Colors.transparent,
                      child: Container(
                          height: 40,
                          width: MediaQuery.of(context).size.width * 0.5,
                          decoration: BoxDecoration(
                              color: Theme.of(context).backgroundColor,
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              IconButton(
                                  splashColor: Colors.white,
                                  icon: Icon(Feather.image),
                                  color: Colors.deepPurple,
                                  onPressed: () {
                                    print("object");
                                  }),
                              Separator(),
                              IconButton(
                                  splashColor: Colors.white,
                                  icon: Icon(Feather.file_text),
                                  color: Colors.deepPurple,
                                  onPressed: () {
                                    print("object");
                                  }),
                              Separator(),
                              IconButton(
                                  splashColor: Colors.white,
                                  icon: Icon(Feather.menu),
                                  color: Colors.deepPurple,
                                  onPressed: () {
                                    handleSettings();
                                  }),
                            ],
                          )),
                    ),
                  )
                ],
              ),
            )),
      ),
    );
  }
}

class Separator extends StatelessWidget {
  const Separator({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      width: 1,
      color: Colors.white.withOpacity(0.8),
    );
  }
}
