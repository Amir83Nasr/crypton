import 'package:crypton_frontend/theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CustomInput extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final TextStyle? labelStyle;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final TextDirection? textDirection;

  const CustomInput({
    super.key,
    required this.controller,
    required this.labelText,
    this.labelStyle,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.errorText,
    this.textDirection = TextDirection.rtl,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textDirection: widget.textDirection,
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      style: appTextTheme.bodyMedium,
      validator: widget.validator,
      decoration: InputDecoration(
        isDense: true,
        labelText: widget.labelText,
        labelStyle: widget.labelStyle ?? appTextTheme.labelLarge,
        hintText: widget.hintText,
        errorText: widget.errorText, // 🔸 اضافه شده
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        suffixIcon:
            widget.obscureText
                ? IconButton(
                  icon: Icon(
                    _obscureText ? Iconsax.eye_slash : Iconsax.eye,
                    size: 24,
                  ),
                  onPressed: _toggleObscure,
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
