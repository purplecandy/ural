import 'package:flutter/material.dart';

import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/blocs/screen_bloc.dart';
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
    final _selectionBloc = SingleBlocProvider.of<ScreenSelectionBloc>(context);
    return StreamBuilder<SubState<SelectionStates, Map<int, ScreenshotModel>>>(
        stream: _selectionBloc.state.stream,
        builder: (context, snap) {
          if (snap.hasData) {
            if (snap.data.state != SelectionStates.empty || hideInital) {
              return Container(
                height: 80,
                child: AppBar(
                  leading: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        if (_selectionBloc.state.data.isEmpty)
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
