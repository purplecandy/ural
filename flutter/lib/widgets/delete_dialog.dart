import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:ural/models/screen_model.dart';

typedef Future<bool> FutureVoidCallback();

class DeleteItemDialog extends StatefulWidget {
  final FutureVoidCallback onConfirm;
  final VoidCallback onSuccess;
  final VoidCallback onError;
  final List<ScreenshotModel> screens;
  const DeleteItemDialog(
      {Key key, this.onConfirm, this.onSuccess, this.onError, this.screens})
      : super(key: key);

  @override
  _DeleteItemDialogState createState() => _DeleteItemDialogState();
}

class _DeleteItemDialogState extends State<DeleteItemDialog> {
  bool rmFile = false, deletingFiles = false;

  List<ScreenshotModel> get screens => widget.screens;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).backgroundColor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Deleting ${screens.length} items",
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Feather.x,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text("Delete from device too?"),
                subtitle: Text("This operation cannot be undone"),
                trailing: Checkbox(
                    value: rmFile,
                    onChanged: (val) {
                      setState(() {
                        rmFile = val;
                      });
                    }),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FlatButton(
                onPressed: () async {
                  setState(() {
                    deletingFiles = true;
                  });
                  widget.onConfirm().then((data) {
                    data ? widget.onSuccess() : widget.onError();
                    Navigator.pop(context);
                  });
                },
                child: deletingFiles
                    ? Container(
                        width: 160,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              height: 10,
                              width: 10,
                              child: CircularProgressIndicator(),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text("Deleting")
                          ],
                        ),
                      )
                    : Text("Confirm"),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19)),
                highlightColor: Colors.deepPurpleAccent,
                color: Colors.deepPurple,
              ),
            )
          ],
        ),
      ),
    );
  }
}
