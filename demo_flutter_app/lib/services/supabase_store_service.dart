import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/order_summary.dart';
import '../models/product.dart';

enum SignUpResult {
  authenticated,
  requiresEmailVerification,
}

class SupabaseStoreService {
  static bool get isConfigured => AppConfig.hasSupabaseConfig;

  static SupabaseClient get _client => Supabase.instance.client;

  static User? get currentUser =>
      isConfigured ? _client.auth.currentUser : null;

    static String? get currentAccessToken =>
      isConfigured ? _client.auth.currentSession?.accessToken : null;

  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.session != null || _client.auth.currentUser != null) {
      return SignUpResult.authenticated;
    }

    return SignUpResult.requiresEmailVerification;
  }

  static Future<void> resendSignUpVerification(String email) async {
    _ensureConfigured();
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  static Future<void> signOut() async {
    if (!isConfigured) return;
    await _client.auth.signOut();
  }

  static Future<List<Product>> fetchProducts() async {
    _ensureConfigured();
    try {
      final response = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

      final rows = response as List<dynamic>;
      return rows
        .map((row) => Product.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
    } catch (e, stack) {
      // In production, consider sending this to a remote logger or analytics
        if (kDebugMode) {
          print('[SupabaseStoreService.fetchProducts] ERROR: '
              '\u001b[31m$e\n$stack\u001b[0m');
        }
      rethrow;
    }
  }

  static Future<List<OrderSummary>> fetchOrdersForCurrentUser() async {
    _ensureConfigured();
    final user = currentUser;
    if (user == null) return const [];
    try {
      final response = await _client
        .from('orders')
        .select('id, order_number, created_at, total, status, order_items(product_name, quantity)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

      final rows = response as List<dynamic>;
      return rows
        .map((row) => OrderSummary.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
    } catch (e, stack) {
        if (kDebugMode) {
          print('[SupabaseStoreService.fetchOrdersForCurrentUser] ERROR: '
              '\u001b[31m$e\n$stack\u001b[0m');
        }
      rethrow;
    }
  }

  static void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError('Supabase is not configured.');
    }
  }
}