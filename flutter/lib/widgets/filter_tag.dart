import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ural/blocs/search_bloc.dart';
import 'package:ural/blocs/tags_bloc.dart';
import 'package:ural/models/tags_model.dart';
import 'package:ural/repository/database_repo.dart';
import 'package:ural/utils/bloc.dart';
import 'package:ural/widgets/thin_listtile.dart';

class FilterByTagsWidget<T> extends StatefulWidget {
  final String title;
  final T bloc;
  FilterByTagsWidget({Key key, this.title, @required this.bloc})
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
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 400),
      child: Container(
        padding: EdgeInsets.all(8),
        color: Theme.of(context).backgroundColor,
        child: Column(
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
                      widget.title ?? "FILTER BY TAGS",
                      style: TextStyle(fontSize: 18),
                    ),
                    CupertinoButton(
                      onPressed: () => bloc.dispatch(FilterAction.reset),
                      child: Text(
                        "Reset",
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                        ),
                      ),
                    )
                  ],
                )),
            //lower section
            Expanded(
              child: BlocBuilder<TagState, List<TagModel>>(
                bloc: _tagsBloc,
                onSuccess: (_, event) => event.state == TagState.loading
                    ? Container()
                    : ListView.builder(
                        physics: ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: event.object.length,
                        itemBuilder: (context, index) => ThinListTiles(
                          color: Color(event.object[index].colorCode),
                          callback: (_) {
                            bloc.dispatch(
                                bloc.event.object
                                        .contains(event.object[index].id)
                                    ? FilterAction.del
                                    : FilterAction.add,
                                data: {"id": event.object[index].id});
                          },
                          trailing: SizedBox(
                            height: 10,
                            child: BlocBuilder<FilterState, Set<int>>(
                              bloc: bloc,
                              onSuccess: (c, e) => Checkbox(
                                  activeColor: Theme.of(context).accentColor,
                                  value:
                                      e.object.contains(event.object[index].id),
                                  onChanged: (val) {}),
                            ),
                          ),
                          title: Text(
                            event.object[index].name,
                            textAlign: TextAlign.left,
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
