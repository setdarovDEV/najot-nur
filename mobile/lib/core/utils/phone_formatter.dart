import 'package:flutter/services.dart';

/// Formats input as Uzbekistan phone: `+998 XX XXX XX XX`.
///
/// - Always keeps the `+998 ` prefix.
/// - Accepts only digits from the user.
/// - Inserts spaces after the 2nd, 5th, 8th, 10th digit of the local part
///   (i.e. 9 digits total, like 90 123 45 67).
class UzPhoneInputFormatter extends TextInputFormatter {
  UzPhoneInputFormatter({this.maxDigits = 9});

  /// Maximum local-part digits (after +998). Standard mobile is 9.
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep only digits from the user input (and the leading `+998` if user
    // pastes a full number, we keep its digits too).
    final raw = newValue.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    String local;
    if (digits.startsWith('998')) {
      local = digits.substring(3);
    } else {
      local = digits;
    }
    if (local.length > maxDigits) {
      local = local.substring(0, maxDigits);
    }

    final formatted = _format('+998 $local');

    // Cursor at the end so typing feels natural.
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _format(String input) {
    // input looks like '+998 90 123 45 67' or '+998 90...'
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '+998 ';
    if (digitsOnly.length <= 3) return '+998 ';

    final local = digitsOnly.substring(3); // drop the 998 prefix
    final buf = StringBuffer('+998 ');
    for (var i = 0; i < local.length; i++) {
      if (i == 2 || i == 5 || i == 7 || i == 9) buf.write(' ');
      buf.write(local[i]);
    }
    return buf.toString();
  }
}

/// Normalises a formatted phone back to E.164 (`+998XXXXXXXXX`).
String normaliseUzPhone(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('998') && digits.length >= 12) {
    return '+${digits.substring(0, 12)}';
  }
  if (digits.length >= 9) {
    return '+998${digits.substring(digits.length - 9)}';
  }
  return input.trim();
}
