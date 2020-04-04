import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_icons/flutter_icons.dart';

import 'package:ural/controllers/permission_handler.dart';
import 'package:ural/background_tasks.dart';
import 'package:ural/utils/async.dart';
import 'package:ural/prefrences.dart';
import 'package:ural/utils/file_utils.dart';


class InitialSetupDialog extends StatefulWidget {
  const InitialSetupDialog({Key key}) : super(key: key);

  @override
  _InitialSetupDialogState createState() => _InitialSetupDialogState();
}

class _InitialSetupDialogState extends State<InitialSetupDialog> {
  bool processingDirectories = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.22,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).backgroundColor),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Ural needs your permission to access your screenshots.",
                textAlign: TextAlign.center,
                // style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            FlatButton(
              onPressed: () async {
                final resp = await getPermissionStatus();
                if (resp.state == ResponseStatus.success) {
                  final UralPrefrences uralPref = UralPrefrences();
                  setState(() {
                    processingDirectories = true;
                  });
                  Fluttertoast.showToast(
                      msg: "Permission Granted",
                      backgroundColor: Colors.greenAccent,
                      textColor: Colors.white);
                  uralPref.setDirectories(await compute(
                      findDirectories, await FileUtils.getStorageList()));
                  // await uralPref.findAndSaveDirectories();
                  startBackGroundJob();
                  uralPref.setSyncStatus(true);
                  uralPref.setInitialSetupStatus(true);
                  Navigator.pop(context);
                } else {
                  Fluttertoast.showToast(
                      msg: resp.state == ResponseStatus.failed
                          ? "Permission denied"
                          : "Can't request permission.",
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.white);
                }
              },
              child: processingDirectories
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
                          Text("Finding screenshots")
                        ],
                      ),
                    )
                  : Text("Grant Permisson"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19)),
              textColor: Colors.white,
              highlightColor: Colors.deepPurpleAccent,
              color: Colors.deepPurple,
            )
          ],
        ),
      ),
    );
  }
}