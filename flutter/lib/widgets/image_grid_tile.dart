import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:ural/background_tasks.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/blocs/search_bloc.dart';
import 'package:ural/blocs/selection_bloc.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/prefrences.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/pages/image_view.dart';
import 'package:ural/widgets/delete_button.dart';

class ImageGridTile extends StatelessWidget {
  final ScreenshotModel model;
  final File file;
  const ImageGridTile({Key key, this.file, this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rscreen = Provider.of<RecentScreenBloc>(context, listen: false);
    final search = Provider.of<SearchScreenBloc>(context, listen: false);
    ScreenSelectionBloc selectionBloc;
    try {
      selectionBloc = Provider.of<ScreenSelectionBloc>(context, listen: false);
    } catch (e) {
      selectionBloc = null;
    }

    return InkWell(
      onLongPress: () {
        if (selectionBloc != null) {
          if (selectionBloc.event.state == SelectionStates.empty)
            selectionBloc.dispatch(SelectionAction.add, data: {"model": model});
        }
      },
      onTap: () async {
        if ((selectionBloc != null) &&
            selectionBloc.event.state != SelectionStates.empty) {
          selectionBloc.event.object.containsKey(model.hash)
              ? selectionBloc
                  .dispatch(SelectionAction.remove, data: {"hash": model.hash})
              : selectionBloc
                  .dispatch(SelectionAction.add, data: {"model": model});
        } else {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ImageView(image: File(model.imagePath), model: model),
              ));
          if (result == "delete")
            DeleteButtonWidget.deleteAction(context, [model],
                rscreen: rscreen, search: search);
        }
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              child: Hero(
                tag: model.hash,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Thumbnail(
                        imagePath: file.path,
                      ),
                    )),
              ),
            ),
            selectionBloc == null
                ? Container()
                : StreamBuilder<
                    Event<SelectionStates, Map<int, ScreenshotModel>>>(
                    stream: selectionBloc.stream,
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
                                child: Icon(Icons.check_circle,
                                    color: Colors.white)),
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

class Thumbnail extends StatefulWidget {
  final String imagePath;
  Thumbnail({Key key, this.imagePath}) : super(key: key);

  @override
  _ThumbanailState createState() => _ThumbanailState();
}

class _ThumbanailState extends State<Thumbnail> with TickerProviderStateMixin {
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
