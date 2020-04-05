import 'package:flutter/material.dart';

import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/models/screen_model.dart';

class SelectionAppBar extends StatelessWidget {
  final bool hideInital;
  final List<Widget> actions;
  const SelectionAppBar({Key key, this.hideInital, this.actions})
      : assert(actions != null),
        super(key: key);

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
                        _selectionBloc.dispatch(SelectionAction.reset);
                      }),
                  title: Text("${snap.data.object.length} selected"),
                  actions: actions,
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
