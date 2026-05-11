import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String extractIndianPhoneDigits(String? value) {
  if (value == null || value.trim().isEmpty) return '';

  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('91') && digits.length > 10) {
    digits = digits.substring(2);
  }
  if (digits.startsWith('0') && digits.length > 10) {
    digits = digits.substring(1);
  }
  if (digits.length > 10) {
    digits = digits.substring(digits.length - 10);
  }
  return digits;
}

String normalizeIndianPhone(String? value) {
  final digits = extractIndianPhoneDigits(value);
  if (digits.isEmpty) return '';
  return '+91$digits';
}

bool isValidIndianPhone(String? value, {bool allowEmpty = true}) {
  final digits = extractIndianPhoneDigits(value);
  if (digits.isEmpty) return allowEmpty;
  return digits.length == 10;
}

String? indianPhoneValidationMessage(
  String? value, {
  bool allowEmpty = true,
}) {
  if (isValidIndianPhone(value, allowEmpty: allowEmpty)) return null;
  return allowEmpty
      ? 'Please enter a valid 10-digit mobile number'
      : 'Mobile number must be 10 digits';
}
List<TextInputFormatter> indianPhoneInputFormatters() {
  return [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];
}

InputDecoration buildIndianPhoneDecoration(
  BuildContext context, {
  required InputDecoration decoration,
  String hintText = '9876543210',
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
  final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
  final borderColor =
      isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  return decoration.copyWith(
    hintText: hintText,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 10, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          'IN  +91',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    ),
  );
}
