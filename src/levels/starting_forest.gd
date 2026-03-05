extends Node2D

## 월드 초기화 및 입력 처리를 담당합니다.

@onready var ground_layer: TileMap = $GroundLayer
@onready var plots_node: Node2D = $Plots

func _ready() -> void:
	# 전체 20x20 맵 생성
	_generate_initial_map(20, 20)
	# 5x5 필지 시스템 구축
	_setup_expansion_plots(20, 20, 5)

func _generate_initial_map(w: int, h: int) -> void:
	var offset_x = - floor(w / 2.0)
	var offset_y = - floor(h / 2.0)
	
	for x in range(w):
		for y in range(h):
			set_tile(int(x + offset_x), int(y + offset_y), 0)
	
	print_debug("[StartingForest] Map tiles generated.")

func _setup_expansion_plots(map_w: int, map_h: int, plot_size: int) -> void:
	var plot_scene = load("res://src/levels/ExpansionPlot.tscn")
	var offset_x = - floor(map_w / 2.0)
	var offset_y = - floor(map_h / 2.0)
	
	for px in range(0, map_w, plot_size):
		for py in range(0, map_h, plot_size):
			# 필지의 시작 좌표
			var grid_pos = Vector2i(int(px + offset_x), int(py + offset_y))
			
			# 중앙 10x10 영역 (-5 to 4) 체크
			var is_center = (grid_pos.x >= -5 and grid_pos.x < 5) and (grid_pos.y >= -5 and grid_pos.y < 5)
			
			if not is_center:
				var plot = plot_scene.instantiate()
				plots_node.add_child(plot)
				# 필지 위치를 5x5 타일 뭉치 중앙으로 설정
				var world_center = ground_layer.map_to_local(grid_pos + Vector2i(2, 2))
				plot.global_position = world_center
				plot.is_locked = true
				# 필지 크기에 맞게 충돌체/안개 조절 필요 (현재는 기본 씬 사용)
	
	print_debug("[StartingForest] Expansion plots configured.")

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
