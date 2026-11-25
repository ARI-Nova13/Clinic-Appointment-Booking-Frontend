class ApiConstants {
  // Override per target, e.g. --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  static String? resolveMediaUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return null;
    if (uri.hasScheme) return uri.toString();
    return Uri.parse(baseUrl).resolve(value.trim()).toString();
  }
}
