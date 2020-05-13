import 'package:flutter/material.dart';
import 'dart:io';

import 'package:ural/models/screen_model.dart';
import 'image_grid_tile.dart';

class ScreenshotGridBuilder extends StatelessWidget {
  final ScrollController controller;
  final List<ScreenshotModel> screenshots;
  const ScreenshotGridBuilder({Key key, this.controller, this.screenshots})
      : assert(screenshots != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(left: 8, right: 8),
        child: GridView.builder(
            physics: ClampingScrollPhysics(),
            controller: controller ?? ScrollController(),
            shrinkWrap: true,
            itemCount: screenshots.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: (150 / 270),
                crossAxisCount: (orientation == Orientation.portrait) ? 3 : 4),
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
              return ImageGridTile(
                model: screenshots[index],
                file: file,
                key: UniqueKey(),
              );
            }),
      ),
    );
  }
}
