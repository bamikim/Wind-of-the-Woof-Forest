extends Control

@onready var close_button: Button = $Panel/CloseButton
@onready var pins_container: HBoxContainer = $Panel/PinsContainer

var available_missions = [
	"res://data/missions/exploration_mission_wood.tres",
	"res://data/missions/exploration_mission_stone.tres",
	"res://data/missions/exploration_mission_dew.tres"
]

func _ready() -> void:
	hide()
	close_button.pressed.connect(hide)
	visibility_changed.connect(_on_visibility_changed)
	
func _on_visibility_changed() -> void:
	if visible:
		_populate_pins()

func _populate_pins() -> void:
	for child in pins_container.get_children():
		child.queue_free()
		
	for mission_path in available_missions:
		var res = load(mission_path) as MissionResource
		if res:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(120, 160)
			
			var text = res.mission_name + "\n\n"
			text += "보상: " + res.reward_material_type + " x" + str(res.reward_material_amount) + "\n"
			text += "시간: " + str(res.duration_seconds / 60.0) + "분"
			
			btn.text = text
			btn.pressed.connect(_on_pin_pressed.bind(res))
			pins_container.add_child(btn)

func _on_pin_pressed(mission_res: MissionResource) -> void:
	# 강아지 선택 UI 열기
	var select_ui_scene = load("res://src/ui/popups/DogSelectUI.tscn")
	var select_ui = select_ui_scene.instantiate()
	get_parent().add_child(select_ui) # HarmonyLevelUI 자식으로 추가 (가장 위)
	select_ui.setup()
	
	select_ui.dog_selected.connect(func(dog: Node2D):
		ExplorationManager.start_exploration(mission_res, dog)
		hide() # 탐험 시작 시 지도 닫기
		UIManager.show_toast(dog.entity_name + " 강아지가 탐험을 떠났습니다!")
	)
