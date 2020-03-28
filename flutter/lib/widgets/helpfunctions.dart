import 'package:flutter/material.dart';

class HelpFuctionWidget extends StatelessWidget {
  const HelpFuctionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(Icons.file_upload),
                title: Text("Manual Upload"),
                subtitle:
                    Text("Want to just save a screenshot? Do a manual upload"),
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(Icons.text_fields),
                title: Text("Text View"),
                subtitle: Text(
                    "Use this when you just want to extract texts from an image"),
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text(
                  "Settings",
                ),
                subtitle: Text(
                    "Here you can modfiy your setting and reconfigure Ural"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
