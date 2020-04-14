import 'package:flutter/material.dart';
import 'package:ural/app.dart';

typedef void VoidCallback(BuildContext context);

class RoundedPurpleButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  const RoundedPurpleButton({Key key, this.title, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: () => onPressed(context),
      child: Text(title),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      textColor: Colors.white,
      colorBrightness: Brightness.dark,
      highlightColor: AppTheme.isDark(context)
          ? Colors.deepPurpleAccent.shade400
          : Colors.deepPurpleAccent,
      color: AppTheme.isDark(context)
          ? Colors.deepPurple.shade300
          : Colors.deepPurple,
    );
  }
}

class FlatPurpleButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  const FlatPurpleButton({Key key, this.title, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: () => onPressed(context),
      child: Text(title),
      textColor: Colors.white,
      highlightColor: AppTheme.isDark(context)
          ? Colors.deepPurpleAccent.shade400
          : Colors.deepPurpleAccent,
      color: AppTheme.isDark(context)
          ? Colors.deepPurple.shade300
          : Colors.deepPurple,
    );
  }
}

class RoundedSplashButton extends StatelessWidget {
  final Widget dialog;
  final IconData icon;
  const RoundedSplashButton({Key key, this.dialog, this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: RawMaterialButton(
        shape: CircleBorder(),
        onPressed: () {
          showDialog(context: context, builder: (context) => dialog);
        },
        child: Icon(
          icon,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
