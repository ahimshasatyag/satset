import 'dart:js_interop';

@JS('document.cookie')
external set _documentCookie(String value);

@JS('document.cookie')
external String get _documentCookie;

@JS('window.setAdminAuthToken')
external set _windowSetAdminAuthToken(JSFunction fn);

const String _tokenCookieName = 'satset_admin_auth_token';
const String _emailCookieName = 'satset_admin_email';
const String _roleCookieName = 'satset_admin_role';

void setAuthTokenCookieImpl({
  required String token,
  required String email,
  String role = 'admin',
  int maxAgeSeconds = 86400,
}) {
  try {
    final encodedToken = Uri.encodeComponent(token);
    final encodedEmail = Uri.encodeComponent(email);
    final encodedRole = Uri.encodeComponent(role);

    _documentCookie =
        '$_tokenCookieName=$encodedToken; path=/; max-age=$maxAgeSeconds; SameSite=Lax';
    _documentCookie =
        '$_emailCookieName=$encodedEmail; path=/; max-age=$maxAgeSeconds; SameSite=Lax';
    _documentCookie =
        '$_roleCookieName=$encodedRole; path=/; max-age=$maxAgeSeconds; SameSite=Lax';
  } catch (_) {}
}

Map<String, String> getAllCookiesImpl() {
  final Map<String, String> cookies = {};
  try {
    final raw = _documentCookie;
    if (raw.trim().isEmpty) return cookies;

    for (final part in raw.split(';')) {
      final trimmed = part.trim();
      final index = trimmed.indexOf('=');
      if (index > 0) {
        final key = trimmed.substring(0, index).trim();
        final val = Uri.decodeComponent(trimmed.substring(index + 1).trim());
        cookies[key] = val;
      }
    }
  } catch (_) {}
  return cookies;
}

String? getAuthTokenCookieImpl() {
  final cookies = getAllCookiesImpl();
  final token = cookies[_tokenCookieName];
  if (token != null && token.isNotEmpty) {
    return token;
  }
  return null;
}

void clearAuthTokenCookieImpl() {
  try {
    _documentCookie =
        '$_tokenCookieName=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT; SameSite=Lax';
    _documentCookie =
        '$_emailCookieName=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT; SameSite=Lax';
    _documentCookie =
        '$_roleCookieName=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT; SameSite=Lax';
  } catch (_) {}
}

void registerConsoleTokenHelperImpl({
  required void Function(String token, String email) onTokenLogin,
}) {
  try {
    _windowSetAdminAuthToken = ((JSString token, JSString? email) {
      final tokenStr = token.toDart.trim();
      final emailStr = (email?.toDart.trim().isNotEmpty == true)
          ? email!.toDart.trim()
          : (getAllCookiesImpl()[_emailCookieName] ?? 'admin@satset.id');

      if (tokenStr.isEmpty) return;

      setAuthTokenCookieImpl(
        token: tokenStr,
        email: emailStr,
        role: 'admin',
      );
      onTokenLogin(tokenStr, emailStr);
    }).toJS;
  } catch (_) {}
}
