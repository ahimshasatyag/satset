import 'dart:js_interop';

@JS('window.open')
external void _windowOpen(String url, String target);

void openWebUrlImpl(String url) {
  try {
    _windowOpen(url, '_blank');
  } catch (_) {}
}

