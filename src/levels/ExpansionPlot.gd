class_name ExpansionPlot
extends Node2D

## 영토 확장 기능을 담당하는 필지 클래스입니다.

signal plot_unlocked

@export var unlock_cost: int = 500
@export var is_locked: bool = true
var grid_pos: Vector2i = Vector2i.ZERO

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
	interaction_area.monitoring = false

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
	interaction_area.monitoring = false
	plot_unlocked.emit()
	print_debug("[ExpansionPlot] Plot unlocked!")

func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_locked:
			_show_confirm_dialog()

func _show_confirm_dialog() -> void:
	if get_node_or_null("UnlockDialog"): return
	
	var dialog = ConfirmationDialog.new()
	dialog.name = "UnlockDialog"
	dialog.title = "영토 확장"
	dialog.dialog_text = "개껌 %d개가 소모됩니다.\n영토를 확장하시겠습니까?" % unlock_cost
	dialog.ok_button_text = "확장하기"
	dialog.cancel_button_text = "취소"
	add_child(dialog)
	dialog.confirmed.connect(request_unlock)
	dialog.canceled.connect(dialog.queue_free)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.popup_centered()
