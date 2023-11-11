import 'dart:io';
import 'package:venice_go/permission_request.dart';

class NavigationDataDownloader {
  /// Download the navigation data from the ACTV website and saves it in the app's local storage.
  /// Throws an exception if the download fails or the permissions are not granted.
  Future<void> download() async {
    var url = Uri.https("actv.avmspa.it",
        "sites/default/files/attachments/opendata/navigazione/actv_nav.zip");
    var client = HttpClient();
    // Download zip file from url
    var request = await client.getUrl(url);
    var response = await request.close();
    await PermissionRequest.request();
  }
}
