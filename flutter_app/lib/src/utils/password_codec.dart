import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordCodec {
  const PasswordCodec._();

  static const String _scheme = 'pbkdf2_sha256';
  static const int _iterations = 45000;
  static const int _keyLength = 32;
  static const int _saltLength = 16;

  static String createHash(String password) {
    final salt = _randomBytes(_saltLength);
    final hash = _pbkdf2(
      utf8.encode(password),
      salt,
      iterations: _iterations,
      keyLength: _keyLength,
    );
    return [
      _scheme,
      _iterations.toString(),
      base64Url.encode(salt),
      base64Url.encode(hash),
    ].join(':');
  }

  static bool verify(String password, String storedValue) {
    if (storedValue.isEmpty) return false;
    if (!isHashed(storedValue)) {
      return password == storedValue;
    }

    final parts = storedValue.split(':');
    if (parts.length != 4) return false;

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    try {
      final salt = base64Url.decode(parts[2]);
      final expected = base64Url.decode(parts[3]);
      final actual = _pbkdf2(
        utf8.encode(password),
        salt,
        iterations: iterations,
        keyLength: expected.length,
      );
      return _constantTimeEquals(actual, expected);
    } catch (_) {
      return false;
    }
  }

  static bool isHashed(String storedValue) {
    return storedValue.startsWith('$_scheme:');
  }

  static bool shouldUpgrade(String storedValue) {
    if (storedValue.isEmpty) return false;
    if (!isHashed(storedValue)) return true;
    final parts = storedValue.split(':');
    if (parts.length != 4) return true;
    final iterations = int.tryParse(parts[1]);
    return iterations == null || iterations < _iterations;
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static List<int> _pbkdf2(
    List<int> password,
    List<int> salt, {
    required int iterations,
    required int keyLength,
  }) {
    final hmac = Hmac(sha256, password);
    final blockCount = (keyLength / hmac.convert(<int>[]).bytes.length).ceil();
    final output = <int>[];

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final block = <int>[
        ...salt,
        (blockIndex >> 24) & 0xff,
        (blockIndex >> 16) & 0xff,
        (blockIndex >> 8) & 0xff,
        blockIndex & 0xff,
      ];
      var u = hmac.convert(block).bytes;
      final result = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }
      output.addAll(result);
    }

    return output.take(keyLength).toList();
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
