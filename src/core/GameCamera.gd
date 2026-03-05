extends Camera2D

## 마우스 드래그를 이용한 팬(Panning) 및 휠을 이용한 줌(Zooming) 기능을 제공하는 카메라 스크립트.

@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 0.1
@export var pan_speed: float = 1.0

var _is_panning: bool = false

func _unhandled_input(event: InputEvent) -> void:
	# Zooming
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_camera(-zoom_speed)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_camera(zoom_speed)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_is_panning = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = false

	# Panning
	if event is InputEventMouseMotion and _is_panning:
		position -= event.relative / zoom * pan_speed

func _zoom_camera(delta: float) -> void:
	var new_zoom = clamp(zoom.x + delta, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
