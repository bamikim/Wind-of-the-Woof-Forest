extends Node2D
class_name BuildCursor

## 건물 배치 모드(Build Mode)에서 유저가 드래그하는 '고스트 미리보기' 스크립트입니다.

signal build_confirmed(res: BuildingResource, grid_pos: Vector2i, cost: int, source: String)
signal build_canceled(source: String)

@onready var ghost_sprite: Sprite2D = $GhostSprite
@onready var area_2d: Area2D = $Area2D
@onready var gizmo_ui: Control = $GizmoUI
@onready var confirm_btn: Button = $GizmoUI/HBoxContainer/ConfirmBtn
@onready var cancel_btn: Button = $GizmoUI/HBoxContainer/CancelBtn

var current_building_res: BuildingResource = null
var is_active: bool = false
var can_build: bool = true
var current_grid_pos: Vector2i = Vector2i.ZERO
var current_cost: int = 0
var current_source: String = ""
var is_dragging: bool = false
var _anim_timer: float = 0.0

# 지오메트리 상수 (아이소메트릭 그리드 256x128 기준)
const TILE_WIDTH = 256
const TILE_HEIGHT = 128

func _ready() -> void:
	hide()
	confirm_btn.pressed.connect(_on_confirm)
	cancel_btn.pressed.connect(_on_cancel)
	
	gizmo_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gizmo_ui.has_node("HBoxContainer"):
		gizmo_ui.get_node("HBoxContainer").mouse_filter = Control.MOUSE_FILTER_IGNORE

func activate(res: BuildingResource, cost: int, source: String) -> void:
	current_building_res = res
	current_cost = cost
	current_source = source
	ghost_sprite.texture = res.texture
	ghost_sprite.hframes = res.hframes
	ghost_sprite.vframes = res.vframes
	ghost_sprite.frame = 0
	ghost_sprite.offset = res.visual_offset
	ghost_sprite.modulate = Color(1, 1, 1, 0.5) # 50% 반투명
	print_debug("[BuildCursor] Ghost offset set to: ", res.visual_offset, " for ", res.building_name)
	
	# 다중 타일 점유 범위에 맞추어 충돌 영역 재생성
	for child in area_2d.get_children():
		if child is CollisionPolygon2D:
			child.queue_free()
			
	for tile_pos in current_building_res.occupied_tiles:
		var poly = CollisionPolygon2D.new()
		var local_offset = Vector2((tile_pos.x - tile_pos.y) * 128.0, (tile_pos.x + tile_pos.y) * 64.0)
		poly.polygon = PackedVector2Array([
			Vector2(-128, 0) + local_offset,
			Vector2(0, -64) + local_offset,
			Vector2(128, 0) + local_offset,
			Vector2(0, 64) + local_offset
		])
		area_2d.add_child(poly)
	
	is_active = true
	is_dragging = false
	BuildManager.is_active = true
	
	_update_position(get_global_mouse_position())
	_check_buildable()
	gizmo_ui.show()
	show()
	
	# 애니메이션 연출 (바운스)
	var tween = create_tween()
	scale = Vector2(0.5, 0.5)
	tween.tween_property(self , "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self , "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func deactivate() -> void:
	is_active = false
	is_dragging = false
	current_building_res = null
	BuildManager.is_active = false
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_stop_drag()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_drag()
		else:
			_stop_drag()

func _start_drag() -> void:
	gizmo_ui.hide()
	ghost_sprite.position.y = -15
	is_dragging = true
	_update_position(get_global_mouse_position())

func _stop_drag() -> void:
	if is_dragging:
		is_dragging = false
		ghost_sprite.position.y = 0
		_update_position(get_global_mouse_position())
		_check_buildable()
		gizmo_ui.show()

func _process(delta: float) -> void:
	if not is_active: return
	
	if current_building_res and (current_building_res.hframes * current_building_res.vframes) > 1:
		_anim_timer += delta
		var frame_duration = 1.0 / current_building_res.animation_fps
		if _anim_timer >= frame_duration:
			_anim_timer -= frame_duration
			ghost_sprite.frame = (ghost_sprite.frame + 1) % (current_building_res.hframes * current_building_res.vframes)
	
	if is_dragging:
		# 마우스를 드래그할 때만 따라다님
		_update_position(get_global_mouse_position())
		
	# 처음 배치 모드가 켜진 직후에는 물리 엔진의 충돌 갱신이 한 프레임 지연될 수 있으므로,
	# 매 틱마다 겹침 여부를 갱신하여 상점에서 사자마자 바로 겹쳐 짓는 버그를 차단합니다.
	_check_buildable()

func _update_position(mouse_pos: Vector2) -> void:
	# 부모(StartingForest)의 좌표계 기반 타일 스냅핑
	var tilemap = get_parent().get_node_or_null("GroundLayer")
	if tilemap is TileMap:
		# 로컬을 그리드로
		var grid_pos = tilemap.local_to_map(mouse_pos)
		
		# 잔디 타일(0)이 점유하는 모든 타일 영역에 위치해 있는지 검사
		can_build = true
		for tile_pos in current_building_res.occupied_tiles:
			var check_pos = grid_pos + tile_pos
			var cell_source = tilemap.get_cell_source_id(0, check_pos)
			if cell_source == -1: # 바닥이 없으면 설치 불가
				can_build = false
				break
		
		current_grid_pos = grid_pos
		# 그리드 중앙 위치 계산
		var snap_pos = tilemap.map_to_local(grid_pos)
		global_position = snap_pos
		queue_redraw() # 위치가 바뀔 때마다 테두리 다시 그리기

func _check_buildable() -> void:
	# 바닥 타일이 없는 경우는 _update_position에서 처리함. 
	# 만약 바닥이 없어서 이미 can_build == false라면 추가 검사 생략
	if not can_build:
		ghost_sprite.modulate = Color(1.0, 0.5, 0.5, 0.7) # 연한 붉은색
		confirm_btn.disabled = true
		queue_redraw()
		return

	# 추가로 겹치는 영역 체크 (건물은 주로 StaticBody2D를 사용)
	# 물리 엔진 틱 지연이나 형태적 한계를 보완하기 위해 
	# 실시간으로 생성되어 있는 기존 건물들의 occupied_tiles 배열과 직접 좌표 비교를 수행
	if can_build:
		# 현재 설치하려는 건물이 덮게 될 절대 그리드 좌표 목록
		var target_tiles = []
		for t_pos in current_building_res.occupied_tiles:
			target_tiles.append(current_grid_pos + t_pos)
		
		var all_buildings = get_tree().get_nodes_in_group("buildings")
		for building in all_buildings:
			if building == self or not building.building_data or building.is_queued_for_deletion():
				continue
				
			var b_grid_pos = Vector2i.ZERO
			if "grid_pos" in building:
				b_grid_pos = building.grid_pos
			else:
				b_grid_pos = Vector2i(
					int(round(get_parent().get_node("GroundLayer").local_to_map(building.global_position).x)),
					int(round(get_parent().get_node("GroundLayer").local_to_map(building.global_position).y))
				)
			
			for t_pos in building.building_data.occupied_tiles:
				var occupied_absolute_pos = b_grid_pos + t_pos
				if target_tiles.has(occupied_absolute_pos):
					can_build = false
					break
			
			if not can_build:
				break
				
	# 레거시 InteractionArea 지원 병행 (확장성 대비)
	if can_build:
		var overlapping_areas = area_2d.get_overlapping_areas()
		for area in overlapping_areas:
			if area.name == "InteractionArea" and area.get_parent() != self:
				can_build = false
				break
			
	if can_build:
		ghost_sprite.modulate = Color(0.5, 1.0, 0.5, 0.7) # 연한 녹색
		confirm_btn.disabled = false
	else:
		ghost_sprite.modulate = Color(1.0, 0.5, 0.5, 0.7) # 연한 붉은색
		confirm_btn.disabled = true
		
	queue_redraw() # 색상 변경 시 테두리 색도 다시 그리기

func _on_confirm() -> void:
	if can_build and current_building_res:
		build_confirmed.emit(current_building_res, current_grid_pos, current_cost, current_source)
		deactivate()

func _on_cancel() -> void:
	build_canceled.emit(current_source)
	deactivate()

func _draw() -> void:
	if not is_active or not current_building_res: return
	
	var color = Color(0.3, 1.0, 0.3, 0.8) if can_build else Color(1.0, 0.3, 0.3, 0.8)
	var width = 4.0
	
	for tile_pos in current_building_res.occupied_tiles:
		var local_offset = Vector2((tile_pos.x - tile_pos.y) * 128.0, (tile_pos.x + tile_pos.y) * 64.0)
		var points = PackedVector2Array([
			Vector2(0, -64) + local_offset,
			Vector2(128, 0) + local_offset,
			Vector2(0, 64) + local_offset,
			Vector2(-128, 0) + local_offset,
			Vector2(0, -64) + local_offset # 도형 닫기
		])
		
		# 투명한 채우기
		draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.2))
		# 외곽선
		draw_polyline(points, color, width, true)
