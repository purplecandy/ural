class TagModel {
  final String name;
  int id, colorCode;
  TagModel(this.id, String name, this.colorCode)
      : this.name = name.trim(),
        assert(name.length <= 25);

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map["name"] = name;
    map["color"] = colorCode;
    return map;
  }

  factory TagModel.fromMap(Map<String, dynamic> map) =>
      TagModel(map["id"], map["name"], map["color"]);
}
