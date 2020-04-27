import 'package:ural/utils/bloc.dart';
import 'package:ural/models/screen_model.dart';
import 'package:ural/utils/file_utils.dart';

enum SelectionStates { contains, empty, modified }
enum SelectionAction {
  ///Requires: `ScreenshotModel:model`
  add,

  ///Requires: `int:hash`
  remove,
  reset
}

class ScreenSelectionBloc extends BlocBase<SelectionStates, SelectionAction,
    Map<int, ScreenshotModel>> {
  ScreenSelectionBloc() : super(state: SelectionStates.empty, object: {});

  @override
  void dispatch(SelectionAction actionState,
      {Map<String, dynamic> data, VoidOnComplete onComplete}) async {
    switch (actionState) {
      case SelectionAction.add:
        _addItem(data["model"]);
        break;
      case SelectionAction.remove:
        _removeItem(data["hash"]);
        break;
      case SelectionAction.reset:
        _reset();
        break;
      default:
    }
    if (onComplete != null) onComplete();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _addItem(ScreenshotModel model) {
    event.object[model.hash] = model;
    updateState(SelectionStates.contains, event.object);
  }

  void _removeItem(int hash) {
    if (event.object.containsKey(hash)) {
      event.object.remove(hash);
      updateState(
          event.object.isEmpty
              ? SelectionStates.empty
              : SelectionStates.modified,
          event.object);
    }
  }

  void _reset() {
    updateState(SelectionStates.empty, {});
  }
}
