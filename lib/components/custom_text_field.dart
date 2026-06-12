import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth_theme.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final String? errorText;
  final Widget? bottomRightWidget;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.errorText,
    this.bottomRightWidget,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Input Label
        Text(
          widget.label,
          style: AuthTheme.inputLabelStyle,
        ),
        const SizedBox(height: 8.0),
        
        // Input Field
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: AuthTheme.inputTextStyle,
          decoration: InputDecoration(
            hintText: widget.hint,
            // Custom border overriding depending on error state
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: hasError ? AuthTheme.errorRed : AuthTheme.borderGrey,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: hasError ? AuthTheme.errorRed : AuthTheme.borderActive,
                width: 1.5,
              ),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: SvgPicture.asset(
                      _obscureText
                          ? 'assets/vectors/eye_hidden.svg'
                          : 'assets/vectors/eye_visible.svg',
                      width: 22.0,
                      height: 22.0,
                      // Fallback icons if SVGs aren't loaded or throw an exception
                      placeholderBuilder: (context) => Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AuthTheme.textGrey.withAlpha(153),
                        size: 22.0,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),

        // Bottom widgets (Error message on left, dynamic widget on right)
        if (hasError || widget.bottomRightWidget != null) ...[
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: hasError
                    ? Text(
                        widget.errorText!,
                        style: const TextStyle(
                          fontFamily: AuthTheme.fontFamily,
                          fontWeight: FontWeight.w500, // Medium
                          fontSize: 13.0,
                          color: AuthTheme.errorRed,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (widget.bottomRightWidget != null) widget.bottomRightWidget!,
            ],
          ),
        ],
      ],
    );
  }
}
