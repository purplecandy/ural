import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:ural/blocs/selection_bloc.dart';
import 'package:ural/blocs/tags_bloc.dart';
import 'package:ural/database/utils.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/models/tags_model.dart';
import 'package:ural/pages/tags.dart';
import 'package:ural/repository/database_repo.dart';
import 'package:ural/utils/bloc.dart';

class AddToTagButtonWidget extends StatelessWidget {
  const AddToTagButtonWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectionBloc =
        Provider.of<ScreenSelectionBloc>(context, listen: false);
    return IconButton(
        color: Theme.of(context).iconTheme.color,
        icon: Icon(Feather.tag),
        onPressed: () {
          showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (context) => Provider<ScreenSelectionBloc>(
                  create: (_) => selectionBloc, child: AddToTagWidget()));
        });
  }
}

class AddToTagWidget extends StatefulWidget {
  AddToTagWidget({Key key}) : super(key: key);

  @override
  _AddToTagWidgetState createState() => _AddToTagWidgetState();
}

class _AddToTagWidgetState extends State<AddToTagWidget> {
  final _tagsBloc = TagsBloc();
  final _selected = Set<int>();
  List<ScreenshotModel> _selectedScreens = List<ScreenshotModel>();
  @override
  void initState() {
    super.initState();
    startup();
  }

  void startup() {
    final repo = Provider.of<DatabaseRepository>(context, listen: false);
    _selectedScreens = Provider.of<ScreenSelectionBloc>(context, listen: false)
        .event
        .object
        .values
        .toList();

    _tagsBloc.initializeDatabase(repo.slDB);
    _tagsBloc.dispatch(TagAction.fetch);
  }

  void handleApply() async {
    final db = Provider.of<DatabaseRepository>(context, listen: false).slDB.db;
    Navigator.pop(context);
    try {
      if (_selected.isEmpty) return;
      for (var item in _selectedScreens) {
        for (var tagId in _selected) {
          await TaggedScreensUtils.insert(db, tagId, item.docId);
        }
      }
      Fluttertoast.showToast(
          msg: "Screenshots added to tags",
          backgroundColor: Colors.greenAccent,
          textColor: Colors.white);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.circular(19)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          //header
          Padding(
              padding:
                  const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Add tags",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    onPressed: handleApply,
                    child: Text(
                      "Apply",
                      style: TextStyle(
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ),
                ],
              )),
          //create new
          Divider(height: 1),
          ListTile(
            leading: Icon(Feather.plus),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => Provider<TagsBloc>(
                      create: (_) => _tagsBloc, child: NewTagDialogue()));
            },
            title: Text("Create new tag"),
          ),
          //display tags
          Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: BlocBuilder<TagState, List<TagModel>>(
                bloc: _tagsBloc,
                onSuccess: (_, event) => Wrap(
                  children: event.object
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FilterChip(
                              selected: _selected.contains(t.id),
                              label: Text(t.name),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selected.add(t.id);
                                  } else {
                                    _selected.remove(t.id);
                                  }
                                });
                              },
                              backgroundColor: Color(t.colorCode),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
