import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth_theme.dart';
import '../mock_data.dart';
import '../components/circular_back_button.dart';
import '../components/login_required_view.dart';

class ReferandEarnScreen extends StatelessWidget {
  const ReferandEarnScreen({super.key});

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard!'),
        backgroundColor: AuthTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!MockData.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: const BackButton(color: AuthTheme.textDark),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: LoginRequiredView(),
            ),
          ),
        ),
      );
    }

    final List<dynamic> fetchCards = MockData.fetchCardsData['fetch_cards'] ?? [];
    final referCard = fetchCards.firstWhere(
      (c) => c['id'] == 'refer_earn',
      orElse: () => null,
    );
    final String? thumbnailUrl = referCard != null ? referCard['thumbnailUrl'] : null;

    final referData = MockData.config['referAndEarn'] as Map<String, dynamic>;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top-Attached Image Block (three sides attached, downside free)
            Stack(
              children: [
                Container(
                  height: 200.0 + statusBarHeight,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24.0),
                      bottomRight: Radius.circular(24.0),
                    ),
                    image: DecorationImage(
                      image: (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                          ? NetworkImage(thumbnailUrl) as ImageProvider
                          : const AssetImage('assets/mockimages/FetchCard.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Overlayed Back Button at Top Left (offset by status bar height)
                Positioned(
                  top: statusBarHeight + 12.0,
                  left: 16.0,
                  child: CircularBackButton(
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Padded Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Share Promo Code Section
                  Text(
                    referData['sharePrompt'],
                    style: const TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 18.0,
                      color: AuthTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  _buildPromoCodeBox(context, referData),
                  const SizedBox(height: 28.0),

                  // How Referral works?
                  Text(
                    referData['howItWorksHeading'],
                    style: const TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 18.0,
                      color: AuthTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _buildReferralSteps(),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeBox(BuildContext context, Map<String, dynamic> data) {
    final code = data['promoCode'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E004B),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFF3B006F), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          Text(
            data['codeInstruction'],
            style: TextStyle(
              fontFamily: AuthTheme.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 12.0,
              color: Colors.white.withAlpha(180),
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontFamily: AuthTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 28.0,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 20.0),
              GestureDetector(
                onTap: () => _copyCode(context, code),
                child: SvgPicture.asset(
                  'assets/vectors/copy.svg',
                  width: 24.0,
                  height: 24.0,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  placeholderBuilder: (context) => const Icon(
                    Icons.copy_rounded,
                    size: 24.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralSteps() {
    return Column(
      children: [
        _buildStepItem(
          stepNumber: "1",
          title: "Share your invite link/code",
          description: "Send your referral code to your friends and family.",
          icon: Icons.share_rounded,
        ),
        const SizedBox(height: 16.0),
        _buildStepItem(
          stepNumber: "2",
          title: "Friend joins & completes signup",
          description: "Your friend uses your code during signup and completes email verification.",
          icon: Icons.person_add_alt_rounded,
        ),
        const SizedBox(height: 16.0),
        _buildStepItem(
          stepNumber: "3",
          title: "Claim rewards instantly",
          description: "Once verified, both you and your friend receive coins. exchange them for real earnings!",
          icon: Icons.emoji_events_rounded,
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.0,
          height: 32.0,
          decoration: const BoxDecoration(
            color: AuthTheme.greyBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontFamily: AuthTheme.fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 14.0,
                color: AuthTheme.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AuthTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0,
                  color: AuthTheme.textDark,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: AuthTheme.fontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.0,
                  color: AuthTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16.0),
        Icon(icon, size: 24.0, color: AuthTheme.primary.withAlpha(200)),
      ],
    );
  }
}
