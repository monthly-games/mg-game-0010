import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();

  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_completed') ?? false;
  }

  static Future<void> markTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<TutorialStep> _steps = const [
    TutorialStep(
      title: 'Welcome to Dungeon Shop!',
      description: 'Run your own shop in a fantasy world',
      icon: Icons.store,
      iconPosition: Alignment.center,
    ),
    TutorialStep(
      title: 'Sell Items',
      description: 'Tap on items in your shop tab to sell them to customers for gold',
      icon: Icons.shopping_bag,
      iconPosition: Alignment.bottomLeft,
    ),
    TutorialStep(
      title: 'Craft Equipment',
      description: 'Use materials to craft powerful items in the crafting tab',
      icon: Icons.construction,
      iconPosition: Alignment.center,
    ),
    TutorialStep(
      title: 'Explore Dungeons',
      description: 'Send adventurers to dungeons to gather rare materials',
      icon: Icons.explore,
      iconPosition: Alignment.topRight,
    ),
    TutorialStep(
      title: 'Earn While Away',
      description: 'Your shop generates idle income even when you\'re offline!',
      icon: Icons.schedule,
      iconPosition: Alignment.centerRight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _completeTutorial();
    }
  }

  Future<void> _completeTutorial() async {
    await TutorialOverlay.markTutorialComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: step.iconPosition,
                  child: Icon(
                    step.icon,
                    size: 100,
                    color: const Color(0xFFd4a574), // Gold color
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Progress indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (index) => Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentStep
                                ? const Color(0xFFd4a574)
                                : Colors.white30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Next button
                    SizedBox(
                      width: 200,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _currentStep == _steps.length - 1
                              ? 'OPEN SHOP'
                              : 'NEXT',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Skip button
                    if (_currentStep < _steps.length - 1)
                      TextButton(
                        onPressed: _completeTutorial,
                        child: const Text(
                          'Skip Tutorial',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Alignment iconPosition;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconPosition,
  });
}
