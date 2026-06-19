extension StringExtensions on String {
  bool get isNullOrEmpty => trim().isEmpty;

  bool get isNotNullOrEmpty => !isNullOrEmpty;

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
