import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';

class MockData {
  static Map<String, dynamic> gamesData = {};
  static Map<String, dynamic> fetchCardsData = {};
  static bool isJsonLoaded = false;

  static Future<void> loadLocalJsonData() async {
    if (isJsonLoaded) return;
    try {
      final gamesStr = await rootBundle.loadString('JsonFetchTests/games.json');
      gamesData = json.decode(gamesStr);

      final fetchCardsStr = await rootBundle.loadString('JsonFetchTests/fetchcards.json');
      fetchCardsData = json.decode(fetchCardsStr);

      isJsonLoaded = true;
    } catch (e) {
      // Fallback or print error
      debugPrint('Error loading JSON assets: $e');
    }
  }

  // Screen text and configuration labels formatted in JSON map.
  static const String _screenConfigJson = '''
  {
    "common": {
      "skip": "Skip",
      "or": "Or"
    },
    "login": {
      "heading": "WebX",
      "tabLabel": "Log in",
      "emailLabel": "Your Email",
      "emailPlaceholder": "user@email.com",
      "passwordLabel": "Password",
      "passwordPlaceholder": "Enter your password",
      "forgotPassword": "Forgot password?",
      "buttonLabel": "Continue",
      "noAccountText": "Don't have an account?",
      "signupLink": "Sign up"
    },
    "signup": {
      "heading": "WebX",
      "tabLabel": "Sign up",
      "emailLabel": "Your Email",
      "emailPlaceholder": "user@email.com",
      "passwordLabel": "Password",
      "passwordPlaceholder": "Enter password",
      "confirmPasswordLabel": "Confirm Password",
      "confirmPasswordPlaceholder": "Re-enter password",
      "referralLabel": "Referral Id (optional)",
      "referralPlaceholder": "Enter referral ID",
      "buttonLabel": "Send OTP",
      "haveAccountText": "Have an account?",
      "loginLink": "Login"
    },
    "forgotPassword": {
      "heading": "Forgot password",
      "subHeading": "Please enter your email to reset the password",
      "emailLabel": "Your Email",
      "emailPlaceholder": "Enter your email",
      "buttonLabel": "Reset Password"
    },
    "checkEmail": {
      "heading": "Check your email",
      "subHeading": "We sent a reset link to contact@dscode...com enter 5 digit code that mentioned in the email",
      "buttonLabel": "Verify Code",
      "resendPrompt": "Haven't got the email yet?",
      "resendLink": "Resend email"
    },
    "setNewPassword": {
      "heading": "Set a new password",
      "subHeading": "Create a new password. Ensure it differs from previous ones for security",
      "passwordLabel": "Password",
      "passwordPlaceholder": "Enter your new password",
      "confirmPasswordLabel": "Confirm Password",
      "confirmPasswordPlaceholder": "Re-enter password",
      "buttonLabel": "Update Password"
    },
    "resetSuccess": {
      "heading": "Password reset",
      "subHeading": "Your password has been successfully reset. click confirm to set a new password",
      "buttonLabel": "Confirm"
    },
    "dialogSuccess": {
      "heading": "Successful",
      "subHeading": "Congratulations! Your password has been changed. Click continue to login",
      "buttonLabel": "Update Password"
    },
    "home": {
      "title": "Home",
      "templateGamesHeading": "Template Games",
      "utilitiesHeading": "Utilities",
      "downloadersHeading": "Downloaders",
      "pdfEditorsHeading": "PDF editors"
    },
    "profile": {
      "title": "Profile",
      "accountLabel": "Account",
      "username": "username",
      "handle": "@userid",
      "streakLabel": "Streak",
      "referEarningsLabel": "Refer Earnings",
      "balance": "\$15,320.45",
      "balanceChange": "+\$0.36 (+2.34%)",
      "receiveButton": "Receive",
      "menuReferLabel": "Refer and earn",
      "menuHelpLabel": "Help Center",
      "version": "Version 1.0.0"
    },
    "referAndEarn": {
      "title": "Refer & Earn",
      "heading": "REFER & EARN",
      "subHeading": "Invite your friends and earn exciting rewards!",
      "amount": "₹ 15,000",
      "rateText": "100 = ₹1",
      "sharePrompt": "Share WebX app",
      "codeInstruction": "use this code while referring a friend",
      "promoCode": "CODEWEBX07",
      "howItWorksHeading": "How Referral works?"
    },
    "withdrawSuccess": {
      "heading": "Successful",
      "transactionIdLabel": "Transaction ID",
      "transactionId": "0x7a8d9b1c2e3f4a5b6c7d8e9f",
      "explorerLinkLabel": "View in Explorer",
      "buttonLabel": "Close"
    }
  }
  ''';

  // Mock lists for Home Screen dynamic categories
  static const List<Map<String, String>> mockUtilities = [
    {"title": "Link Shortener", "icon": "manage_page_icon.svg"},
    {"title": "IP Lookup", "icon": "export.svg"},
    {"title": "QR Generator", "icon": "sort.svg"}
  ];

  static const List<Map<String, String>> mockDownloaders = [
    {"title": "Video Downloader", "icon": "Icon - Receive.svg"},
    {"title": "Audio Extractor", "icon": "export.svg"}
  ];

  static const List<Map<String, String>> mockPdfEditors = [
    {"title": "PDF Merger", "icon": "See All Icon.svg"},
    {"title": "PDF Compress", "icon": "sort.svg"}
  ];

  static Map<String, dynamic> get config {
    return json.decode(_screenConfigJson);
  }

  static bool isLoggedIn = false;

  // Simulated Database of users
  static final List<Map<String, String>> _mockUsersDb = [
    {
      'email': 'user@email.com',
      'password': 'password123',
    }
  ];

  // Configured Correct OTP code for password reset verification
  static const String validOtp = '86300';

  static bool useRealBackend = true;

  /// Simulates Login Endpoint
  /// Returns a JSON string response matching standard Django auth endpoints
  static Future<String> login(String email, String password) async {
    if (useRealBackend) {
      final res = await ApiService.login(email, password);
      if (res['success'] == true) {
        isLoggedIn = true;
      }
      return json.encode(res);
    }

    await Future.delayed(const Duration(milliseconds: 800)); // Network simulation

    if (email.trim().isEmpty) {
      return json.encode({
        'success': false,
        'error': 'Email cannot be empty',
      });
    }

    if (password.isEmpty) {
      return json.encode({
        'success': false,
        'error': 'Password cannot be empty',
      });
    }

    final userIndex = _mockUsersDb.indexWhere(
      (user) => user['email'] == email.trim().toLowerCase()
    );

    if (userIndex == -1) {
      return json.encode({
        'success': false,
        'error': 'Email not registered',
      });
    }

    if (_mockUsersDb[userIndex]['password'] != password) {
      return json.encode({
        'success': false,
        'error': 'Wrong password',
      });
    }

    isLoggedIn = true;

    return json.encode({
      'success': true,
      'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mockTokenPayload',
      'message': 'Login successful',
    });
  }

  /// Simulates Registration Endpoint
  static Future<String> register(String email, String password, String confirmPassword, {String? referralCode}) async {
    if (useRealBackend) {
      if (password != confirmPassword) {
        return json.encode({
          'success': false,
          'error': 'Passwords do not match',
        });
      }
      final res = await ApiService.register(email, password, referralCode: referralCode);
      return json.encode(res);
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (email.trim().isEmpty || !email.contains('@')) {
      return json.encode({
        'success': false,
        'error': 'Please enter a valid email address',
      });
    }

    if (password.length < 6) {
      return json.encode({
        'success': false,
        'error': 'Password must be at least 6 characters long',
      });
    }

    if (password != confirmPassword) {
      return json.encode({
        'success': false,
        'error': 'Passwords do not match',
      });
    }

    // Check if user already exists
    final exists = _mockUsersDb.any(
      (user) => user['email'] == email.trim().toLowerCase()
    );

    if (exists) {
      return json.encode({
        'success': false,
        'error': 'Email already registered',
      });
    }

    // Add user to database
    _mockUsersDb.add({
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    // Simulate creation
    return json.encode({
      'success': true,
      'message': 'Registration successful. OTP sent.',
    });
  }

  /// Simulates Request Password Reset (Forgot Password)
  static Future<String> requestPasswordReset(String email) async {
    if (useRealBackend) {
      final res = await ApiService.requestPasswordReset(email);
      return json.encode(res);
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (email.trim().isEmpty || !email.contains('@')) {
      return json.encode({
        'success': false,
        'error': 'Please enter a valid email address',
      });
    }

    return json.encode({
      'success': true,
      'message': 'Reset code sent successfully to $email',
    });
  }

  /// Simulates OTP Code Verification
  static Future<String> verifyOtp(String code) async {
    if (useRealBackend) {
      final res = await ApiService.verifyOtp(code);
      if (res['success'] == true) {
        isLoggedIn = true;
      }
      return json.encode(res);
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (code == validOtp) {
      isLoggedIn = true;
      return json.encode({
        'success': true,
        'message': 'Code verified successfully',
      });
    } else {
      return json.encode({
        'success': false,
        'error': 'Invalid code. Please try again.',
      });
    }
  }

  /// Simulates Set New Password
  static Future<String> updatePassword(String newPassword, String confirmPassword) async {
    if (useRealBackend) {
      final res = await ApiService.updatePassword(newPassword, confirmPassword);
      return json.encode(res);
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (newPassword.length < 6) {
      return json.encode({
        'success': false,
        'error': 'Password must be at least 6 characters',
      });
    }

    if (newPassword != confirmPassword) {
      return json.encode({
        'success': false,
        'error': 'Passwords do not match',
      });
    }

    // Update the password in our mock database
    _mockUsersDb[0]['password'] = newPassword;

    return json.encode({
      'success': true,
      'message': 'Password updated successfully',
    });
  }
}
