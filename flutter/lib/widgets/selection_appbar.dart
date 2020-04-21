import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ural/utils/bloc.dart';

import 'package:ural/blocs/selection_bloc.dart';
import 'package:ural/models/screen_model.dart';

typedef List<Widget> ActionBuilder(BuildContext context);

class SelectionAppBar extends StatelessWidget {
  /// true - to keep the AppBar hidden initially
  final bool hideInital;
  final List<Widget> actions;
  final ActionBuilder actionBuilder;
  const SelectionAppBar(
      {Key key, this.hideInital, this.actions, this.actionBuilder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _selectionBloc =
        Provider.of<ScreenSelectionBloc>(context, listen: false);
    return StreamBuilder<Event<SelectionStates, Map<int, ScreenshotModel>>>(
        stream: _selectionBloc.stream,
        builder: (context, snap) {
          if (snap.hasData) {
            if (snap.data.state != SelectionStates.empty || hideInital) {
              return Container(
                height: 80,
                child: AppBar(
                  backgroundColor: Theme.of(context).backgroundColor,
                  textTheme: Theme.of(context).textTheme,
                  iconTheme: Theme.of(context).iconTheme,
                  actionsIconTheme: Theme.of(context).iconTheme,
                  leading: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        if (_selectionBloc.event.object.isEmpty)
                          Navigator.pop(context);
                        _selectionBloc.dispatch(SelectionAction.reset);
                      }),
                  title: Text("${snap.data.object.length} selected"),
                  actions: actionBuilder == null ? [] : actionBuilder(context),
                ),
              );
            }
          }
          return SizedBox(
            height: 0,
            width: 0,
          );
        });
  }
}
