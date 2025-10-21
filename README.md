# Card 3D Carousel

A customizable 3D card carousel with flip animations for Flutter. Perfect for game cards, trading cards, or any card-based interface.

## Features

- 🎴 **3D Card Carousel**: Beautiful 3D perspective with smooth animations
- 🔄 **Flip Animations**: Cards flip to reveal front/back content
- 👆 **Gesture Support**: Swipe left/right to navigate, swipe up or tap to select
- ⚡ **Smooth Animations**: Optimized for 60fps performance
- 🎨 **Customizable**: Easy to customize card appearance and behavior
- 📱 **Responsive**: Works on all screen sizes

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  card_3d_carousel: ^1.0.0
```

## Usage

### Basic Example

```dart
import 'package:card_3d_carousel/card_3d_carousel.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isCardSelected = false;
  String? selectedCardImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Card 3D Carousel')),
      body: Card3DAnimation(
        totalCards: 78, // Total number of cards
        isCardSelected: isCardSelected,
        selectedCardImageUrl: selectedCardImageUrl,
        onCardSelected: () {
          setState(() {
            isCardSelected = true;
            selectedCardImageUrl = 'https://example.com/card-image.jpg';
          });
        },
        onAnimationCompleted: () {
          // Handle card selection completion
          print('Card selection animation completed!');
        },
      ),
    );
  }
}
```

### Advanced Example with Custom Configuration

```dart
Card3DAnimation(
  totalCards: 156,
  isAnimating: false, // Disable interactions during external animations
  isCardSelected: selectedCard != null,
  selectedCardImageUrl: selectedCard?.imageUrl,
  onCardSelected: () {
    // Handle card selection
    setState(() {
      selectedCard = getRandomCard();
    });
  },
  onAnimationCompleted: () {
    // Navigate to next screen or show card details
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CardDetailsScreen(selectedCard!)),
    );
  },
)
```

## API Reference

### Card3DAnimation

The main widget for the 3D card carousel.

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `totalCards` | `int` | `156` | Total number of cards in the deck |
| `onCardSelected` | `VoidCallback?` | `null` | Called when a card is selected |
| `onAnimationCompleted` | `VoidCallback?` | `null` | Called when selection animation completes |
| `isAnimating` | `bool` | `false` | Disable interactions during animations |
| `selectedCardImageUrl` | `String?` | `null` | URL of the selected card's front image |
| `isCardSelected` | `bool` | `false` | Whether a card is currently selected |

#### Gestures

- **Swipe Left/Right**: Navigate through cards
- **Swipe Up**: Select the center card
- **Tap**: Select the center card

#### Animation Phases

1. **Rise Phase (0-30%)**: Card rises up
2. **Flip Phase (30-70%)**: Card flips to reveal front
3. **Fall Phase (70-100%)**: Card falls back down

## Customization

### Card Appearance

The package uses a default card back design. To customize:

1. Add your card back image to `assets/images/daily_tarot_card.png`
2. Update your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
```

### Animation Timing

The package uses optimized animation timings:
- **Rotation**: 80ms for smooth navigation
- **Selection**: 2000ms for dramatic card flip
- **Velocity-based**: Faster swipes navigate more cards

## Examples

Check out the `example/` directory for complete working examples.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any problems or have questions, please file an issue at [GitHub Issues](https://github.com/mehmetcoban/card_3d_carousel/issues).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.