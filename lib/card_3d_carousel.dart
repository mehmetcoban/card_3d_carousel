import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// A customizable 3D card carousel with flip animations for Flutter.
///
/// Perfect for tarot cards, game cards, or any card-based interface.
/// Features smooth 3D animations, gesture support, and customizable appearance.
class Card3DAnimation extends StatefulWidget {
  /// Total number of cards in the deck
  final int totalCards;

  /// Callback triggered when a card is selected
  final VoidCallback? onCardSelected;

  /// Callback triggered when card selection animation completes
  final VoidCallback? onAnimationCompleted;

  /// Callback triggered when a card is selected, provides the selected card index
  final Function(int)? onCardSelectedWithIndex;

  /// Whether the widget is currently animating (disables interactions)
  final bool isAnimating;

  /// URL of the selected card image to display
  final String? selectedCardImageUrl;

  /// Whether a card is currently selected
  final bool isCardSelected;

  /// Creates a 3D card carousel widget.
  ///
  /// [totalCards] defaults to 156 cards.
  /// [isAnimating] disables user interactions when true.
  /// [isCardSelected] indicates if a card is currently selected.
  const Card3DAnimation({
    super.key,
    this.totalCards = 156,
    this.onCardSelected,
    this.onAnimationCompleted,
    this.onCardSelectedWithIndex,
    this.isAnimating = false,
    this.selectedCardImageUrl,
    this.isCardSelected = false,
  });

  @override
  State<Card3DAnimation> createState() => _Card3DAnimationState();
}

class _Card3DAnimationState extends State<Card3DAnimation>
    with TickerProviderStateMixin {
  int currentIndex = 0;

  late AnimationController _selectionController;
  late Animation<double> _selectionAnimation;

  bool isAnimating = false;
  List<_CardData> cardDataList = [];
  int _nextCardId = 0;
  List<String> rotationQueue = [];

  final int animationDuration = 80; // Reduced from 150 to 80 (faster)
  // Total animation duration: Rise, Flip, Fall
  final int selectionDuration =
      2000; // 2 seconds for visible animation for better visibility
  final double dragThreshold = 30.0; // Reduced from 50 to 30 (more sensitive)

  // Animation phases (percentages within the 0.0 to 1.0 duration)
  final double risePhaseEnd = 0.3; // Rises up to 30%
  final double flipPhaseEnd = 0.7; // Flips/stays at peak up to 70%

  // --- INITIAL SETUP AND WIDGET UPDATE ---

  @override
  void initState() {
    super.initState();

    _selectionController =
        AnimationController(
          duration: Duration(milliseconds: selectionDuration),
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            // Notify parent widget when animation is completed.
            widget.onAnimationCompleted?.call();
          }
        });

    _selectionAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.linear),
    );

    _initializeCards();

    // If card is selected externally (e.g., when transitioning to Step 3)
    if (widget.isCardSelected) {
      _selectionController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant Card3DAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If card selection is triggered externally, start animation
    if (widget.isCardSelected && !oldWidget.isCardSelected) {
      _startSelectionAnimation();
    }
  }

  void _initializeCards() {
    cardDataList.clear();
    for (int i = 0; i < 5; i++) {
      final cardIndex =
          (currentIndex + i - 2 + widget.totalCards) % widget.totalCards;
      cardDataList.add(
        _CardData(
          id: _nextCardId++,
          arrayIndex: i,
          cardIndex: cardIndex,
          position: _getPositionForArrayIndex(i),
          previousPosition: _getPositionForArrayIndex(i),
        ),
      );
    }
  }

  _CardPosition _getPositionForArrayIndex(int arrayIndex) {
    switch (arrayIndex) {
      case 0:
        return _CardPosition.left2;
      case 1:
        return _CardPosition.left1;
      case 2:
        return _CardPosition.center;
      case 3:
        return _CardPosition.right1;
      case 4:
        return _CardPosition.right2;
      default:
        return _CardPosition.center;
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  // --- QUEUE AND ROTATION MANAGEMENT ---
  void _processQueue() {
    if (rotationQueue.isEmpty) {
      isAnimating = false;
      return;
    }

    if (isAnimating ||
        _selectionController.isAnimating ||
        widget.isCardSelected) {
      return;
    }

    isAnimating = true;
    final direction = rotationQueue.removeAt(0);

    if (direction == 'left') {
      _performRotateLeft();
    } else if (direction == 'right') {
      _performRotateRight();
    }
  }

  void _queueRotation(String direction) {
    rotationQueue.add(direction);

    if (!isAnimating) {
      _processQueue();
    }
  }

  void _performRotateLeft() {
    final newCardDeckIndex =
        (currentIndex + 1 + 2 + widget.totalCards) % widget.totalCards;

    final enteringCard = _CardData(
      id: _nextCardId++,
      arrayIndex: 5,
      cardIndex: newCardDeckIndex,
      position: _CardPosition.enterRight,
      previousPosition: _CardPosition.enterRight,
    );

    setState(() {
      for (int i = 0; i < 5; i++) {
        cardDataList[i].previousPosition = cardDataList[i].position;

        if (i == 0) {
          cardDataList[i].position = _CardPosition.exitLeft;
        } else {
          cardDataList[i].position = _getPositionForArrayIndex(i - 1);
        }
      }
      cardDataList.add(enteringCard);
      currentIndex = (currentIndex + 1) % widget.totalCards;
    });

    Future.delayed(Duration(milliseconds: animationDuration + 1), () {
      if (!mounted) return;
      setState(() {
        cardDataList.removeAt(0);

        for (int i = 0; i < 5; i++) {
          cardDataList[i].arrayIndex = i;
          cardDataList[i].cardIndex =
              (currentIndex + i - 2 + widget.totalCards) % widget.totalCards;

          cardDataList[i].previousPosition = cardDataList[i].position;
          cardDataList[i].position = _getPositionForArrayIndex(i);
        }
      });

      isAnimating = false;
      _processQueue();
    });
  }

  void _performRotateRight() {
    final newCardDeckIndex =
        (currentIndex - 1 - 2 + widget.totalCards) % widget.totalCards;

    final enteringCard = _CardData(
      id: _nextCardId++,
      arrayIndex: -1,
      cardIndex: newCardDeckIndex,
      position: _CardPosition.enterLeft,
      previousPosition: _CardPosition.enterLeft,
    );

    setState(() {
      for (int i = 0; i < 5; i++) {
        cardDataList[i].previousPosition = cardDataList[i].position;

        if (i == 4) {
          cardDataList[i].position = _CardPosition.exitRight;
        } else {
          cardDataList[i].position = _getPositionForArrayIndex(i + 1);
        }
      }
      cardDataList.insert(0, enteringCard);
      currentIndex = (currentIndex - 1 + widget.totalCards) % widget.totalCards;
    });

    Future.delayed(Duration(milliseconds: animationDuration + 1), () {
      if (!mounted) return;
      setState(() {
        cardDataList.removeAt(5);

        for (int i = 0; i < 5; i++) {
          cardDataList[i].arrayIndex = i;
          cardDataList[i].cardIndex =
              (currentIndex + i - 2 + widget.totalCards) % widget.totalCards;

          cardDataList[i].previousPosition = cardDataList[i].position;
          cardDataList[i].position = _getPositionForArrayIndex(i);
        }
      });

      isAnimating = false;
      _processQueue();
    });
  }

  // --- SELECTION ANIMATION ---
  void _startSelectionAnimation() {
    if (isAnimating ||
        _selectionController.isAnimating ||
        widget.isCardSelected) {
      return;
    }

    // Notify parent that selection is triggered. Parent will set isCardSelected to true.
    widget.onCardSelected?.call();

    // Also send the current card index
    final centerCard = cardDataList.firstWhere(
      (card) => card.position == _CardPosition.center,
    );
    widget.onCardSelectedWithIndex?.call(centerCard.cardIndex + 1);

    // Start animation from 0 to 1 (exactly like your working code)
    _selectionController.reset();
    _selectionController.forward();

    // When animation completes, `onAnimationCompleted` will be called automatically via `addStatusListener`.
  }

  // --- GESTURE DETECTOR ---
  @override
  Widget build(BuildContext context) {
    // If card is selected OR selection animation is running OR external animation is disabled, horizontal movement is blocked.
    final bool isInteractionBlocked =
        widget.isCardSelected ||
        _selectionController.isAnimating ||
        widget.isAnimating;

    return GestureDetector(
      // onPanUpdate removed - no drag and hold

      // Only for swipe (quick swipe) onPanEnd
      onPanEnd: isInteractionBlocked
          ? null
          : (details) {
              if (isAnimating) {
                return;
              }

              const double velocityThreshold =
                  100; // Reduced from 200 to 100 (more sensitive)
              final deltaY = details.velocity.pixelsPerSecond.dy;
              final deltaX = details.velocity.pixelsPerSecond.dx;

              // 1. VERTICAL SWIPE (SELECTION)
              // Card selection with upward swipe (WORKS FROM ANYWHERE)
              if (deltaY < -velocityThreshold) {
                _startSelectionAnimation(); // Select center card
                return;
              }

              // 2. HORIZONTAL SWIPE (ROTATION)
              // WORKS FROM ANYWHERE - You can swipe from side cards too
              if (deltaX.abs() > velocityThreshold) {
                // Calculate how many cards to swipe based on velocity
                int cardCount = 1; // Default 1 card

                if (deltaX.abs() > 2000) {
                  cardCount = 10; // Very very fast swipe: 10 cards
                } else if (deltaX.abs() > 1500) {
                  cardCount = 8; // Very fast swipe: 8 cards
                } else if (deltaX.abs() > 1000) {
                  cardCount = 6; // Fast swipe: 6 cards
                } else if (deltaX.abs() > 600) {
                  cardCount = 4; // Medium speed swipe: 4 cards
                } else if (deltaX.abs() > 300) {
                  cardCount = 2; // Normal swipe: 2 cards
                } else {
                  cardCount = 1; // Slow swipe: 1 card
                }

                // Add multiple cards to queue
                for (int i = 0; i < cardCount; i++) {
                  if (deltaX > 0) {
                    _queueRotation('right');
                  } else {
                    _queueRotation('left');
                  }
                }
              }
            },
      // Also trigger selection when center card is tapped (added)
      onTap: isInteractionBlocked
          ? null
          : () {
              _startSelectionAnimation();
            },

      child: SizedBox(
        height: 400,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _selectionAnimation,
          builder: (context, child) {
            final sortedCardList = List<_CardData>.from(cardDataList);

            // Updated Z-order so selected card always appears on top.
            sortedCardList.sort((a, b) {
              final aIsCenter = a.position == _CardPosition.center;
              final bIsCenter = b.position == _CardPosition.center;

              if (aIsCenter) {
                return 1; // Put center card last (drawn on top)
              }
              if (bIsCenter) {
                return -1;
              }

              return a.position.translateZ.compareTo(b.position.translateZ);
            });

            return Stack(
              children: sortedCardList
                  .map(
                    (cardData) => _buildCard(
                      cardData,
                      ValueKey(cardData.id),
                      isInteractionBlocked,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  // --- CARD CONFIGURATION ---
  Widget _buildCard(_CardData cardData, Key key, bool isInteractionBlocked) {
    final isCenter = cardData.position == _CardPosition.center;

    // CHANGE: All cards should remain visible even after card selection
    // final bool shouldBeVisible = true; // Always true

    return TweenAnimationBuilder<_CardPosition>(
      key: key,
      // Pause animation during selection animation
      duration: Duration(
        milliseconds: widget.isCardSelected
            ? selectionDuration
            : animationDuration,
      ),
      curve: Curves.easeOut,
      tween: _CardPositionTween(
        begin: cardData.previousPosition,
        end: cardData.position,
      ),
      builder: (context, animatedPosition, child) {
        final double selectionValue = isCenter ? _selectionAnimation.value : 0;

        // --- 1. Rise and Fall (Center Card Only) ---
        double yRiseValue = 0.0;
        if (selectionValue > 0) {
          if (selectionValue < risePhaseEnd) {
            // 0 -> 0.3 (Rising)
            yRiseValue = Curves.easeOut.transform(
              selectionValue / risePhaseEnd,
            );
          } else if (selectionValue < flipPhaseEnd) {
            // 0.3 -> 0.7 (Waiting at peak)
            yRiseValue = 1.0;
          } else {
            // 0.7 -> 1.0 (Falling)
            yRiseValue = Curves.easeIn.transform(
              1.0 - ((selectionValue - flipPhaseEnd) / (1.0 - flipPhaseEnd)),
            );
          }
        }
        final double riseOffset = yRiseValue * 120.0; // Max 120 units rise

        // --- 2. Flip Animation (Center Card Only) ---
        double flipValue = 0.0;
        if (selectionValue > 0) {
          if (selectionValue >= risePhaseEnd &&
              selectionValue <= flipPhaseEnd) {
            // 0.3 to 0.7 (40% duration) goes from 0 to 1
            flipValue =
                (selectionValue - risePhaseEnd) / (flipPhaseEnd - risePhaseEnd);
            flipValue = Curves.easeInOut.transform(flipValue);
          } else if (selectionValue > flipPhaseEnd) {
            // After 0.7, flip value stays constant at 1.0 (180 degrees)
            flipValue = 1.0;
          }
        }
        final double flipAngle =
            flipValue * math.pi; // Rotates from 0 to pi and stays there

        // Debug: Print animation values (only when animating)
        if (isCenter && selectionValue > 0) {
          // Debug: Animation values
          // print('🎯 Animation: Value=$selectionValue, Rise=$yRiseValue, Flip=$flipValue, RiseOffset=${riseOffset.toStringAsFixed(1)}');
        }

        // --- 2.1. X Axis Rotation (Perspective Effect) ---
        // Add slight X axis rotation during flip
        double tiltAngle = 0.0;
        if (selectionValue >= risePhaseEnd && selectionValue <= flipPhaseEnd) {
          // Tilt card during flip (first one direction, then back)
          double tiltProgress =
              (selectionValue - risePhaseEnd) / (flipPhaseEnd - risePhaseEnd);
          tiltAngle =
              math.sin(tiltProgress * math.pi) *
              0.15; // Between -0.15 and +0.15 radians
        }

        // --- 2.2. Scale Increase During Flip ---
        double selectionScale = 1.0;
        if (selectionValue > 0 && selectionValue < 1.0) {
          // Enlarge card during flip
          selectionScale =
              1.0 +
              (math.sin(selectionValue * math.pi) * 0.15); // Max 15% growth
        }

        // --- 3. General Card Position (Drag removed) ---
        final Matrix4 cardPositionMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translateByVector3(
            Vector3(
              animatedPosition.translateX,
              animatedPosition.translateY - riseOffset, // Rise added
              animatedPosition.translateZ,
            ),
          )
          ..rotateY(animatedPosition.rotateY)
          ..scaleByVector3(Vector3.all(animatedPosition.scale));

        final double finalOpacity = animatedPosition.opacity;

        return Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: finalOpacity,
              child: Transform(
                alignment: Alignment.center,
                transform: cardPositionMatrix,
                child: _Card(
                  rotationAngle: isCenter
                      ? flipAngle
                      : 0, // Send angle for center card
                  tiltAngle: isCenter ? tiltAngle : 0.0, // X axis tilt
                  selectionScale: isCenter
                      ? selectionScale
                      : 1.0, // Scale during flip
                  selectedCardImageUrl: widget.selectedCardImageUrl,
                  cardNumber: cardData.cardIndex + 1,
                  totalCards: widget.totalCards,
                  isCenter: isCenter,
                  isCardSelected: widget.isCardSelected,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ====================================================================
// 2. CARD POSITION MODELS AND TWEEN
// ====================================================================

class _CardData {
  final int id;
  int arrayIndex;
  int cardIndex;
  _CardPosition position;
  _CardPosition previousPosition;

  _CardData({
    required this.id,
    required this.arrayIndex,
    required this.cardIndex,
    required this.position,
    required this.previousPosition,
  });
}

class _CardPosition {
  final double translateX;
  final double translateY;
  final double translateZ;
  final double rotateY;
  final double scale;
  final double opacity;

  const _CardPosition({
    required this.translateX,
    required this.translateY,
    required this.translateZ,
    required this.rotateY,
    required this.scale,
    this.opacity = 1.0,
  });

  static const center = _CardPosition(
    translateX: 0,
    translateY: 0,
    translateZ: 150,
    rotateY: 0,
    scale: 1.1,
    opacity: 1.0,
  );

  static const left1 = _CardPosition(
    translateX: -90,
    translateY: 30,
    translateZ: 50,
    rotateY: 0,
    scale: 0.9,
    opacity: 0.95,
  );

  static const right1 = _CardPosition(
    translateX: 90,
    translateY: 30,
    translateZ: 50,
    rotateY: 0,
    scale: 0.9,
    opacity: 0.95,
  );

  static const left2 = _CardPosition(
    translateX: -160,
    translateY: 60,
    translateZ: 0,
    rotateY: 0,
    scale: 0.75,
    opacity: 0.8,
  );

  static const right2 = _CardPosition(
    translateX: 160,
    translateY: 60,
    translateZ: 0,
    rotateY: 0,
    scale: 0.75,
    opacity: 0.8,
  );

  static const exitLeft = _CardPosition(
    translateX: -400,
    translateY: 80,
    translateZ: -100,
    rotateY: 0,
    scale: 0.6,
    opacity: 0.0,
  );

  static const exitRight = _CardPosition(
    translateX: 400,
    translateY: 80,
    translateZ: -100,
    rotateY: 0,
    scale: 0.6,
    opacity: 0.0,
  );

  static const enterRight = _CardPosition(
    translateX: 400,
    translateY: 60,
    translateZ: 0,
    rotateY: 0,
    scale: 0.75,
    opacity: 0.0,
  );

  static const enterLeft = _CardPosition(
    translateX: -400,
    translateY: 60,
    translateZ: 0,
    rotateY: 0,
    scale: 0.75,
    opacity: 0.0,
  );
}

class _CardPositionTween extends Tween<_CardPosition> {
  _CardPositionTween({required _CardPosition begin, required _CardPosition end})
    : super(begin: begin, end: end);

  @override
  _CardPosition lerp(double t) {
    if (t == 0.0) return begin!;
    if (t == 1.0) return end!;
    return _CardPosition(
      translateX: lerpDouble(begin!.translateX, end!.translateX, t)!,
      translateY: lerpDouble(begin!.translateY, end!.translateY, t)!,
      translateZ: lerpDouble(begin!.translateZ, end!.translateZ, t)!,
      rotateY: lerpDouble(begin!.rotateY, end!.rotateY, t)!,
      scale: lerpDouble(begin!.scale, end!.scale, t)!,
      opacity: lerpDouble(begin!.opacity, end!.opacity, t)!,
    );
  }
}

// ====================================================================
// 3. CARD VISUAL COMPONENT (External Angle Control) - NEW AND FIXED
// ====================================================================

class _Card extends StatelessWidget {
  final int cardNumber;
  final int totalCards;
  final bool isCenter;
  final double rotationAngle;
  final double tiltAngle; // X axis tilt
  final double selectionScale; // Scale during flip
  final String? selectedCardImageUrl;
  final bool isCardSelected;

  const _Card({
    required this.cardNumber,
    required this.totalCards,
    required this.isCenter,
    required this.rotationAngle,
    this.tiltAngle = 0.0,
    this.selectionScale = 1.0,
    this.selectedCardImageUrl,
    this.isCardSelected = false,
  });

  // Card front face (selected card image)
  Widget _buildFrontContent() {
    if (selectedCardImageUrl == null || selectedCardImageUrl!.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Image.network(
      selectedCardImageUrl!,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red.shade900,
          child: const Center(
            child: Text(
              'Kart Yüklenemedi',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  // Card back face (Generic card image)
  Widget _buildBackContent() {
    // Default card back design without requiring asset
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade300,
            Colors.deepPurple.shade600,
            Colors.deepPurple.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 60, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'CARD',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              '$cardNumber',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Increase size when card is selected and real image is shown
    final double cardWidth = isCardSelected && isCenter
        ? 223
        : 180; // 350/280 * 180 ≈ 225
    final double cardHeight = isCardSelected && isCenter
        ? 350
        : 280; // Same as Step 3

    if (!isCenter) {
      // Non-center cards only show back face
      return Container(
        width: 180,
        height: 280,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: _buildBackContent(),
      );
    }

    // Apply rotation for center card
    final double angle = rotationAngle;

    // Card main rotation (0 to pi) + X axis tilt + Scale
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // 3D perspective
      ..rotateX(tiltAngle) // X axis tilt (perspective effect)
      ..rotateY(angle) // Y axis rotation (flip)
      ..scaleByVector3(Vector3.all(selectionScale)); // Enlarge during flip

    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 800), // Smooth size transition
        curve: Curves.easeInOut,
        width: cardWidth,
        height: cardHeight,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          // Position both faces using Stack.
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. BACK FACE (Back Content - visible when angle < 90 degrees)
              // Ensures image is visible up to 90%
              Visibility(
                visible: angle < math.pi / 2,
                // No rotation needed, already rotating with main transform
                child: _buildBackContent(),
              ),

              // 2. FRONT FACE (Front Content - visible when angle > 90 degrees)
              // Card front face must be rotated 180 degrees to replace back face.
              Visibility(
                visible: angle >= math.pi / 2,
                child: Transform(
                  // This 180 degree (math.pi) rotation prevents image mirroring
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildFrontContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
