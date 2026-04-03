import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  system,
  english,
  french,
  spanish,
}

enum AppCurrency {
  auto,
  ghs,
  usd,
  eur,
  gbp,
}

class AppSettingsProvider extends ChangeNotifier {
  static const _languageKey = 'app.language';
  static const _currencyKey = 'app.currency';

  AppLanguage _language = AppLanguage.system;
  AppCurrency _currency = AppCurrency.auto;

  AppLanguage get language => _language;
  AppCurrency get currency => _currency;

  Locale? get localeOverride => switch (_language) {
        AppLanguage.system => null,
        AppLanguage.english => const Locale('en'),
        AppLanguage.french => const Locale('fr'),
        AppLanguage.spanish => const Locale('es'),
      };

  String get languageLabel => switch (_language) {
        AppLanguage.system => 'System Default',
        AppLanguage.english => 'English',
        AppLanguage.french => 'Francais',
        AppLanguage.spanish => 'Espanol',
      };

  String get currencyLabel => switch (_currency) {
        AppCurrency.auto => 'Auto',
        AppCurrency.ghs => 'GH₵ (Ghanaian Cedi)',
        AppCurrency.usd => r'$ (US Dollar)',
        AppCurrency.eur => 'EUR (Euro)',
        AppCurrency.gbp => 'GBP (British Pound)',
      };

  String get currencyCodeLabel => switch (_currency) {
        AppCurrency.auto => 'Auto',
        AppCurrency.ghs => 'GHS',
        AppCurrency.usd => 'USD',
        AppCurrency.eur => 'EUR',
        AppCurrency.gbp => 'GBP',
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageRaw = prefs.getString(_languageKey);
    final currencyRaw = prefs.getString(_currencyKey);

    _language = AppLanguage.values.firstWhere(
      (value) => value.name == languageRaw,
      orElse: () => AppLanguage.system,
    );
    _currency = AppCurrency.values.firstWhere(
      (value) => value.name == currencyRaw,
      orElse: () => AppCurrency.auto,
    );

    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (_language == value) return;
    _language = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value.name);
  }

  Future<void> setCurrency(AppCurrency value) async {
    if (_currency == value) return;
    _currency = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, value.name);
  }

  String formatMoney(double amount, BuildContext context) {
    final locale = localeOverride ?? Localizations.maybeLocaleOf(context) ??
        WidgetsBinding.instance.platformDispatcher.locale;
    final code = _currencyCodeForLocale(locale);
    final format = NumberFormat.simpleCurrency(
      name: code,
      locale: _intlLocaleTag(locale),
    );
    return format.format(amount);
  }

  String resolveCurrencyCode(BuildContext context) {
    final locale = localeOverride ?? Localizations.maybeLocaleOf(context) ??
        WidgetsBinding.instance.platformDispatcher.locale;
    return _currencyCodeForLocale(locale);
  }

  String _currencyCodeForLocale(Locale locale) {
    if (_currency != AppCurrency.auto) {
      return switch (_currency) {
        AppCurrency.auto => 'USD',
        AppCurrency.ghs => 'GHS',
        AppCurrency.usd => 'USD',
        AppCurrency.eur => 'EUR',
        AppCurrency.gbp => 'GBP',
      };
    }

    final country = locale.countryCode?.toUpperCase();
    switch (country) {
      case 'GH':
        return 'GHS';
      case 'GB':
        return 'GBP';
      case 'FR':
      case 'DE':
      case 'IT':
      case 'ES':
      case 'PT':
      case 'NL':
      case 'BE':
      case 'IE':
        return 'EUR';
      case 'US':
      default:
        return 'USD';
    }
  }

  String _intlLocaleTag(Locale locale) {
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}_$country';
  }
}
