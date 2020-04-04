import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

class ImageDialog extends StatefulWidget {
  const ImageDialog({Key key}) : super(key: key);

  @override
  _ImageDialogState createState() => _ImageDialogState();
}

class _ImageDialogState extends State<ImageDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(8),
        // height: MediaQuery.of(context).size.height * 0.22,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).backgroundColor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                "You will have to pick a screenshot from below to save it manually.",
                textAlign: TextAlign.center,
                // style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            FlatButton(
              onPressed: () {},
              child: Text("UPLOAD & SAVE"),
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
