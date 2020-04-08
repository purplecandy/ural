class ScreenshotModel {
  final int hash, docId;
  final String imagePath, text;

  ScreenshotModel(this.hash, this.imagePath, this.text, [this.docId]);

  factory ScreenshotModel.fromMap(Map<String, dynamic> map) {
    return ScreenshotModel(
        map["hash"], map["imagePath"], map["text"], map["docid"]);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = new Map<String, dynamic>();
    map["hash"] = hash;
    map["imagePath"] = imagePath;
    map["text"] = text;
    return map;
  }
}
