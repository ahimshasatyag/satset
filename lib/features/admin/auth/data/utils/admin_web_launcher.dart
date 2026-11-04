import 'admin_web_launcher_stub.dart'
    if (dart.library.js_interop) 'admin_web_launcher_web.dart';

class AdminWebLauncher {
  AdminWebLauncher._();

  static void openUrl(String url) {
    openWebUrlImpl(url);
  }

  static void openEmailProvider(String email) {
    final clean = email.trim().toLowerCase();
    String targetUrl = 'https://mail.google.com';
    if (clean.endsWith('@outlook.com') ||
        clean.endsWith('@hotmail.com') ||
        clean.endsWith('@live.com')) {
      targetUrl = 'https://outlook.live.com';
    } else if (clean.endsWith('@yahoo.com') || clean.endsWith('@ymail.com')) {
      targetUrl = 'https://mail.yahoo.com';
    }
    openUrl(targetUrl);
  }
}

