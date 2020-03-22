import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:ural/pages/help.dart';
import 'dart:io';

import 'settings.dart';
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
  // TabController _tabController;
  // final PageController _pageController = PageController();
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
    // _tabController = TabController(length: 2, vsync: this);
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

  void showAlert() {
    showDialog(context: context, builder: (context) => ImageDialog());
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
                      color: Theme.of(context).backgroundColor,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
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
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                              hintStyle: TextStyle(color: Colors.black),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.black,
                              ),
                              border: InputBorder.none,
                              hintText: "Type what you're looking for here"),
                        ),
                      ),
                    ),
                  ),
                  //BOTTOM BUTTONS
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
                              SizedBox(
                                width: 40,
                                child: RawMaterialButton(
                                  shape: CircleBorder(),
                                  onPressed: () {
                                    // handleSettings();
                                    showAlert();
                                  },
                                  child: Icon(
                                    Feather.image,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              Separator(),
                              SizedBox(
                                width: 40,
                                child: RawMaterialButton(
                                  shape: CircleBorder(),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) => TextScan());
                                  },
                                  child: Icon(
                                    Feather.file_text,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              Separator(),
                              SizedBox(
                                width: 40,
                                child: RawMaterialButton(
                                  shape: CircleBorder(),
                                  onPressed: () {
                                    // handleSettings();
                                  },
                                  child: Icon(
                                    Feather.tag,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              Separator(),
                              SizedBox(
                                width: 40,
                                child: RawMaterialButton(
                                  shape: CircleBorder(),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) =>
                                            SingleBlocProvider<ScreenBloc>(
                                                bloc: _bloc,
                                                child: MenuDialog()));
                                  },
                                  child: Icon(
                                    Feather.menu,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ),
                  ),
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

class HorizontalSeprator extends StatelessWidget {
  const HorizontalSeprator({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16),
      height: 0.3,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

class MenuDialog extends StatefulWidget {
  MenuDialog({Key key}) : super(key: key);

  @override
  _MenuDialogState createState() => _MenuDialogState();
}

class _MenuDialogState extends State<MenuDialog> {
  @override
  Widget build(BuildContext context) {
    final ScreenBloc screenBloc = SingleBlocProvider.of<ScreenBloc>(context);
    return Dialog(
      elevation: 10,
      // color: Colors.transparent,
      // textStyle: TextStyle(color: Colors.white),
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).backgroundColor),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                SizedBox(
                  width: 40,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Feather.x,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            // HorizontalSeprator(),
            MenuTile(Feather.settings, "Settings", () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SingleBlocProvider<ScreenBloc>(
                          bloc: screenBloc, child: SettingsPage())));
            }),
            HorizontalSeprator(),
            MenuTile(Feather.help_circle, "Help", () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => HelpPage()));
            }),
            HorizontalSeprator(),
            MenuTile(Feather.mail, "Feedback", () {}),
            HorizontalSeprator(),
            MenuTile(Feather.info, "More Information", () {}),
            // HorizontalSeprator()
          ],
        ),
      ),
    );
  }
}

class ImageDialog extends StatefulWidget {
  const ImageDialog({Key key}) : super(key: key);

  @override
  _ImageDialogState createState() => _ImageDialogState();
}

class _ImageDialogState extends State<ImageDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.22,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).backgroundColor),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                SizedBox(
                  width: 40,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Feather.x,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "You will have to pick a screenshot from below to save it manually.",
                textAlign: TextAlign.center,
                // style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            FlatButton(
              onPressed: () {},
              child: Text("UPLOAD & SAVE"),
              shape: RoundedRectangleBorder(),
              textColor: Colors.white,
              highlightColor: Colors.deepPurpleAccent,
              color: Colors.deepPurple,
            )
          ],
        ),
      ),
    );
  }
}

class TextScan extends StatefulWidget {
  TextScan({Key key}) : super(key: key);

  @override
  _TextScanState createState() => _TextScanState();
}

class _TextScanState extends State<TextScan> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.22,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).backgroundColor),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                SizedBox(
                  width: 40,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Feather.x,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "You will have to pick a screenshot from below to view extracts the text from it..",
                textAlign: TextAlign.center,
                // style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            FlatButton(
              onPressed: () {},
              child: Text("UPLOAD & SCAN"),
              shape: RoundedRectangleBorder(),
              textColor: Colors.white,
              highlightColor: Colors.deepPurpleAccent,
              color: Colors.deepPurple,
            )
          ],
        ),
      ),
    );
  }
}

class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback callback;
  MenuTile(this.icon, this.title, this.callback);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: callback,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16),
          child: Container(
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  title,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w300),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
