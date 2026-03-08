class_name BaseBuilding
extends BaseEntity

## 모든 상호작용 가능한 건물의 부모 클래스입니다.

@onready var interaction_component: InteractionComponent = $InteractionComponent
@onready var mission_component: MissionComponent = $MissionComponent
@onready var sprite: Sprite2D = $Sprite2D

@export var building_data: BuildingResource:
	set(value):
		building_data = value
		if is_inside_tree():
			_apply_building_data()

var available_missions: Array[MissionResource] = []
var _anim_timer: float = 0.0

func _ready() -> void:
	super._ready()
	if building_data:
		_apply_building_data()
	
	if interaction_component:
		interaction_component.interacted.connect(_on_interacted)
	
	if mission_component:
		mission_component.mission_completed.connect(_on_mission_completed)

func _apply_building_data() -> void:
	entity_name = building_data.building_name
	if building_data.texture:
		sprite.texture = building_data.texture
		sprite.hframes = building_data.hframes
		sprite.vframes = building_data.vframes
		sprite.frame = 0
	available_missions = building_data.available_missions

func _process(delta: float) -> void:
	if building_data and (building_data.hframes * building_data.vframes) > 1:
		_anim_timer += delta
		var frame_duration = 1.0 / building_data.animation_fps
		if _anim_timer >= frame_duration:
			_anim_timer -= frame_duration
			sprite.frame = (sprite.frame + 1) % (building_data.hframes * building_data.vframes)

func _on_interacted() -> void:
	if GameManager.is_edit_mode:
		_show_edit_ui()
		return

	# 미션 상태에 따라 다른 처리
	match mission_component.current_state:
		MissionComponent.MissionState.IDLE:
			_show_mission_select_ui()
		MissionComponent.MissionState.IN_PROGRESS:
			print_debug("[BaseBuilding] Mission in progress...")
		MissionComponent.MissionState.COMPLETED:
			mission_component.claim_reward()

func _show_edit_ui() -> void:
	# 중복 팝업 방지: 이미 편집 UI가 표시 중이면 준단
	if get_node_or_null("BuildingEditUI"):
		return
	var ui_scene = load("res://src/ui/popups/BuildingEditUI.tscn")
	var ui = ui_scene.instantiate()
	ui.name = "BuildingEditUI"
	add_child(ui)
	ui.move_requested.connect(_on_move_requested)
	ui.flip_requested.connect(_on_flip_requested)
	ui.store_requested.connect(_on_store_requested)
	print_debug("[BaseBuilding] Showing edit UI for: ", entity_name)

func _on_move_requested() -> void:
	if building_data:
		# 1. 큐프리로 객체 소멸 전 인벤토리에 넣어줌 처리 (비용 0 으로 빌드 모드 시작을 위해)
		GameManager.add_item(building_data.building_id, 1)
		# 2. 이동 모드를 의미하는 "move" 소스와 함께 즉시 빌드 모드 진입
		GameManager.start_build_mode.emit(building_data, 0, "move")
		# 3. 기존 건물을 삭제하여 묶여있던 충돌, 표시 제거
		queue_free()

func _on_flip_requested() -> void:
	sprite.flip_h = not sprite.flip_h
	print_debug("[BaseBuilding] Flipped sprite for: ", entity_name)

func _show_mission_select_ui() -> void:
	var ui_scene = load("res://src/ui/popups/MissionSelectUI.tscn")
	var ui = ui_scene.instantiate()
	add_child(ui)
	ui.setup(available_missions)
	ui.mission_selected.connect(_on_mission_selected)
	print_debug("[BaseBuilding] Showing mission select UI for: ", entity_name)

func _on_store_requested() -> void:
	if building_data:
		GameManager.add_item(building_data.building_id, 1)
		print_debug("[BaseBuilding] Stored building in Bag: ", entity_name)
		queue_free()

func _on_mission_selected(mission: MissionResource) -> void:
	# 마을의 강아지(바둑이)를 찾아서 호출
	var dogs = get_tree().get_nodes_in_group("dogs")
	if dogs.is_empty():
		print_debug("[BaseBuilding] No dog found in the forest!")
		return
		
	var dog = dogs[0] as BaseDog
	if dog:
		# 강아지가 도착하면 미션을 시작하도록 콜백 연결
		dog.interact_with(self , func(): mission_component.start_mission(mission))
		print_debug("[BaseBuilding] Called %s to start mission: %s" % [dog.entity_name, mission.mission_name])

func _on_mission_completed(_mission: MissionResource) -> void:
	# 미션이 완료되면 강아지를 다시 자유 상태로
	var dogs = get_tree().get_nodes_in_group("dogs")
	if not dogs.is_empty():
		var dog = dogs[0] as BaseDog
		dog.set_wandering()
		
	# 완료 연출 (보상 아이콘 표시)
	var reward_scene = load("res://src/ui/commons/RewardIcon.tscn")
	var reward_icon = reward_scene.instantiate()
	add_child(reward_icon)
	# 건물 머리 위쯤에 표시
	reward_icon.position = Vector2(-32, -100)
	reward_icon.clicked.connect(_on_reward_icon_clicked)
	print_debug("[BaseBuilding] Mission completed! Reward icon displayed.")

func _on_reward_icon_clicked() -> void:
	mission_component.claim_reward()

func _on_static_body_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if interaction_component:
			interaction_component.interact()
