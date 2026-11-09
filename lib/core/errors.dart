import 'dart:async';
import 'dart:io';

const offlineMessage =
    'No internet connection. Check your signal or Wi-Fi and try again.';

/// True when [e] looks like a network problem rather than a real failure.
bool isOffline(Object e) {
  if (e is SocketException || e is TimeoutException) return true;
  final t = '${e.runtimeType} $e'.toLowerCase();
  return t.contains('socketexception') ||
      t.contains('clientexception') ||
      t.contains('failed host lookup') ||
      t.contains('network is unreachable') ||
      t.contains('connection closed') ||
      t.contains('connection reset') ||
      t.contains('connection refused') ||
      t.contains('connection timed out') ||
      t.contains('timeoutexception') ||
      t.contains('retryablefetch');
}

/// A message for a person: the offline text, or the error itself.
String describeError(Object e) => isOffline(e) ? offlineMessage : e.toString();

/// "Could not save: ..." for a message bar, or the offline text.
String failMessage(String what, Object e) =>
    isOffline(e) ? offlineMessage : '$what: $e';
