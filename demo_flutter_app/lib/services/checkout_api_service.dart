import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'supabase_store_service.dart';

class CheckoutApiService {
  const CheckoutApiService._();

  static bool get isConfigured => AppConfig.hasApiBaseUrl;

  static Future<ShippingQuote> quoteShipping({
    required String destinationCountry,
    required String currency,
    required List<CheckoutItemInput> items,
  }) async {
    final response = await _post(
      '/api/shipping/quote',
      body: {
        'destinationCountry': destinationCountry,
        'currency': currency,
        'items': items.map((item) => item.toJson()).toList(),
      },
      requiresAuth: false,
    );

    return ShippingQuote.fromJson(response);
  }

  static Future<CheckoutSession> initializeCheckout({
    required String currency,
    required List<CheckoutItemInput> items,
    required ShippingAddressInput shippingAddress,
  }) async {
    final response = await _post(
      '/api/checkout/initialize',
      body: {
        'currency': currency,
        'items': items.map((item) => item.toJson()).toList(),
        'shippingAddress': shippingAddress.toJson(),
      },
      requiresAuth: true,
    );

    return CheckoutSession.fromJson(response);
  }

  static Future<CheckoutVerification> verifyCheckout({
    required String reference,
  }) async {
    final response = await _post(
      '/api/checkout/verify',
      body: {'reference': reference},
      requiresAuth: true,
    );

    return CheckoutVerification.fromJson(response);
  }

  static Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    required bool requiresAuth,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'APP_API_BASE_URL is not configured. Add it in .env and rerun with --dart-define-from-file=.env.',
      );
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = SupabaseStoreService.currentAccessToken;
      if (token == null || token.isEmpty) {
        throw StateError('You must be signed in to complete checkout.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw StateError('Request timed out. Please check your connection and try again.');
    }

    final decoded = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'Request failed with status ${response.statusCode}.',
      );
    }

    return decoded;
  }

  static Map<String, dynamic> _decodeJson(String source) {
    if (source.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }
}

class CheckoutItemInput {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double weightKg;

  const CheckoutItemInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.weightKg = 0.35,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'weightKg': weightKg,
      };
}

class ShippingAddressInput {
  final String country;
  final String city;
  final String addressLine1;
  final String? addressLine2;
  final String? postalCode;

  const ShippingAddressInput({
    required this.country,
    required this.city,
    required this.addressLine1,
    this.addressLine2,
    this.postalCode,
  });

  Map<String, dynamic> toJson() => {
        'country': country,
        'city': city,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'postalCode': postalCode,
      };
}

class ShippingQuote {
  final String provider;
  final String service;
  final double amount;
  final String currency;
  final String? etaDays;
  final double packageWeightKg;

  const ShippingQuote({
    required this.provider,
    required this.service,
    required this.amount,
    required this.currency,
    required this.etaDays,
    required this.packageWeightKg,
  });

  factory ShippingQuote.fromJson(Map<String, dynamic> map) {
    return ShippingQuote(
      provider: map['provider']?.toString() ?? 'unknown',
      service: map['service']?.toString() ?? 'Standard',
      amount: _toDouble(map['amount']),
      currency: map['currency']?.toString() ?? 'USD',
      etaDays: map['etaDays']?.toString(),
      packageWeightKg: _toDouble(map['packageWeightKg']),
    );
  }
}

class CheckoutSession {
  final String orderId;
  final String orderNumber;
  final String authorizationUrl;
  final String reference;
  final double amount;
  final String currency;

  const CheckoutSession({
    required this.orderId,
    required this.orderNumber,
    required this.authorizationUrl,
    required this.reference,
    required this.amount,
    required this.currency,
  });

  factory CheckoutSession.fromJson(Map<String, dynamic> map) {
    return CheckoutSession(
      orderId: map['orderId']?.toString() ?? '',
      orderNumber: map['orderNumber']?.toString() ?? '',
      authorizationUrl: map['authorizationUrl']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      currency: map['currency']?.toString() ?? 'USD',
    );
  }
}

class CheckoutVerification {
  final bool paid;
  final String status;
  final String? reference;

  const CheckoutVerification({
    required this.paid,
    required this.status,
    required this.reference,
  });

  factory CheckoutVerification.fromJson(Map<String, dynamic> map) {
    return CheckoutVerification(
      paid: map['paid'] == true,
      status: map['status']?.toString() ?? 'unknown',
      reference: map['reference']?.toString(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
