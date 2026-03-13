extends Control

@onready var label: Label = $Label

var target_position: Vector2 = Vector2.ZERO
var random_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	pass

func setup(icon_text: String, start_pos: Vector2, t_pos: Vector2) -> void:
	label.text = icon_text
	global_position = start_pos
	target_position = t_pos
	
	# 초기 흩뿌려지는 듯한 랜덤 오프셋
	random_offset = Vector2(randf_range(-60, 60), randf_range(-80, -20))

	# 크기 0에서 커지면서 등장
	scale = Vector2.ZERO
	
	var tween = create_tween()
	# 1. 튀어오르기 (포물선 느낌을 위해 ease_out 적용)
	tween.tween_property(self , "global_position", global_position + random_offset, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(self , "scale", Vector2(1.5, 1.5), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# 2. 약간 대기
	tween.tween_interval(0.1)
	
	# 3. 목표 위치로 쓩 날아가기
	tween.tween_property(self , "global_position", target_position, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(self , "scale", Vector2(0.5, 0.5), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# 4. 파괴
	tween.tween_callback(queue_free)
