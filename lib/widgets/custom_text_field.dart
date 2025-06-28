import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(
        color: Colors.black87, // Explicit dark text color
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? label,
        labelStyle: TextStyle(
          color: Colors.grey[600], // Dark gray for label
        ),
        hintStyle: TextStyle(
          color: Colors.grey[500], // Light gray for hint
        ),
        prefixIcon: prefixIcon != null ? Icon(
          prefixIcon,
          color: Colors.grey[600], // Dark gray for prefix icon
        ) : null,
        suffixIcon: suffixIcon,
        counterText: '', // Hide character counter
      ),
    );
  }
} 