import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Password hashing utility using PBKDF2 with HMAC-SHA256 (120,000 iterations).
abstract final class PasswordHasher {
  static const int iterations = 120000;

  static Future<String> hashPassword({required String password, required String salt}) {
    return compute<List<String>, String>(_derivePasswordHash, <String>[password, salt]);
  }

  static String generateSalt([int length = 16]) {
    final random = math.Random.secure();
    return base64UrlEncode(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  static bool constantTimeEquals(String first, String second) {
    final firstBytes = utf8.encode(first);
    final secondBytes = utf8.encode(second);
    var difference = firstBytes.length ^ secondBytes.length;
    final length = math.max(firstBytes.length, secondBytes.length);
    for (var index = 0; index < length; index++) {
      final firstByte = index < firstBytes.length ? firstBytes[index] : 0;
      final secondByte = index < secondBytes.length ? secondBytes[index] : 0;
      difference |= firstByte ^ secondByte;
    }
    return difference == 0;
  }
}

String _derivePasswordHash(List<String> arguments) {
  const int iterations = PasswordHasher.iterations;
  final passwordBytes = utf8.encode(arguments[0]);
  final salt = base64Url.decode(arguments[1]);
  final hmac = Hmac(sha256, passwordBytes);
  final firstBlock = Uint8List(salt.length + 4)..setRange(0, salt.length, salt);
  firstBlock[firstBlock.length - 1] = 1;
  var current = hmac.convert(firstBlock).bytes;
  final derived = Uint8List.fromList(current);
  for (var round = 1; round < iterations; round++) {
    current = hmac.convert(current).bytes;
    for (var index = 0; index < derived.length; index++) {
      derived[index] ^= current[index];
    }
  }
  return base64UrlEncode(derived);
}
