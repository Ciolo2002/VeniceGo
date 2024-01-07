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

  /// Requests the permissions for storage and location.
  static Future<void> request() async {
    if (Platform.isAndroid) {
      await _requestAndroid();
    } else if (Platform.isIOS) {
      // TODO iOS
      throw Exception("permission_request.dart vi spara questo errore.");
      // https://stackoverflow.com/questions/68599765/flutter-permission-handler-grant-not-showing-on-ios
    } else {
      throw Exception("Platform not supported.");
    }
  }
}
