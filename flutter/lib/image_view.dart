import 'dart:io';
import 'package:flutter/material.dart';

class ImageView extends StatelessWidget {
  final File imageFile;
  const ImageView({Key key, this.imageFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16),
        height: double.infinity,
        width: double.infinity,
        child: Image.file(imageFile),
      ),
    );
  }
}
