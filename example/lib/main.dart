import 'package:flutter/material.dart';
import 'package:card_3d_carousel/card_3d_carousel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card 3D Carousel Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isCardSelected = false;
  String? selectedCardImageUrl;
  int selectedCardNumber = 0;

  // Demo kart resimleri
  final List<String> cardImages = [
    'https://picsum.photos/300/400?random=1'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card 3D Carousel Demo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Seçilen kart bilgisi
          if (isCardSelected)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.deepPurple.shade100,
              child: Column(
                children: [
                  Text(
                    'Selected Card: #$selectedCardNumber',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Swipe left/right to navigate, swipe up or tap to select',
                    style: TextStyle(color: Colors.deepPurple.shade700),
                  ),
                ],
              ),
            ),
          
          // 3D Kart Carousel
          Expanded(
            child: Card3DAnimation(
              totalCards: 78, // Toplam kart sayısı
              isCardSelected: isCardSelected,
              selectedCardImageUrl: selectedCardImageUrl,
              onCardSelectedWithIndex: (int cardNumber) {
                setState(() {
                  // Don't set isCardSelected = true here, let animation complete first
                  selectedCardNumber = cardNumber;
                  selectedCardImageUrl = cardImages[selectedCardNumber % cardImages.length];
                });
              },
              onAnimationCompleted: () {
                // Animasyon tamamlandığında
                print('Card selection animation completed!');
                setState(() {
                  isCardSelected = true;
                });
                // Burada kart detaylarına gidebilirsiniz
                _showCardDetails();
              },
            ),
          ),
          
          // Reset butonu
          if (isCardSelected)
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isCardSelected = false;
                    selectedCardImageUrl = null;
                    selectedCardNumber = 0;
                  });
                },
                child: Text('Reset Selection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCardDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Card Selected!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Card Number: $selectedCardNumber'),
            SizedBox(height: 16),
            if (selectedCardImageUrl != null)
              Container(
                height: 200,
                width: 150,
                child: Image.network(
                  selectedCardImageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}