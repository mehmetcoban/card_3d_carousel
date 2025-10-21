import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:card_3d_carousel/card_3d_carousel.dart';

void main() {
  group('Card3DAnimation Widget Tests', () {
    testWidgets('should render without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Card3DAnimation(totalCards: 78))),
      );

      expect(find.byType(Card3DAnimation), findsOneWidget);
    });

    testWidgets('should handle card selection callback', (
      WidgetTester tester,
    ) async {
      bool cardSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card3DAnimation(
              totalCards: 78,
              onCardSelected: () {
                cardSelected = true;
              },
            ),
          ),
        ),
      );

      // Tap on the center card to trigger selection
      await tester.tap(find.byType(Card3DAnimation));
      await tester.pump();

      expect(cardSelected, true);
    });

    testWidgets('should accept custom parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card3DAnimation(
              totalCards: 156,
              isAnimating: false,
              isCardSelected: false,
              selectedCardImageUrl: 'https://example.com/card.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(Card3DAnimation), findsOneWidget);
    });

    testWidgets('should handle swipe gestures', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Card3DAnimation(totalCards: 78))),
      );

      // Simulate a left swipe
      await tester.drag(find.byType(Card3DAnimation), const Offset(-200, 0));
      await tester.pump();

      // Widget should still be present
      expect(find.byType(Card3DAnimation), findsOneWidget);
    });
  });
}
