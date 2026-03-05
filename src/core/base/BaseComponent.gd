class_name BaseComponent
extends Node

## 모든 컴포넌트의 부모 클래스.
## 소유주 엔티티에 대한 참조를 가집니다.

var owner_entity: Node2D = null:
	set(value):
		owner_entity = value
		_on_owner_set()

func _on_owner_set() -> void:
	# 상속받는 클래스에서 초기화 로직 구현
	pass
