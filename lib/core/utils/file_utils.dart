import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String> createVideoPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/readcap_$timestamp.mp4';
  }

  static Future<File> copyToExports(String sourcePath) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final target = File('${directory.path}/readcap_export_$timestamp.mp4');
    return File(sourcePath).copy(target.path);
  }

}
