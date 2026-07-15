import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_logger.dart';

// Re-export so callers get Permission plus its request()/status extensions
// with a single import of this helper.
export 'package:permission_handler/permission_handler.dart';

/// Android storage-permission selection shared by every file-picking service
/// (MP3 picker, settings import), so the version cascade exists once.

/// Android SDK version; 0 on non-Android platforms.
Future<int> androidSdkInt() async {
  if (!Platform.isAndroid) return 0;
  final v = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
  AppLogger.d('Android SDK version: $v');
  return v;
}

/// The permission to request before opening a file picker.
///
/// With [audio] (media files): Android 13+ uses the granular
/// [Permission.audio], older versions [Permission.storage]. For generic
/// documents ([audio] false) Android 13+ needs no runtime permission at all
/// (the system picker is SAF-based) — callers should skip requesting when
/// [androidSdkInt] >= 33.
Future<Permission> storagePermissionForDevice({bool audio = false}) async {
  final sdkInt = await androidSdkInt();
  if (audio && sdkInt >= 33) {
    AppLogger.d('Using Permission.audio for Android $sdkInt');
    return Permission.audio;
  }
  AppLogger.d('Using Permission.storage for Android $sdkInt');
  return Permission.storage;
}
