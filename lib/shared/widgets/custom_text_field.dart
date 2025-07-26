// lib/shared/widgets/custom_text_field.dart

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool isObscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isEnabled; // <-- 1. ADD THIS NEW PROPERTY

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.isObscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isEnabled = true, // <-- 2. ADD IT TO THE CONSTRUCTOR WITH A DEFAULT VALUE
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      validator: validator,
      enabled: isEnabled, // <-- 3. USE THE PROPERTY HERE
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: Theme.of(context).inputDecorationTheme.border,
        focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
      ),
    );
  }
}