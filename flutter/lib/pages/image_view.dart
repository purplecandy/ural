import 'dart:io';
import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_view/photo_view.dart';
import 'package:open_file/open_file.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:provider/provider.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/utils/file_utils.dart';
import 'package:ural/widgets/dialogs/alert.dart';
import 'package:ural/widgets/popup_progress.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';

// import 'package:ural/utils/bloc_provider.dart';
// import 'package:ural/blocs/screen_bloc.dart';

class ImageView<T extends AbstractScreenshots> extends StatefulWidget {
  final ScreenshotModel model;
  ImageView({Key key, this.model}) : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState<T>();
}

class _ImageViewState<T> extends State<ImageView> {
  final scaffold = GlobalKey<ScaffoldState>();
  final scaleController = PhotoViewScaleStateController();
  ScreenshotModel get model => widget.model;
  File image;
  img.Image encodedImage;
  Widget textPainter = Container();
  List<Rect> rects = [];
  List<String> recognizedText = [];
  bool textViewEnabled = false;
  @override
  void initState() {
    startup();
    super.initState();
  }

  void startup() {
    try {
      image = File(model.imagePath);
      encodedImage = img.decodeImage(image.readAsBytesSync());
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffold,
      backgroundColor: Colors.black,
      body: Container(
        padding: EdgeInsets.all(16),
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              ignoring: textViewEnabled,
              child: PhotoView.customChild(
                scaleStateController: scaleController,
                child: Image.file(image),
              ),
            ),
            textViewEnabled
                ? FittedBox(
                    child: SizedBox(
                      height: encodedImage.height.toDouble(),
                      width: encodedImage.width.toDouble(),
                      child: GestureDetector(
                        onTapDown: (details) {
                          final index = rects.lastIndexWhere(
                              (rect) => rect.contains(details.localPosition));

                          if (index != -1) {
                            scaffold.currentState
                                .showBottomSheet((context) => TextView(
                                      text: recognizedText[index],
                                    ));
                          }
                        },
                        child: textPainter,
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
                icon: Icon(
                  Feather.share_2,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await Share.file(
                    'Ural image share',
                    FileUtils.getEntityName(image.path),
                    image.readAsBytesSync(),
                    FileUtils.getMime(image.path),
                  );
                }),
            IconButton(
                icon: Icon(
                  Feather.share,
                  color: Colors.white,
                ),
                onPressed: () async {
                  OpenFile.open(image.path);
                }),
            IconButton(
                icon: Icon(
                  Feather.trash,
                  color: Colors.white,
                ),
                onPressed: () async {
                  /// TODO: Implement delete
                  // await screenBloc.delete(widget.imageFile.path);
                  // Navigator.pop(context);
                  showDialog(
                      context: context,
                      builder: (context) => BetterAlertDialog(
                            title: "Delete Screenshot?",
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Are you sure?"),
                                  Text(
                                      "It will permanently delete the screenshot from your phone."),
                                ]),
                            confirmText: "Delete",
                            cancelText: "Cancel",
                            // When the action is terminated
                            onCancel: () => Navigator.pop(context),
                            // When the action is confirmed
                            onConfirm: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Provider.of<T>(context, listen: false);
                            },
                          ));
                }),
            IconButton(
                icon: Icon(
                  textViewEnabled ? Feather.image : Feather.type,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (textViewEnabled) {
                    setState(() {
                      textViewEnabled = false;
                    });
                  } else {
                    if (recognizedText.isNotEmpty && rects.isNotEmpty) {
                      setState(() {
                        textViewEnabled = true;
                      });
                      return;
                    }
                    showPopUpProgress(context, future: () async {
                      final recognizer =
                          FirebaseVision.instance.textRecognizer();
                      final result = await recognizer
                          .processImage(FirebaseVisionImage.fromFile(image));
                      result.blocks.forEach((b) {
                        rects.add(b.boundingBox);
                        recognizedText.add(b.text);
                      });
                    }, onDone: () {
                      setState(() {
                        scaleController.reset();
                        textViewEnabled = true;
                        textPainter = CustomPaint(
                          painter: TextPainter(rects),
                        );
                      });
                    });
                  }
                })
          ],
        ),
      ),
    );
  }
}

class TextPainter extends CustomPainter {
  final List<Rect> rects;
  TextPainter(this.rects);

  @override
  void paint(Canvas canvas, Size size) {
    for (var rect in rects) {
      canvas.drawRect(
          rect.inflate(10),
          Paint()
            ..color = Colors.teal.withOpacity(0.3)
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class TextView extends StatelessWidget {
  final String text;
  const TextView({Key key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                  icon: Icon(Feather.copy),
                  onPressed: () async {
                    await ClipboardManager.copyToClipBoard(text);
                    Fluttertoast.showToast(msg: "Text copied");
                  }),
              IconButton(
                  icon: Icon(Icons.g_translate),
                  onPressed: () async {
                    String url = Uri.encodeFull(
                        "https://translate.google.co.in/?hl=en&tab=TT#view=home&op=translate&sl=auto&tl=en&text=$text");
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  })
            ],
          )
        ],
      ),
    );
  }
}
