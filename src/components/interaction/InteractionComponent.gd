class_name InteractionComponent
extends BaseComponent

## 마우스 클릭 및 상호작용 이벤트를 감지하는 컴포넌트입니다.

signal interacted

func _ready() -> void:
	# 부모 노드가 Area2D인 경우 등 다양한 상황에 대비할 수 있지만,
	# 여기서는 간단하게 owner_entity의 input_event를 활용하거나 
	# 부모가 상속받는 클래스에서 직접 호출하도록 설계합니다.
	pass

func interact() -> void:
	interacted.emit()
	print_debug("[InteractionComponent] Interaction triggered on: ", owner_entity.entity_name if owner_entity else "Unknown")
