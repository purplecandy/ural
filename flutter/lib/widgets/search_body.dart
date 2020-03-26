import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/controllers/image_handler.dart';
import 'package:ural/pages/image_view.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/prefrences.dart';
import 'dart:io';

import 'package:ural/repository/database_repo.dart';
import 'package:ural/pages/textview.dart';
import 'package:ural/utils/bloc_provider.dart';

class SearchBodyWidget extends StatefulWidget {
  SearchBodyWidget({Key key}) : super(key: key);

  @override
  _SearchBodyWidgetState createState() => _SearchBodyWidgetState();
}

class _SearchBodyWidgetState extends State<SearchBodyWidget> {
  SearchScreenBloc _searchBloc = SearchScreenBloc();

  void handleTextView(File imageFile) async {
    final textBlocs = await recognizeImage(
        imageFile, FirebaseVision.instance.textRecognizer(),
        getBlocks: true);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TextView(
                  textBlocks: textBlocs,
                )));
  }

  @override
  void initState() {
    super.initState();
    startup();
  }

  void startup() async {
    final repo = MultiRepositoryProvider.of<DatabaseRepository>(context);
    final uralPref = MultiRepositoryProvider.of<UralPrefrences>(context);
    _searchBloc.initializeDatabase(repo.slDB);
    final SearchFieldBloc searchFieldBloc =
        SingleBlocProvider.of<SearchFieldBloc>(context);
    searchFieldBloc.state.stream
        .debounceTime(Duration(milliseconds: 300))
        .listen((data) {
      if (data.state != SearchFieldState.reset) {
        _searchBloc.dispatch(
            SearchAction.fetch, {"query": data.object, "ural_pref": uralPref});
      }
    });
  }

  List<Widget> buildSearchResults() {
    final UralPrefrences uralPref =
        MultiRepositoryProvider.of<UralPrefrences>(context);
    final SearchFieldBloc searchFieldBloc =
        SingleBlocProvider.of<SearchFieldBloc>(context);
    List<Widget> searchResults = [];
    searchResults.add(SizedBox(
      height: 50,
      child: ListTile(
        title: Text("RECENT SEARCHES"),
      ),
    ));
    for (var item in uralPref.getRecentSearches()) {
      searchResults.add(Material(
        child: InkWell(
          onTap: () {
            searchFieldBloc
                .dispatch(SearchFieldState.recent, {"recent_query": item});
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.only(left: 10),
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: <Widget>[
                  Icon(Feather.search),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      item,
                      textAlign: TextAlign.left,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ));
    }
    return searchResults;
  }

  @override
  Widget build(BuildContext context) {
    final SearchFieldBloc searchFieldBloc =
        SingleBlocProvider.of<SearchFieldBloc>(context);
    return SingleBlocProvider<SearchScreenBloc>(
      bloc: _searchBloc,
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: 40,
          ),
          StreamBuilder<SubState<SearchFieldState, String>>(
              stream: searchFieldBloc.state.stream,
              builder: (context,
                  AsyncSnapshot<SubState<SearchFieldState, String>> snapshot) {
                if (snapshot.hasData) {
                  switch (snapshot.data.state) {
                    case SearchFieldState.reset:
                      return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: buildSearchResults());
                      break;
                    case SearchFieldState.change:
                      return Column(
                        children: <Widget>[
                          SizedBox(
                            height: 60,
                            child: ListTile(
                              title: Text("SEARCH RESULTS FOR: " +
                                  snapshot.data.object),
                            ),
                          ),
                          ScreenshotListGrid()
                        ],
                      );
                    default:
                  }
                }
                return Container();
              }),
        ],
      ),
    );
  }
}

class ScreenshotListGrid extends StatelessWidget {
  const ScreenshotListGrid({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final ScreenBloc screenBloc = SingleBlocProvider.of<ScreenBloc>(context);
    final SearchFieldBloc searchFieldBloc =
        SingleBlocProvider.of<SearchFieldBloc>(context);
    final SearchScreenBloc bloc =
        SingleBlocProvider.of<SearchScreenBloc>(context);

    return Container(
        child: StreamBuilder<SubState<SearchStates, List<ScreenshotModel>>>(
            stream: bloc.state.stream,
            builder: (context,
                AsyncSnapshot<SubState<SearchStates, List<ScreenshotModel>>>
                    snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.state == SearchStates.idle) {
                  return _EmptyListWidget(
                    message:
                        "Looking for a screenshot?\nJust try searching what was inside it.",
                  );
                } else if (snapshot.data.state == SearchStates.searching) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  // search is complete
                  if (snapshot.data.state == SearchStates.empty) {
                    return _EmptyListWidget(
                      message:
                          "Couldn't find anything. Please trying typing something else",
                    );
                  } else {
                    return Material(
                      color: Colors.transparent,
                      child: GridView.builder(
                          // controller: _scrollController,
                          shrinkWrap: true,
                          itemCount: snapshot.data.object.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      (orientation == Orientation.portrait)
                                          ? 2
                                          : 3),
                          itemBuilder: (context, index) {
                            File file =
                                File(snapshot.data.object[index].imagePath);
                            return file.existsSync()
                                ? ImageGridTile(
                                    bloc: screenBloc,
                                    file: file,
                                  )
                                : Container(
                                    child: Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  );
                          }),
                    );
                  }
                }
              }
              return Container();
            }));
  }
}

class ImageGridTile extends StatelessWidget {
  final ScreenBloc bloc;
  final File file;
  const ImageGridTile({Key key, this.bloc, this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => SingleBlocProvider<ScreenBloc>(
                    bloc: bloc,
                    child: ImageView(
                      imageFile: file,
                    ),
                  ))),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Container(
              margin: EdgeInsets.all(8),
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  // color: Colors.black.withOpacity(0.2),
                  // colorBlendMode: BlendMode.luminosity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyListWidget extends StatelessWidget {
  final String message;
  const _EmptyListWidget({Key key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
