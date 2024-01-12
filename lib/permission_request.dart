import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PermissionRequest {
  static Future<void> _requestAndroid() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();
    // Check if permissions are granted
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        throw Exception("Please give ${status.name} permissions.");
      }
    });
  }
  static Future<void> _requestIOS() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();
    // Check if permissions are granted
    statuses.forEach((permission, status) {
      print(permission);
      print(status);
      if (!status.isGranted) {
      }
    });
  }

  /// Requests the permissions for storage and location.
  static Future<void> request() async {
    if (Platform.isAndroid) {
      await _requestAndroid();
    } else if (Platform.isIOS) {
      await _requestIOS();
    } else {
      throw Exception("Platform not supported.");
    }
  }
}
