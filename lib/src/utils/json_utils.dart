/// Safely reads a nested string from JSON maps.
String? jsonString(Map<String, dynamic>? json, String key) {
  final value = json?[key];
  if (value == null) return null;
  return value.toString();
}

/// Parses Unix epoch seconds into [DateTime].
DateTime dateTimeFromEpochSeconds(dynamic value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000,
        isUtc: true);
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
