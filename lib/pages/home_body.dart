import 'package:flutter/material.dart';
import 'package:ural/image_view.dart';
import 'package:ural/models/screen_model.dart';
import 'dart:io';

class HomeBody extends StatefulWidget {
  final List<ScreenModel> screenshots;
  HomeBody({Key key, this.screenshots}) : super(key: key);

  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  List<ScreenModel> get screenshots => widget.screenshots;
  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;

    return Material(
      child: GridView.builder(
          itemCount: screenshots.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: (orientation == Orientation.portrait) ? 2 : 3),
          itemBuilder: (context, index) {
            File file;
            try {
              file = File(screenshots[index].path);
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
                      builder: (context) => ImageView(
                            imageFile: file,
                          ))),
              child: Container(
                margin: EdgeInsets.all(8),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }),
    );
  }
}
