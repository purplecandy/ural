import 'package:permission_handler/permission_handler.dart';
import 'package:ural/utils/async.dart';

Future<AsyncResponse> getPermissionStatus() async {
  PermissionStatus permission =
      await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
  PermissionHandler permissionHandler = PermissionHandler();
  Map<PermissionGroup, PermissionStatus> resp = {};
  if (permission == PermissionStatus.granted) {
    return AsyncResponse(ResponseStatus.success, null);
  } else if (permission == PermissionStatus.denied ||
      permission == PermissionStatus.unknown ||
      permission == PermissionStatus.restricted) {
    resp =
        await permissionHandler.requestPermissions([PermissionGroup.storage]);
  }
  if (resp[PermissionGroup.storage] == PermissionStatus.granted) {
    return AsyncResponse(ResponseStatus.success, null);
  } else if (resp[PermissionGroup.storage] == PermissionStatus.denied) {
    return AsyncResponse(ResponseStatus.failed, null);
  } else {
    return AsyncResponse(ResponseStatus.unkown, null);
  }
}
