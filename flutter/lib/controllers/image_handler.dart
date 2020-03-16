import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ural/utils/async.dart';
import 'package:ural/urls.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

Future<dynamic> recognizeImage(File image, TextRecognizer recognizer,
    {bool getBlocks = false}) async {
  //parsed image
  final visionImage = FirebaseVisionImage.fromFile(image);
  //processing parsed image
  final visionText = await recognizer.processImage(visionImage);
  if (getBlocks) return visionText.blocks;
  //reutrn text
  return visionText;
}

/// Uploads the image to the server
Future<AsyncResponse> syncImageToServer(
    File _image, TextRecognizer recognizer, String token) async {
  if (_image != null) {
    //Decoding image to create a small thumbnail
    img.Image image = img.decodeImage(_image.readAsBytesSync());
    img.Image thumbnail = img.copyResize(image, width: 120);

    //Storing thumb in temp directory
    Directory tempDir = await getTemporaryDirectory();

    //Encoded string
    String encoded;

    //Wiritting the file in temp directory and encode it's bytes with base64
    var path = _image.path.split("/").last;
    final filename = path.split(".")[0] + ".jpg";
    File(tempDir.path + '/' + filename)
      ..writeAsBytes(img.encodeJpg(thumbnail)).then((file) async {
        encoded = base64.encode(await file.readAsBytes());
      });

    //Target url
    String url = ApiUrls.root + ApiUrls.images;

    //Vision text
    String text;
    //Perform text recognition
    await recognizeImage(_image, recognizer).then((obj) => text = obj.text);

    //Create payload
    String payload = json.encode({
      "filename": filename,
      "thumbnail": encoded,
      "image_path": _image.path,
      "text": text,
      "short_text": "",
      "hash_code": _image.path.hashCode.toString()
    });
    try {
      final response = await http.post(url,
          body: payload, headers: ApiUrls.authenticatedHeader(token));
      if (response.statusCode == 201) {
        print("Image uploaded successfully");
        //success
        return AsyncResponse(ResponseStatus.success, null);
      } else {
        print(response.body);
        return AsyncResponse(ResponseStatus.error, null);
      }
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, null);
    }
  }
  return AsyncResponse(ResponseStatus.unkown, null);
}
