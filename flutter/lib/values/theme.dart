// import 'package:flutter/material.dart' show Color, ThemeData, Colors, AppBarTheme;
import 'package:flutter/material.dart';

class DarkTheme {
  static Color backgrounZero = Color(0xFF050505);
  static Color backgroundOne = Color(0xFF17181a);
  static Color backgroundTwo = Color(0xFF242528);
}

class LighTheme {
  static Color backgrounZero = Color(0xFFeff0f5);
  static Color backgroundOne = Color(0xFF9194a1);
  static Color backgroundTwo = Color(0xFFffffff);
}

_textThemeLight() => ThemeData.light().textTheme.apply(fontFamily: "Inter");
_textThemeDark() => ThemeData.dark().textTheme.apply(fontFamily: "Inter");

ThemeData lightThemeData() => ThemeData.light().copyWith(
      accentColor: LighTheme.backgroundOne,
      primaryColor: LighTheme.backgroundTwo,
      scaffoldBackgroundColor: LighTheme.backgrounZero,
      backgroundColor: LighTheme.backgrounZero,
      appBarTheme: ThemeData.light().appBarTheme.copyWith(
          color: LighTheme.backgroundTwo,
          textTheme: TextTheme(
              title: TextStyle(
                  color: Colors.black,
                  fontSize: 21,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w700)),
          iconTheme: ThemeData.light().iconTheme,
          actionsIconTheme: ThemeData.light().accentIconTheme),
      textTheme: _textThemeLight(),
    );

ThemeData darkThemeData() => ThemeData.dark().copyWith(
      primaryColorDark: DarkTheme.backgroundOne,
      splashColor: DarkTheme.backgroundOne,
      accentColor: Color(0xFFe91e63),
      scaffoldBackgroundColor: DarkTheme.backgrounZero,
      canvasColor: DarkTheme.backgroundOne,
      backgroundColor: DarkTheme.backgroundOne,
      appBarTheme: ThemeData.dark().appBarTheme.copyWith(
          color: DarkTheme.backgroundOne,
          textTheme: TextTheme(
              title: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w700)),
          iconTheme: ThemeData.dark().iconTheme,
          actionsIconTheme: ThemeData.dark().accentIconTheme),
      textTheme: _textThemeDark(),
    );
