import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:open_file/open_file.dart';

import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/blocs/screen_bloc.dart';

class ImageView extends StatefulWidget {
  final File imageFile;
  ImageView({Key key, this.imageFile}) : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  @override
  Widget build(BuildContext context) {
    final ScreenBloc screenBloc = SingleBlocProvider.of<ScreenBloc>(context);
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16),
        height: double.infinity,
        width: double.infinity,
        child: PhotoView.customChild(child: Image.file(widget.imageFile)),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            // TODO: implement a share function
            // IconButton(
            //     icon: Icon(
            //       Icons.share,
            //       color: Colors.white,
            //     ),
            //     onPressed: () async {
            //     }),
            IconButton(
                icon: Icon(
                  Icons.open_in_new,
                  color: Colors.white,
                ),
                onPressed: () async {
                  OpenFile.open(widget.imageFile.path);
                }),
            IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await screenBloc.delete(widget.imageFile.path);
                  Navigator.pop(context);
                })
          ],
        ),
      ),
    );
  }
}
