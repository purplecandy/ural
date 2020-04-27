import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:ural/app.dart';

import 'package:ural/blocs/tags_bloc.dart';
import 'package:ural/models/tags_model.dart';
import 'package:ural/pages/tagged_screens.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/repository/database_repo.dart';
import 'package:ural/values/theme.dart';
import 'package:ural/widgets/buttons.dart';
import 'package:ural/widgets/dialogs/base.dart';
import 'package:ural/widgets/dialogs/confirmation_dialog.dart';

class TagsPage extends StatefulWidget {
  TagsPage({Key key}) : super(key: key);

  @override
  _TagsPageState createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  TagsBloc _tagsBloc = TagsBloc();

  @override
  void initState() {
    super.initState();
    startup();
  }

  void startup() {
    final repo = Provider.of<DatabaseRepository>(context, listen: false);
    if (repo.slDB != null) _tagsBloc.initializeDatabase(repo.slDB);
    _tagsBloc.dispatch(TagAction.fetch);
  }

  @override
  Widget build(BuildContext context) {
    return Provider<TagsBloc>(
      create: (_) => _tagsBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Tags"),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.lightbulb_outline),
                onPressed: () => AppTheme.toggleTheme(context))
          ],
        ),
        body: StreamBuilder<Event<TagState, List<TagModel>>>(
          stream: _tagsBloc.stream,
          builder: (BuildContext context,
              AsyncSnapshot<Event<TagState, List<TagModel>>> snapshot) {
            if (snapshot.hasData) {
              switch (snapshot.data.state) {
                case TagState.completed:
                  return ListView.builder(
                    itemCount: snapshot.data.object.length,
                    itemBuilder: (context, index) => Card(
                      color: Color(snapshot.data.object[index].colorCode),
                      child: ListTile(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TaggedScreen(
                                      model: snapshot.data.object[index],
                                    ))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            IconButton(
                                icon: Icon(Feather.edit_2),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) => Provider<TagsBloc>(
                                          create: (_) => _tagsBloc,
                                          child: NewTagDialogue(
                                            create: false,
                                            tagModel:
                                                snapshot.data.object[index],
                                            index: index,
                                          )));
                                }),
                            IconButton(
                              icon: Icon(Feather.trash),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) => ConfirmationDialog(
                                          onConfirm: (_, c) {
                                            Navigator.pop(_);
                                            _tagsBloc.dispatch(TagAction.delete,
                                                data: {
                                                  "index": index,
                                                  "model": snapshot
                                                      .data.object[index]
                                                });
                                          },
                                          title: "Delete Tag",
                                          buttonText: "Confirm",
                                          processingText: "Deleting",
                                          optionTitle:
                                              "Do you want to remove the screenshots too?",
                                          optionSubtitle:
                                              "It will permanantely delete the screenshots from your phone.",
                                        ));
                              },
                            )
                          ],
                        ),
                        title: Text(snapshot.data.object[index].name),
                      ),
                    ),
                  );
                  break;
                default:
              }
            }
            return Container();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) => Provider<TagsBloc>(
                    create: (_) => _tagsBloc, child: NewTagDialogue()));
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class NewTagDialogue extends StatefulWidget {
  /// True to create a new tag. False to update an existing Tag
  /// Default: `false`
  final bool create;
  final TagModel tagModel;
  final int index;
  NewTagDialogue({Key key, this.create = true, this.tagModel, this.index})
      : super(key: key);

  @override
  _NewTagDialogueState createState() => _NewTagDialogueState();
}

class _NewTagDialogueState extends State<NewTagDialogue> {
  bool get create => widget.create;
  TagModel get model => widget.tagModel;
  TextEditingController controller = TextEditingController();
  int _selectedColor = -1;
  List<Color> colorShades = [
    Colors.red.shade200,
    Colors.cyan.shade200,
    Colors.blue.shade200,
    Colors.purple.shade200,
    Colors.green.shade200,
    Colors.orange.shade200,
    Colors.brown.shade200,
  ];

  @override
  void initState() {
    super.initState();
    if (create == false && model != null) {
      controller.text = model.name;
      for (var i = 0; i < colorShades.length; i++) {
        if (colorShades[i].value == model.colorCode) {
          _selectedColor = i;
          break;
        }
      }
    }
  }

  void handleCreate(TagsBloc bloc) {
    if (controller.text.length > 0 && _selectedColor != -1) {
      bloc.dispatch(TagAction.create, data: {
        "name": controller.text,
        "color": colorShades[_selectedColor].value
      });
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
          msg: _selectedColor == -1
              ? "Please select a color"
              : "Name can't be blank",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  void handleUpdate(TagsBloc bloc) {
    if (controller.text.isNotEmpty && _selectedColor != -1) {
      bloc.dispatch(TagAction.update, data: {
        "index": widget.index,
        "model": TagModel(
            model.id, controller.text, colorShades[_selectedColor].value)
      });
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
          msg: _selectedColor == -1
              ? "Please select a color"
              : "Name can't be blank",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TagsBloc bloc = Provider.of<TagsBloc>(context, listen: false);
    return BaseDialog(
      title: create ? "Create Tag" : "Update Tag",
      child: Column(
        children: <Widget>[
          TextField(
            controller: controller,
            maxLength: 25,
            decoration: InputDecoration(
                focusColor: Theme.of(context).accentColor,
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                  width: 1,
                  style: BorderStyle.solid,
                  color: Theme.of(context).accentColor,
                )),
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Theme.of(context).accentColor),
                labelText: "Name"),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Color"),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: colorShades.length,
                itemBuilder: (context, index) => InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = index;
                    });
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    child: Stack(
                      children: <Widget>[
                        ColorTile(
                          color: colorShades[index],
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: _selectedColor == index
                              ? Icon(
                                  Icons.done,
                                  color: Colors.black,
                                )
                              : Container(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: RoundedPurpleButton(
              onPressed: () {
                if (create) {
                  handleCreate(bloc);
                } else {
                  handleUpdate(bloc);
                }
              },
              title: create ? "Create" : "Update",
            ),
          )
        ],
      ),
    );
  }
}

class ColorTile extends StatelessWidget {
  const ColorTile({Key key, this.color}) : super(key: key);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
