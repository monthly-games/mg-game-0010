# MG-0010: 던전 샵 시뮬레이터

상점 경영 + 방치 생산 + 전투

## 개요

| 항목 | 내용 |
|------|------|
| Game ID | game_0010 |
| 코드명 | MG-0010 |
| 장르 | 상점 경영 + 방치 생산 + 전투 |
| 타깃 지역 | KR, SEA |

## 구조

```
mg-game-0010/
  ├─ common/                    # submodules
  │   ├─ game/                  # → mg-common-game
  │   ├─ backend/               # → mg-common-backend
  │   ├─ analytics/             # → mg-common-analytics
  │   └─ infra/                 # → mg-common-infra
  ├─ game/
  │   ├─ lib/
  │   │   ├─ features/          # 게임 고유 기능
  │   │   ├─ theme/             # 테마/스타일
  │   │   └─ main.dart
  │   ├─ assets/                # 에셋 파일
  │   └─ test/                  # 테스트
  ├─ backend/                   # 게임 전용 백엔드 확장
  ├─ analytics/                 # 게임 전용 이벤트/쿼리
  ├─ marketing/
  │   ├─ campaigns/             # 캠페인 정의
  │   └─ creatives/             # 크리에이티브 에셋
  ├─ docs/
  │   ├─ design/                # GDD, 경제 설계, 레벨 디자인
  │   └─ notes/                 # 개발 노트
  ├─ config/
  │   └─ game_manifest.json     # 게임 메타데이터
  ├─ .github/workflows/         # CI/CD
  └─ README.md
```

## 시작하기

### 1. 저장소 클론 및 submodule 초기화

```bash
git clone --recursive git@github.com:monthly-games/mg-game-0010.git
cd mg-game-0010
git submodule update --init --recursive
```

### 2. Flutter 프로젝트 실행

```bash
cd game
flutter pub get
flutter run
```

## 관련 문서

- [GDD](docs/design/gdd_game_0010.json)
