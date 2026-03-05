class_name BaseEntity
extends Node2D

## 모든 게임 내 개체(강아지, 건물)의 부모 클래스.
## 기본적인 상태 관리 및 컴포넌트 참조 기능을 포함합니다.

@export var entity_name: String = "Unknown Entity"
@export var entity_id: String = ""

func _ready() -> void:
	# 자식 노드들 중 컴포넌트들을 찾아 소유주 설정
	for child in get_children():
		if child is BaseComponent:
			child.owner_entity = self
	
	print_debug("[BaseEntity] %s initialized." % entity_name)
