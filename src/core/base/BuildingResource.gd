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
@export var available_missions: Array[MissionResource] = []
@export var harmony_xp_gain: int = 50 # 배치 시 얻는 조화도 경험치
