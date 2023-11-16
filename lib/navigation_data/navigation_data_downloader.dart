import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import "package:archive/archive_io.dart";

class NavigationDataDownloader {
  /// Downloads the navigation data from the ACTV website and saves it in the app's local storage.
  /// Assumes that permissions are already granted at app start.
  /// Throws an exception if the download fails or data is corrupted.
  Future<void> _download(final Directory dir) async {
    // TODO: call this method every two weeks
    final Uri uri = Uri.https("actv.avmspa.it",
        "sites/default/files/attachments/opendata/navigazione/actv_nav.zip");
    // Download using Request and Response
    final http.Request request = http.Request('GET', uri);
    final http.StreamedResponse response = await request.send();
    final File file = File("${dir.path}/actv_nav.zip");
    await response.stream.pipe(file.openWrite());
    // Check for file integrity
    if (response.contentLength != file.lengthSync()) {
      throw Exception("Downloaded file is corrupted.");
    }
  }

  /// Extracts the navigation data from the app's local storage.
  /// Assumes that permissions are already granted at app start.
  /// Throws an exception if the unzipping fails.
  Future<void> _extractData(final Directory dir) async {
    final String zipFile = "${dir.path}/actv_nav.zip";

    try {
      final File file = File(zipFile);
      final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
      extractArchiveToDisk(archive, 'actv_nav');
    } catch (e) {
      rethrow;
    }
  }

  /// Downloads and extracts the navigation data from the ACTV website.
  /// Assumes that permissions are already granted at app start.
  /// Throws an exception if the download or the unzipping fails.
  Future<void> initNavigationData() async {
    try {
      await _download(await getApplicationDocumentsDirectory());
      await _extractData(await getApplicationDocumentsDirectory());
    } catch (e) {
      rethrow;
    }
  }
}
