import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';

import 'models/screen_model.dart';
import 'database.dart';

Future<bool> uploadImagesInBackground() async {
  final pref = await SharedPreferences.getInstance();
  if (pref.containsKey("ural_default_folder")) {
    final dir = Directory(pref.getString("ural_default_folder"));
    final textRecognizer = FirebaseVision.instance.textRecognizer();
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
