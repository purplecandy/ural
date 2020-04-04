import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image/image.dart' as img;
import 'package:workmanager/workmanager.dart';
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
  if (pref.containsKey("ural_settings_directories")) {
    // set default directory
    final List<String> dirs =
        pref.getString("ural_settings_directories").split(":");

    for (var path in dirs) {
      final dir = Directory(path);
      // initialize a textrecognizer
      final textRecognizer = FirebaseVision.instance.textRecognizer();
      // initialize our database
      final ScreenshotListDatabase _slDB = ScreenshotListDatabase();
      await _slDB.initDB();
      try {
        List<FileSystemEntity> fileEntities = dir.listSync(recursive: true)
          ..sort((f1, f2) => FileSystemEntity.isFileSync(f1.path) &&
                  FileSystemEntity.isFileSync(f2.path)
              ? File(f1.path)
                  .lastModifiedSync()
                  .compareTo(File(f2.path).lastModifiedSync())
              : 1);

        for (FileSystemEntity entity in fileEntities) {
          if (entity is File) {
            //identify if the file is an image format
            String ext = entity.path
                .substring(entity.path.length - 3, entity.path.length);
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
              //asynchronosly generate the thumbnail
              generateThumb(entity.path);
            }
          }
        }
      } catch (e) {
        print("Exception from background task: $e");
        return false;
      }
    }
    print("Success uploaded");
    return true;
  }

  return false;
}

/// Generate thumbnail from image source
Future<void> generateThumb(String path) async {
  Directory docs = await getApplicationDocumentsDirectory();
  Directory temp = Directory(docs.path + '/thumbs');
  if (!temp.existsSync()) temp.createSync();
  File _thumb = File(temp.path + '/${path.hashCode}.png');
  //generate and load the cache file
  img.Image original = img.decodeImage(File(path).readAsBytesSync());
  img.Image thumb = img.copyResize(original, width: 270);
  _thumb.writeAsBytesSync(img.encodePng(thumb));
}

/// A one-of background task initializer it's executed almost instantly
void restartBackgroundJob() async {
  await cancelBackGroundJob();
  startBackGroundJob();
}

/// The standard background job, only runs at specified frequiencies
void startBackGroundJob() async {
  await Workmanager.registerPeriodicTask("uralfetchscreens", "ural_background",
      frequency: Duration(hours: 2), initialDelay: Duration(seconds: 1));
}

/// Removed the background job from the work-manager
Future<void> cancelBackGroundJob() async {
  await Workmanager.cancelByUniqueName("uralfetchscreens");
}
