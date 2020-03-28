import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ural/pages/setup.dart';

class SettingsModalWidget extends StatelessWidget {
  const SettingsModalWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => Setup()));
                },
                leading: Icon(Icons.build),
                title: Text("Setup Ural"),
                subtitle: Text("Configure Ural settings"),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                  onTap: () async {
                    const url = "mailto:hellomr82k@gmail.com?subject=Feedback";
                    if (await canLaunch(url)) {
                      launch(url);
                    }
                  },
                  leading: Icon(Icons.person),
                  title: Text("Mohammed Nadeem"),
                  subtitle: Text("Author of Ural"),
                  trailing: Icon(
                    Icons.mail,
                    color: Colors.redAccent,
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                onTap: () async {
                  const url =
                      "https://play.google.com/store/apps/details?id=in.kibibyte.ural";
                  if (await canLaunch(url)) {
                    launch(url);
                  }
                },
                leading: Icon(Icons.rate_review),
                title: Text("Rate and Review"),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                onTap: () async {
                  const url =
                      "https://github.com/purplecandy/ural/tree/master/flutter";
                  if (await canLaunch(url)) {
                    launch(url);
                  }
                },
                leading: Icon(Icons.archive),
                title: Text("Github Repository"),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
