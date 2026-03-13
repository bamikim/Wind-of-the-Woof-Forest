class_name BuildingResource
extends Resource

## 건물의 속성과 외형, 제공 미션을 정의하는 리소스 클래스입니다.

@export var building_id: String = ""
@export var building_name: String = "Unknown Building"
@export var texture: Texture2D = null
@export var hframes: int = 1
@export var vframes: int = 1
@export var animation_fps: float = 8.0
@export var icon: Texture2D = null
@export var visual_offset: Vector2 = Vector2(0, -50) # 건물별 중심점 오프셋 조정
@export var occupied_tiles: Array[Vector2i] = [Vector2i(0, 0)] # 건물이 차지하는 로컬 그리드 좌표들
@export var required_materials: Dictionary = {} # 건설에 필요한 추가 재료 (예: {"wood": 5, "stone": 2})
@export var available_missions: Array[MissionResource] = []
@export var recommended_job: DogResource.Job = DogResource.Job.NONE # 권장 직업 일치 시 보너스 (NONE이면 보너스 대상 아님)
@export var harmony_xp_gain: int = 50 # 배치 시 얻는 조화도 경험치
