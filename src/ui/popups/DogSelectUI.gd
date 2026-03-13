extends Control

## 미션을 수행할 강아지 선택 창 스크립트입니다.

signal dog_selected(dog: Node2D)
signal selection_canceled

@onready var dog_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/DogList
@onready var close_button: Button = $Panel/CloseButton

const JOB_NAMES = {
	0: "자유업",
	1: "농부",
	2: "셰프",
	3: "제빵사",
	4: "탐험가"
}

const PERSONALITY_NAMES = {
	0: "평범함",
	1: "활발함",
	2: "꼼꼼함",
	3: "게으름",
	4: "호기심"
}

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)

func setup() -> void:
	_refresh_list()

func _refresh_list() -> void:
	for child in dog_list.get_children():
		child.queue_free()
	
	var all_dogs = get_tree().get_nodes_in_group("dogs")
	# 현재 유휴 상태인 강아지만 필터링 (선택적)
	var available_dogs = []
	for dog in all_dogs:
		if dog.current_state == dog.DogState.WANDERING:
			available_dogs.append(dog)
			
	if available_dogs.is_empty():
		var lbl = Label.new()
		lbl.text = "현재 일을 할 수 있는 강아지가 없습니다."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dog_list.add_child(lbl)
		return
		
	for dog in available_dogs:
		var dog_res = dog.get("dog_data")
		var job_str = "자유업"
		var per_str = "평범함"
		if dog_res:
			job_str = JOB_NAMES.get(dog_res.job, "자유업")
			per_str = PERSONALITY_NAMES.get(dog_res.personality, "평범함")
			
		var btn = Button.new()
		btn.text = "%s (직업: %s / 성격: %s)" % [dog.entity_name, job_str, per_str]
		btn.pressed.connect(_on_dog_btn_pressed.bind(dog))
		dog_list.add_child(btn)

func _on_dog_btn_pressed(dog: Node2D) -> void:
	dog_selected.emit(dog)
	queue_free()

func _on_close_button_pressed() -> void:
	selection_canceled.emit()
	queue_free()
