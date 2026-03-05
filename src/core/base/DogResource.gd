class_name DogResource
extends Resource

## 강아지 개체의 속성과 외형을 정의하는 리소스 클래스입니다.

@export var dog_id: String = ""
@export var dog_name: String = "Unknown Dog"
@export var breed: String = "Mix"
@export var texture: Texture2D = null # 기본/미리보기용
@export var idle_spritesheet: Texture2D = null
@export var walk_spritesheet: Texture2D = null
@export var move_speed_multiplier: float = 1.0
