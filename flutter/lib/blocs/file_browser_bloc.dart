import 'dart:io';

import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/utils/file_utils.dart';
import 'package:rxdart/rxdart.dart';

enum BrowserState { intial, update, done, loading }

class FileBrowserBloc extends BlocBase {
  String currentPath = "";
  List<String> pathHistory = [];

  List<FileSystemEntity> currentDirectory = [];

  BehaviorSubject<BrowserState> _browserSubject =
      BehaviorSubject.seeded(BrowserState.loading);

  ValueStream<BrowserState> get streamOfPaths => _browserSubject.stream;

  void getInitialPath() async {
    currentDirectory = await FileUtils.getStorageList();
    _browserSubject.add(BrowserState.intial);
    if (pathHistory.length > 0) pathHistory = [];
  }

  void changePath(int index) async {
    if (currentDirectory[index] is Directory) {
      currentPath = currentDirectory[index].path;
      currentDirectory = await FileUtils.getFilesInPath(currentPath);
      currentDirectory = FileUtils.sortList(currentDirectory, 0);
      _browserSubject.add(BrowserState.update);
      pathHistory.add(currentPath);
    } else {
      print(FileUtils.getMime(currentDirectory[index].path));
    }
  }

  void jumpToPreviousPath(int index) async {
    if (pathHistory.length != index) {
      currentPath = pathHistory.elementAt(index);
      currentDirectory = await FileUtils.getFilesInPath(currentPath);
      currentDirectory = FileUtils.sortList(currentDirectory, 0);
      pathHistory.removeRange(index + 1, pathHistory.length);
      _browserSubject.add(BrowserState.update);
    }
  }

  void goToPreviousPath() async {
    if (pathHistory.length == 1) {
      pathHistory.removeLast();
      currentDirectory = await FileUtils.getStorageList();
      _browserSubject.add(BrowserState.intial);
    } else {
      if (pathHistory.length > 1) {
        pathHistory.removeLast();
        currentPath = pathHistory.last;
        currentDirectory = await FileUtils.getFilesInPath(currentPath);
        _browserSubject.add(BrowserState.update);
      }
    }
  }

  void dispose() {
    _browserSubject.close();
  }
}
