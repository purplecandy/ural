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
      accentColor: Colors.deepPurple,
      primaryColor: LighTheme.backgroundTwo,
      scaffoldBackgroundColor: LighTheme.backgrounZero,
      backgroundColor: LighTheme.backgroundTwo,
      appBarTheme: ThemeData.light().appBarTheme.copyWith(
          textTheme: _textThemeLight(),
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
          textTheme: _textThemeDark(),
          iconTheme: ThemeData.dark().iconTheme,
          actionsIconTheme: ThemeData.dark().accentIconTheme),
      textTheme: _textThemeDark(),
    );
