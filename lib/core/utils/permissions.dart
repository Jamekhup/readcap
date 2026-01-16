import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Future<bool> requestCameraAndMic() async {
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    return camera.isGranted && mic.isGranted;
  }

  static Future<bool> requestStorage() async {
    final photos = await Permission.photos.request();
    final videos = await Permission.videos.request();
    final storage = await Permission.storage.request();
    return photos.isGranted || videos.isGranted || storage.isGranted;
  }

  static Future<bool> openSettings() {
    return openAppSettings();
  }
}
