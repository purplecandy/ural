import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart' show Feather;
import 'package:provider/provider.dart';
import 'package:ural/blocs/selection_bloc.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/models/screen_model.dart';
import 'dialogs/alert.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DeleteButtonWidget<T extends AbstractScreenshots>
    extends StatelessWidget {
  const DeleteButtonWidget({Key key}) : super(key: key);

  void onConfirm(BuildContext context, T rscreenBloc,
      ScreenSelectionBloc selectionBloc, List<ScreenshotModel> selectedModels) {
    rscreenBloc.dispatch(RecentScreenAction.delete,
        data: {"selected_models": selectedModels}, onComplete: () {
      selectionBloc.dispatch(SelectionAction.reset);
      rscreenBloc.dispatch(RecentScreenAction.fetch);
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: "Screenshots deleted successfully",
          backgroundColor: Colors.greenAccent,
          textColor: Colors.white);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rscreenBloc = Provider.of<T>(context, listen: false);
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
              builder: (context) => BetterAlertDialog(
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
                      onConfirm(
                          context, rscreenBloc, selectionBloc, selectedModels);
                    },
                  ));
        });
  }
}
