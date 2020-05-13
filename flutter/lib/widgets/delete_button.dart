import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart' show Feather;
import 'package:provider/provider.dart';
import 'package:ural/blocs/search_bloc.dart';
import 'package:ural/blocs/selection_bloc.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/blocs/abstract_screens.dart';
import 'dialogs/alert.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DeleteButtonWidget<T extends AbstractScreenshots> extends StatefulWidget {
  const DeleteButtonWidget({Key key}) : super(key: key);

  static void deleteAction(BuildContext context, List<ScreenshotModel> models,
      {RecentScreenBloc rscreen, SearchScreenBloc search}) async {
    try {
      if (rscreen == null && search == null) {
        rscreen = Provider.of<RecentScreenBloc>(context, listen: false);
        search = Provider.of<SearchScreenBloc>(context, listen: false);
      }
    } catch (e) {
      print(e);
    }

    rscreen?.dispatch(
      RecentScreenAction.delete,
      data: {"selected_models": models},
    );

    search?.dispatch(
      SearchAction.delete,
      data: {"selected_models": models},
    );

    Fluttertoast.showToast(
        msg: "Screenshots deleted successfully",
        backgroundColor: Colors.greenAccent,
        textColor: Colors.white);
  }

  @override
  _DeleteButtonWidgetState<T> createState() => _DeleteButtonWidgetState<T>();
}

class _DeleteButtonWidgetState<T extends AbstractScreenshots>
    extends State<DeleteButtonWidget<T>> {
  void handleConfirm(List<ScreenshotModel> models) =>
      DeleteButtonWidget.deleteAction(context, models);

  @override
  Widget build(BuildContext context) {
    final selectionBloc =
        Provider.of<ScreenSelectionBloc>(context, listen: false);
    return IconButton(
        icon: Icon(Feather.trash),
        color: Theme.of(context).iconTheme.color,
        onPressed: () {
          final selectedModels =
              List<ScreenshotModel>.from(selectionBloc.event.object.values);
          // a lot of callbacks
          // reminds me of shitty javascript
          showDialog(
              context: context,
              builder: (_) => BetterAlertDialog(
                    title: "Delete Selected(${selectedModels.length}) ?",
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Are you sure?"),
                          Text(
                              "Once screenshots are deleted they can't be recovered"),
                        ]),
                    confirmText: "Delete",
                    cancelText: "Cancel",
                    // When the action is terminated
                    onCancel: () => Navigator.pop(context),
                    // When the action is confirmed
                    onConfirm: () {
                      Navigator.pop(context);
                      handleConfirm(selectedModels);
                    },
                  ));
        });
  }
}
