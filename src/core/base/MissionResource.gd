class_name MissionResource
extends Resource

## 미션 데이터를 정의하는 리소스 클래스입니다.

@export var mission_id: String = ""
@export var mission_name: String = "Untitled Mission"
@export var duration_seconds: float = 10.0
@export var reward_amount: int = 10
@export var reward_xp: int = 5
@export var extra_reward_id: String = ""
@export var extra_reward_chance: float = 0.0
@export var reward_material_type: String = "" # 탐험 미션용 (예: "wood", "stone", "dew")
@export var reward_material_amount: int = 0
@export var icon: Texture2D = null
