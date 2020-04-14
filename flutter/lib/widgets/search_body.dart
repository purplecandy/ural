import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';

import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/widgets/image_grid_tile.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/prefrences.dart';
import 'package:ural/utils/bloc_provider.dart';

class SearchBodyWidget extends StatefulWidget {
  SearchBodyWidget({Key key}) : super(key: key);

  @override
  _SearchBodyWidgetState createState() => _SearchBodyWidgetState();
}

class _SearchBodyWidgetState extends State<SearchBodyWidget> {
  @override
  void initState() {
    super.initState();
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
    searchResults.add(FilterByTagsWidget());
    return searchResults;
  }

  @override
  Widget build(BuildContext context) {
    final SearchFieldBloc searchFieldBloc =
        SingleBlocProvider.of<SearchFieldBloc>(context);
    return ListView(
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
    // final SearchFieldBloc searchFieldBloc =
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
                                    model: snapshot.data.object[index],
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
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class FilterByTagsWidget extends StatefulWidget {
  final String title;
  FilterByTagsWidget({Key key, this.title}) : super(key: key);

  @override
  _FilterTagsWidgetState createState() => _FilterTagsWidgetState();
}

class _FilterTagsWidgetState extends State<FilterByTagsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: <Widget>[Text(widget.title ?? "Filter by tags")],
      ),
    );
  }
}
