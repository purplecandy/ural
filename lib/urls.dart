class ApiUrls {
  static String root = "http://192.168.0.107:8000/";
  // static String root = "http://192.168.43.90:8000/";
  static String auth = "auth/";
  static String user = "user/";
  static String search = "search/";
  static String images = "images/";

  static Map<String, String> headers = {"Content-Type": "application/json"};
  static Map<String, String> authenticatedHeader(String token) =>
      {"Authorization": "Token $token", "Content-type": "application/json"};
}
