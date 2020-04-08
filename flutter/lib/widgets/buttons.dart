import 'package:flutter/material.dart';

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
      highlightColor: Colors.deepPurpleAccent,
      color: Colors.deepPurple,
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
      highlightColor: Colors.deepPurpleAccent,
      color: Colors.deepPurple,
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
