import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/controllers/image_handler.dart';
import 'package:ural/pages/image_view.dart';
import 'package:ural/models/screen_model.dart';
import 'dart:io';

import 'package:ural/pages/textview.dart';
import 'package:ural/utils/bloc_provider.dart';

class HomeBody extends StatefulWidget {
  final String title;
  final List<ScreenshotModel> screenshots;
  HomeBody({Key key, this.screenshots, this.title}) : super(key: key);

  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  List<ScreenshotModel> get screenshots => widget.screenshots;
  String get title => widget.title;
  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final ScreenBloc screenBloc = SingleBlocProvider.of<ScreenBloc>(context);
    return Material(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          Expanded(
            child: GridView.builder(
                shrinkWrap: true,
                itemCount: screenshots.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        (orientation == Orientation.portrait) ? 2 : 3),
                itemBuilder: (context, index) {
                  File file;
                  try {
                    file = File(screenshots[index].imagePath);
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
                    child: Stack(
                      children: [
                        Container(
                          margin: EdgeInsets.all(8),
                          width: double.infinity,
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                          ),
                        ),
                        FractionalTranslation(
                          translation: Offset(3, 0.2),
                          child: FloatingActionButton(
                            onPressed: () async {
                              final textBlocs = await recognizeImage(file,
                                  FirebaseVision.instance.textRecognizer(),
                                  getBlocks: true);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TextView(
                                            textBlocks: textBlocs,
                                          )));
                            },
                            elevation: 0,
                            heroTag: null,
                            mini: true,
                            child: Icon(Icons.text_fields),
                          ),
                        )
                      ],
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
