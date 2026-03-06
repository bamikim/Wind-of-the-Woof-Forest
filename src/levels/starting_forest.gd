extends Node2D

## 월드 초기화 및 입력 처리를 담당합니다.

@onready var ground_layer: TileMap = $GroundLayer
@onready var plots_node: Node2D = $Plots
@onready var object_manager: Node2D = $ObjectManager
@onready var build_cursor: Node2D = $BuildCursor

func _ready() -> void:
	# 초기 10x10 영역만 타일 생성
	_generate_initial_map(10, 10)
	# 5x5 필지 시스템 구축 (전체 20x20 맵 기준)
	_setup_expansion_plots(20, 20, 5)
	
	# 배치 모드 연동
	GameManager.start_build_mode.connect(_on_start_build_mode)
	if build_cursor:
		build_cursor.build_confirmed.connect(_on_build_confirmed)
		build_cursor.build_canceled.connect(_on_build_canceled)

func _generate_initial_map(w: int, h: int) -> void:
	var offset_x = - floor(w / 2.0)
	var offset_y = - floor(h / 2.0)
	
	for x in range(w):
		for y in range(h):
			set_tile(int(x + offset_x), int(y + offset_y), 0)
	
	print_debug("[StartingForest] Initial 10x10 map tiles generated.")

func _setup_expansion_plots(_map_w: int, _map_h: int, _plot_size: int) -> void:
	var plot_scene = load("res://src/levels/ExpansionPlot.tscn")
	
	# 동, 서, 남, 북 4방향 필지 좌표 (10x10 크기)
	var plot_configs = [
		Vector2i(-5, -15), # North
		Vector2i(-5, 5), # South
		Vector2i(-15, -5), # West
		Vector2i(5, -5) # East
	]
	
	for grid_pos in plot_configs:
		var plot = plot_scene.instantiate()
		plots_node.add_child(plot)
		
		# 10x10 필지의 중앙 world 위치 (5.0, 5.0 tiles offset)
		var world_center = ground_layer.map_to_local(Vector2(grid_pos.x + 5.0, grid_pos.y + 5.0))
		plot.global_position = world_center
		plot.is_locked = true
		
		if plot is ExpansionPlot:
			plot.grid_pos = grid_pos
			plot.plot_unlocked.connect(_on_plot_unlocked.bind(grid_pos))
	
	print_debug("[StartingForest] Cross-shaped expansion plots configured.")

func _on_plot_unlocked(grid_pos: Vector2i) -> void:
	# 필지가 해금되면 10x10 타일 채움
	_fill_plot_tiles(grid_pos, 10)
	print_debug("[StartingForest] 10x10 tiles filled for plot at: ", grid_pos)

func _fill_plot_tiles(start_pos: Vector2i, size: int) -> void:
	for x in range(size):
		for y in range(size):
			set_tile(start_pos.x + x, start_pos.y + y, 0)

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
		GameManager.mark_as_purchased(res.building_id)
	elif source == "bag" or source == "move":
		if not GameManager.remove_item(res.building_id, 1):
			print_debug("[StartingForest] Build failed: Item not in inventory!")
			return
	
	# 실제 건물 생성 및 배치
	var building_scene = load("res://src/entities/buildings/BaseBuilding.tscn")
	var building = building_scene.instantiate() as BaseBuilding
	object_manager.add_child(building)
	building.building_data = res
	place_object_at_grid(building, grid_pos)
	
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
		GameManager.open_shop_requested.emit()
