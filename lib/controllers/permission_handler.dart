import 'package:permission_handler/permission_handler.dart';

Future<void> getPermissionStatus() async {
  PermissionStatus permission =
      await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
  if (permission == PermissionStatus.granted) {
  } else if (permission == PermissionStatus.denied ||
      permission == PermissionStatus.unknown ||
      permission == PermissionStatus.restricted) {
    await PermissionHandler().requestPermissions([PermissionGroup.storage]);
    getPermissionStatus();
  }
}
