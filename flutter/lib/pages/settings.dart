import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:ural/blocs/screen_bloc.dart';
import 'package:ural/utils/bloc_provider.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
              value: true,
              onChanged: (b) {}),
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
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Directories"),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.3,
        width: MediaQuery.of(context).size.width * 0.9,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: 10,
          itemBuilder: (context, index) => ListTile(
            title: Text("$index"),
            trailing: IconButton(
                icon: Icon(
                  Feather.trash,
                  color: Colors.redAccent,
                ),
                onPressed: () {}),
          ),
        ),
      ),
      actions: <Widget>[
        FlatButton(onPressed: () {}, child: Text("Close")),
        FlatButton(onPressed: () {}, child: Text("Add"))
      ],
    );
  }
}
