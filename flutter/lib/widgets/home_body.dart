import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/controllers/image_handler.dart';
import 'package:ural/pages/image_view.dart';
import 'package:ural/models/screen_model.dart';
import 'dart:io';

import 'package:ural/pages/textview.dart';
import 'package:ural/utils/bloc_provider.dart';

class HomeBodyWidget extends StatefulWidget {
  HomeBodyWidget({Key key}) : super(key: key);

  @override
  _HomeBodyWidgetState createState() => _HomeBodyWidgetState();
}

class _HomeBodyWidgetState extends State<HomeBodyWidget> {
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
    _scrollController.addListener(() {
      if (_scrollController.position.outOfRange) {
        print("OUT OF RANGE");
      }
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (heightFactor > 0) {
          setState(() {
            heightFactor = heightFactor - 0.1;
          });
        }
      } else {}
      if (_scrollController.offset <=
              _scrollController.position.minScrollExtent &&
          _scrollController.position.outOfRange) {
        if (heightFactor <= 0.1) {
          setState(() {
            heightFactor = heightFactor + 0.1;
          });
        }
      }
      print("OFF:" + _scrollController.offset.toString());
      print(heightFactor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final ScreenBloc screenBloc = SingleBlocProvider.of<ScreenBloc>(context);
    return StreamBuilder<RecentScreenStates>(
        stream: screenBloc.streamOfRecentScreens,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == RecentScreenStates.loading) {
              return Material(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              if (screenBloc.recentScreenshots.length == 0) {
                return _EmptyListWidget(
                  callback: screenBloc.listAllScreens,
                );
              } else {
                return Material(
                  color: Colors.transparent,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height:
                            MediaQuery.of(context).size.height * heightFactor,
                      ),
                      Expanded(
                        child: GridView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            itemCount: screenBloc.recentScreenshots.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        (orientation == Orientation.portrait)
                                            ? 2
                                            : 3),
                            itemBuilder: (context, index) {
                              File file;
                              try {
                                file = File(screenBloc
                                    .recentScreenshots[index].imagePath);
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            file,
                                            // color: Colors.black.withOpacity(0.2),
                                            // colorBlendMode: BlendMode.luminosity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      // FractionalTranslation(
                                      //   translation: Offset(3, 3),
                                      //   child: IconButton(
                                      //       color: Colors.white,
                                      //       icon: Icon(Feather.more_horizontal),
                                      //       onPressed: () {
                                      //         handleTextView(file);
                                      //       }),
                                      // )
                                    ],
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                );
              }
            }
          }
          return Container();
        });
  }
}

class _EmptyListWidget extends StatelessWidget {
  final VoidCallback callback;
  const _EmptyListWidget({Key key, this.callback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
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
    );
  }
}
