// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
// import 'package:ural/urls.dart';
// import 'package:ural/utils/async.dart';
// import 'dart:async';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';
// import 'image_handler.dart';
// import 'dart:convert';
// import 'package:ural/auth_bloc.dart';

// Future<AsyncResponse> handleUpload(
//     File _image, TextRecognizer recognizer) async {
//   if (_image != null) {
//     img.Image image = img.decodeImage(_image.readAsBytesSync());
//     img.Image thumbnail = img.copyResize(image, width: 120);
//     Directory tempDir = await getTemporaryDirectory();
//     String encoded;
//     var path = _image.path.split("/").last;
//     final filename = path.split(".")[0] + ".jpg";
//     File(tempDir.path + '/' + filename)
//       ..writeAsBytes(img.encodeJpg(thumbnail)).then((file) async {
//         encoded = base64.encode(await file.readAsBytes());
//         // encoded = file.readAsBytesSync().toString();
//       });
//     String url = ApiUrls.root + ApiUrls.images;
//     String text;
//     await recognizeImage(_image, recognizer).then((obj) => text = obj.text);
//     String payload = json.encode({
//       "filename": filename,
//       "thumbnail": encoded,
//       "image_path": _image.path,
//       "text": text,
//       "short_text": "",
//     });
//     try {
//       final response = await http.post(url,
//           body: payload,
//           headers: ApiUrls.authenticatedHeader(Auth().user.token));
//       if (response.statusCode == 201) {
//         print("Image uploaded successfully");
//         return AsyncResponse(ResponseStatus.success, null);
//       } else {
//         print(response.body);
//         return AsyncResponse(ResponseStatus.error,
//             "Invalid response from the server, check logs for more details");
//       }
//     } catch (e) {
//       print(e);
//       return AsyncResponse(ResponseStatus.failed, null);
//     }
//   }
//   return AsyncResponse(
//       ResponseStatus.unkown, "Unkown error. The image is probably null");
// }
