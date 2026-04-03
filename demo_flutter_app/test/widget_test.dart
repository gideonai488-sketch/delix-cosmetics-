import 'package:demo_flutter_app/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:demo_flutter_app/main.dart' show DelixApp;

void main() {
  testWidgets('App shell loads with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: const DelixApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
