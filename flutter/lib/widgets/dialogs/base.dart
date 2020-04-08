import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart' show Feather;

class HorizontalSeprator extends StatelessWidget {
  const HorizontalSeprator({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16),
      height: 0.3,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

typedef void CloseCallback(BuildContext context);

class BaseDialog extends StatelessWidget {
  final String title;
  final CloseCallback onClose;
  final Widget child;
  const BaseDialog(
      {Key key, @required this.title, this.onClose, @required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 16),
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).backgroundColor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                SizedBox(
                  width: 40,
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    onPressed: () {
                      onClose == null
                          ? Navigator.pop(context)
                          : onClose(context);
                    },
                    child: Icon(
                      Feather.x,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            //child widgets
            child
          ],
        ),
      ),
    );
  }
}
