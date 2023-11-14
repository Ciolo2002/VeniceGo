import 'dart:io';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import "package:archive/archive_io.dart";

class NavigationDataDownloader {
  /// Downloads the navigation data from the ACTV website and saves it in the app's local storage.
  /// Assumes that permissions are already granted at app start.
  /// Throws an exception if the download fails.
  Future<void> _download() async {
    // TODO: call this method every two weeks
    final Uri url = Uri.https("actv.avmspa.it",
        "sites/default/files/attachments/opendata/navigazione/actv_nav.zip");
    Response response = await get(url);
    if (response.statusCode != 200) {
      throw Exception("Download failed, try again later.");
    }
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    File actvData = File("${appDocumentsDir.path}/actv_nav.zip");
    actvData.writeAsBytes(response.bodyBytes);
  }

  /// Extracts the navigation data from the app's local storage.
  /// Assumes that permissions are already granted at app start.
  /// Throws an exception if the unzipping fails.
  Future<void> _extractData() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String path = "${appDocumentsDir.path}/actv_nav.zip";
    final InputFileStream inputStream = InputFileStream(path);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    for (final file in archive.files) {
      if (file.isFile) {
        final outputStream =
            OutputFileStream("${appDocumentsDir.path}/actv_nav/${file.name}");
        try {
          file.writeContent(outputStream);
        } catch (e) {
          rethrow;
        } finally {
          outputStream.close();
        }
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
