import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:ural/background_tasks.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/file_browser.dart';
import 'package:ural/prefrences.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'package:ural/utils/file_utils.dart';

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
      ScreenBloc.startBackGroundJob();
      print("Background job started");
    } else {
      ScreenBloc.cancelBackGroundJob();
      print("Background job cancelled");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScreenBloc screenBloc = SingleBlocProvider.of<ScreenBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            title: Text(
              "Modify screenshot directories",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "Add or Remove directories",
              style: TextStyle(color: Colors.white),
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
            title: Text(
              "Change theme settings",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "Current theme dark",
              style: TextStyle(color: Colors.white),
            ),
          ),
          Divider(
            color: Colors.grey,
          ),
          SwitchListTile(
              title: Text(
                "Background Sync",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "If disable sync then you will have to manually turn it on.",
                style: TextStyle(color: Colors.white),
              ),
              value: syncStatus,
              onChanged: (val) {
                handleSyncStatus(val);
              }),
          Divider(
            color: Colors.grey,
          ),
          ListTile(
            title: Text(
              "Reset everything",
              style: TextStyle(color: Colors.redAccent),
            ),
            subtitle: Text(
              "Deletes everything and rebuild the database",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => ResetConfirmationDialog(
                        callback: screenBloc.hardReset,
                      ));
            },
          ),
        ],
      ),
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
              widget.callback().then((d) {
                Navigator.pop(context);
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
