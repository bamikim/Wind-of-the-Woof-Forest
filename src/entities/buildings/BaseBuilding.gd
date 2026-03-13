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
var anim_speed_scale: float = 1.0
var _pending_dog: BaseDog = null
var _working_dog: BaseDog = null
var grid_pos: Vector2i = Vector2i.ZERO

var _overhead_progress: ProgressBar
var _working_label: Label

func _ready() -> void:
	super._ready()
	if building_data:
		_apply_building_data()
	
	if interaction_component:
		interaction_component.interacted.connect(_on_interacted)
	
	if mission_component:
		mission_component.mission_completed.connect(_on_mission_completed)
		mission_component.mission_started.connect(_on_mission_started)
		
	_setup_overhead_ui()

func _setup_overhead_ui() -> void:
	_overhead_progress = ProgressBar.new()
	_overhead_progress.custom_minimum_size = Vector2(80, 15)
	_overhead_progress.position = Vector2(-40, -120) # 스프라이트 위쪽
	_overhead_progress.show_percentage = false
	_overhead_progress.theme_type_variation = "FlatProgressBar" # (선택적) 테마 설정
	_overhead_progress.hide()
	add_child(_overhead_progress)
	
	_working_label = Label.new()
	_working_label.text = "작업 중..."
	_working_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_working_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	_working_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_working_label.add_theme_constant_override("outline_size", 4)
	_working_label.hide()
	add_child(_working_label)

func _apply_building_data() -> void:
	entity_name = building_data.building_name
	if building_data.texture:
		sprite.texture = building_data.texture
		sprite.hframes = building_data.hframes
		sprite.vframes = building_data.vframes
		sprite.frame = 0
		sprite.offset = building_data.visual_offset
		print_debug("[BaseBuilding] Applied visual_offset: ", building_data.visual_offset, " to ", entity_name)
		sprite.frame = 0
		
		# 1. 기존 충돌체 제거
		var static_body = $StaticBody2D
		for child in static_body.get_children():
			if child is CollisionPolygon2D:
				child.queue_free()
		
		# NavigationObstacle2D: 기존 충돌체처럼 새로 재생성 (occupied_tiles 바닥 마름모 폴리곤 기준)
		var old_obs = get_node_or_null("NavObstacle")
		if old_obs:
			old_obs.queue_free()
			await get_tree().process_frame
				
		# 2. 하나의 통합 충돌체 폴리곤 생성 (다중 타일도 하나로 씌워 빈틈 방지)
		var min_x = 0; var max_x = 0; var min_y = 0; var max_y = 0
		if building_data.occupied_tiles.size() > 0:
			var t0 = building_data.occupied_tiles[0]
			min_x = t0.x; max_x = t0.x; min_y = t0.y; max_y = t0.y
			for t in building_data.occupied_tiles:
				if t.x < min_x: min_x = t.x
				if t.x > max_x: max_x = t.x
				if t.y < min_y: min_y = t.y
				if t.y > max_y: max_y = t.y
		
		var left_pt = Vector2((min_x - max_y) * 128.0 - 64.0, (min_x + max_y) * 64.0)
		var right_pt = Vector2((max_x - min_y) * 128.0 + 64.0, (max_x + min_y) * 64.0)
		var top_pt = Vector2((min_x - min_y) * 128.0, (min_x + min_y) * 64.0 - 112.0)
		var bot_pt = Vector2((max_x - max_y) * 128.0, (max_x + max_y) * 64.0 + 48.0)
		
		var poly = CollisionPolygon2D.new()
		poly.polygon = PackedVector2Array([
			left_pt,
			Vector2(left_pt.x, top_pt.y + 32.0),
			top_pt,
			Vector2(right_pt.x, top_pt.y + 32.0),
			right_pt,
			bot_pt
		])
		static_body.add_child(poly)
		
		# NavigationObstacle2D 생성: occupied_tiles 바닥 전체를 포함하는 다이아몬드 폴리곤
		var obstacle = NavigationObstacle2D.new()
		obstacle.name = "NavObstacle"
		
		# 바닥 타일 전체를 감싸는 다이아몬드 폴리곤 (네비게이션 회피용)
		# 강아지가 타일 안으로 들어오지 못하게 약간 여유폭을 주었습니다.
		var obs_pts: PackedVector2Array = PackedVector2Array()
		obs_pts.append(Vector2(left_pt.x - 30.0, 0.0))
		obs_pts.append(Vector2(0.0, top_pt.y + 40.0))
		obs_pts.append(Vector2(right_pt.x + 30.0, 0.0))
		obs_pts.append(Vector2(0.0, bot_pt.y - 10.0))
		obstacle.vertices = obs_pts
		add_child(obstacle)
		
	available_missions = building_data.available_missions

## 강아지가 일을 수행하기 위해 서야 하는 "정면 바깥" 월드 좌표를 반환합니다.
func get_interaction_position() -> Vector2:
	if not building_data or building_data.occupied_tiles.size() == 0:
		return global_position + Vector2(0, 100)
		
	var max_x = building_data.occupied_tiles[0].x
	var max_y = building_data.occupied_tiles[0].y
	for t in building_data.occupied_tiles:
		if t.x > max_x: max_x = t.x
		if t.y > max_y: max_y = t.y
		
	# 가장 아래쪽 모서리 좌표 (건물의 정면 끝)
	var bot_y = (max_x + max_y) * 64.0 + 48.0
	var bot_x = (max_x - max_y) * 128.0
	
	# 장애물보다 확실히 바깥(아래쪽)에 위치하도록 오프셋 추가
	return global_position + Vector2(bot_x, bot_y + 40.0)

## 건물 스프라이트의 최상단 월드 좌표 (머리 위)를 반환합니다.
func get_overhead_position() -> Vector2:
	if not sprite.texture:
		return Vector2(0, -150)
		
	var frame_size = sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
	var top_y = sprite.offset.y - (frame_size.y / 2.0)
	return Vector2(sprite.offset.x, top_y - 20.0)

func _process(delta: float) -> void:
	if building_data and (building_data.hframes * building_data.vframes) > 1:
		_anim_timer += delta * anim_speed_scale
		var frame_duration = 1.0 / building_data.animation_fps
		if _anim_timer >= frame_duration:
			_anim_timer -= frame_duration
			sprite.frame = (sprite.frame + 1) % (building_data.hframes * building_data.vframes)
			
	# 오버헤드 UI 실시간 업데이트
	if mission_component and mission_component.current_state == MissionComponent.MissionState.IN_PROGRESS:
		if _overhead_progress and not _overhead_progress.visible:
			_overhead_progress.show()
			if _working_label: _working_label.show()
			
		if _overhead_progress:
			_overhead_progress.max_value = mission_component.current_mission.duration_seconds
			_overhead_progress.value = mission_component.current_mission.duration_seconds - mission_component.remaining_time
			
		# 작업 중 텍스트와 프로그레스 바 위치 업데이트 (애니메이션 효과)
		var base_pos = get_overhead_position()
		var bounce_y = sin(Time.get_ticks_msec() / 200.0) * 5.0
		
		if _overhead_progress:
			_overhead_progress.position = base_pos + Vector2(-40, 10 + bounce_y)
		if _working_label:
			_working_label.position = base_pos + Vector2(-40, -15 + bounce_y)
	else:
		if _overhead_progress:
			_overhead_progress.hide()
		if _working_label:
			_working_label.hide()

func _on_interacted() -> void:
	if UIManager.is_edit_mode:
		if mission_component and mission_component.current_state != MissionComponent.MissionState.IDLE:
			UIManager.show_toast("미션이 진행 중인 건물은 편집할 수 없습니다.")
			return
		_show_edit_ui()
		return

	# 강아지가 오고 있는 중이라면 (미션 시작 전이지만 이동 중)
	if _working_dog and mission_component.current_state == MissionComponent.MissionState.IDLE:
		print_debug("[BaseBuilding] Dog is on its way. Please wait.")
		return
		
	# 미션 상태에 따라 다른 처리
	match mission_component.current_state:
		MissionComponent.MissionState.IDLE:
			_show_dog_select_ui()
		MissionComponent.MissionState.IN_PROGRESS:
			_show_mission_progress_ui()
		MissionComponent.MissionState.COMPLETED:
			mission_component.claim_reward()
			
			var completed_icons = get_children().filter(func(c): return c.name == "RewardIcon")
			for icon in completed_icons:
				icon.queue_free()

func _show_edit_ui() -> void:
	# 중복 팝업 방지: 이미 편집 UI가 표시 중이면 준단
	if get_node_or_null("BuildingEditUI"):
		return
	var ui_scene = load("res://src/ui/popups/BuildingEditUI.tscn")
	var ui = ui_scene.instantiate()
	ui.name = "BuildingEditUI"
	add_child(ui)
	ui.z_index = 100
	ui.z_as_relative = false
	ui.move_requested.connect(_on_move_requested)
	ui.flip_requested.connect(_on_flip_requested)
	ui.store_requested.connect(_on_store_requested)
	print_debug("[BaseBuilding] Showing edit UI for: ", entity_name)

func _on_move_requested() -> void:
	if building_data:
		# 2. occupied_tiles 기반으로 새로운 다중 충돌체 생성 (실제 클릭 감지용이므로 작게 만듦: 128x64)
		# 중요: 다중 타일 건물이 BuildCursor의 Area2D와 겹칠 때 "모든 조각"이 충돌을 일으키게끔 레이어 설정
		var static_body = $StaticBody2D
		if static_body:
			static_body.collision_layer = 1
			static_body.collision_mask = 1
		
		# 1. 큐프리로 객체 소멸 전 인벤토리에 넣어줌 처리 (비용 0 으로 빌드 모드 시작을 위해)
		InventoryManager.add_item(building_data.building_id, 1)
		# 2. 이동 모드를 의미하는 "move" 소스와 함께 즉시 빌드 모드 진입
		BuildManager.start_build_mode.emit(building_data, 0, "move")
		# 3. 기존 건물을 삭제하여 묶여있던 충돌, 표시 제거
		queue_free()

func _on_flip_requested() -> void:
	sprite.flip_h = not sprite.flip_h
	print_debug("[BaseBuilding] Flipped sprite for: ", entity_name)

func _show_dog_select_ui() -> void:
	if get_node_or_null("DogSelectUI"): return
	var ui_scene = load("res://src/ui/popups/DogSelectUI.tscn")
	var ui = ui_scene.instantiate()
	ui.name = "DogSelectUI"
	add_child(ui)
	ui.z_index = 100
	ui.z_as_relative = false
	ui.setup()
	ui.dog_selected.connect(_on_dog_selected)
	print_debug("[BaseBuilding] Showing dog select UI for: ", entity_name)

func _on_dog_selected(dog: Node2D) -> void:
	_pending_dog = dog as BaseDog
	_show_mission_select_ui()

func _show_mission_select_ui() -> void:
	var ui_scene = load("res://src/ui/popups/MissionSelectUI.tscn")
	var ui = ui_scene.instantiate()
	add_child(ui)
	ui.z_index = 100
	ui.z_as_relative = false
	ui.setup(available_missions)
	ui.mission_selected.connect(_on_mission_selected)
	print_debug("[BaseBuilding] Showing mission select UI for: ", entity_name)

func _show_mission_progress_ui() -> void:
	if get_node_or_null("MissionProgressUI"): return
	var ui_scene = load("res://src/ui/popups/MissionProgressUI.tscn")
	var ui = ui_scene.instantiate()
	ui.name = "MissionProgressUI"
	add_child(ui)
	ui.z_index = 100
	ui.z_as_relative = false
	
	var dog_name = "강아지"
	if _working_dog:
		dog_name = _working_dog.entity_name
		
	ui.setup(mission_component, dog_name)
	ui.cancel_requested.connect(_on_mission_cancel_requested)

func _on_mission_cancel_requested() -> void:
	print_debug("[BaseBuilding] Mission cancelled.")
	if _working_dog:
		_working_dog.set_wandering()
		_working_dog = null
		
	mission_component.current_state = MissionComponent.MissionState.IDLE
	mission_component.current_mission = null
	anim_speed_scale = 1.0
	if _overhead_progress:
		_overhead_progress.hide()
	if _working_label:
		_working_label.hide()

func _on_store_requested() -> void:
	if building_data:
		InventoryManager.add_item(building_data.building_id, 1)
		print_debug("[BaseBuilding] Stored building in Bag: ", entity_name)
		queue_free()

func _on_mission_selected(mission: MissionResource) -> void:
	if not _pending_dog:
		print_debug("[BaseBuilding] No dog selected for mission!")
		return
		
	# 강아지가 도착하면 미션을 시작하도록 콜백 연결
	_working_dog = _pending_dog
	_pending_dog.interact_with(self , func(): mission_component.start_mission(mission))
	print_debug("[BaseBuilding] Called %s to start mission: %s" % [_pending_dog.entity_name, mission.mission_name])
	_pending_dog = null

func _on_mission_started(_mission: MissionResource) -> void:
	pass

func _on_mission_completed(_mission: MissionResource) -> void:
	anim_speed_scale = 1.0
	
	# 미션이 완료되면 강아지를 다시 자유 상태로
	if _working_dog:
		_working_dog.set_wandering()
		_working_dog = null
		
	# 완료 연출 (보상 아이콘 표시)
	var reward_scene = load("res://src/ui/commons/RewardIcon.tscn")
	var reward_icon = reward_scene.instantiate()
	add_child(reward_icon)
	# 건물 머리 위쪽(다이내믹 높이)에 표시
	var base_pos = get_overhead_position()
	reward_icon.position = base_pos + Vector2(-32, -32) # RewardIcon 크기(64x64) 중앙 정렬
	reward_icon.clicked.connect(_on_reward_icon_clicked)
	print_debug("[BaseBuilding] Mission completed! Reward icon displayed.")

func _on_reward_icon_clicked() -> void:
	mission_component.claim_reward()

func _on_static_body_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# 배치 모드 중에는 다른 건물을 클릭해도 상호작용을 차단합니다
	if BuildManager.is_active:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if interaction_component:
			interaction_component.interact()
