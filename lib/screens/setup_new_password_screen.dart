import 'dart:convert';
import 'package:flutter/material.dart';
import '../auth_theme.dart';
import '../mock_data.dart';
import '../components/custom_text_field.dart';
import '../components/custom_button.dart';
import '../components/circular_back_button.dart';

class SetupNewPasswordScreen extends StatefulWidget {
  const SetupNewPasswordScreen({super.key});

  @override
  State<SetupNewPasswordScreen> createState() => _SetupNewPasswordScreenState();
}

class _SetupNewPasswordScreenState extends State<SetupNewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateFields);
    _confirmPasswordController.addListener(_validateFields);
  }

  void _validateFields() {
    setState(() {
      _isButtonEnabled = _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_isButtonEnabled || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final newPass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    final responseStr = await MockData.updatePassword(newPass, confirmPass);
    final response = json.decode(responseStr);

    setState(() {
      _isLoading = false;
    });

    if (response['success'] == true) {
      if (mounted) {
        // Navigate to Password Reset Success Screen
        Navigator.pushNamed(context, '/reset-success');
      }
    } else {
      setState(() {
        _errorText = response['error'] ?? 'Failed to update password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = MockData.config['setNewPassword'] as Map<String, dynamic>;

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
                  onPressed: () => Navigator.maybePop(context),
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
              const SizedBox(height: 32.0),

              // New Password Input
              CustomTextField(
                label: config['passwordLabel'],
                hint: config['passwordPlaceholder'],
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 20.0),

              // Confirm Password Input
              CustomTextField(
                label: config['confirmPasswordLabel'],
                hint: config['confirmPasswordPlaceholder'],
                controller: _confirmPasswordController,
                isPassword: true,
                errorText: _errorText,
              ),
              const SizedBox(height: 32.0),

              // Update Button
              CustomButton(
                label: config['buttonLabel'],
                isEnabled: _isButtonEnabled,
                isLoading: _isLoading,
                onPressed: _handleUpdate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
