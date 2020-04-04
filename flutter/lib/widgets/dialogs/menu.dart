import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

import 'base.dart';
import 'package:ural/pages/settings.dart';
import 'package:ural/pages/help.dart';

class MenuDialog extends StatefulWidget {
  MenuDialog({Key key}) : super(key: key);

  @override
  _MenuDialogState createState() => _MenuDialogState();
}

class _MenuDialogState extends State<MenuDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10,
      // color: Colors.transparent,
      // textStyle: TextStyle(color: Colors.white),
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.3,
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
            // HorizontalSeprator(),
            MenuTile(Feather.settings, "Settings", () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsPage()));
            }),
            HorizontalSeprator(),
            MenuTile(Feather.help_circle, "Help", () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => HelpPage()));
            }),
            HorizontalSeprator(),
            MenuTile(Feather.mail, "Feedback", () {}),
            HorizontalSeprator(),
            MenuTile(Feather.info, "More Information", () {}),
            // HorizontalSeprator()
          ],
        ),
      ),
    );
  }
}

class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback callback;
  MenuTile(this.icon, this.title, this.callback);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: callback,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16),
          child: Container(
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  title,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w300),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
