import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';

import 'package:ural/blocs/abstract_screens.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/widgets/buttons.dart' show RoundedPurpleButton;
import 'package:ural/models/screen_model.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/widgets/screenshot_grid.dart';

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
    Provider.of<T>(context, listen: false).dispatch(RecentScreenAction.fetch);
  }

  @override
  Widget build(BuildContext context) {
    final rscreenBloc = Provider.of<T>(context, listen: false);
    return ListView(children: [
      SizedBox(
        height: 40,
      ),
      SizedBox(
        height: 60,
        child: ListTile(
            title: Text("ALL SCREENSHOTS"),
            subtitle: StreamBuilder(
                stream: rscreenBloc.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData)
                    return Text(
                        "${rscreenBloc.event.object.length} items sycned");
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
      StreamBuilder<Event<RecentScreenStates, List<ScreenshotModel>>>(
          stream: rscreenBloc.stream,
          builder: (context,
              AsyncSnapshot<Event<RecentScreenStates, List<ScreenshotModel>>>
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
                  return ScreenshotGridBuilder(
                    controller: _scrollController,
                    screenshots: snapshot.data.object,
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
    return Container(
      // color: Theme.of(context).backgroundColor/\,
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
          RoundedPurpleButton(
            onPressed: () {
              callback();
            },
            title: "Refresh",
          )
        ],
      ),
    );
  }
}
