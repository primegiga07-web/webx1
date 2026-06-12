import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth_theme.dart';
import '../mock_data.dart';
import 'withdraw_successful_dialog.dart';

import '../components/login_required_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AuthTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileData = MockData.config['profile'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Title (Centered "Profile")
              Center(
                child: Text(
                  profileData['title'],
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 32.0,
                    color: AuthTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 32.0),

              if (!MockData.isLoggedIn)
                const LoginRequiredView()
              else ...[
                // Account Header
                Text(
                  profileData['accountLabel'],
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 18.0,
                    color: AuthTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Account Info Card (Username, Handle, Streak)
                _buildAccountCard(context, profileData),
                const SizedBox(height: 20.0),

                // Refer Earnings Card (Balance, Receive Button)
                _buildEarningsCard(context, profileData),
                const SizedBox(height: 24.0),

                // Menu List
                _buildMenuItem(
                  context,
                  label: profileData['menuReferLabel'],
                  icon: Icons.wallet_giftcard_rounded,
                  onTap: () {
                    Navigator.pushNamed(context, '/refer-and-earn');
                  },
                ),
                const SizedBox(height: 12.0),
                _buildMenuItem(
                  context,
                  label: profileData['menuHelpLabel'],
                  icon: Icons.help_outline_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Help Center...')),
                    );
                  },
                ),
                const SizedBox(height: 12.0),
                _buildMenuItem(
                  context,
                  label: 'Log Out',
                  icon: Icons.logout_rounded,
                  onTap: () {
                    MockData.isLoggedIn = false;
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                ),
                const SizedBox(height: 32.0),

                // Version Footer
                Center(
                  child: Text(
                    profileData['version'],
                    style: const TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.0,
                      color: AuthTheme.textGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate background matching mockup
        borderRadius: BorderRadius.circular(20.0),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar circle
              Container(
                width: 48.0,
                height: 48.0,
                decoration: const BoxDecoration(
                  color: Color(0xFF475569),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    data['username'].toString().substring(0, 3).toUpperCase(),
                    style: const TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              // Usernames
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['username'],
                      style: const TextStyle(
                        fontFamily: AuthTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      data['handle'],
                      style: const TextStyle(
                        fontFamily: AuthTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                        color: AuthTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Copy Button
              GestureDetector(
                onTap: () => _copyToClipboard(context, data['handle'], 'User handle copied!'),
                child: SvgPicture.asset(
                  'assets/vectors/copy.svg',
                  width: 20.0,
                  height: 20.0,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  placeholderBuilder: (context) => const Icon(
                    Icons.copy_rounded,
                    size: 20.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16.0),
          const Divider(color: Color(0xFF334155), height: 1.0, thickness: 1.0),
          const SizedBox(height: 16.0),

          // Streak Row
          Row(
            children: [
              SvgPicture.asset(
                'assets/vectors/Icon - Trend up.svg',
                width: 20.0,
                height: 20.0,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                placeholderBuilder: (context) => const Icon(
                  Icons.trending_up_rounded,
                  size: 20.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16.0),
              Text(
                data['streakLabel'],
                style: const TextStyle(
                  fontFamily: AuthTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context, Map<String, dynamic> data) {
    final List<dynamic> fetchCards = MockData.fetchCardsData['fetch_cards'] ?? [];
    final profileCard = fetchCards.firstWhere(
      (c) => c['id'] == 'profile_referearnings',
      orElse: () => null,
    );
    final String? thumbnailUrl = profileCard != null ? profileCard['thumbnailUrl'] : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D1F), // Slightly darker black/grey
        borderRadius: BorderRadius.circular(20.0),
        image: DecorationImage(
          image: (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              ? NetworkImage(thumbnailUrl) as ImageProvider
              : const AssetImage('assets/mockimages/FetchCard.png'),
          fit: BoxFit.cover,
          opacity: 0.04, // Render as a subtle textured pattern
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['referEarningsLabel'],
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.0,
                    color: AuthTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  data['balance'],
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 28.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  data['balanceChange'],
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.0,
                    color: Color(0xFF4ADE80), // Premium Green indicator
                  ),
                ),
              ],
            ),
          ),
          
          // Receive Button
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                barrierColor: Colors.black.withAlpha(160), // Dark modal backdrop
                builder: (context) => const WithdrawSuccessfulDialog(),
              );
            },
            borderRadius: BorderRadius.circular(24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/vectors/Icon - Receive.svg',
                    width: 16.0,
                    height: 16.0,
                    colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    placeholderBuilder: (context) => const Icon(
                      Icons.download_rounded,
                      size: 16.0,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    data['receiveButton'],
                    style: const TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    icon,
                    size: 20.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16.0),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.0,
                      color: AuthTheme.textDark,
                    ),
                  ),
                ),
                // Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.0,
                  color: AuthTheme.textGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
