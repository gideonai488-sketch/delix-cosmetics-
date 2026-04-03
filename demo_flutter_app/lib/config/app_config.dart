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

  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  static bool get hasApiBaseUrl => apiBaseUrl.trim().isNotEmpty;
  static bool get hasPaystackPublicKey => paystackPublicKey.trim().isNotEmpty;
  static bool get hasSupabaseConfig =>
      _looksLikeHttpUrl(supabaseUrl) && supabaseAnonKey.trim().isNotEmpty;
  static bool get hasOpenAiKey => openAiApiKey.trim().isNotEmpty;

  static bool _looksLikeHttpUrl(String value) {
    final trimmed = value.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }
}
