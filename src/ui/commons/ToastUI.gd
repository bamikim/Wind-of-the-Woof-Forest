extends Control

@onready var label: Label = $Panel/Label

func _ready() -> void:
	# 초기 상태 투명하게
	modulate.a = 0.0

func show_message(msg: String, duration: float = 2.0) -> void:
	label.text = msg
	
	# 약간 아래에서 위로 올라오면서 페이드 인
	var start_pos = position + Vector2(0, 50)
	var end_pos = position
	
	position = start_pos
	
	var tween = create_tween()
	# 등장
	tween.tween_property(self , "position", end_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(self , "modulate:a", 1.0, 0.3)
	
	# 대기
	tween.tween_interval(duration)
	
	# 퇴장
	tween.tween_property(self , "position", end_pos - Vector2(0, 50), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(self , "modulate:a", 0.0, 0.3)
	
	# 삭제
	tween.tween_callback(queue_free)
