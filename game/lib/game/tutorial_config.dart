import 'package:mg_common_game/systems/tutorial/tutorial.dart';

/// Tutorial configuration for MG-0010: Dungeon Shop Simulator.
///
/// Placeholder tutorial steps for v1.2.0 pilot integration.
/// In production, replace descriptions with localized strings
/// and add targetSelector for highlight positioning.
const kOnboardingTutorial = TutorialConfig(
  id: 'onboarding',
  name: 'Dungeon Shop Tutorial',
  steps: [
    TutorialStep(
      id: 'welcome',
      title: 'Welcome, Shopkeeper!',
      description: 'Run your own dungeon shop — craft, display, and sell.',
      actionHint: 'Tap to continue',
    ),
    TutorialStep(
      id: 'first_craft',
      title: 'Craft an Item',
      description:
          'Use dungeon materials to craft your first item. '
          'Higher-quality materials yield better gear.',
      actionHint: 'Tap craft',
      targetSelector: 'craft_button',
    ),
    TutorialStep(
      id: 'open_shop',
      title: 'Open Your Shop',
      description:
          'Display crafted items on the shelf and wait for customers.',
      actionHint: 'Tap display',
      targetSelector: 'display_button',
    ),
    TutorialStep(
      id: 'dungeon_run',
      title: 'Enter the Dungeon',
      description: 'Explore dungeons to gather rare crafting materials.',
      actionHint: 'Tap to continue',
    ),
  ],
  skippable: true,
  showOnFirstLaunch: true,
  trigger: TutorialTrigger.firstLaunch,
);
