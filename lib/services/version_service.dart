import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static Future<String> getVersionString() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }
} 