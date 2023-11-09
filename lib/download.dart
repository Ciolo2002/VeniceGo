import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import "package:http/http.dart" as http;
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
class Navigation {
  Future<void> download() async {
    var url = Uri.https("actv.avmspa.it", "sites/default/files/attachments/opendata/navigazione/actv_nav.zip");
    var client = HttpClient();
    // Download zip file from url
    var request = await client.getUrl(url);
    var response = await request.close();
    // Save bytes to file
    var bytes = await consolidateHttpClientResponseBytes(response);
    File file = File('actv_nav.zip');

  }
  
}