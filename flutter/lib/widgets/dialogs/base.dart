import 'package:flutter/material.dart';

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
