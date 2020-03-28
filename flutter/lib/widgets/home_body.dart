import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/controllers/image_handler.dart';
import 'package:ural/database.dart';
import 'package:ural/pages/image_view.dart';
import 'package:ural/models/screen_model.dart';
import 'dart:io';
import 'package:ural/repository/database_repo.dart';
import 'package:ural/pages/textview.dart';
import 'package:ural/utils/bloc_provider.dart';

class HomeBodyWidget extends StatefulWidget {
  HomeBodyWidget({Key key}) : super(key: key);

  @override
  _HomeBodyWidgetState createState() => _HomeBodyWidgetState();
}

class _HomeBodyWidgetState extends State<HomeBodyWidget> {
  final RecentScreenBloc _rscreenBloc = RecentScreenBloc();
  ScrollController _scrollController = ScrollController();

  double heightFactor = 0.1;

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
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
              ScrollDirection.reverse &&
          _scrollController.offset > 20) {
        setState(() {
          heightFactor = 0.0;
        });
      } else {
        if (_scrollController.offset < 5) {
          setState(() {
            heightFactor = 0.1;
          });
        }
      }
    });
  }

  void startup() async {
    final repo = MultiRepositoryProvider.of<DatabaseRepository>(context);
    repo.addListeners(() {
      _rscreenBloc.initializeDatabase(repo.slDB);
      _rscreenBloc.dispatch(RecentScreenAction.fetch);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _rscreenBloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final ScreenBloc screenBloc = SingleBlocProvider.of<ScreenBloc>(context);
    return ListView(children: [
      SizedBox(
        height: 40,
      ),
      SizedBox(
        height: 60,
        child: ListTile(
            title: Text("ALL SCREENSHOTS"),
            subtitle: StreamBuilder(
                stream: _rscreenBloc.state.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData)
                    return Text(
                        "${_rscreenBloc.state.data.length} items sycned");
                  return Container();
                }),
            trailing: IconButton(
              icon: Icon(
                Feather.refresh_ccw,
              ),
              onPressed: () {
                _rscreenBloc.dispatch(RecentScreenAction.fetch);
              },
            )),
      ),
      StreamBuilder<SubState<RecentScreenStates, List<ScreenshotModel>>>(
          stream: _rscreenBloc.state.stream,
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
                    callback: screenBloc.listAllScreens,
                  );
                } else {
                  return Material(
                    color: Colors.transparent,
                    child: GridView.builder(
                        physics: ClampingScrollPhysics(),
                        controller: _scrollController,
                        shrinkWrap: true,
                        itemCount: snapshot.data.object.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                (orientation == Orientation.portrait) ? 2 : 3),
                        itemBuilder: (context, index) {
                          File file;
                          try {
                            file = File(snapshot.data.object[index].imagePath);
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
                          return InkWell(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) =>
                                        SingleBlocProvider<ScreenBloc>(
                                          bloc: screenBloc,
                                          child: ImageView(
                                            imageFile: file,
                                          ),
                                        ))),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20)),
                              child: Stack(
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(8),
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        file,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(
              height: 40,
            ),
            FlatButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.pinkAccent, width: 1)),
                textColor: Colors.white,
                onPressed: callback,
                child: Text("Refresh"))
          ],
        ),
      ),
    );
  }
}
