import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:posthog_flutter/posthog_flutter.dart';

/// Provides methods to securely encrypt and decrypt invite codes
class EncryptionService {
  static String _secretKeyString = "";

  static Future<void> init() async {
    final secretKey = await getSecretKey();
    _secretKeyString = secretKey;
  }

  static Future<String> getSecretKey() async {
    final prefs = await Posthog().getFeatureFlagPayload('group-key');

    if (prefs == null) {
      throw Exception('Group key not found');
    }

    return (prefs as Map<String, dynamic>)['secret'];
  }

  // Cache the encryption key to avoid recomputing
  static final encrypt.Key _key = _deriveKey(_secretKeyString);
  static final encrypt.IV _iv = encrypt.IV.fromLength(16);

  /// Derives a 32 byte key from the secret string using SHA-256
  static encrypt.Key _deriveKey(String secret) {
    final bytes = utf8.encode(secret);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts a group ID to create a secure invite code
  static String encryptGroupId(String groupId) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final encrypted = encrypter.encrypt(groupId, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Error encrypting group ID: $e');
      // Fall back to original group ID if encryption fails
      return groupId;
    }
  }

  /// Decrypts an invite code to get the original group ID
  static String decryptInviteCode(String inviteCode) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt(
        encrypt.Encrypted.fromBase64(inviteCode),
        iv: _iv,
      );
      return decrypted;
    } catch (e) {
      debugPrint('Error decrypting invite code: $e');
      // Return the original code if decryption fails
      // This handles cases where the code might not be encrypted
      return inviteCode;
    }
  }
}
