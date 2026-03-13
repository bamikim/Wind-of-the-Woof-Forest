extends Node2D

## 월드 초기화 및 입력 처리를 담당합니다.

@onready var ground_layer: TileMap = $GroundLayer
@onready var plots_node: Node2D = $Plots
@onready var object_manager: Node2D = $ObjectManager
@onready var build_cursor: Node2D = $BuildCursor

var nav_region: NavigationRegion2D

func _ready() -> void:
	# 내비게이션 리전 생성
	nav_region = NavigationRegion2D.new()
	add_child(nav_region)
	
	# 30x30 전체 맵 생성
	_generate_initial_map(30, 30)
	
	# 타일 기반 내비게이션 업데이트
	_update_navigation_polygon()
	
	# 배치 모드 연동
	BuildManager.start_build_mode.connect(_on_start_build_mode)
	GameManager.game_loaded.connect(_on_game_loaded)
	
	if build_cursor:
		build_cursor.build_confirmed.connect(_on_build_confirmed)
		build_cursor.build_canceled.connect(_on_build_canceled)

func _generate_initial_map(w: int, h: int) -> void:
	var offset_x = - floor(w / 2.0)
	var offset_y = - floor(h / 2.0)
	
	for x in range(w):
		for y in range(h):
			set_tile(int(x + offset_x), int(y + offset_y), 0)
	
	print_debug("[StartingForest] %dx%d map tiles generated." % [w, h])

func _on_game_loaded() -> void:
	# 세이브에서 불러온 건물들을 필드에 생성합니다
	for b_data in InventoryManager.placed_buildings:
		var res_path = b_data.get("path", "")
		if res_path == "": continue
			
		var res = load(res_path) as BuildingResource
		if res:
			var building_scene = load("res://src/entities/buildings/BaseBuilding.tscn")
			var building = building_scene.instantiate() as BaseBuilding
			object_manager.add_child(building)
			building.add_to_group("buildings")
			building.building_data = res
			
			building.global_position = Vector2(b_data.get("pos_x", 0), b_data.get("pos_y", 0))
			building.sprite.flip_h = b_data.get("flip_h", false)
			# 저장된 위치를 설정 (ground_layer 기준 그리드 좌표)
			if ground_layer:
				building.grid_pos = Vector2i(ground_layer.local_to_map(building.global_position))
			
			# 미션 정보 복원
			var m_state = b_data.get("m_state", 0)
			var m_time = b_data.get("m_time", 0.0)
			var m_id = b_data.get("m_id", "")
			if m_state == 1 and building.mission_component:
				if m_id != "":
					var mission_res = load(m_id) as MissionResource
					if mission_res:
						building.mission_component.current_mission = mission_res
				building.mission_component.current_state = m_state
				building.mission_component.remaining_time = m_time
				building.mission_component.bonus_amount = b_data.get("m_b_amt", 0)
				building.mission_component.bonus_xp = b_data.get("m_b_xp", 0)
				building.mission_component.extra_chance_multi = b_data.get("m_e_multi", 1.0)
				building.mission_component.worker_name = b_data.get("m_w_name", "")
				building.mission_component.worker_personality = b_data.get("m_w_per", 0)
				building.mission_component.worker_job = b_data.get("m_w_job", 0)
				
				# 활성 미션이 있다면 배회 중인 강아지를 하나 찾아 건물에 재할당
				var dogs = get_tree().get_nodes_in_group("dogs")
				for d in dogs:
					if d is BaseDog and d.current_state == d.DogState.WANDERING:
						building._working_dog = d
						d.force_working_at(building)
						break
				
	print_debug("[StartingForest] Spawning placed buildings complete. Count: ", InventoryManager.placed_buildings.size())
	
	# 아직 진행 중인 탐험 미션 복구
	var pending_explorations = GameManager.get_meta("pending_explorations", [])
	if pending_explorations.size() > 0:
		var dogs = get_tree().get_nodes_in_group("dogs")
		for exp_dict in pending_explorations:
			var m_id = exp_dict.get("m_id", "")
			var d_name = exp_dict.get("d_name", "")
			var t_left = exp_dict.get("time_left", 0.0)
			
			var target_dog = null
			for d in dogs:
				if d.entity_name == d_name:
					target_dog = d
					break
					
			if target_dog:
				var res = load(m_id) as MissionResource
				if res:
					# 시간만 갱신된 상태로 ExplorationManager에 다시 할당
					ExplorationManager.active_explorations.append({
						"mission": res,
						"dog": target_dog,
						"time_left": t_left
					})
					target_dog.hide()
					target_dog.set_process(false)
					target_dog.set_physics_process(false)
					target_dog.current_state = target_dog.DogState.WORKING
					print_debug("[StartingForest] Resumed exploration: ", d_name)
		
		# 처리 후 정리
		GameManager.set_meta("pending_explorations", [])
	
	# 오프라인 미션 보상 UI 띄우기 (결과가 존재하면)
	var offline_missions = GameManager.get_meta("offline_completed_missions", [])
	if offline_missions.size() > 0:
		var ui_scene = load("res://src/ui/popups/OfflineJournalUI.tscn")
		if ui_scene:
			var ui = ui_scene.instantiate()
			ui.name = "OfflineJournalUI"
			add_child(ui)
			ui.z_index = 200
			ui.setup(offline_missions)
			GameManager.set_meta("offline_completed_missions", []) # 초기화


## 그리드 좌표(Tile)를 월드 좌표(Vector2)로 변환합니다.
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if ground_layer:
		return ground_layer.map_to_local(grid_pos)
	return Vector2.ZERO

## 특정 그리드 위치에 오브젝트를 배치합니다.
func place_object_at_grid(object: Node2D, grid_pos: Vector2i) -> void:
	object.global_position = grid_to_world(grid_pos)
	print_debug("[StartingForest] Object %s placed at grid %s" % [object.name, grid_pos])

## 특정 좌표에 타일을 배치합니다.
## type 0: Grass
func set_tile(grid_x: int, grid_y: int, source_id: int) -> void:
	if ground_layer:
		# layer 0, coords, source_id, atlas_coords
		ground_layer.set_cell(0, Vector2i(grid_x, grid_y), source_id, Vector2i(0, 0))

func _update_navigation_polygon() -> void:
	if not ground_layer or not nav_region: return
	
	var nav_poly = NavigationPolygon.new()
	nav_poly.agent_radius = 24.0 # 강아지 반경과 동일하게 맞춤
	
	# 현재 깔린 모든 타일의 외곽을 감싸는 단일 다각형 생성 (간략화된 예시)
	# 실제로는 셀들을 모아서 Outline을 병합해야 하지만, Isomaetric의 특성상 맵의 가장 큰 외곽 4개 점만 잡아도 됩니다.
	# 현재 맵은 초기 10x10 및 추가된 필지 구조입니다. 
	# 여기서는 임시로 전체를 아우르는 아주 거대한 폴리곤을 던져줍니다.
	var outline = PackedVector2Array()
	# 대략적으로 타일맵을 충분히 덮을 크기 (-100, -100 ~ 100, 100 타일 범위)
	var p1 = ground_layer.map_to_local(Vector2(-30, -30))
	var p2 = ground_layer.map_to_local(Vector2(30, -30))
	var p3 = ground_layer.map_to_local(Vector2(30, 30))
	var p4 = ground_layer.map_to_local(Vector2(-30, 30))
	
	outline.append(Vector2(0, p1.y)) # 맨 위
	outline.append(Vector2(p2.x, 0)) # 오른쪽 끝
	outline.append(Vector2(0, p3.y)) # 맨 아래
	outline.append(Vector2(p4.x, 0)) # 왼쪽 끝
	
	nav_poly.add_outline(outline)
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly
	print_debug("[StartingForest] NavigationPolygon updated.")

# --- Build Mode Logic ---
func _on_start_build_mode(res: Resource, cost: int, source: String) -> void:
	if build_cursor and res is BuildingResource:
		print_debug("[StartingForest] Entered Build Mode with: ", res.building_name)
		build_cursor.activate(res as BuildingResource, cost, source)
		if has_node("GridOverlay"):
			$GridOverlay.set_active(true)

func _on_build_confirmed(res: BuildingResource, grid_pos: Vector2i, cost: int, source: String) -> void:
	print_debug("[StartingForest] Building placed at: ", grid_pos)
	
	if has_node("GridOverlay"):
		$GridOverlay.set_active(false)
	
	if source == "shop":
		if not GameManager.deduct_treats(cost):
			print_debug("[StartingForest] Build failed: Not enough treats!")
			return
		
		for mat in res.required_materials.keys():
			GameManager.remove_material(mat, res.required_materials[mat])
			
		InventoryManager.mark_as_purchased(res.building_id)
	elif source == "bag" or source == "move":
		if not InventoryManager.remove_item(res.building_id, 1):
			print_debug("[StartingForest] Build failed: Item not in inventory!")
			return
	
	# 실제 건물 생성 및 배치
	var building_scene = load("res://src/entities/buildings/BaseBuilding.tscn")
	var building = building_scene.instantiate() as BaseBuilding
	object_manager.add_child(building)
	building.add_to_group("buildings")
	building.building_data = res
	place_object_at_grid(building, grid_pos)
	building.grid_pos = grid_pos
	
	# 배치 연출 (바운스)
	var tween = create_tween()
	var original_scale = building.scale
	building.scale = Vector2(0, 0)
	tween.tween_property(building, "scale", original_scale * 1.2, 0.2).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(building, "scale", original_scale, 0.1).set_trans(Tween.TRANS_BOUNCE)
	
	# 먼지 파티클 생성
	var dust_scene = load("res://src/vfx/DustParticles.tscn")
	if dust_scene:
		var dust = dust_scene.instantiate()
		object_manager.add_child(dust)
		dust.global_position = ground_layer.map_to_local(grid_pos)
		dust.emitting = true
		# 사운드도 나중에 SoundManager 연동 가능

func _on_build_canceled(source: String) -> void:
	print_debug("[StartingForest] Build Mode canceled.")
	if has_node("GridOverlay"):
		$GridOverlay.set_active(false)
	
	if source == "shop":
		UIManager.emit_open_shop_requested()
