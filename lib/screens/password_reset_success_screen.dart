import 'package:flutter/material.dart';
import '../auth_theme.dart';
import '../mock_data.dart';
import '../components/custom_button.dart';
import '../components/circular_back_button.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = MockData.config['resetSuccess'] as Map<String, dynamic>;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back Button
              Align(
                alignment: Alignment.topLeft,
                child: CircularBackButton(
                  onPressed: () {
                    // Pop back to the LoginSignup Screen
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                ),
              ),
              const SizedBox(height: 36.0),

              // Title
              Text(
                config['heading'],
                style: AuthTheme.headerStyle,
              ),
              const SizedBox(height: 8.0),

              // Subtitle
              Text(
                config['subHeading'],
                style: AuthTheme.bodyStyle,
              ),
              const SizedBox(height: 48.0),

              // Success Visual Element (Tick Illustration)
              Center(
                child: Container(
                  width: 96.0,
                  height: 96.0,
                  decoration: BoxDecoration(
                    color: AuthTheme.primary.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 54.0,
                      color: AuthTheme.primary,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),

              // Confirm/Continue Button
              CustomButton(
                label: config['buttonLabel'],
                isEnabled: true,
                onPressed: () {
                  // Navigate back to the very first page (login/signup tabs)
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
