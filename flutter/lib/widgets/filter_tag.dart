import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';
import 'package:ural/blocs/search_bloc.dart';
import 'package:ural/blocs/tags_bloc.dart';
import 'package:ural/models/tags_model.dart';
import 'package:ural/repository/database_repo.dart';
import 'package:ural/utils/bloc.dart';

class FilterByTagsWidget<T> extends StatefulWidget {
  final void Function() onApply;
  final String title;
  final T bloc;
  FilterByTagsWidget(
      {Key key, this.title, @required this.bloc, @required this.onApply})
      : super(key: key);

  @override
  _FilterTagsWidgetState createState() => _FilterTagsWidgetState();
}

class _FilterTagsWidgetState extends State<FilterByTagsWidget> {
  get bloc => widget.bloc;
  final _tagsBloc = TagsBloc();
  Set<int> filter = Set();

  @override
  void didChangeDependencies() {
    final repo = Provider.of<DatabaseRepository>(context, listen: true);
    if (repo.slDB.db != null) {
      _tagsBloc.initializeDatabase(repo.slDB);
      _tagsBloc.dispatch(TagAction.fetch);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // constraints: BoxConstraints(maxHeight: 400),
      padding: EdgeInsets.only(top: 20),
      color: Theme.of(context).backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //upper section
          Padding(
              padding:
                  const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    widget.title ?? "Filter by tags",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    onPressed: widget.onApply,
                    child: Text(
                      "Apply",
                      style: TextStyle(
                        color: Colors.pinkAccent,
                      ),
                    ),
                  )
                ],
              )),
          //
          Divider(height: 1),
          ListTile(
            leading: Icon(Feather.x),
            title: Text("Remove filters"),
            onTap: () => bloc.dispatch(FilterAction.reset),
          ),
          Divider(height: 1),
          //
          //lower section
          Expanded(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: BlocBuilder<TagState, List<TagModel>>(
                bloc: _tagsBloc,
                onSuccess: (_, event) => BlocBuilder<FilterState, Set<int>>(
                  bloc: bloc,
                  onSuccess: (_, e) => Wrap(
                    children: event.object
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: FilterChip(
                                label: Text(t.name),
                                selected: e.object.contains(t.id),
                                onSelected: (val) {
                                  bloc.dispatch(
                                      !val
                                          ? FilterAction.del
                                          : FilterAction.add,
                                      data: {"id": t.id});
                                },
                                backgroundColor: Color(t.colorCode),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
