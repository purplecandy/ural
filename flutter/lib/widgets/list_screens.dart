import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'dart:io';

import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/widgets/buttons.dart' show FlatPurpleButton;
import 'package:ural/widgets/image_grid_tile.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/utils/bloc_provider.dart';

class ListScreenshotsWidget<T extends AbstractScreenshots>
    extends StatefulWidget {
  ListScreenshotsWidget({Key key}) : super(key: key);

  @override
  _ListScreenshotsWidgetState createState() => _ListScreenshotsWidgetState<T>();
}

class _ListScreenshotsWidgetState<T extends AbstractScreenshots>
    extends State<ListScreenshotsWidget> {
  ScrollController _scrollController = ScrollController();

  void refresh() {
    SingleBlocProvider.of<RecentScreenBloc>(context)
        .dispatch(RecentScreenAction.fetch);
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final rscreenBloc = SingleBlocProvider.of<T>(context);
    return ListView(children: [
      SizedBox(
        height: 40,
      ),
      SizedBox(
        height: 60,
        child: ListTile(
            title: Text("ALL SCREENSHOTS"),
            subtitle: StreamBuilder(
                stream: rscreenBloc.state.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData)
                    return Text(
                        "${rscreenBloc.state.data.length} items sycned");
                  return Container();
                }),
            trailing: IconButton(
              icon: Icon(
                Feather.refresh_ccw,
              ),
              onPressed: () {
                rscreenBloc.dispatch(RecentScreenAction.fetch);
              },
            )),
      ),
      StreamBuilder<SubState<RecentScreenStates, List<ScreenshotModel>>>(
          stream: rscreenBloc.state.stream,
          builder: (context,
              AsyncSnapshot<SubState<RecentScreenStates, List<ScreenshotModel>>>
                  snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data.state == RecentScreenStates.loading) {
                return Material(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                if (snapshot.data.object.length == 0) {
                  return _EmptyListWidget(
                    callback: refresh,
                  );
                } else {
                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: EdgeInsets.only(left: 8, right: 8),
                      child: GridView.builder(
                          physics: ClampingScrollPhysics(),
                          controller: _scrollController,
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
                            File file;
                            try {
                              file =
                                  File(snapshot.data.object[index].imagePath);
                              if (!file.existsSync()) {
                                throw Exception("Image does not exist");
                              }
                            } catch (e) {
                              return Container(
                                child: Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              );
                            }
                            return ImageGridTile(
                              model: snapshot.data.object[index],
                              file: file,
                              key: UniqueKey(),
                            );
                          }),
                    ),
                  );
                }
              }
            }
            return Container();
          }),
    ]);
  }
}

class _EmptyListWidget extends StatelessWidget {
  final VoidCallback callback;
  const _EmptyListWidget({Key key, this.callback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        height: 200,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "You don't have any screenshots synced.",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(
              height: 40,
            ),
            FlatPurpleButton(
              onPressed: (_) {
                callback();
              },
              title: "Refresh",
            )
          ],
        ),
      ),
    );
  }
}
