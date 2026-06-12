import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'auth_theme.dart';
import 'screens/login_signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/check_email_screen.dart';
import 'screens/setup_new_password_screen.dart';
import 'screens/password_reset_success_screen.dart';
import 'screens/main_shell.dart';
import 'screens/refer_and_earn_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/template_games_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebX Authentication',
      debugShowCheckedModeBanner: false,
      theme: AuthTheme.themeData,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginSignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/check-email': (context) => const CheckEmailScreen(),
        '/setup-new-password': (context) => const SetupNewPasswordScreen(),
        '/reset-success': (context) => const PasswordResetSuccessScreen(),
        '/main-shell': (context) => const MainShell(),
        '/refer-and-earn': (context) => const ReferandEarnScreen(),
        '/webview': (context) => const WebViewScreen(),
        '/template-games': (context) => const TemplateGamesScreen(),
      },
    );
  }
}
