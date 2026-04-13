import 'package:mg_common_game/systems/tutorial/tutorial.dart';
import 'package:mg_common_game/systems/tutorial/tutorial_data.dart';

/// Tutorial configuration for MG-0010: Dungeon Shop Simulator.
///
/// Placeholder tutorial steps for v1.2.0 pilot integration.
const kOnboardingTutorial = TutorialConfig(
  id: 'onboarding',
  name: 'Dungeon Shop Tutorial',
  steps: [
    TutorialStep(
      id: 'play_button',
      title: '게임을 시작하세요',
      description: '플레이 버튼을 눌러 게임을 시작합니다.',
    ),
    TutorialStep(
      id: 'objective',
      title: '목표를 달성하세요',
      description: '화면의 안내를 따라 목표를 완수하세요.',
    ),
    TutorialStep(
      id: 'reward',
      title: '보상을 획득하세요',
      description: '목표 달성 시 골드와 경험치를 받습니다.',
    ),
    TutorialStep(
      id: 'unlock',
      title: '새 콘텐츠를 해제하세요',
      description: '레벨을 올려 새로운 콘텐츠를 해제하세요.',
    ),
  ],
  skippable: true,
  showOnFirstLaunch: true,
);
