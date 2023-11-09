import 'package:permission_handler/permission_handler.dart';

class PermissionRequest {
  static Future<void> request() async {
    var storage = await Permission.storage.status;
    while (storage.isDenied) {
      await Permission.storage.request();
    }
    var location = await Permission.location.status;
    while (location.isDenied) {
      await Permission.location.request();
    }
  }
}
