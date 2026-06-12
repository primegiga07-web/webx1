// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth_theme.dart';
import '../mock_data.dart';
import '../components/custom_button.dart';
import '../components/circular_back_button.dart';

class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key});

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  // 5 digits code controllers and focus nodes
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      _controllers[i].addListener(_validateFields);
    }
  }

  void _validateFields() {
    bool allFilled = true;
    for (var controller in _controllers) {
      if (controller.text.trim().isEmpty) {
        allFilled = false;
        break;
      }
    }
    setState(() {
      _isButtonEnabled = allFilled;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Generate full code string from individual inputs
  String get _fullCode => _controllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerification() async {
    if (!_isButtonEnabled || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final responseStr = await MockData.verifyOtp(_fullCode);
    final response = json.decode(responseStr);

    setState(() {
      _isLoading = false;
    });

    if (response['success'] == true) {
      if (mounted) {
        final args = ModalRoute.of(context)?.settings.arguments;
        bool isSignUp = false;
        if (args is Map<String, dynamic>) {
          isSignUp = args['isSignUp'] as bool? ?? false;
        }

        if (isSignUp) {
          // Signup Flow -> Mark logged in & navigate to Home (MainShell)
          MockData.isLoggedIn = true;
          Navigator.pushNamedAndRemoveUntil(context, '/main-shell', (route) => false);
        } else {
          // Forgot Password Flow -> Setup new password
          Navigator.pushNamed(context, '/setup-new-password');
        }
      }
    } else {
      setState(() {
        _errorText = response['error'] ?? 'Verification failed';
      });
    }
  }

  void _handleResend() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new 5-digit verification code has been sent to your email.'),
        backgroundColor: AuthTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? emailArg;
    if (args is Map<String, dynamic>) {
      emailArg = args['email'] as String?;
    } else if (args is String) {
      emailArg = args;
    }

    final config = MockData.config['checkEmail'] as Map<String, dynamic>;

    // Dynamically insert user's email into description text if available
    String subHeadingText = config['subHeading'];
    if (emailArg != null && emailArg.isNotEmpty) {
      subHeadingText = subHeadingText.replaceFirst('contact@dscode...com', emailArg);
    }

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

              // Description / Subheading
              Text(
                subHeadingText,
                style: AuthTheme.bodyStyle,
              ),
              const SizedBox(height: 40.0),

              // Row of 5 OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) => _buildOtpBox(index)),
              ),

              // Inline Validation Error message below the OTP boxes
              if (_errorText != null) ...[
                const SizedBox(height: 12.0),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.0,
                    color: AuthTheme.errorRed,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32.0),

              // Verify Button
              CustomButton(
                label: config['buttonLabel'],
                isEnabled: _isButtonEnabled,
                isLoading: _isLoading,
                onPressed: _handleVerification,
              ),

              const SizedBox(height: 24.0),

              // Resend prompt at bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    config['resendPrompt'],
                    style: AuthTheme.bodyStyle,
                  ),
                  const SizedBox(width: 4.0),
                  GestureDetector(
                    onTap: _handleResend,
                    child: Text(
                      config['resendLink'],
                      style: const TextStyle(
                        fontFamily: AuthTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                        color: AuthTheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dynamic OTP Box styling and navigation
  Widget _buildOtpBox(int index) {
    final controller = _controllers[index];
    final focusNode = _focusNodes[index];
    final hasError = _errorText != null;
    final isFilled = controller.text.isNotEmpty;

    Color borderColors;
    if (hasError) {
      borderColors = AuthTheme.errorRed;
    } else if (focusNode.hasFocus || isFilled) {
      borderColors = AuthTheme.primary;
    } else {
      borderColors = AuthTheme.borderGrey;
    }

    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: RawKeyboardListener(
        focusNode: FocusNode(), // Temporary node to intercept key events
        onKey: (event) {
          if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (controller.text.isEmpty && index > 0) {
              // Move focus backwards on backspace if field is already empty
              _focusNodes[index - 1].requestFocus();
              _controllers[index - 1].clear();
            }
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLines: 1,
          maxLength: 1,
          showCursor: true,
          cursorColor: AuthTheme.primary,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontFamily: AuthTheme.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
            color: AuthTheme.textDark,
          ),
          decoration: InputDecoration(
            counterText: "",
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: borderColors, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: borderColors, width: 1.5),
            ),
          ),
          onChanged: (value) {
            setState(() {}); // Redraw borders on value change
            if (value.isNotEmpty) {
              if (index < 4) {
                // Focus next box on input
                _focusNodes[index + 1].requestFocus();
              } else {
                // Remove focus on last box entry
                focusNode.unfocus();
              }
            }
          },
        ),
      ),
    );
  }
}
