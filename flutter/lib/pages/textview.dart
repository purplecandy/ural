import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart' show TextBlock;
import 'package:url_launcher/url_launcher.dart';

class TextView extends StatelessWidget {
  final List<TextBlock> textBlocks;
  const TextView({Key key, this.textBlocks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Text View"),
      ),
      body: ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemCount: textBlocks.length,
          itemBuilder: (context, index) => Card(
                child: Container(
                  padding: EdgeInsets.all(14),
                  child: Stack(children: [
                    Text(textBlocks[index].text),
                    Align(
                      alignment: Alignment.topRight,
                      child: Column(
                        children: <Widget>[
                          IconButton(
                              icon: Icon(Icons.content_copy),
                              onPressed: () async {
                                ClipboardManager.copyToClipBoard(
                                        textBlocks[index].text)
                                    .then((result) {
                                  final snackBar = SnackBar(
                                    content: Text('Copied to Clipboard'),
                                  );
                                  Scaffold.of(context).showSnackBar(snackBar);
                                });
                              }),
                          IconButton(
                              icon: Icon(Icons.g_translate),
                              onPressed: () async {
                                String url = Uri.encodeFull(
                                    "https://translate.google.co.in/?hl=en&tab=TT#view=home&op=translate&sl=auto&tl=en&text=${textBlocks[index].text}");
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  final snackBar = SnackBar(
                                    content:
                                        Text('Failed while launching browser'),
                                  );
                                  Scaffold.of(context).showSnackBar(snackBar);
                                }
                              }),
                        ],
                      ),
                    )
                  ]),
                ),
              )),
    );
  }
}
