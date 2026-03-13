class_name DogResource
extends Resource

## 강아지 개체의 속성과 외형을 정의하는 리소스 클래스입니다.

@export var dog_id: String = ""
@export var dog_name: String = "Unknown Dog"
@export var breed: String = "Mix"
@export var texture: Texture2D = null # 기본/미리보기용
@export var idle_spritesheet: Texture2D = null
@export var walk_spritesheet: Texture2D = null
	
enum Job {NONE, FARMER, CHEF, BAKER, EXPLORER}
enum Personality {NORMAL, ENERGETIC, METICULOUS, LAZY, CURIOUS}

@export var job: Job = Job.NONE
@export var personality: Personality = Personality.NORMAL
