import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Configuration: Gateway server URL
  // "http://10.0.2.2:8000/api" maps to localhost for Android emulator.
  // Use "http://127.0.0.1:8000/api" for iOS simulators or web.
  static String gatewayUrl = "https://webx-gateway.onrender.com/api";

  // Cached session variables
  static String? cachedShardUrl;
  static String? cachedUid;
  static String? accessToken;
  static String? currentEmail;
  static String? verifiedOtpCode;

  // Custom connection failure error text
  static const String serverUnreachableError = 
      "Server is temporarily unreachable. Please report this to support.";

  /// Helper to dynamically rewrite localhost for Android Emulator compatibility
  static String _normalizeUrl(String url) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return url.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  /// Helper to safely execute HTTP POST/GET requests and catch offline timeouts
  static Future<http.Response> _safeRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn().timeout(const Duration(seconds: 10));
      return response;
    } catch (e) {
      debugPrint("API Connection Failure: $e");
      // Return a simulated 503 response to alert the user
      return http.Response(
        json.encode({
          'success': false,
          'error': serverUnreachableError,
        }),
        503,
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// 1. Gateway: Check email exists globally
  static Future<Map<String, dynamic>> checkEmail(String email) async {
    final response = await _safeRequest(() => http.post(
      Uri.parse("${_normalizeUrl(gatewayUrl)}/gateway/check-email/"),
      headers: {'content-type': 'application/json'},
      body: json.encode({'email': email.trim()}),
    ));

    try {
      return json.decode(response.body);
    } catch (_) {
      return {'success': false, 'error': 'Failed to parse response'};
    }
  }

  /// 2. Gateway: Signup user (reserves UID on active shard)
  static Future<Map<String, dynamic>> register(
    String email, 
    String password, 
    {String? referralCode}
  ) async {
    currentEmail = email.trim();
    final response = await _safeRequest(() => http.post(
      Uri.parse("${_normalizeUrl(gatewayUrl)}/gateway/signup/"),
      headers: {'content-type': 'application/json'},
      body: json.encode({
        'email': email.trim(),
        'password': password,
        'referral_code': referralCode?.trim() ?? '',
      }),
    ));

    try {
      final data = json.decode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        cachedShardUrl = _normalizeUrl(data['shard_url'] as String);
        cachedUid = data['uid'];
      }
      return data;
    } catch (_) {
      return {'success': false, 'error': 'Failed to parse response'};
    }
  }

  /// 3. Gateway + Shard: Login user
  static Future<Map<String, dynamic>> login(String email, String password) async {
    currentEmail = email.trim();

    // Step A: Ask Gateway for the user's specific Shard URL
    final gatewayResp = await _safeRequest(() => http.post(
      Uri.parse("${_normalizeUrl(gatewayUrl)}/gateway/login/"),
      headers: {'content-type': 'application/json'},
      body: json.encode({'email': email.trim()}),
    ));

    if (gatewayResp.statusCode != 200) {
      try {
        return json.decode(gatewayResp.body);
      } catch (_) {
        return {'success': false, 'error': 'User not registered'};
      }
    }

    Map<String, dynamic> gatewayData;
    try {
      gatewayData = json.decode(gatewayResp.body);
    } catch (_) {
      return {'success': false, 'error': 'Routing failed'};
    }

    final rawShardUrl = gatewayData['shard_url'] as String;
    final shardUrl = _normalizeUrl(rawShardUrl);
    final uid = gatewayData['uid'] as String;

    // Step B: Authenticate directly against that Shard to get JWT Token
    final shardResp = await _safeRequest(() => http.post(
      Uri.parse("${shardUrl.rstrip('/')}/api/auth/login/"),
      headers: {'content-type': 'application/json'},
      body: json.encode({
        'email': email.trim(),
        'password': password,
      }),
    ));

    try {
      final shardData = json.decode(shardResp.body);
      if (shardResp.statusCode == 200 && shardData['success'] == true) {
        cachedShardUrl = shardUrl;
        cachedUid = uid;
        accessToken = shardData['tokens']['access'];
      }
      return shardData;
    } catch (_) {
      return {'success': false, 'error': 'Authentication server failed'};
    }
  }

  /// 4. Shard: Verify OTP (OTP is checked on the active Shard)
  static Future<Map<String, dynamic>> verifyOtp(String code) async {
    if (cachedShardUrl == null || currentEmail == null) {
      return {'success': false, 'error': 'Verification session missing'};
    }

    final normalizedUrl = _normalizeUrl(cachedShardUrl!);
    final response = await _safeRequest(() => http.post(
      Uri.parse("${normalizedUrl.rstrip('/')}/api/auth/verify-otp/"),
      headers: {'content-type': 'application/json'},
      body: json.encode({
        'email': currentEmail,
        'code': code.trim(),
      }),
    ));

    try {
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        accessToken = data['tokens']['access'];
        cachedUid = data['uid'];
        verifiedOtpCode = code.trim(); // Save verified OTP code
      }
      return data;
    } catch (_) {
      return {'success': false, 'error': 'Failed to verify code'};
    }
  }

  /// 5. Gateway + Shard: Request Forgot Password Reset OTP
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    currentEmail = email.trim();

    // Step A: Find Shard URL from Gateway
    final gatewayResp = await _safeRequest(() => http.post(
      Uri.parse("${_normalizeUrl(gatewayUrl)}/gateway/login/"),
      headers: {'content-type': 'application/json'},
      body: json.encode({'email': email.trim()}),
    ));

    if (gatewayResp.statusCode != 200) {
      try {
        return json.decode(gatewayResp.body);
      } catch (_) {
        return {'success': false, 'error': 'Email not registered'};
      }
    }

    Map<String, dynamic> gatewayData;
    try {
      gatewayData = json.decode(gatewayResp.body);
    } catch (_) {
      return {'success': false, 'error': 'Routing lookup failed'};
    }

    final shardUrl = _normalizeUrl(gatewayData['shard_url'] as String);
    cachedShardUrl = shardUrl;

    // Step B: Ask that Shard to send a password reset OTP
    final shardResp = await _safeRequest(() => http.post(
      Uri.parse("${shardUrl.rstrip('/')}/api/auth/forgot-password/"),
      headers: {'content-type': 'application/json'},
      body: json.encode({'email': email.trim()}),
    ));

    try {
      return json.decode(shardResp.body);
    } catch (_) {
      return {'success': false, 'error': 'Failed to request reset OTP'};
    }
  }

  /// 6. Shard: Reset password with code
  static Future<Map<String, dynamic>> updatePassword(
    String newPassword, 
    String confirmPassword,
  ) async {
    if (cachedShardUrl == null || currentEmail == null) {
      return {'success': false, 'error': 'Password reset session expired'};
    }

    final normalizedUrl = _normalizeUrl(cachedShardUrl!);
    final response = await _safeRequest(() => http.post(
      Uri.parse("${normalizedUrl.rstrip('/')}/api/auth/reset-password/"),
      headers: {'content-type': 'application/json'},
      body: json.encode({
        'email': currentEmail,
        'code': verifiedOtpCode ?? '',
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    ));

    try {
      return json.decode(response.body);
    } catch (_) {
      return {'success': false, 'error': 'Failed to reset password'};
    }
  }

  /// 7. Shard: Claim streak count and trigger milestones
  static Future<Map<String, dynamic>> claimStreak() async {
    if (cachedShardUrl == null || accessToken == null) {
      return {'success': false, 'error': 'Session expired. Please log in again.'};
    }

    final normalizedUrl = _normalizeUrl(cachedShardUrl!);
    final response = await _safeRequest(() => http.post(
      Uri.parse("${normalizedUrl.rstrip('/')}/api/activity/claim-streak/"),
      headers: {
        'content-type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ));

    try {
      return json.decode(response.body);
    } catch (_) {
      return {'success': false, 'error': 'Streak verification failed'};
    }
  }

  /// 8. Shard: Submit UPI withdrawal request
  static Future<Map<String, dynamic>> requestWithdrawal(
    String name, 
    String upiId, 
    int amountCoins
  ) async {
    if (cachedShardUrl == null || accessToken == null) {
      return {'success': false, 'error': 'Session expired. Please log in again.'};
    }

    final normalizedUrl = _normalizeUrl(cachedShardUrl!);
    final response = await _safeRequest(() => http.post(
      Uri.parse("${normalizedUrl.rstrip('/')}/api/wallet/withdraw/"),
      headers: {
        'content-type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'name': name.trim(),
        'upi_id': upiId.trim(),
        'amount_coins': amountCoins,
      }),
    ));

    try {
      return json.decode(response.body);
    } catch (_) {
      return {'success': false, 'error': 'Failed to request withdrawal'};
    }
  }

  /// 9. Shard: Fetch current coins balance & streak count from server
  static Future<Map<String, dynamic>> fetchProfile() async {
    if (cachedShardUrl == null || accessToken == null) {
      return {'success': false, 'error': 'Session expired'};
    }

    final normalizedUrl = _normalizeUrl(cachedShardUrl!);
    final response = await _safeRequest(() => http.get(
      Uri.parse("${normalizedUrl.rstrip('/')}/api/auth/profile/"),
      headers: {
        'content-type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ));

    try {
      return json.decode(response.body);
    } catch (_) {
      return {'success': false, 'error': 'Profile sync failed'};
    }
  }
}

extension StringExtension on String {
  String rstrip(String pattern) {
    if (endsWith(pattern)) {
      return substring(0, length - pattern.length);
    }
    return this;
  }
}
