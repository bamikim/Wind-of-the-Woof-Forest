# 프로젝트 아키텍처 및 구현 지침 (ARCHITECTURE.md)

이 문서는 '멍멍 숲의 바람' 프로젝트의 기술적 설계와 개발 표준을 정의합니다.

## 1. 프로젝트 폴더 구조 (Recommended File Structure)

Godot 4.x의 권장 사항과 컴포넌트 기반 설계를 반영한 구조입니다.

```text
res://
├── assets/                 # 외부 리소스 (아트, 사운드 등)
│   ├── sprites/            # 스프라이트 (강아지, 건물, 환경)
│   ├── tilesets/           # 타일맵 에셋
│   ├── sounds/             # 효과음 및 BGM
│   └── fonts/              # 글꼴
├── src/                    # 소스 코드 및 씬
│   ├── core/               # 핵심 엔진 및 전역 시스템
│   │   ├── autoload/       # 싱글톤 (GameManager, ServerTime 등)
│   │   └── base/           # 베이스 클래스 (BaseEntity, BaseComponent)
│   ├── components/         # 재사용 가능한 컴포넌트
│   │   ├── interaction/
│   │   ├── navigation/
│   │   └── mission/
│   ├── entities/           # 게임 내 개체
│   │   ├── dogs/           # 강아지 씬 및 스크립트
│   │   └── buildings/      # 건물 씬 및 스크립트
│   ├── ui/                 # UI 관련 씬 및 스크립트
│   │   ├── main_hud/
│   │   ├── popups/
│   │   └── commons/
│   ├── levels/             # 맵 및 영토 확장 관련
│   └── utils/              # 유틸리티 함수 및 상수
├── data/                   # 로컬 데이터 (JSON, Resources)
└── project.godot           # 프로젝트 설정
```

## 2. 구현 가이드라인 (Coding Standards)

### 2.1. GDScript 2.0 베스트 프랙티스
- **정적 타이핑 필수**: 모든 변수와 함수 리턴 타입에 타입을 지정합니다.
  ```gdscript
  var dog_name: String = "Bori"
  func get_speed() -> float:
      return 100.0
  ```
- **Signal 이름**: 과거형보다는 명령형/이벤트형을 사용합니다. (`mission_started`, `reward_collected`)
- **컴포넌트 패턴**: `Node`를 상속받은 소형 컴포넌트를 엔티티 아래에 배치하여 기능을 분리합니다.

### 2.2. 명명 규칙 (Naming Conventions)
- **파일**: `snake_case.gd`, `snake_case.tscn`
- **클래스 (class_name)**: `PascalCase`
- **변수 및 함수**: `snake_case`
- **상수**: `UPPER_SNAKE_CASE`

## 3. 핵심 컴포넌트 상세 설계

### 3.1. InteractionComponent
- **역할**: 마우스 클릭/터치 감지 및 상호작용 가능한 상태인지 판단.
- **주요 속성**: `owner_entity`, `is_interactable`
- **주요 함수**: `on_input_event()`, `interact()`

### 3.2. NavigationComponent
- **역할**: 아이소메트릭 그리드 상에서의 경로 탐색 및 이동 제어.
- **주요 속성**: `navigation_agent`, `target_position`
- **주요 함수**: `move_to(position)`, `stop()`

### 3.3. MissionComponent
- **역할**: 미션 진행 시간 관리 (서버 시간 기반) 및 보상 생성.
- **주요 속성**: `current_mission_id`, `end_time`
- **주요 함수**: `start_mission(mission_id)`, `check_completion()`, `claim_reward()`

## 4. 데이터 관리 전략 (Firestore 및 Local)
- **Firebase SDK**: Godot용 Firebase 플러그인을 사용하여 REST API 또는 SDK 연동.
- **오프라인 대응**: 마지막 서버 동기화 시점과 로컬 시간을 대조하여 비정상적 시간 변조 여부 체크.
- **Batching**: 영토 편집이나 가구 위치 변경은 즉시 전송하지 않고 '저장/종료' 시점에 일괄 전송.

## 5. 아트 및 렌더링 지침
- **Isometric Alignment**: 256x128 픽셀 그리드에 맞춰 픽셀 퍼펙트 정렬.
- **Y-Sort**: 모든 `Entity`와 `MapLayer`는 `y_sort_enabled = true`를 활성화하여 뎁스 문제 방지.
- **UI 반응성**: 16:9 및 21:9 등 다양한 종횡비에 대응할 수 있도록 테이너(Container) 노드 활용.

## 6. 에셋 교체 용이성 전략 (Asset Replacement Strategy)

나중에 에셋을 쉽게 교체할 수 있도록 다음과 같은 방식을 유지합니다.

### 6.1. UI 테마 및 스타일박스 (Theme & StyleBox)
- 모든 UI 요소는 개별 노드에서 색상이나 텍스처를 직접 수정하지 않고, `res://assets/themes/main_theme.tres` 전역 테마를 참조합니다.
- 버튼, 패널 등의 디자인은 `StyleBox` 리소스를 사용하여, 리소스 파일만 교체하면 게임 전체 UI가 변경되도록 구성합니다.

### 6.2. 플레이스홀더 리소스 (Placeholder Resources)
- 실제 아트가 나오기 전까지는 `ColorRect`나 기본 프리미티브 대신, `res://assets/placeholders/`에 있는 임시 스프라이트를 사용합니다.
- 모든 엔티티는 특정 경로의 `.tres` 리소스 파일을 로드하여 스프라이트와 애니메이션 정보를 가져오도록 설계하여, 리소스 파일 내용만 바꾸면 씬 수정 없이 외형이 바뀌게 합니다.
