import 'dart:io' show Platform, File;

class ApiConfig {
  // ============================================================
  // 真机调试时，修改下面这行为你电脑的局域网 IP 地址
  // 电脑和手机必须连接同一个 WiFi
  // 获取方式：命令行输入 ipconfig（Windows）或 ifconfig（Mac/Linux）
  // 示例：'192.168.1.100' 或 '192.168.31.50'
  // ============================================================
  static const String lanIp = '10.138.195.136';

  static String get baseUrl {
    if (Platform.isAndroid) {
      if (_isEmulator) {
        return 'http://10.0.2.2:3000';
      }
      return 'http://$lanIp:3000';
    }
    // iOS simulator uses localhost; real device needs the same LAN IP
    return 'http://localhost:3000';
  }

  /// Detect Android emulator by checking /proc/cpuinfo.
  /// Emulators report "goldfish" or "ranchu" as the hardware name.
  static bool get _isEmulator {
    if (!Platform.isAndroid) return false;
    try {
      final content = File('/proc/cpuinfo').readAsStringSync();
      return content.contains('goldfish') || content.contains('ranchu');
    } catch (_) {
      return false;
    }
  }

  /// Returns a human-readable description of the current configuration.
  static String get debugInfo {
    final kind = Platform.isAndroid
        ? (_isEmulator ? 'Android 模拟器' : 'Android 真机')
        : 'iOS';
    return '$kind → $baseUrl';
  }
}
