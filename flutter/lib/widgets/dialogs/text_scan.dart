import 'package:flutter/material.dart';
import 'package:ural/widgets/buttons.dart';
import 'package:ural/widgets/dialogs/base.dart';

class TextScan extends StatefulWidget {
  TextScan({Key key}) : super(key: key);

  @override
  _TextScanState createState() => _TextScanState();
}

class _TextScanState extends State<TextScan> {
  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: "Scan Image",
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "You will have to pick a screenshot from below to view extracts the text from it..",
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          RoundedPurpleButton(
            title: "Scan",
            onPressed: (_) {},
          )
        ],
      ),
    );
  }
}
