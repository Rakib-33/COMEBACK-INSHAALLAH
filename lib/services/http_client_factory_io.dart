import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createPlatformHttpClient() {
  final ioHttpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 20)
    ..badCertificateCallback = (cert, host, port) {
      return host == 'api-uniplex.mist.ac.bd';
    };

  return IOClient(ioHttpClient);
}
