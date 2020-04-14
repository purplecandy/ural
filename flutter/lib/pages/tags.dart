import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:ural/blocs/tags_bloc.dart';
import 'package:ural/models/tags_model.dart';
import 'package:ural/pages/tagged_screens.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/repository/database_repo.dart';
import 'package:ural/widgets/buttons.dart';
import 'package:ural/widgets/dialogs/base.dart';

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
        ),
        body: StreamBuilder<SubState<TagState, List<TagModel>>>(
          stream: _tagsBloc.state.stream,
          builder: (BuildContext context,
              AsyncSnapshot<SubState<TagState, List<TagModel>>> snapshot) {
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
  NewTagDialogue({Key key}) : super(key: key);

  @override
  _NewTagDialogueState createState() => _NewTagDialogueState();
}

class _NewTagDialogueState extends State<NewTagDialogue> {
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
  Widget build(BuildContext context) {
    final TagsBloc bloc = Provider.of<TagsBloc>(context, listen: false);
    return BaseDialog(
      title: "Create Tag",
      child: Column(
        children: <Widget>[
          TextField(
            controller: controller,
            maxLength: 25,
            decoration: InputDecoration(
                border: OutlineInputBorder(), labelText: "Name"),
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
              onPressed: (context) {
                if (controller.text.length > 0 && _selectedColor != -1) {
                  bloc.dispatch(TagAction.create, {
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
              },
              title: "Create",
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
