// import 'package:ural/urls.dart';

// class ScreenModel {
//   final int id;
//   final String path, thumb, text;
//   ScreenModel({this.id, this.path, this.thumb, this.text});

//   factory ScreenModel.fromJson(Map<String, dynamic> jsonData) {
//     return ScreenModel(
//       id: jsonData["id"],
//       path: jsonData["image_path"],
//       thumb: ApiUrls.root + jsonData["thumbnail"],
//       text: jsonData["thumbnail"] ?? null,
//     );
//   }
// }

class ScreenshotModel {
  final int hash;
  final String imagePath, text;

  ScreenshotModel(this.hash, this.imagePath, this.text);

  factory ScreenshotModel.fromMap(Map<String, dynamic> map) {
    return ScreenshotModel(map["hash"], map["imagePath"], map["text"]);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = new Map<String, dynamic>();
    map["hash"] = hash;
    map["imagePath"] = imagePath;
    map["text"] = text;
    return map;
  }
}
