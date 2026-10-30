import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Whether a webhook request was signed with [secretKey]: [timestamp] and
/// [signature] are its `x-webflow-timestamp` and `x-webflow-signature`
/// headers, and [body] is the body as it arrived, not decoded and encoded
/// again.
///
/// Webflow signs `timestamp:body` with HMAC-SHA256, the timestamp in
/// milliseconds. A request sent more than [tolerance] away from [now] is
/// refused, so a captured one cannot be replayed later.
bool isWebflowSignature({
  required String secretKey,
  required String? timestamp,
  required String? signature,
  required String body,
  DateTime? now,
  Duration tolerance = const Duration(minutes: 5),
}) {
  var sentAt = int.tryParse(timestamp ?? "");
  if (sentAt == null || signature == null) return false;
  var age = (now ?? DateTime.now()).millisecondsSinceEpoch - sentAt;
  if (age.abs() > tolerance.inMilliseconds) return false;

  var expected = Hmac(sha256, utf8.encode(secretKey))
      .convert(utf8.encode("$timestamp:$body"))
      .toString();
  return _sameInConstantTime(expected, signature.toLowerCase());
}

bool _sameInConstantTime(String a, String b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return difference == 0;
}
