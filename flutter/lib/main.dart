import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'background_tasks.dart';
import 'app.dart';

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
