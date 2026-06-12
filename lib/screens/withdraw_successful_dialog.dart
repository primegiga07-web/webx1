import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth_theme.dart';
import '../mock_data.dart';

class WithdrawSuccessfulDialog extends StatelessWidget {
  const WithdrawSuccessfulDialog({super.key});

  void _copyTxId(BuildContext context, String txId) {
    Clipboard.setData(ClipboardData(text: txId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction ID copied!'),
        backgroundColor: AuthTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txData = MockData.config['withdrawSuccess'] as Map<String, dynamic>;

    return Dialog(
      backgroundColor: const Color(0xFF1A1D21), // Dark Slate/Charcoal dialog background matching mockup
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Stack(
        children: [
          // Close Icon at Top-Right
          Positioned(
            top: 16.0,
            right: 16.0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: SvgPicture.asset(
                'assets/vectors/iconamoon_close-thin.svg',
                width: 28.0,
                height: 28.0,
                colorFilter: const ColorFilter.mode(Colors.white38, BlendMode.srcIn),
                placeholderBuilder: (context) => const Icon(
                  Icons.close_rounded,
                  size: 24.0,
                  color: Colors.white38,
                ),
              ),
            ),
          ),

          // Main Dialog Content
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20.0),

                // Success Illustration Tick Icon
                Center(
                  child: SvgPicture.asset(
                    'assets/vectors/Illustration - successful.svg',
                    width: 96.0,
                    height: 96.0,
                    placeholderBuilder: (context) => Container(
                      width: 96.0,
                      height: 96.0,
                      decoration: BoxDecoration(
                        color: AuthTheme.primary.withAlpha(30),
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
                ),
                const SizedBox(height: 24.0),

                // Title
                Text(
                  txData['heading'],
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 24.0,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),

                // Transaction ID Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      txData['transactionIdLabel'],
                      style: const TextStyle(
                        fontFamily: AuthTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                        color: Colors.white70,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copyTxId(context, txData['transactionId']),
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
                const SizedBox(height: 20.0),

                // Explorer Link Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      txData['explorerLinkLabel'],
                      style: const TextStyle(
                        fontFamily: AuthTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                        color: Colors.white70,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Blockchain Explorer...')),
                        );
                      },
                      child: SvgPicture.asset(
                        'assets/vectors/export.svg',
                        width: 20.0,
                        height: 20.0,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        placeholderBuilder: (context) => const Icon(
                          Icons.open_in_new_rounded,
                          size: 20.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36.0),

                // Close Button
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22262B), // Dark slate/grey button
                    foregroundColor: Colors.white,
                    elevation: 0.0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: Text(
                    txData['buttonLabel'],
                    style: const TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
