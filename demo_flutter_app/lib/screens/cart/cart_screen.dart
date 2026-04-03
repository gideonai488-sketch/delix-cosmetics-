import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/checkout_api_service.dart';
import '../../services/supabase_store_service.dart';
import '../../theme/app_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final items = cart.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _showClearDialog(context, cart),
              child: const Text('Clear',
                  style: TextStyle(color: AppColors.crimson)),
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _CartItemTile(
                        item: item,
                        cart: cart,
                        settings: settings,
                      );
                    },
                  ),
                ),
                _buildOrderSummary(context, cart, settings),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 48, color: AppColors.crimson),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some beautiful products\nto get started!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    CartProvider cart,
    AppSettingsProvider settings,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', settings.formatMoney(cart.subtotal, context)),
          const SizedBox(height: 6),
          _summaryRow(
            'Delivery',
            cart.deliveryFee == 0
                ? 'FREE'
                : settings.formatMoney(cart.deliveryFee, context),
            valueColor: cart.deliveryFee == 0 ? Colors.green : null,
          ),
          if (cart.deliveryFee == 0) ...[
            const SizedBox(height: 4),
            const Text('🎉 You qualify for free delivery!',
                style: TextStyle(fontSize: 11, color: Colors.green)),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Add ${settings.formatMoney(200 - cart.subtotal, context)} more for free delivery',
              style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.border),
          ),
            _summaryRow('Total', settings.formatMoney(cart.total, context),
              isBold: true, valueColor: AppColors.crimson),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () => _showCheckout(context, cart, settings),
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedForeground,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? AppColors.foreground)),
      ],
    );
  }

  void _showClearDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.crimson)),
          ),
        ],
      ),
    );
  }

  void _showCheckout(
    BuildContext context,
    CartProvider cart,
    AppSettingsProvider settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSheet(
        cart: cart,
        settings: settings,
      ),
    );
  }
}

class _CheckoutSheet extends StatefulWidget {
  final CartProvider cart;
  final AppSettingsProvider settings;

  const _CheckoutSheet({
    required this.cart,
    required this.settings,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _countryController = TextEditingController(text: 'GH');
  final _cityController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _postalCodeController = TextEditingController();

  ShippingQuote? _shippingQuote;
  bool _isLoadingQuote = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = widget.settings.resolveCurrencyCode(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Checkout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Currency: $currencyCode',
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _countryController,
                label: 'Country Code (ISO-2)',
                hint: 'GH, US, GB, FR',
                maxLength: 2,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _cityController,
                label: 'City',
                hint: 'Accra',
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _address1Controller,
                label: 'Address Line 1',
                hint: 'Street and house number',
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _address2Controller,
                label: 'Address Line 2 (optional)',
                hint: 'Apartment, suite, landmark',
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _postalCodeController,
                label: 'Postal Code (optional)',
                hint: '00233',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingQuote ? null : _fetchShippingQuote,
                      icon: _isLoadingQuote
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.local_shipping_outlined),
                      label: const Text('Get Shipping Quote'),
                    ),
                  ),
                ],
              ),
              if (_shippingQuote != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shipping: ${_shippingQuote!.service} (${_shippingQuote!.provider.toUpperCase()})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fee: ${widget.settings.formatMoney(_shippingQuote!.amount, context)}',
                        style: const TextStyle(color: AppColors.crimson),
                      ),
                      if ((_shippingQuote!.etaDays ?? '').isNotEmpty)
                        Text(
                          'ETA: ${_shippingQuote!.etaDays}',
                          style: const TextStyle(color: AppColors.mutedForeground),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _summaryRow(
                'Items total',
                widget.settings.formatMoney(widget.cart.subtotal, context),
              ),
              const SizedBox(height: 6),
              _summaryRow(
                'Shipping',
                widget.settings
                    .formatMoney(_shippingQuote?.amount ?? 0, context),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppColors.border),
              ),
              _summaryRow(
                'Grand total',
                widget.settings.formatMoney(
                  widget.cart.subtotal + (_shippingQuote?.amount ?? 0),
                  context,
                ),
                isBold: true,
              ),
              const SizedBox(height: 16),
              if (!SupabaseStoreService.isConfigured ||
                  SupabaseStoreService.currentUser == null)
                const Text(
                  'Sign in first to complete checkout.',
                  style: TextStyle(color: AppColors.crimson),
                ),
              if (!AppConfig.hasApiBaseUrl)
                const Text(
                  'Set APP_API_BASE_URL to your backend URL in .env to enable checkout.',
                  style: TextStyle(color: AppColors.crimson),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _startCheckout,
                  child: Text(_isSubmitting ? 'Processing...' : 'Pay with Paystack'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? AppColors.crimson : AppColors.foreground,
          ),
        ),
      ],
    );
  }

  Future<void> _fetchShippingQuote() async {
    final country = _countryController.text.trim().toUpperCase();
    if (country.length != 2) {
      _showError('Enter a valid 2-letter destination country code.');
      return;
    }

    final currencyCode = widget.settings.resolveCurrencyCode(context);
    final items = widget.cart.items
        .map(
          (item) => CheckoutItemInput(
            productId: item.product.id,
            productName: item.product.name,
            quantity: item.quantity,
            unitPrice: item.product.price,
          ),
        )
        .toList();

    setState(() => _isLoadingQuote = true);
    try {
      final quote = await CheckoutApiService.quoteShipping(
        destinationCountry: country,
        currency: currencyCode,
        items: items,
      );
      if (!mounted) return;
      setState(() => _shippingQuote = quote);
    } on StateError catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Could not fetch shipping quote. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingQuote = false);
      }
    }
  }

  Future<void> _startCheckout() async {
    if (!SupabaseStoreService.isConfigured || SupabaseStoreService.currentUser == null) {
      _showError('Please sign in before checkout.');
      return;
    }

    if (!CheckoutApiService.isConfigured) {
      _showError('APP_API_BASE_URL is missing in your .env configuration.');
      return;
    }

    final country = _countryController.text.trim().toUpperCase();
    final city = _cityController.text.trim();
    final address1 = _address1Controller.text.trim();
    if (country.length != 2 || city.isEmpty || address1.isEmpty) {
      _showError('Country, city, and address line 1 are required.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final currencyCode = widget.settings.resolveCurrencyCode(context);
      final items = widget.cart.items
          .map(
            (item) => CheckoutItemInput(
              productId: item.product.id,
              productName: item.product.name,
              quantity: item.quantity,
              unitPrice: item.product.price,
            ),
          )
          .toList();

      final session = await CheckoutApiService.initializeCheckout(
        currency: currencyCode,
        items: items,
        shippingAddress: ShippingAddressInput(
          country: country,
          city: city,
          addressLine1: address1,
          addressLine2: _address2Controller.text.trim().isEmpty
              ? null
              : _address2Controller.text.trim(),
          postalCode: _postalCodeController.text.trim().isEmpty
              ? null
              : _postalCodeController.text.trim(),
        ),
      );

      if (session.authorizationUrl.isEmpty) {
        throw StateError('Checkout could not start. Missing Paystack URL.');
      }

      final launched = await launchUrl(
        Uri.parse(session.authorizationUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw StateError('Could not open payment page. Please try again.');
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Complete Payment'),
            content: const Text(
              'Finish payment in the opened page, then tap Verify Payment.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Verify Payment'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      final verify = await CheckoutApiService.verifyCheckout(
        reference: session.reference,
      );

      if (!verify.paid) {
        _showError('Payment is not confirmed yet. Please try verification again.');
        return;
      }

      widget.cart.clear();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified. Your order is now processing.'),
          backgroundColor: Colors.green,
        ),
      );
    } on StateError catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Checkout failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  final CartProvider cart;
  final AppSettingsProvider settings;

  const _CartItemTile({
    required this.item,
    required this.cart,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: CachedNetworkImage(
              imageUrl: item.product.imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(
                width: 90,
                height: 90,
                color: AppColors.muted,
                child: const Icon(Icons.spa_outlined,
                    color: AppColors.mutedForeground),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.formatMoney(item.product.price, context),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.crimson),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _stepper(Icons.remove,
                          () => cart.decrementItem(item.product.id)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('${item.quantity}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      _stepper(Icons.add, () => cart.addItem(item.product)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  settings.formatMoney(item.subtotal, context),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepper(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: Icon(icon, size: 16),
      ),
    );
  }
}
