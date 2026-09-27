import '../../i18n/tr.dart';

class FormValidators {
  FormValidators._();

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return tr('{0} is required', [fieldName]);
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('Email is required');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return tr('Enter a valid email address');
    }

    return null;
  }

  static String? minLength(String? value, int min, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return tr('{0} is required', [fieldName]);
    }

    if (value.trim().length < min) {
      return tr('{0} must be at least {1} characters', [fieldName, min]);
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('Phone number is required');
    }

    final phoneRegex = RegExp(r'^[0-9+\-\s()]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return tr('Enter a valid phone number');
    }

    return null;
  }

  static String? ssnLast4(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('SSN is required');
    }

    final digits = value.trim();
    if (digits.length != 4 || int.tryParse(digits) == null) {
      return tr('Enter the last 4 digits of your SSN');
    }

    return null;
  }
}
