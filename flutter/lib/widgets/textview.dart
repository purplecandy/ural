import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class TextView extends StatelessWidget {
  final String text;
  const TextView({Key key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                  icon: Icon(Feather.share_2),
                  onPressed: () async {
                    Share.text("Ural text share", text, 'text/plain');
                  }),
              IconButton(
                  icon: Icon(Feather.copy),
                  onPressed: () async {
                    await ClipboardManager.copyToClipBoard(text);
                    Fluttertoast.showToast(msg: "Text copied");
                  }),
              IconButton(
                  icon: Icon(Icons.g_translate),
                  onPressed: () async {
                    String url = Uri.encodeFull(
                        "https://translate.google.co.in/?hl=en&tab=TT#view=home&op=translate&sl=auto&tl=en&text=$text");
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  })
            ],
          )
        ],
      ),
    );
  }
}
