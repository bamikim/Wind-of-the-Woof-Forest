extends Control

## 미션 완료 시 나타나는 보상 아이콘 스크립트입니다.

signal clicked

@onready var texture_rect: TextureRect = $TextureRect

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit()
		_animate_collection()

func _animate_collection() -> void:
	# 간단한 수령 애니메이션 (위로 올라가며 사라짐)
	var tween = create_tween()
	tween.tween_property(self , "position:y", position.y - 100, 0.5)
	tween.parallel().tween_property(self , "modulate:a", 0.0, 0.5)
	tween.finished.connect(queue_free)
