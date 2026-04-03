class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'APP_API_BASE_URL',
    defaultValue: '',
  );

  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: '',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get hasApiBaseUrl => apiBaseUrl.trim().isNotEmpty;
  static bool get hasPaystackPublicKey => paystackPublicKey.trim().isNotEmpty;
  static bool get hasSupabaseConfig =>
      _looksLikeHttpUrl(supabaseUrl) && supabaseAnonKey.trim().isNotEmpty;
  static bool get hasAiBackend => hasApiBaseUrl;

  static bool _looksLikeHttpUrl(String value) {
    final trimmed = value.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }
}
