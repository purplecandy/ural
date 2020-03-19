import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';

import 'models/screen_model.dart';
import 'database.dart';

Future<bool> uploadImagesInBackground() async {
  /// We need to first check if the user has specified any default-folder
  /// If there is any default folder
  /// We will simple abondon everything and return false
  /// which just tells the WorkManager plugin that the task failed
  /// It's handy in debugging to understand wheather your tasks are running properly
  final pref = await SharedPreferences.getInstance();
  if (pref.containsKey("ural_default_folder")) {
    // set default directory
    final dir = Directory(pref.getString("ural_default_folder"));
    // initialize a textrecognizer
    final textRecognizer = FirebaseVision.instance.textRecognizer();
    // initialize our database
    final ScreenshotListDatabase _slDB = ScreenshotListDatabase();
    await _slDB.initDB();
    try {
      List<FileSystemEntity> fileEntities = dir.listSync(recursive: true);
      for (FileSystemEntity entity in fileEntities) {
        if (entity is File) {
          //identify if the file is an image format
          String ext =
              entity.path.substring(entity.path.length - 3, entity.path.length);
          if (["jpg", "png"].contains(ext)) {
            /// Check if the image already exist
            final bool exist = await _slDB.exist(entity.path.hashCode);

            /// Skip if true
            if (exist) continue;
            final visionImage = FirebaseVisionImage.fromFile(entity);
            String text = "";
            await textRecognizer.processImage(visionImage).then((vt) {
              text = vt.text;
            });
            ScreenshotModel model =
                ScreenshotModel(entity.path.hashCode, entity.path, text);
            _slDB.insert(model);
            print("Success uploaded");
          }
        }
      }
      return true;
    } catch (e) {
      print("Exception from background task: $e");
      return false;
    }
  }
  return false;
}
