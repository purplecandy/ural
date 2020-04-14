import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:ural/app.dart';
import 'package:ural/background_tasks.dart';
// import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/file_browser.dart';
import 'package:ural/prefrences.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/utils/file_utils.dart';
import 'package:ural/repository/database_repo.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UralPrefrences uralPref = UralPrefrences();
  bool syncStatus;

  @override
  void initState() {
    super.initState();
    syncStatus = uralPref.getSyncStatus();
  }

  void handleSyncStatus(bool val) {
    setState(() {
      syncStatus = val;
    });
    uralPref.setSyncStatus(syncStatus);
    if (syncStatus) {
      startBackGroundJob();
      print("Background job started");
    } else {
      cancelBackGroundJob();
      print("Background job cancelled");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            title: Text(
              "Modify screenshot directories",
            ),
            subtitle: Text(
              "Add or Remove directories",
            ),
            onTap: () {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => ListDirectoryDialog());
            },
          ),
          Divider(
            color: Colors.grey,
          ),
          ListTile(
            onTap: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => SwitchThemeDialog()),
            title: Text(
              "Change theme settings",
            ),
            subtitle: Text(
              "Current theme dark",
            ),
          ),
          Divider(
            color: Colors.grey,
          ),
          SwitchListTile(
              title: Text(
                "Background Sync",
              ),
              subtitle: Text(
                "If disable sync then you will have to manually turn it on.",
              ),
              value: syncStatus,
              onChanged: (val) {
                handleSyncStatus(val);
              }),
          Divider(
            color: Colors.grey,
          ),
          // ListTile(
          //   title: Text(
          //     "Reset everything",
          //     style: TextStyle(color: Colors.redAccent),
          //   ),
          //   subtitle: Text(
          //     "Deletes everything and rebuild the database",
          //     style: TextStyle(color: Colors.redAccent),
          //   ),
          //   onTap: () {
          //     showDialog(
          //         context: context,
          //         barrierDismissible: false,
          //         builder: (context) => ResetConfirmationDialog(
          //               callback: () {},
          //             ));
          //   },
          // ),
        ],
      ),
    );
  }
}

class SwitchThemeDialog extends StatefulWidget {
  const SwitchThemeDialog({Key key}) : super(key: key);

  @override
  _SwitchThemeDialogState createState() => _SwitchThemeDialogState();
}

class _SwitchThemeDialogState extends State<SwitchThemeDialog> {
  ThemeMode _mode;

  @override
  void initState() {
    super.initState();
    setMode();
  }

  void setMode() {
    _mode = AppTheme.mode(context);
  }

  void handleRadioChange(ThemeMode tmode) {
    setState(() {
      _mode = tmode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text("App Theme"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RadioListTile(
            value: ThemeMode.light,
            groupValue: _mode,
            onChanged: handleRadioChange,
            title: Text("Light"),
          ),
          RadioListTile(
            value: ThemeMode.dark,
            groupValue: _mode,
            onChanged: handleRadioChange,
            title: Text("Dark"),
          )
        ],
      ),
      actions: <Widget>[
        FlatButton(
            onPressed: () => Navigator.pop(context), child: Text("Cancel")),
        FlatButton(
            onPressed: () {
              if (_mode != AppTheme.mode(context))
                AppTheme.toggleTheme(context);
              Navigator.pop(context);
            },
            child: Text("Apply"))
      ],
    );
  }
}

typedef Future<void> FutureVoidCallback();

class ResetConfirmationDialog extends StatefulWidget {
  final FutureVoidCallback callback;
  ResetConfirmationDialog({Key key, this.callback}) : super(key: key);

  @override
  _ResetConfirmationDialogState createState() =>
      _ResetConfirmationDialogState();
}

class _ResetConfirmationDialogState extends State<ResetConfirmationDialog> {
  final UralPrefrences uralPref = UralPrefrences();
  Future<void> handleReset() async {
    //reset database
    await MultiRepositoryProvider.of<DatabaseRepository>(context).hardReset();
    print('DATABASE DELETED');
    //reset preferences
    uralPref.removeKey(uralPref.directoryKey);
    print('SCREENSHOTS DIRECTORIES REMOVED');
    uralPref.removeKey(uralPref.recentSearchesKey);
    print('RECENT SEARCHES REMOVED');

    //delete thumbnails
    if (UralPrefrences.thumbsDir.existsSync())
      UralPrefrences.thumbsDir.deleteSync(recursive: true);
    print('THUMBNAILS DELETED');
    //reset completed

    //Now re-adding all configurations
    //finding directories
    uralPref.setDirectories(
        await compute(findDirectories, await FileUtils.getStorageList()));
    print('RE-ADDING DIRECTORIES');
  }

  bool actionClicked = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Are you sure you want to reset?"),
      content: Text("This action can't be reverted"),
      actions: <Widget>[
        FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancle")),
        FlatButton(
          onPressed: () async {
            if (!actionClicked) {
              setState(() {
                actionClicked = true;
              });
            }
          },
          child: actionClicked
              ? SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(),
                )
              : Text("Delete"),
          color: Colors.redAccent,
        ),
      ],
    );
  }
}

class ListDirectoryDialog extends StatefulWidget {
  ListDirectoryDialog({Key key}) : super(key: key);

  @override
  _ListDirectoryDialogState createState() => _ListDirectoryDialogState();
}

class _ListDirectoryDialogState extends State<ListDirectoryDialog> {
  UralPrefrences uralPref = UralPrefrences();
  List<String> directories = [];

  @override
  void initState() {
    super.initState();
    directories = uralPref.getDirectories();
  }

  void handleSaveDirectory(String path) {
    directories.add(path);
    uralPref.setDirectories(directories);
    setState(() {
      directories = directories;
    });
    print(uralPref.getDirectories());
  }

  void handleRemoveDirectory(int index) {
    uralPref.removeDirectory(directories[index]);
    directories.removeAt(index);
    setState(() {
      directories = directories;
    });
    print(uralPref.getDirectories());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text("Directories"),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        width: MediaQuery.of(context).size.width * 0.9,
        child: directories.isEmpty
            ? Text("You don't have any directories saved")
            : ListView.builder(
                shrinkWrap: true,
                itemCount: directories.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(FileUtils.getEntityName(directories[index])),
                  trailing: IconButton(
                      icon: Icon(
                        Feather.trash,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        handleRemoveDirectory(index);
                      }),
                ),
              ),
      ),
      actions: <Widget>[
        FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Close")),
        FlatButton(
            onPressed: () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FileBrowser(
                            title: "Pick a folder",
                            action: handleSaveDirectory,
                          )));
            },
            child: Text("Add"))
      ],
    );
  }
}
