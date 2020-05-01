import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';
import 'package:ural/app.dart';

import 'package:ural/blocs/search_bloc.dart';
import 'package:ural/blocs/tags_bloc.dart';
import 'package:ural/models/tags_model.dart';
import 'package:ural/repository/database_repo.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/values/theme.dart';
import 'package:ural/widgets/image_grid_tile.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/prefrences.dart';

/// This widget has 2 stream that is SearchFieldBloc and SearchScreenBloc
///
/// SearchScreenBloc is dependent on SearchFieldBloc
///
/// SearchFieldBloc is switching between widgets depending upon the current value
///
/// SearchScreenBloc outputs the the search result
///
/// when the state of SearchFieldBloc is `SearchFieldStates.change` only then the SearchScreenBloc is displayed
///
/// everytime the query is changed a `SearchStates.fetch` is fired with the new query after a small delay
/// then the stream displays [ScreenshotListBuilder()] which is basically listenting to search results
class SearchBodyWidget extends StatefulWidget {
  SearchBodyWidget({Key key}) : super(key: key);

  @override
  _SearchBodyWidgetState createState() => _SearchBodyWidgetState();
}

class _SearchBodyWidgetState extends State<SearchBodyWidget> {
  UralPrefrences uralPref;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    uralPref = Provider.of<UralPrefrences>(context, listen: true);
    super.didChangeDependencies();
  }

  List<Widget> buildSearchResults() {
    final SearchFieldBloc searchFieldBloc =
        Provider.of<SearchFieldBloc>(context, listen: false);
    List<Widget> searchResults = [];
    if (uralPref.initialized) {
      searchResults.add(SizedBox(
        height: 50,
        child: ListTile(
          title: Text("RECENT SEARCHES"),
        ),
      ));
      for (var item in uralPref.getRecentSearches()) {
        searchResults.add(Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: InkWell(
            onTap: () {
              searchFieldBloc.dispatch(SearchFieldState.recent,
                  data: {"recent_query": item});
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
    }
    // searchResults.add(Divider());
    // searchResults.add(FilterByTagsWidget(
    //   onApply: (ids) {
    //     print(ids);
    //   },
    // ));
    return searchResults;
  }

  @override
  Widget build(BuildContext context) {
    final SearchFieldBloc searchFieldBloc =
        Provider.of<SearchFieldBloc>(context, listen: false);
    return ListView(
      children: <Widget>[
        SizedBox(
          height: 40,
        ),
        StreamBuilder<Event<SearchFieldState, String>>(
            stream: searchFieldBloc.stream,
            builder: (context,
                AsyncSnapshot<Event<SearchFieldState, String>> snapshot) {
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
                            title: Text(
                                "SEARCH RESULTS FOR: " + snapshot.data.object),
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
    );
  }
}

class ScreenshotListGrid extends StatelessWidget {
  const ScreenshotListGrid({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    // final ScreenBloc screenBloc = SingleBlocProvider.of<ScreenBloc>(context);
    // final SearchFieldBloc searchFieldBloc = Provider.of<SearchFieldBloc>(context);
    final SearchScreenBloc bloc =
        Provider.of<SearchScreenBloc>(context, listen: false);

    return Container(
        child: StreamBuilder<Event<SearchStates, List<ScreenshotModel>>>(
            stream: bloc.stream,
            builder: (context,
                AsyncSnapshot<Event<SearchStates, List<ScreenshotModel>>>
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
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        color: Colors.transparent,
                        child: GridView.builder(
                            physics: ClampingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data.object.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: (150 / 270),
                                    crossAxisCount:
                                        (orientation == Orientation.portrait)
                                            ? 3
                                            : 4),
                            itemBuilder: (context, index) {
                              File file =
                                  File(snapshot.data.object[index].imagePath);
                              return file.existsSync()
                                  ? ImageGridTile(
                                      model: snapshot.data.object[index],
                                      file: file,
                                    )
                                  : Container(
                                      child: Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    );
                            }),
                      ),
                    );
                  }
                }
              }
              return Container();
            }));
  }
}

class _EmptyListWidget extends StatelessWidget {
  final String message;
  const _EmptyListWidget({Key key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
