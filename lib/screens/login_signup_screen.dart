import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth_theme.dart';
import '../mock_data.dart';
import '../components/custom_text_field.dart';
import '../components/custom_button.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupConfirmPasswordController = TextEditingController();
  final TextEditingController _signupReferralController = TextEditingController();

  // Dynamic States
  bool _isLoginLoading = false;
  bool _isSignupLoading = false;
  String? _loginPasswordError;
  String? _signupError;

  // Active state flags
  bool _isLoginButtonEnabled = false;
  bool _isSignupButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Listeners for enabling/disabling buttons dynamically
    _loginEmailController.addListener(_validateLoginFields);
    _loginPasswordController.addListener(_validateLoginFields);

    _signupEmailController.addListener(_validateSignupFields);
    _signupPasswordController.addListener(_validateSignupFields);
    _signupConfirmPasswordController.addListener(_validateSignupFields);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // Clear errors on tab change
      setState(() {
        _loginPasswordError = null;
        _signupError = null;
      });
    }
  }

  void _validateLoginFields() {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    setState(() {
      _isLoginButtonEnabled = email.isNotEmpty && password.isNotEmpty;
    });
  }

  void _validateSignupFields() {
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text;
    final confirmPassword = _signupConfirmPasswordController.text;
    setState(() {
      _isSignupButtonEnabled = email.isNotEmpty && password.isNotEmpty && confirmPassword.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _signupReferralController.dispose();
    super.dispose();
  }

  // Action methods
  Future<void> _handleLogin() async {
    if (!_isLoginButtonEnabled || _isLoginLoading) return;

    setState(() {
      _isLoginLoading = true;
      _loginPasswordError = null;
    });

    final email = _loginEmailController.text;
    final password = _loginPasswordController.text;

    final responseStr = await MockData.login(email, password);
    final response = json.decode(responseStr);

    setState(() {
      _isLoginLoading = false;
    });

    if (response['success'] == true) {
      // Login Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Login Successful!'),
            backgroundColor: AuthTheme.primary,
          ),
        );
        // Print JWT Token
        debugPrint("User Token: ${response['token']}");
        // Navigate to Main Shell
        Navigator.pushReplacementNamed(context, '/main-shell');
      }
    } else {
      // Display error
      setState(() {
        _loginPasswordError = response['error'] ?? 'Login failed';
      });
    }
  }

  Future<void> _handleSignup() async {
    if (!_isSignupButtonEnabled || _isSignupLoading) return;

    setState(() {
      _isSignupLoading = true;
      _signupError = null;
    });

    final email = _signupEmailController.text;
    final password = _signupPasswordController.text;
    final confirmPassword = _signupConfirmPasswordController.text;
    final referral = _signupReferralController.text;

    final responseStr = await MockData.register(email, password, confirmPassword, referralCode: referral);
    final response = json.decode(responseStr);

    setState(() {
      _isSignupLoading = false;
    });

    if (response['success'] == true) {
      if (mounted) {
        // Navigate to OTP Screen
        Navigator.pushNamed(
          context,
          '/check-email',
          arguments: {
            'email': email,
            'isSignUp': true,
          },
        );
      }
    } else {
      setState(() {
        _signupError = response['error'] ?? 'Signup failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = MockData.config;
    final common = config['common'] as Map<String, dynamic>;
    final login = config['login'] as Map<String, dynamic>;
    final signup = config['signup'] as Map<String, dynamic>;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar (WebX Logo & Skip Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60.0), // Spacer to balance layout
                  Text(
                    login['heading'],
                    style: AuthTheme.titleStyle,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/main-shell');
                    },
                    child: Row(
                      children: [
                        Text(
                          common['skip'],
                          style: const TextStyle(
                            fontFamily: AuthTheme.fontFamily,
                            fontWeight: FontWeight.w600, // SemiBold
                            fontSize: 16.0,
                            color: AuthTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        SvgPicture.asset(
                          'assets/vectors/arrow_right.svg',
                          width: 14.0,
                          height: 14.0,
                          colorFilter: const ColorFilter.mode(AuthTheme.primary, BlendMode.srcIn),
                          placeholderBuilder: (context) => const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14.0,
                            color: AuthTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Animated Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AuthTheme.primary,
                  indicatorWeight: 2.5,
                  labelColor: AuthTheme.primary,
                  unselectedLabelColor: AuthTheme.textGrey,
                  labelStyle: const TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w600, // SemiBold
                    fontSize: 16.0,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w500, // Medium
                    fontSize: 16.0,
                  ),
                  tabs: [
                    Tab(text: login['tabLabel']),
                    Tab(text: signup['tabLabel']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Tab View Content (Expands to fill remaining screen space)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Login Tab
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildLoginForm(login, common),
                  ),
                  // Signup Tab
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildSignupForm(signup, common),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(Map<String, dynamic> loginData, Map<String, dynamic> commonData) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16.0),
              CustomTextField(
                label: loginData['emailLabel'],
                hint: loginData['emailPlaceholder'],
                controller: _loginEmailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20.0),
              CustomTextField(
                label: loginData['passwordLabel'],
                hint: loginData['passwordPlaceholder'],
                controller: _loginPasswordController,
                isPassword: true,
                errorText: _loginPasswordError,
                bottomRightWidget: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: Text(
                    loginData['forgotPassword'],
                    style: const TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                      color: AuthTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30.0),
              CustomButton(
                label: loginData['buttonLabel'],
                isEnabled: _isLoginButtonEnabled,
                isLoading: _isLoginLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 24.0),
              _buildDivider(commonData['or']),
              const SizedBox(height: 24.0),
              GoogleButton(
                label: 'Login with Google',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connecting to Google Login...')),
                  );
                },
              ),
              const Spacer(),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loginData['noAccountText'],
                    style: AuthTheme.bodyStyle,
                  ),
                  const SizedBox(width: 4.0),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Text(
                      loginData['signupLink'],
                      style: const TextStyle(
                        fontFamily: AuthTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                        color: AuthTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(Map<String, dynamic> signupData, Map<String, dynamic> commonData) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16.0),
              CustomTextField(
                label: signupData['emailLabel'],
                hint: signupData['emailPlaceholder'],
                controller: _signupEmailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),
              CustomTextField(
                label: signupData['passwordLabel'],
                hint: signupData['passwordPlaceholder'],
                controller: _signupPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 16.0),
              CustomTextField(
                label: signupData['confirmPasswordLabel'],
                hint: signupData['confirmPasswordPlaceholder'],
                controller: _signupConfirmPasswordController,
                isPassword: true,
                errorText: _signupError,
              ),
              const SizedBox(height: 16.0),
              CustomTextField(
                label: signupData['referralLabel'],
                hint: signupData['referralPlaceholder'],
                controller: _signupReferralController,
                isPassword: true,
              ),
              const SizedBox(height: 24.0),
              CustomButton(
                label: signupData['buttonLabel'],
                isEnabled: _isSignupButtonEnabled,
                isLoading: _isSignupLoading,
                onPressed: _handleSignup,
              ),
              const SizedBox(height: 20.0),
              _buildDivider(commonData['or']),
              const SizedBox(height: 20.0),
              GoogleButton(
                label: 'Sign up with Google',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connecting to Google Signup...')),
                  );
                },
              ),
              const Spacer(),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    signupData['haveAccountText'],
                    style: AuthTheme.bodyStyle,
                  ),
                  const SizedBox(width: 4.0),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: Text(
                      signupData['loginLink'],
                      style: const TextStyle(
                        fontFamily: AuthTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                        color: AuthTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(String centerText) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            centerText,
            style: const TextStyle(
              fontFamily: AuthTheme.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
              color: AuthTheme.textGrey,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
        ),
      ],
    );
  }
}
