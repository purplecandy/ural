import 'package:after_layout/after_layout.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ural/auth_bloc.dart';
import 'package:ural/user_dialog.dart';
import 'package:ural/utils/async.dart';
import 'textview.dart';
import 'auth_dialog.dart';
import 'dart:io';

import 'package:ural/utils/bloc_provider.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {"/": (context) => Home()},
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with AfterLayoutMixin {
  File _image;
  final recognizer = FirebaseVision.instance.textRecognizer();
  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  Future<List<TextBlock>> recognizeImage() async {
    final fbImage = FirebaseVisionImage.fromFile(_image);
    final visionText = await recognizer.processImage(fbImage);
    return visionText.blocks;
    // String text = visionText.text;
    // print(text);
    // for (TextBlock block in visionText.blocks) {
    //   final Rect boundingBox = block.boundingBox;
    //   final List<Offset> cornerPoints = block.cornerPoints;
    //   final String text = block.text;
    //   final List<RecognizedLanguage> languages = block.recognizedLanguages;

    //   for (TextLine line in block.lines) {
    //     // Same getters as TextBlock
    //     for (TextElement element in line.elements) {
    //       // Same getters as TextBlock

    //     }
    //   }
    // }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) async {
    final authState = await Auth().authenticate();
    if (authState.state == ResponseStatus.failed)
      showDialog(
        context: context,
        child: AuthenticationDialog(),
        barrierDismissible: false,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ural"),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                showDialog(context: context, child: UserDialog());
              })
        ],
      ),
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width * 0.8,
          child: _image == null ? Text("No image") : Image.file(_image),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: null,
            onPressed: () async {
              final blocks = await recognizeImage();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => TextView(
                            textBlocks: blocks,
                          )));
            },
            child: Icon(Icons.text_fields),
          ),
          SizedBox(
            height: 40,
          ),
          FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: getImage,
          ),
        ],
      ),
    );
  }
}
