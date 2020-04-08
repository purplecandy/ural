import 'package:flutter/material.dart';
import 'package:ural/widgets/buttons.dart';
import 'package:ural/widgets/dialogs/base.dart';

class ImageDialog extends StatefulWidget {
  const ImageDialog({Key key}) : super(key: key);

  @override
  _ImageDialogState createState() => _ImageDialogState();
}

class _ImageDialogState extends State<ImageDialog> {
  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: "Image Upload",
      child: Column(
        children: <Widget>[
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
          RoundedPurpleButton(
            title: "Upload",
            onPressed: (_) {},
          )
        ],
      ),
    );
  }
}
