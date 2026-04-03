import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../models/order_summary.dart';
import '../../services/supabase_store_service.dart';
import '../../theme/app_theme.dart';

enum _OrderStatus { processing, shipped, delivered, cancelled }

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderSummary>> _ordersFuture;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _ordersFuture = Future.value(const <OrderSummary>[]);
    if (SupabaseStoreService.isConfigured &&
        SupabaseStoreService.currentUser != null) {
      _ordersFuture = _loadOrders();
    }

    if (SupabaseStoreService.isConfigured) {
      _authSubscription = SupabaseStoreService.authStateChanges.listen((_) {
        if (!mounted) return;
        setState(() {
          if (SupabaseStoreService.currentUser == null) {
            _ordersFuture = Future.value(const <OrderSummary>[]);
            return;
          }
          _ordersFuture = _loadOrders();
        });
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<List<OrderSummary>> _loadOrders() async {
    if (!SupabaseStoreService.isConfigured ||
        SupabaseStoreService.currentUser == null) {
      return const <OrderSummary>[];
    }

    return SupabaseStoreService.fetchOrdersForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseStoreService.isConfigured) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('My Orders')),
        body: _buildMessage(
          icon: Icons.settings_ethernet,
          title: 'Supabase setup required',
          subtitle:
              'Add SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define-from-file=.env and relaunch the app.',
        ),
      );
    }

    if (SupabaseStoreService.isConfigured &&
        SupabaseStoreService.currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('My Orders')),
        body: _buildMessage(
          icon: Icons.lock_outline,
          title: 'Sign in to see your orders',
          subtitle: 'Your order history will appear here after authentication.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders')),
      body: FutureBuilder<List<OrderSummary>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.crimson),
            );
          }

          if (snapshot.hasError) {
            return _buildMessage(
              icon: Icons.receipt_long_outlined,
              title: 'Unable to load orders',
              subtitle: 'Check your Supabase tables and try again.',
            );
          }

          final orders = snapshot.data ?? const <OrderSummary>[];
          if (orders.isEmpty) return _buildEmpty();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              child: Icon(icon, size: 48, color: AppColors.crimson),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ],
        ),
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
            child: const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.crimson),
          ),
          const SizedBox(height: 20),
          const Text('No orders yet',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your order history will appear here.',
              style: TextStyle(color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderSummary order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                _StatusBadge(status: _statusFromString(order.status)),
              ],
            ),
            const SizedBox(height: 8),
              Text(_formatDate(order.createdAt),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mutedForeground)),
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 5, color: AppColors.mutedForeground),
                      const SizedBox(width: 8),
                      Text(item,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.foreground)),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.mutedForeground)),
                Text(settings.formatMoney(order.total, context),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.crimson)),
              ],
            ),
            if (_statusFromString(order.status) == _OrderStatus.shipped) ...[
              const SizedBox(height: 12),
              _buildTrackingBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.border),
        const SizedBox(height: 8),
        const Text('📦 Order shipped – on its way to you!',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.foreground,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.65,
          backgroundColor: AppColors.muted,
          color: AppColors.crimson,
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ordered', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
            Text('Processing', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
            Text('Shipped', style: TextStyle(fontSize: 10, color: AppColors.crimson, fontWeight: FontWeight.bold)),
            Text('Delivered', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
          ],
        ),
      ],
    );
  }
}

_OrderStatus _statusFromString(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'shipped':
      return _OrderStatus.shipped;
    case 'delivered':
      return _OrderStatus.delivered;
    case 'cancelled':
      return _OrderStatus.cancelled;
    default:
      return _OrderStatus.processing;
  }
}

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

class _StatusBadge extends StatelessWidget {
  final _OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case _OrderStatus.processing:
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF856404);
        label = 'Processing';
        break;
      case _OrderStatus.shipped:
        bg = const Color(0xFFD1ECF1);
        fg = const Color(0xFF0C5460);
        label = 'Shipped';
        break;
      case _OrderStatus.delivered:
        bg = const Color(0xFFD4EDDA);
        fg = const Color(0xFF155724);
        label = 'Delivered';
        break;
      case _OrderStatus.cancelled:
        bg = const Color(0xFFF8D7DA);
        fg = const Color(0xFF721C24);
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
