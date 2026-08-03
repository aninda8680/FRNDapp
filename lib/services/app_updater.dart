import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class AppUpdater {
  final Dio dio = Dio();

  Future<void> downloadAndInstall(
      String url,
      Function(int received, int total) onProgress,
      ) async {

    final dir = await getExternalStorageDirectory();

    final filePath = "${dir!.path}/update.apk";

    await dio.download(
      url,
      filePath,
      onReceiveProgress: onProgress,
    );

    await OpenFilex.open(filePath);
  }
}
