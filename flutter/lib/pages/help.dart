import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ural/widgets/all.dart' show HelpFuctionWidget, FaqsWidget;

class HelpPage extends StatelessWidget {
  const HelpPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Help"),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "Guide",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              HelpFuctionWidget(),
              Container(
                padding: EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "How Ural works?",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Card(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: Text(
                          "1",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.red),
                        ),
                        title: Text("Sync/Upload your images"),
                      ),
                      Divider(),
                      ListTile(
                        leading: Text(
                          "2",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.purple),
                        ),
                        title: Text(
                            "Get your screenshot by searching the content of your screenshot"),
                      )
                    ],
                  ),
                ),
              ),
              FlatButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.pinkAccent, width: 1)),
                  textColor: Colors.white,
                  onPressed: () async {
                    const url = "https://youtu.be/a-diWDZX2vM";
                    if (await canLaunch(url)) {
                      launch(url);
                    }
                  },
                  child: Text("Watch Demo on YT")),
              Container(
                padding: EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "FAQs",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              FaqsWidget(),
              FlatButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.pinkAccent, width: 1)),
                  textColor: Colors.white,
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: Text("Close")),
              SizedBox(
                height: 40,
              )
            ],
          ),
        ),
      ),
    );
  }
}
