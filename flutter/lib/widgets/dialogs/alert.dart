import 'package:flutter/material.dart';
import 'package:ural/values/theme.dart';
import 'package:ural/app.dart';

class BetterAlertDialog extends StatelessWidget {
  final Widget child;
  final String title, confirmText, cancelText;
  final void Function() onConfirm;
  final void Function() onCancel;
  const BetterAlertDialog(
      {Key key,
      this.child,
      this.onConfirm,
      this.onCancel,
      this.title,
      this.confirmText,
      this.cancelText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.isDark(context)
          ? DarkTheme.backgroundOne
          : LighTheme.backgroundTwo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(title),
      content: child,
      actions: <Widget>[
        FlatButton(onPressed: onCancel, child: Text(cancelText)),
        FlatButton(onPressed: onConfirm, child: Text(confirmText))
      ],
    );
  }
}
