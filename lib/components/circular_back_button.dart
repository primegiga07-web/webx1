import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth_theme.dart';

class CircularBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CircularBackButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
      decoration: const BoxDecoration(
        color: AuthTheme.greyBg,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24.0),
          onTap: onPressed ?? () => Navigator.maybePop(context),
          child: Center(
            child: SvgPicture.asset(
              'assets/vectors/chevron_left.svg',
              width: 18.0,
              height: 18.0,
              colorFilter: const ColorFilter.mode(AuthTheme.textDark, BlendMode.srcIn),
              placeholderBuilder: (context) => const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.0,
                color: AuthTheme.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
