import 'package:shared_preferences/shared_preferences.dart';
import 'package:ural/models.dart';
import 'package:ural/urls.dart';
import 'package:ural/utils/async.dart';
import 'package:ural/utils/bloc_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

@override
class Auth extends BlocBase {
  User user;

  static final Auth _instance = Auth._internal();

  factory Auth() {
    return _instance;
  }

  Auth._internal();

  void cacheToken(String token, String username) async {
    final pref = await SharedPreferences.getInstance();
    pref.setString("uralToken", token);
    pref.setString("ural_username", username);
  }

  Future<User> getCachedToken() async {
    final pref = await SharedPreferences.getInstance();
    final token = pref.getString("uralToken");
    if (token == null) return null;
    return User(pref.getString("ural_username"), token);
  }

  Future<AsyncResponse> authenticate() async {
    final resp = await getCachedToken();
    if (resp == null) {
      return AsyncResponse(ResponseStatus.failed, null);
    }
    user = resp;
    return AsyncResponse(ResponseStatus.success, null);
  }

  Future<AsyncResponse<String>> signIn(
      {String username, String password}) async {
    String url = ApiUrls.root + ApiUrls.auth;
    String payload = json.encode({"username": username, "password": password});

    try {
      final resp =
          await http.post(url, body: payload, headers: ApiUrls.headers);
      if (resp.statusCode == 200) {
        final jsonData = json.decode(resp.body);
        user = User(username, jsonData["token"]);
        cacheToken(jsonData["token"], username);
        return AsyncResponse<String>(ResponseStatus.success, jsonData["token"]);
      }
      return AsyncResponse(ResponseStatus.error, "Authentication failed");
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, null);
    }
  }

  Future<AsyncResponse<String>> signup(
      {String username, String password}) async {
    String url = ApiUrls.root + ApiUrls.user;
    String payload = json.encode({"username": username, "password": password});

    try {
      final response =
          await http.post(url, body: payload, headers: ApiUrls.headers);
      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        user = User(username, jsonData["token"]);
        cacheToken(jsonData["token"], username);
        return AsyncResponse(ResponseStatus.success, null);
      }
      return AsyncResponse(ResponseStatus.error,
          "Invalid username, it's probably already taken");
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.failed, null);
    }
  }

  Future<AsyncResponse> logout() async {
    final pref = await SharedPreferences.getInstance();
    try {
      pref.remove("ural_username");
      pref.remove("uralToken");
      return AsyncResponse(ResponseStatus.success, null);
    } catch (e) {
      print(e);
      return AsyncResponse(ResponseStatus.unkown, null);
    }
  }

  @override
  void dispose() {}
}
