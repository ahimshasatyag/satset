String? _stubToken;
String? _stubEmail;
String? _stubRole;

void setAuthTokenCookieImpl({
  required String token,
  required String email,
  String role = 'admin',
  int maxAgeSeconds = 86400,
}) {
  _stubToken = token;
  _stubEmail = email;
  _stubRole = role;
}

Map<String, String> getAllCookiesImpl() {
  final map = <String, String>{};
  if (_stubToken != null && _stubToken!.isNotEmpty) {
    map['satset_admin_auth_token'] = _stubToken!;
  }
  if (_stubEmail != null && _stubEmail!.isNotEmpty) {
    map['satset_admin_email'] = _stubEmail!;
  }
  if (_stubRole != null && _stubRole!.isNotEmpty) {
    map['satset_admin_role'] = _stubRole!;
  }
  return map;
}

String? getAuthTokenCookieImpl() => _stubToken;

void clearAuthTokenCookieImpl() {
  _stubToken = null;
  _stubEmail = null;
  _stubRole = null;
}

void registerConsoleTokenHelperImpl({
  required void Function(String token, String email) onTokenLogin,
}) {}
