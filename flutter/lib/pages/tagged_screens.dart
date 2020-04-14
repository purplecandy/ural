import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';

import 'package:ural/models/tags_model.dart';
import 'package:ural/pages/screens_view.dart';
import 'package:ural/repository/database_repo.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/widgets/buttons.dart';
import 'package:ural/widgets/list_screens.dart';

class TaggedScreen extends StatefulWidget {
  final TagModel model;
  TaggedScreen({Key key, this.model}) : super(key: key);

  @override
  _TaggedScreenState createState() => _TaggedScreenState();
}

class _TaggedScreenState extends State<TaggedScreen> {
  TagModel get model => widget.model;
  final _tagBloc = TaggedScreenBloc();

  @override
  void initState() {
    super.initState();
    startup();
  }

  void startup() async {
    final dbRepo = MultiRepositoryProvider.of<DatabaseRepository>(context);
    _tagBloc.initializeDatabase(dbRepo.slDB);
    _tagBloc.initializeModel(model);
    _tagBloc.dispatch(RecentScreenAction.fetch);
  }

  @override
  Widget build(BuildContext context) {
    return Provider<TaggedScreenBloc>(
      create: (_) => _tagBloc,
      child: Scaffold(
          appBar: AppBar(
            title: Text(model.name),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.show_chart),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => PopUpProgress());
                  })
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ScreenView(
                          actionBuilder: (_) {
                            List<Widget> actions = [];
                            actions.add(Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: FlatPurpleButton(
                                  title: "ADD",
                                  onPressed: (_) async {
                                    final docIds = List<int>.from(
                                        Provider.of<ScreenSelectionBloc>(_,
                                                listen: false)
                                            .event
                                            .object
                                            .values
                                            .map<int>((m) => m.docId));
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) => PopUpProgress());
                                    _tagBloc.handleAdd(docIds).then((d) {
                                      Navigator.pop(_);
                                      Navigator.pop(_);
                                    });
                                  },
                                ),
                              ),
                            ));
                            return actions;
                          },
                        ))),
            child: Icon(Feather.plus),
          ),
          body: Provider<TaggedScreenBloc>(
            create: (_) => _tagBloc,
            child: ListScreenshotsWidget<TaggedScreenBloc>(),
          )),
    );
  }
}

class PopUpProgress extends StatefulWidget {
  PopUpProgress({Key key}) : super(key: key);

  @override
  _PopUpProgressState createState() => _PopUpProgressState();
}

class _PopUpProgressState extends State<PopUpProgress> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      height: 30,
      width: 15,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 6,
        ),
      ),
    );
  }
}
