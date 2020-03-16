import 'package:ural/urls.dart';

class ScreenModel {
  final int id;
  final String path, thumb, text;
  ScreenModel({this.id, this.path, this.thumb, this.text});

  factory ScreenModel.fromJson(Map<String, dynamic> jsonData) {
    return ScreenModel(
      id: jsonData["id"],
      path: jsonData["image_path"],
      thumb: ApiUrls.root + jsonData["thumbnail"],
      text: jsonData["thumbnail"] ?? null,
    );
  }
}
