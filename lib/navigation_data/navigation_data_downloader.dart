import 'dart:io';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

class NavigationDataDownloader {
  /// Downloads the navigation data from the ACTV website and saves it in the app's local storage.
  /// Assumes that permissions are already granted at app start.
  /// Throws an exception if the download fails or the permissions are not granted.
  Future<void> download() async {
    // TODO: call this method every two weeks
    Uri url = Uri.https("actv.avmspa.it",
        "sites/default/files/attachments/opendata/navigazione/actv_nav.zip");
    Response response = await get(url);
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    File actvData = File("${appDocumentsDir.path}/actv_nav.zip");
    actvData.writeAsBytes(response.bodyBytes);
  }
}
