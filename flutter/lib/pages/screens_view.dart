import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:ural/widgets/selection_appbar.dart';
import 'package:ural/widgets/searchfield.dart';
import 'package:ural/prefrences.dart';
import 'package:ural/repository/database_repo.dart';
import 'package:ural/widgets/all.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/widgets/search_body.dart';

class ScreenView extends StatefulWidget {
  final List<Widget> actions;
  final bool isStandalone;
  final Widget bottomButtons;
  ScreenView(
      {Key key, this.bottomButtons, this.isStandalone = true, this.actions})
      : super(key: key);

  @override
  _ScreenViewState createState() => _ScreenViewState();
}

class _ScreenViewState extends State<ScreenView>
    with SingleTickerProviderStateMixin {
  final _rscreenBloc = RecentScreenBloc();
  final _searchFieldBloc = SearchFieldBloc();
  final _selectionBloc = ScreenSelectionBloc();
  final _searchBloc = SearchScreenBloc();

  final _searchFieldController = TextEditingController();
  final _scaffold = GlobalKey<ScaffoldState>();
  final focusNode = FocusNode();
  AnimationController _animController;

  String searchQuery = "";
  bool searchStack = false;
  double left = 50;

  Widget get buttomButtons => widget.bottomButtons;
  bool get isStandalone => widget.isStandalone;

  @override
  void initState() {
    super.initState();
    startup();
  }

  void startup() async {
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
      reverseDuration: Duration(milliseconds: 250),
    );
    _searchFieldBloc.initialize(_searchFieldController);
    final repo = MultiRepositoryProvider.of<DatabaseRepository>(context);
    final uralPref = MultiRepositoryProvider.of<UralPrefrences>(context);

    /// Incase if the database hasn't been initialized subscribe to changes
    if (repo.slDB.db == null) {
      repo.addListeners(() {
        _rscreenBloc.initializeDatabase(repo.slDB);
        _searchBloc.initializeDatabase(repo.slDB);
        _rscreenBloc.dispatch(RecentScreenAction.fetch);
      });
    } else {
      _rscreenBloc.initializeDatabase(repo.slDB);
      _searchBloc.initializeDatabase(repo.slDB);
      _rscreenBloc.dispatch(RecentScreenAction.fetch);
    }

    /// Delaying the stream to not make continousl calls onChange
    _searchFieldBloc.state.stream
        .debounceTime(Duration(milliseconds: 300))
        .listen((data) {
      if (data.state != SearchFieldState.reset) {
        _searchBloc.dispatch(
            SearchAction.fetch, {"query": data.object, "ural_pref": uralPref});
      }
    });
    //gotta wait for database to get initialized
    // await _bloc.initializeDatabase();
    //then lazily load all the screens
    // _bloc.listAllScreens();
    focusNode.addListener(() {
      if (focusNode.hasPrimaryFocus) {
        setState(() {
          left = 0;
          searchStack = true;
          _animController.forward();
        });
      }
    });
  }

  bool hasFocus() => searchStack;

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async {
        if (!searchStack && isStandalone) return true;
        focusNode.unfocus();
        setState(() {
          _animController.reverse().whenComplete(() {
            setState(() {
              searchStack = false;
            });
          });
        });
        return false;
      },
      child: SingleBlocProvider<ScreenSelectionBloc>(
        bloc: _selectionBloc,
        child: SingleBlocProvider<SearchFieldBloc>(
          bloc: _searchFieldBloc,
          child: SingleBlocProvider<RecentScreenBloc>(
            bloc: _rscreenBloc,
            child: SingleBlocProvider<SearchScreenBloc>(
              bloc: _searchBloc,
              child: Scaffold(
                  key: _scaffold,
                  body: Container(
                    height: deviceHeight,
                    width: deviceWidth,
                    margin: EdgeInsets.only(top: 10),
                    child: Stack(
                      children: <Widget>[
                        Visibility(
                          visible: !searchStack,
                          child: Container(
                            margin: EdgeInsets.only(top: isStandalone ? 50 : 0),
                            child: ListScreenshotsWidget<RecentScreenBloc>(),
                          ),
                        ),
                        Visibility(
                          visible: searchStack,
                          child: SlideTransition(
                            position:
                                Tween(begin: Offset(0.0, 1.0), end: Offset.zero)
                                    .animate(_animController),
                            child: Container(
                              color: Theme.of(context).backgroundColor,
                              height: deviceHeight,
                              width: deviceWidth,
                              child: SearchBodyWidget(),
                            ),
                          ),
                        ),
                        Align(
                          heightFactor: 2.5,
                          alignment: Alignment.center,
                          child: SearchFieldWidget(
                            hintText: "Type what you're looking for here",
                            controller: _searchFieldController,
                            focusNode: focusNode,
                            hasFocus: hasFocus,
                            onChanged: (val) {
                              searchQuery = val;
                            },
                            onSubmitted: (val) {
                              if (val.length > 0)
                                _searchFieldBloc
                                    .dispatch(SearchFieldState.change);
                            },
                          ),
                        ),
                        //BOTTOM BUTTONS PLACEHOLDER
                        buttomButtons ?? Container(),
                        //BOTTOM BUTTONS ENDS
                        SelectionAppBar(
                          actions: <Widget>[],
                          hideInital: isStandalone,
                        )
                      ],
                    ),
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
