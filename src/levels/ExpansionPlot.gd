class_name ExpansionPlot
extends Node2D

## 영토 확장 기능을 담당하는 필지 클래스입니다.

signal plot_unlocked

@export var unlock_cost: int = 500
@export var is_locked: bool = true

@onready var fog_cloud: Node2D = $FogCloud
@onready var interaction_area: Area2D = $InteractionArea
@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var dim_overlay: Polygon2D = $DimOverlay
@onready var lock_icon: Sprite2D = $LockIcon

func _ready() -> void:
	if not is_locked:
		unlock_immediately()
	else:
		# 잠긴 상태 연출 (반투명 어둡게)
		if dim_overlay: dim_overlay.show()
		if lock_icon: lock_icon.show()

func unlock_immediately() -> void:
	is_locked = false
	if fog_cloud:
		fog_cloud.hide()
	if nav_region:
		nav_region.enabled = true
	if dim_overlay: dim_overlay.hide()
	if lock_icon: lock_icon.hide()
	interaction_area.input_pickable = false

func request_unlock() -> void:
	if not is_locked: return
	
	if GameManager.dog_treats >= unlock_cost:
		_perform_unlock()
	else:
		print_debug("[ExpansionPlot] Not enough dog treats! Need: ", unlock_cost)

func _perform_unlock() -> void:
	GameManager.dog_treats -= unlock_cost
	is_locked = false
	
	# 안개 걷히는 연출 시작
	if fog_cloud and fog_cloud.has_method("disperse"):
		fog_cloud.disperse()
	else:
		if fog_cloud: fog_cloud.hide()
	
	if nav_region:
		nav_region.enabled = true
		
	if dim_overlay: dim_overlay.hide()
	if lock_icon: lock_icon.hide()
		
	interaction_area.input_pickable = false
	plot_unlocked.emit()
	print_debug("[ExpansionPlot] Plot unlocked!")

func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		request_unlock()
