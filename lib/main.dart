import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ural/auth_bloc.dart';
import 'package:ural/urls.dart';
import 'package:ural/user_dialog.dart';
import 'package:ural/utils/async.dart';
import 'textview.dart';
import 'auth_dialog.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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
  VisionText _visionText;
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

  Future<VisionText> getTextFromImage() async {
    final fbImage = FirebaseVisionImage.fromFile(_image);
    final visionText = await recognizer.processImage(fbImage);
    return visionText;
  }

  Future<void> handleUpload() async {
    if (_image != null) {
      img.Image image = img.decodeImage(_image.readAsBytesSync());
      img.Image thumbnail = img.copyResize(image, width: 120);
      Directory tempDir = await getTemporaryDirectory();
      String encoded;
      var path = _image.path.split("/").last;
      final filename = path.split(".")[0] + ".jpg";
      File(tempDir.path + '/' + filename)
        ..writeAsBytes(img.encodeJpg(thumbnail)).then((file) async {
          encoded = base64.encode(await file.readAsBytes());
          // encoded = file.readAsBytesSync().toString();
        });
      String url = ApiUrls.root + ApiUrls.images;
      String text;
      await getTextFromImage().then((obj) => text = obj.text);
      String payload = json.encode({
        "filename": filename,
        "thumbnail": encoded,
        "image_path": _image.path,
        "text": text,
        "short_text": "",
      });
      try {
        final response = await http.post(url,
            body: payload,
            headers: ApiUrls.authenticatedHeader(Auth().user.token));
        if (response.statusCode == 201) {
          print("Image uploaded successfully");
        } else {
          print(response.body);
        }
      } catch (e) {
        print(e);
      }
    }
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

  // Center(
  //       child: Container(
  //         height: MediaQuery.of(context).size.height * 0.8,
  //         width: MediaQuery.of(context).size.width * 0.8,
  //         child: _image == null ? Text("No image") : Image.file(_image),
  //       ),
  //     )

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(8),
            height: 110,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Card(
                child: ListTile(
                  title: TextField(
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type what you're looking for here"),
                  ),
                  trailing:
                      IconButton(icon: Icon(Icons.search), onPressed: null),
                ),
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: <Widget>[
                FloatingActionButton(
                  elevation: 0,
                  heroTag: null,
                  onPressed: () async {
                    handleUpload();
                  },
                  child: Icon(Icons.file_upload),
                ),
                FloatingActionButton(
                  elevation: 0,
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
                FloatingActionButton(
                  elevation: 0,
                  child: Icon(Icons.add),
                  onPressed: getImage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
