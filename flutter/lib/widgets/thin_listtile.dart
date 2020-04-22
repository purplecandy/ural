import 'package:flutter/material.dart';

class ThinListTiles extends StatelessWidget {
  final void Function(BuildContext context) callback;
  final Widget leading, title, trailing;
  final Color color;
  const ThinListTiles(
      {Key key,
      this.callback,
      this.leading,
      this.title,
      this.trailing,
      this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).backgroundColor,
      child: InkWell(
        onTap: callback == null ? null : () => callback(context),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: EdgeInsets.only(left: 10),
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // Icon(Feather.search),
                    leading ?? Container(),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: title ?? Container(),
                    ),
                  ],
                ),
                trailing ?? Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
