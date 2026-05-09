import 'package:flutter/material.dart';

class TextEntry extends StatelessWidget {
  const TextEntry({
    required this.label,
    this.placeholder,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.minLines,
    this.maxLines,
    super.key,
  });

  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final isMultiline = label.contains('Notes') || label.contains('Specializations');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        minLines: minLines ?? (isMultiline ? 3 : 1),
        maxLines: obscureText ? 1 : maxLines ?? (isMultiline ? 3 : 1),
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF0B63C9), width: 1.4),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
