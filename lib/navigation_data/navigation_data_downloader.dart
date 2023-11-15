import 'dart:io';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import "package:archive/archive_io.dart";

class NavigationDataDownloader {
  /// Downloads the navigation data from the ACTV website and saves it in the app's local storage.
  /// Assumes that permissions are already granted at app start.
  /// Throws an exception if the download fails or data is corrupted.
  Future<void> _download() async {
    // TODO: call this method every two weeks
    // TODO: find out why it does not download full file
    const String url =
        "https://actv.avmspa.it/sites/default/files/attachments/opendata/navigazione/actv_nav.zip";
    Response response = await get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("Download failed, try again later.");
    }
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    File actvData = File("${appDocumentsDir.path}/actv_nav.zip");
    actvData.writeAsBytes(response.bodyBytes);
    final int contentLength = response.contentLength ?? 0;
    final int downloadedSize = await actvData.length();

    if (contentLength != downloadedSize) {
      await actvData.delete();
      throw Exception("Downloaded file is corrupted or incomplete.");
    }
  }

  /// Extracts the navigation data from the app's local storage.
  /// Assumes that permissions are already granted at app start.
  /// Throws an exception if the unzipping fails.
  Future<void> _extractData() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String zipFile = "${appDocumentsDir.path}/actv_nav.zip";

    try {
      final File file = File(zipFile);
      final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
      extractArchiveToDisk(archive, 'out');
    } catch (e) {
      // Handle the FormatException
      if (e is FormatException) {
        // The ZIP file is corrupted or incomplete
        print("Error: Invalid ZIP file format or incomplete archive.");
      } else {
        // Other unexpected errors
        print("Error: Failed to extract ZIP archive: $e");
      }
    }
  }

  /// Downloads and extracts the navigation data from the ACTV website.
  /// Assumes that permissions are already granted at app start.
  /// Throws an exception if the download or the unzipping fails.
  Future<void> initNavigationData() async {
    try {
      await _download();
      await _extractData();
    } catch (e) {
      rethrow;
    }
  }
}
