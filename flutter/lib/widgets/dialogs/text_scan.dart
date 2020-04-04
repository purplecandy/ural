import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

class TextScan extends StatefulWidget {
  TextScan({Key key}) : super(key: key);

  @override
  _TextScanState createState() => _TextScanState();
}

class _TextScanState extends State<TextScan> {
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
                "You will have to pick a screenshot from below to view extracts the text from it..",
                textAlign: TextAlign.center,
                // style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            FlatButton(
              onPressed: () {},
              child: Text("UPLOAD & SCAN"),
              shape: RoundedRectangleBorder(),
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
