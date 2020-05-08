import 'dart:io';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:open_file/open_file.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:image/image.dart' as img;

import 'package:ural/models/screen_model.dart';
import 'package:ural/utils/file_utils.dart';
import 'package:ural/widgets/dialogs/alert.dart';
import 'package:ural/widgets/popup_progress.dart';
import 'package:ural/widgets/textview.dart';

class ImageView extends StatefulWidget {
  final File image;
  final ScreenshotModel model;
  final void Function() onDelete;
  ImageView({Key key, this.image, this.model, @required this.onDelete})
      : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  final scaffold = GlobalKey<ScaffoldState>();
  final scaleController = PhotoViewScaleStateController();
  ScreenshotModel get model => widget.model;
  File get image => widget.image;
  img.Image encodedImage;
  Widget textPainter = Container();
  List<Rect> rects = [];
  List<String> recognizedText = [];
  bool textViewEnabled = false;
  @override
  void initState() {
    super.initState();
  }

  Future<void> parseImage() async {
    final bytes = await image.readAsBytes();
    encodedImage = img.decodeImage(bytes);
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
              child: Hero(
                tag: model.hash,
                child: PhotoView.customChild(
                  scaleStateController: scaleController,
                  child: Image.file(image),
                ),
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
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => TextView(
                                text: recognizedText[index],
                              ),
                            );
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
                                      "It will permanently delete it from your phone."),
                                ]),
                            confirmText: "Delete",
                            cancelText: "Cancel",
                            // When the action is terminated
                            onCancel: () => Navigator.pop(context),
                            // When the action is confirmed
                            onConfirm: () {
                              widget.onDelete?.call();
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
                        scaleController.reset();
                        textViewEnabled = true;
                      });
                      return;
                    }
                    showPopUpProgress(context, future: () async {
                      await parseImage();
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
            ..color = Colors.lime.withOpacity(0.2)
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
