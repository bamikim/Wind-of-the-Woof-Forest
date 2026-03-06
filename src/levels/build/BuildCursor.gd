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
	ghost_sprite.modulate = Color(1, 1, 1, 0.5) # 50% 반투명
	is_active = true
	is_dragging = false
	
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

func _process(_delta: float) -> void:
	if not is_active: return
	
	if is_dragging:
		# 마우스를 드래그할 때만 따라다님
		_update_position(get_global_mouse_position())
		_check_buildable()

func _update_position(mouse_pos: Vector2) -> void:
	# 부모(StartingForest)의 좌표계 기반 타일 스냅핑
	var tilemap = get_parent().get_node_or_null("GroundLayer")
	if tilemap is TileMap:
		# 로컬을 그리드로
		var grid_pos = tilemap.local_to_map(mouse_pos)
		
		# 잔디 타일(0)이 깔려있는지 확인
		var cell_source = tilemap.get_cell_source_id(0, grid_pos)
		can_build = (cell_source != -1) # 바닥이 없으면 설치 불가
		
		current_grid_pos = grid_pos
		# 그리드 중앙 위치 계산
		var snap_pos = tilemap.map_to_local(grid_pos)
		global_position = snap_pos

func _check_buildable() -> void:
	# 바닥 타일이 없는 경우는 _update_position에서 처리함. 추가로 겹치는 영역 체크
	var overlapping = area_2d.get_overlapping_areas()
	
	for area in overlapping:
		# 같은 건물의 InteractionArea와 겹치는지 확인 (여기서는 Area2D의 소속 여부로 판단)
		# 확장을 위해 일단 겹치면 불가 처리 (추후 태그나 그룹 설정 필요)
		if area.name == "InteractionArea" and area.get_parent() != self:
			can_build = false
			break
			
	if can_build:
		ghost_sprite.modulate = Color(0.5, 1.0, 0.5, 0.7) # 연한 녹색
		confirm_btn.disabled = false
	else:
		ghost_sprite.modulate = Color(1.0, 0.5, 0.5, 0.7) # 연한 붉은색
		confirm_btn.disabled = true

func _on_confirm() -> void:
	if can_build and current_building_res:
		build_confirmed.emit(current_building_res, current_grid_pos, current_cost, current_source)
		deactivate()

func _on_cancel() -> void:
	build_canceled.emit(current_source)
	deactivate()
