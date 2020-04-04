import 'package:flutter/foundation.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

import 'package:ural/widgets/dialogs/initial_setup.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/prefrences.dart';
import 'package:ural/widgets/all.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/widgets/search_body.dart';

class ScreenView extends StatefulWidget {
  final Widget bottomButtons;
  ScreenView({Key key, this.bottomButtons}) : super(key: key);

  @override
  _ScreenViewState createState() => _ScreenViewState();
}

class _ScreenViewState extends State<ScreenView> {
  final SearchFieldBloc _searchFieldBloc = SearchFieldBloc();
  final TextEditingController _searchFieldController = TextEditingController();
  final _selectionBloc = ScreenSelectionBloc();

  UralPrefrences uralPref = UralPrefrences();
  final _scaffold = GlobalKey<ScaffoldState>();
  final recognizer = FirebaseVision.instance.textRecognizer();
  final FocusNode focusNode = FocusNode();
  String searchQuery = "";
  int currentTab = 0;

  bool intial = false;
  bool searchStack = false;

  Widget get buttomButtons => widget.bottomButtons;

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(length: 2, vsync: this);
    startup();
  }

  void startup() async {
    //initialize our controller
    _searchFieldBloc.initialize(_searchFieldController);

    intialSetup();

    //gotta wait for database to get initialized
    // await _bloc.initializeDatabase();
    //then lazily load all the screens
    // _bloc.listAllScreens();
    focusNode.addListener(() {
      if (focusNode.hasPrimaryFocus) {
        setState(() {
          searchStack = true;
        });
      }
    });
  }

  Future<void> intialSetup() async {
    await uralPref.getInstance();
    setState(() {
      intial = uralPref.getInitalSetupStatus();
    });
    if (intial == false) {
      showDialog(context: context, builder: (context) => InitialSetupDialog());
    }
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
      child: SingleBlocProvider<SearchFieldBloc>(
        bloc: _searchFieldBloc,
        child: SingleBlocProvider<ScreenSelectionBloc>(
          bloc: _selectionBloc,
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
                            controller: _searchFieldController,
                            focusNode: focusNode,
                            onChanged: (val) {
                              searchQuery = val;
                            },
                            onEditingComplete: () {
                              print("IM CLOSING");
                            },
                            onSubmitted: (val) {
                              if (val.length > 0)
                                _searchFieldBloc
                                    .dispatch(SearchFieldState.change);
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
                    //BOTTOM BUTTONS PLACEHOLDER
                    buttomButtons ?? Container(),
                    //BOTTOM BUTTONS ENDS
                    StreamBuilder<
                            SubState<SelectionStates,
                                Map<int, ScreenshotModel>>>(
                        stream: _selectionBloc.state.stream,
                        builder: (context, snap) {
                          if (snap.hasData) {
                            if (snap.data.state != SelectionStates.empty) {
                              return Container(
                                height: 80,
                                child: AppBar(
                                  leading: IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () {
                                        _selectionBloc
                                            .dispatch(SelectionAction.reset);
                                      }),
                                  title: Text(
                                      "${snap.data.object.length} selected"),
                                  actions: <Widget>[
                                    IconButton(
                                        icon: Icon(
                                          Feather.tag,
                                          size: 19,
                                        ),
                                        onPressed: () {}),
                                    IconButton(
                                        icon: Icon(
                                          Feather.trash,
                                          size: 19,
                                        ),
                                        onPressed: () {})
                                  ],
                                ),
                              );
                            }
                          }
                          return SizedBox(
                            height: 0,
                            width: 0,
                          );
                        }),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}
