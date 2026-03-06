🐾 멍멍 숲의 바람 (Wind of the Woof Forest) 협업 규칙

이 문서는 개발 과정에서 일관성을 유지하고, 리팩토링 및 에셋 교체 비용을 최소화하기 위한 프로젝트의 '헌법'입니다.

1. 프로젝트 철학 (Philosophy)

힐링 & 감성 (Healing First): 모든 UI와 연출은 지브리풍의 따스함을 유지합니다. 급격한 색상 변화나 공격적인 효과음은 배제합니다.

모바일 최적화 (Mobile First): 모든 입력은 터치(Drag & Drop)를 기준으로 설계하며, 저사양 기기에서도 구동되도록 최적화합니다.

컴포넌트 중심 (Composition over Inheritance): 하나의 거대한 스크립트 대신, 기능을 작은 노드 단위로 쪼개어 붙이는 방식을 고수합니다.

2. 기술적 규칙 (Technical Standards)

엔진 버전: Godot 4.x (Compatibility 렌더러 고정).

언어: GDScript 2.0 (정적 타이핑 필수 - var speed: float = 200.0 방식).

타일 규격: 256x128 아이소메트릭 (2:1 비율). 모든 좌표 계산은 이 상수를 기반으로 합니다.

Y-Sort & Pivot:

모든 게임 내 개체는 Y Sort Enabled = true 필수.

스프라이트의 Offset은 항상 발바닥 중앙(하단)을 (0, 0)으로 설정합니다.

UI 시스템:

하드코딩된 스타일 대신 Theme 리소스를 활용합니다.

나중에 이미지만 교체할 수 있도록 StyleBoxTexture를 적극 활용합니다.

3. 데이터 및 보안 규칙 (Data & Security)

Firestore 경로 규칙:

공용(마을 배치 등): /artifacts/${appId}/public/data/${collectionName}

개인(재화, 레벨 등): /artifacts/${appId}/users/${userId}/${collectionName}

서버 시간 우선: 건설 시간, 미션 완료 시간은 기기 시간이 아닌 Firestore 서버 타임스탬프를 기준으로 검증합니다.

4. 협업 및 AI 지침 (AI Collaboration)

에이전트 온보딩: 새로운 세션 시작 시 항상 puppy_valley_master_plan.md와 이 규칙 파일을 먼저 제공합니다.

계획 우선 (Plan-First): 코드를 짜기 전, implementation_plan.md를 통해 로직의 구조(노드 트리, 시그널 흐름)를 먼저 정의합니다.

코드 문서화: 모든 함수 상단에는 기능과 매개변수를 설명하는 주석을 한글로 작성합니다.

5. 명명 규칙 (Naming Conventions)

파일명/폴더명: snake_case (예: main_scene.tscn, dog_manager.gd).

클래스명 (class_name): PascalCase (예: BaseBuilding).

함수/변수: snake_case. (상수는 SCREAMING_SNAKE_CASE).

시그널: 과거분사형 또는 상태 변화를 나타내는 명확한 이름 (예: mission_started, gold_changed).

"규칙은 창의성을 가두는 틀이 아니라, 더 큰 꿈을 안전하게 지탱해주는 뼈대입니다."
