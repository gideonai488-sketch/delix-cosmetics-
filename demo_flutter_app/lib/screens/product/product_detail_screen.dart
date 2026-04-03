import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cart = context.watch<CartProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final inCart = cart.containsProduct(p.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.foreground,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: AppColors.foreground),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: p.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.muted,
                      child: const Icon(Icons.spa_outlined,
                          size: 80, color: AppColors.mutedForeground),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          p.category.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.crimson,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(p.name,
                          style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      // Rating
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: p.rating,
                            itemBuilder: (_, _) =>
                                const Icon(Icons.star, color: AppColors.gold),
                            itemCount: 5,
                            itemSize: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${p.rating} (${p.reviews} reviews)',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Price row
                      Row(
                        children: [
                          Text(
                            settings.formatMoney(p.price, context),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.crimson,
                            ),
                          ),
                          if (p.isOnSale) ...[
                            const SizedBox(width: 10),
                            Text(
                              settings.formatMoney(p.originalPrice, context),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.mutedForeground,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                '-${p.discountPercent}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (p.size != null) ...[
                        const SizedBox(height: 6),
                        Text('Size: ${p.size}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground)),
                      ],
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 14),
                      // Description
                      Text('Description',
                          style:
                              Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(p.description,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                              height: 1.6)),
                      if (p.details.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text('Key Details',
                            style:
                                Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        ...p.details.map((d) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(top: 5, right: 8),
                                    child: Icon(Icons.circle,
                                        size: 6,
                                        color: AppColors.crimson),
                                  ),
                                  Expanded(
                                    child: Text(d,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.mutedForeground,
                                            height: 1.5)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      if (p.included.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text('What\'s Included',
                            style:
                                Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.included
                              .map((item) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius:
                                          BorderRadius.circular(50),
                                    ),
                                    child: Text(item,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.crimson,
                                            fontWeight: FontWeight.w500)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.card,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Qty stepper
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _qtyButton(
                            Icons.remove, () {
                          if (_quantity > 1) setState(() => _quantity--);
                        }),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('$_quantity',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                        ),
                        _qtyButton(
                            Icons.add, () => setState(() => _quantity++)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        for (var i = 0; i < _quantity; i++) {
                          cart.addItem(p);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${p.name} added to cart'),
                            backgroundColor: AppColors.crimson,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                          inCart ? Icons.shopping_bag : Icons.add_shopping_cart,
                          size: 18),
                      label: Text(inCart ? 'Add More' : 'Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.foreground),
      ),
    );
  }
}
