import 'package:flutter/material.dart';
import '../auth_theme.dart';
import 'custom_button.dart';

class LoginRequiredView extends StatelessWidget {
  final String title;
  final String subtitle;

  const LoginRequiredView({
    super.key,
    this.title = 'Authentication Required',
    this.subtitle = 'Please log in or sign up to view your profile, track your streak, and earn referral rewards.',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon Container
          Center(
            child: Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(40.0),
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 36.0,
                color: AuthTheme.textDark,
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontFamily: AuthTheme.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 20.0,
              color: AuthTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),

          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: AuthTheme.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
              color: AuthTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),

          // Action Button
          CustomButton(
            label: 'Log In / Sign Up',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
