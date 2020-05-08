import 'package:flutter/material.dart';

class PopUpProgress extends StatelessWidget {
  const PopUpProgress({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      height: 30,
      width: 15,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 6,
        ),
      ),
    );
  }
}

void showPopUpProgress(BuildContext context,
    {Future<void> Function() future, void Function() onDone}) async {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => PopUpProgress());
  await future();
  Navigator.pop(context);
  onDone();
}
