import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:ural/background_tasks.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/prefrences.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'dart:io';
import 'package:ural/pages/image_view.dart';

class ImageGridTile extends StatelessWidget {
  final ScreenshotModel model;
  // final ScreenBloc bloc;
  final File file;
  const ImageGridTile({Key key, this.file, this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ScreenSelectionBloc selectionBloc =
        SingleBlocProvider.of<ScreenSelectionBloc>(context);
    return InkWell(
      onLongPress: () {
        if (selectionBloc.state.currentState == SelectionStates.empty)
          selectionBloc.dispatch(SelectionAction.add, {"hash": model.hash});
      },
      onTap: () {
        if (selectionBloc.state.currentState != SelectionStates.empty) {
          selectionBloc.state.data.containsKey(model.hash)
              ? selectionBloc
                  .dispatch(SelectionAction.remove, {"hash": model.hash})
              : selectionBloc
                  .dispatch(SelectionAction.add, {"hash": model.hash});
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => ImageView(
                  imageFile: file,
                ),
              ));
        }
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Container(
              // margin: EdgeInsets.all(8),
              width: double.infinity,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Thumbanail(
                      imagePath: file.path,
                    ),
                  )),
            ),
            StreamBuilder<SubState<SelectionStates, Map<int, ScreenshotModel>>>(
              stream: selectionBloc.state.stream,
              builder: (context, snap) {
                if (snap.hasData) {
                  return Visibility(
                    visible: (snap.data.state != SelectionStates.empty &&
                        snap.data.object.containsKey(model.hash)),
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      color: Colors.deepPurple.withOpacity(0.3),
                      child: Center(
                          child: Icon(
                        MaterialCommunityIcons.check_circle,
                      )),
                    ),
                  );
                }
                return SizedBox(
                  height: 0,
                  width: 0,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class Thumbanail extends StatefulWidget {
  final String imagePath;
  Thumbanail({Key key, this.imagePath}) : super(key: key);

  @override
  _ThumbanailState createState() => _ThumbanailState();
}

class _ThumbanailState extends State<Thumbanail> with TickerProviderStateMixin {
  bool _thumbGenerated = false;
  Widget _placeholder = Container(
    height: 15,
    width: 15,
    child: CircularProgressIndicator(),
  );
  File _thumb;

  @override
  void initState() {
    super.initState();
    startup();
  }

  void startup() async {
    // getApplicationSupportDirectory().then((d) => print("Support -> " + d.path));
    // getApplicationDocumentsDirectory()
    //     .then((d) => print("Document ->" + d.path));
    // getTemporaryDirectory().then((temp) {
    //   _thumb = File(temp.path + '/${widget.imagePath.hashCode}.png');
    //   setState(() {
    //     _thumbGenerated = true;
    //   });
    // });
    setState(() {
      _thumb = File(
          UralPrefrences.thumbsDir.path + '/${widget.imagePath.hashCode}.png');
      //fallback load original image
      if (!_thumb.existsSync()) {
        _thumb = File(widget.imagePath);
        generateThumb(widget.imagePath);
      }
      _thumbGenerated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return !_thumbGenerated
        ? _placeholder
        : Image.file(
            _thumb,
            fit: BoxFit.cover,
          );
  }
}
