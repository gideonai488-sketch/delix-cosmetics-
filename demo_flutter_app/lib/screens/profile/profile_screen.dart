import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_settings_provider.dart';
import '../../services/supabase_store_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;
  User? _user;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _user = SupabaseStoreService.currentUser;
    if (SupabaseStoreService.isConfigured) {
      _authSubscription = SupabaseStoreService.authStateChanges.listen((event) {
        if (!mounted) return;
        setState(() => _user = event.session?.user);
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _user != null;
    final settings = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: isLoggedIn
          ? _buildProfile(context, settings)
          : _buildGuest(context, settings),
    );
  }

  Widget _buildGuest(BuildContext context, AppSettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                size: 54, color: AppColors.crimson),
          ),
          const SizedBox(height: 20),
          const Text('Welcome to Delix',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Sign in to track orders, save favourites\nand enjoy personalised shopping.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: SupabaseStoreService.isConfigured
                  ? () => _showAuthSheet(context)
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Set SUPABASE_URL and SUPABASE_ANON_KEY, then run with --dart-define-from-file=.env.'),
                        ),
                      ),
              child: const Text('Sign In / Create Account'),
            ),
          ),
          const SizedBox(height: 40),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          _settingRow(
            Icons.language,
            'Language',
            settings.languageLabel,
            onTap: () => _showLanguagePicker(context, settings),
          ),
          _settingRow(
            Icons.currency_exchange,
            'Currency',
            settings.currencyLabel,
            onTap: () => _showCurrencyPicker(context, settings),
          ),
          _settingRow(Icons.info_outline, 'About Delix', null),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, AppSettingsProvider settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.crimsonDark, AppColors.crimsonLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _user?.email ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Stats row
        Row(
          children: [
            _statCard('3', 'Orders'),
            const SizedBox(width: 10),
            _statCard('5', 'Wishlist'),
            const SizedBox(width: 10),
            _statCard('12', 'Reviews'),
          ],
        ),
        const SizedBox(height: 20),
        // Settings
        _sectionHeader('Account'),
        _menuItem(
          Icons.location_on_outlined,
          'Delivery Addresses',
          onTap: () => _openSimpleListPage(
            context,
            title: 'Delivery Addresses',
            items: const [
              'Home - 12 Oxford Street, Accra',
              'Office - Airport City, Accra',
            ],
            emptyState: 'No saved addresses yet.',
          ),
        ),
        _menuItem(
          Icons.payment_outlined,
          'Payment Methods',
          onTap: () => _openInfoPage(
            context,
            title: 'Payment Methods',
            body:
                'Card and wallet support is managed through your secure checkout provider. You can add support for saved cards from backend APIs.',
          ),
        ),
        _menuItem(
          Icons.favorite_outline,
          'Wishlist',
          onTap: () => _openSimpleListPage(
            context,
            title: 'Wishlist',
            items: const [
              'Hydrating Glow Serum',
              'Matte Velvet Lip Kit',
            ],
            emptyState: 'Your wishlist is empty for now.',
          ),
        ),
        _divider(),
        _sectionHeader('Preferences'),
        _switchItem(Icons.notifications_outlined, 'Push Notifications', _notificationsOn,
            (v) => setState(() => _notificationsOn = v)),
        _menuItem(
          Icons.language,
          'Language',
          trailing: settings.languageLabel,
          onTap: () => _showLanguagePicker(context, settings),
        ),
        _menuItem(Icons.currency_exchange, 'Currency',
            trailing: settings.currencyCodeLabel,
            onTap: () => _showCurrencyPicker(context, settings)),
        _divider(),
        _sectionHeader('Support'),
        _menuItem(
          Icons.help_outline,
          'Help Center',
          onTap: () => _openInfoPage(
            context,
            title: 'Help Center',
            body:
                'For account support, contact support@delix.app. For order issues, include your order number for faster help.',
          ),
        ),
        _menuItem(
          Icons.privacy_tip_outlined,
          'Privacy Policy',
          onTap: () => _openInfoPage(
            context,
            title: 'Privacy Policy',
            body:
                'Delix only stores essential account and order data required to deliver your purchases. You can request account deletion from support at any time.',
          ),
        ),
        _menuItem(
          Icons.info_outline,
          'About Delix',
          onTap: () => _openInfoPage(
            context,
            title: 'About Delix',
            body:
                'Delix is a beauty shopping experience with curated skincare, makeup, fragrance, and routine recommendations.',
          ),
        ),
        _divider(),
        _menuItem(Icons.logout, 'Sign Out',
            textColor: AppColors.crimson,
            onTap: () async {
              await SupabaseStoreService.signOut();
              if (!mounted) return;
              setState(() => _user = null);
            }),
        const SizedBox(height: 60),
      ],
    );
  }

  String get _displayName {
    final metadata = _user?.userMetadata;
    final fullName = metadata?['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    final email = _user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Delix Customer';
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.crimson)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedForeground,
              letterSpacing: 1.2)),
    );
  }

  Widget _menuItem(IconData icon, String label,
      {String? trailing,
      Color? textColor,
      VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: textColor ?? AppColors.foreground, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              color: textColor ?? AppColors.foreground,
              fontWeight: FontWeight.w500)),
      trailing: trailing != null
          ? Text(trailing,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.mutedForeground))
          : const Icon(Icons.chevron_right,
              color: AppColors.mutedForeground, size: 20),
      onTap: onTap,
    );
  }

  Widget _switchItem(IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: AppColors.foreground, size: 22),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.crimson,
      ),
    );
  }

  Widget _settingRow(
    IconData icon,
    String label,
    String? value, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.foreground, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: value != null
          ? Text(value,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.mutedForeground))
          : const Icon(Icons.chevron_right,
              color: AppColors.mutedForeground, size: 20),
      onTap: onTap,
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: AppColors.border),
      );

  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuthSheet(
        onAuthenticated: () {
          Navigator.pop(context);
          setState(() => _user = SupabaseStoreService.currentUser);
        },
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    AppSettingsProvider settings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Select Language',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ...AppLanguage.values.map(
                (language) => ListTile(
                  title: Text(_labelForLanguage(language)),
                  trailing: settings.language == language
                      ? const Icon(Icons.check, color: AppColors.crimson)
                      : null,
                  onTap: () async {
                    await settings.setLanguage(language);
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    AppSettingsProvider settings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Select Currency',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ...AppCurrency.values.map(
                (currency) => ListTile(
                  title: Text(_labelForCurrency(currency)),
                  trailing: settings.currency == currency
                      ? const Icon(Icons.check, color: AppColors.crimson)
                      : null,
                  onTap: () async {
                    await settings.setCurrency(currency);
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _labelForLanguage(AppLanguage value) => switch (value) {
        AppLanguage.system => 'System Default',
        AppLanguage.english => 'English',
        AppLanguage.french => 'Francais',
        AppLanguage.spanish => 'Espanol',
      };

  String _labelForCurrency(AppCurrency value) => switch (value) {
        AppCurrency.auto => 'Auto (Based on locale)',
        AppCurrency.ghs => 'GH₵ (Ghanaian Cedi)',
        AppCurrency.usd => r'$ (US Dollar)',
        AppCurrency.eur => 'EUR (Euro)',
        AppCurrency.gbp => 'GBP (British Pound)',
      };

  void _openInfoPage(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _InfoScreen(title: title, body: body),
      ),
    );
  }

  void _openSimpleListPage(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String emptyState,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SimpleListScreen(
          title: title,
          items: items,
          emptyState: emptyState,
        ),
      ),
    );
  }
}

class _AuthSheet extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const _AuthSheet({required this.onAuthenticated});

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  bool _isSignIn = true;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isSignIn ? 'Welcome back 👋' : 'Join Delix ✨',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _isSignIn
                  ? 'Sign in to your account'
                  : 'Create a free account',
              style: const TextStyle(
                  color: AppColors.mutedForeground, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppColors.mutedForeground, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock_outline,
                    color: AppColors.mutedForeground, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(
                  _isSubmitting
                      ? 'Please wait...'
                      : _isSignIn
                          ? 'Sign In'
                          : 'Create Account',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _isSignIn = !_isSignIn),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.mutedForeground),
                    children: [
                      TextSpan(
                          text: _isSignIn
                              ? "Don't have an account? "
                              : 'Already have an account? '),
                      TextSpan(
                        text: _isSignIn ? 'Sign up' : 'Sign in',
                        style: const TextStyle(
                            color: AppColors.crimson,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both email and password.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isSignIn) {
        await SupabaseStoreService.signIn(email: email, password: password);
        if (!mounted) return;
        widget.onAuthenticated();
      } else {
        final result = await SupabaseStoreService.signUp(
          email: email,
          password: password,
        );
        if (!mounted) return;

        if (result == SignUpResult.authenticated) {
          widget.onAuthenticated();
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. Check your email and verify your account before signing in.',
            ),
          ),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSignIn
                  ? 'Invalid credentials or email not verified yet. Check your inbox for verification mail, then try again.'
                  : error.message,
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _InfoScreen extends StatelessWidget {
  final String title;
  final String body;

  const _InfoScreen({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.foreground,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class _SimpleListScreen extends StatelessWidget {
  final String title;
  final List<String> items;
  final String emptyState;

  const _SimpleListScreen({
    required this.title,
    required this.items,
    required this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? Center(
              child: Text(
                emptyState,
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(items[index]),
                );
              },
            ),
    );
  }
}
