import 'dart:io';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter/material.dart';
import 'package:ural/blocs/file_browser_bloc.dart';
import 'package:ural/utils/file_utils.dart';

typedef ActionCallBack = void Function(String);

class FileBrowser extends StatefulWidget {
  final ActionCallBack action;
  final String title;
  FileBrowser({Key key, this.title, this.action}) : super(key: key);

  @override
  _FileBrowserState createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  FileBrowserBloc fileBrowserBloc = FileBrowserBloc();

  List<FileSystemEntity> get paths => fileBrowserBloc.currentDirectory;
  FileBrowserBloc get bloc => fileBrowserBloc;

  Widget buildLeadingWidget(FileSystemEntity entity, BrowserState state) {
    if (entity is File) {
      //check mime type
      String mime = FileUtils.getMime(entity.path);
      String type = "";
      if (mime != null) {
        type = mime.split("/")[0];
      }

      if (type == "image") {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.file(
            entity,
            fit: BoxFit.cover,
          ),
        );
      } else if (type == "video") {
        return Container(
          height: 50,
          width: 50,
          color: Theme.of(context).backgroundColor,
          child: Center(
              child: Icon(
            AntDesign.playcircleo,
            color: Theme.of(context).accentColor,
          )),
        );
      } else {
        return Container(
          height: 50,
          width: 50,
          color: Theme.of(context).backgroundColor,
          child: Center(
              child: Icon(
            AntDesign.file1,
            color: Theme.of(context).accentColor,
          )),
        );
      }
    } else {
      return Container(
        height: 50,
        width: 50,
        color: Theme.of(context).primaryColor.withOpacity(0.4),
        child: Center(
            child: Icon(
          state == BrowserState.intial
              ? getStorageIcon(entity.path.split("/"))
              : AntDesign.folder1,
          color: Theme.of(context).accentColor,
        )),
      );
    }
  }

  IconData getStorageIcon(List<String> path) {
    if (path.contains("emulated")) {
      return MaterialIcons.phone_android;
    } else {
      return MaterialIcons.sd_card;
    }
  }

  @override
  void initState() {
    super.initState();
    bloc.getInitialPath();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: StreamBuilder<BrowserState>(
            stream: bloc.streamOfPaths,
            builder: (BuildContext context, AsyncSnapshot<BrowserState> snap) {
              if (snap.hasData) {
                if (snap.data == BrowserState.intial) {
                  return IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        if (snap.data == BrowserState.intial)
                          Navigator.pop(context);
                      });
                } else {
                  return IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        bloc.goToPreviousPath();
                      });
                }
              }
              return Container();
            },
          ),
          title: Text(widget.title),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(40),
            child: StreamBuilder<BrowserState>(
              stream: bloc.streamOfPaths,
              builder:
                  (BuildContext context, AsyncSnapshot<BrowserState> snap) {
                if (snap.hasData) {
                  if (snap.data != BrowserState.loading) {
                    if (snap.data != BrowserState.intial) {
                      return Container(
                        margin: EdgeInsets.only(left: 10),
                        height: 40,
                        width: MediaQuery.of(context).size.width,
                        child: ListView.builder(
                          // shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: bloc.pathHistory.length,
                          itemBuilder: (context, index) => Row(
                            children: <Widget>[
                              FlatButton(
                                padding: EdgeInsets.all(4),
                                onPressed: () {
                                  bloc.jumpToPreviousPath(index);
                                },
                                child: Text(
                                  FileUtils.getEntityName(
                                      bloc.pathHistory[index]),
                                  style: TextStyle(
                                      color:
                                          (index + 1 != bloc.pathHistory.length)
                                              ? Colors.white.withOpacity(0.5)
                                              : Colors.pinkAccent),
                                ),
                              ),
                              (index + 1 != bloc.pathHistory.length)
                                  ? Icon(
                                      Icons.arrow_forward_ios,
                                      size: 15,
                                    )
                                  : Container()
                            ],
                          ),
                        ),
                      );
                    }
                  }
                }
                return Container();
              },
            ),
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                bloc.getInitialPath();
              },
              icon: Icon(AntDesign.home),
            )
          ],
        ),
        body: StreamBuilder<BrowserState>(
          stream: fileBrowserBloc.streamOfPaths,
          builder: (BuildContext context, AsyncSnapshot<BrowserState> snap) {
            if (snap.hasData) {
              if (snap.data != BrowserState.loading) {
                return ListView.builder(
                  itemCount: fileBrowserBloc.currentDirectory.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        leading: buildLeadingWidget(paths[index], snap.data),
                        onTap: () {
                          bloc.changePath(index);
                        },
                        title: Text(
                          FileUtils.getEntityName(paths[index].path),
                        ));
                  },
                );
              }

              if (snap.data == BrowserState.loading)
                return Center(
                  child: CircularProgressIndicator(),
                );
            }
            return Container();
          },
        ),
        bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: StreamBuilder<BrowserState>(
                    stream: bloc.streamOfPaths,
                    builder: (context, snap) {
                      return FlatButton(
                        onPressed: snap.data == BrowserState.intial
                            ? null
                            : () {
                                widget.action(bloc.currentPath);
                                Navigator.pop(context);
                              },
                        child: Text(
                          "SELECT",
                          style: TextStyle(
                              color: snap.data == BrowserState.intial
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white),
                        ),
                        highlightColor: Colors.deepPurpleAccent,
                        color: Colors.deepPurple,
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                      );
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
