import 'package:flutter/material.dart';
import 'package:ural/prefrences.dart';
import 'package:workmanager/workmanager.dart';
import 'background_tasks.dart';

import 'package:ural/pages/home.dart';

void callbackDispatcher() {
  print("CallBackDispacther RUNNING");
  Workmanager.executeTask((task, input) async {
    return await uploadImagesInBackground();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager.initialize(callbackDispatcher, isInDebugMode: true);

  runApp(App());
}

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    // loadUralPrefrences();
  }

  // void loadUralPrefrences() async {
  //   await UralPrefrences().getInstance();
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF424242),
        primaryColorLight: Color(0xFF6d6d6d),
        primaryColorDark: Color(0xFF1b1b1b),
        accentColor: Color(0xFFe91e63),
        // scaffoldBackgroundColor: Color(0xFF6d6d6d),
        scaffoldBackgroundColor: Color(0xFF1b1b1b),
        canvasColor: Color(0xFF1b1b1b),
        backgroundColor: Color(0xFF1b1b1b),
      ),
      routes: {"/": (context) => HomePage()},
    );
  }
}
