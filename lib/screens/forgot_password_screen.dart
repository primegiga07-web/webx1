import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth_theme.dart';
import '../mock_data.dart';
import '../components/custom_text_field.dart';
import '../components/custom_button.dart';
import '../components/circular_back_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateFields);
  }

  void _validateFields() {
    setState(() {
      _isButtonEnabled = _emailController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_isButtonEnabled || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final email = _emailController.text;
    final responseStr = await MockData.requestPasswordReset(email);
    final response = json.decode(responseStr);

    setState(() {
      _isLoading = false;
    });

    if (response['success'] == true) {
      if (mounted) {
        // Navigate to Check Email (OTP code verification) screen
        Navigator.pushNamed(
          context,
          '/check-email',
          arguments: {
            'email': email.trim(),
            'isSignUp': false,
          },
        );
      }
    } else {
      setState(() {
        _errorText = response['error'] ?? 'Reset request failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = MockData.config['forgotPassword'] as Map<String, dynamic>;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              const CircularBackButton(),
              const SizedBox(height: 36.0),

              // Title Header
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
              const SizedBox(height: 32.0),

              // Input Field
              CustomTextField(
                label: config['emailLabel'],
                hint: config['emailPlaceholder'],
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _errorText,
              ),
              const SizedBox(height: 32.0),

              // Reset Button
              CustomButton(
                label: config['buttonLabel'],
                isEnabled: _isButtonEnabled,
                isLoading: _isLoading,
                onPressed: _handleReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
