extends Camera2D

## 마우스 드래그 및 모바일 터치(Pan, Pinch-to-Zoom) 지원 멀티플랫폼 카메라 스크립트.

@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 0.1
@export var pan_speed: float = 1.0
@export var pinch_speed: float = 0.005 # 모바일 줌 민감도

var _is_panning: bool = false
var _touches: Dictionary = {}

func _unhandled_input(event: InputEvent) -> void:
	var build_active = false
	if get_parent() and get_parent().has_node("BuildCursor"):
		build_active = get_parent().get_node("BuildCursor").is_active

	# 1. 마우스 조작 (PC용)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(zoom_speed)
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(-zoom_speed)
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT:
			if build_active and event.button_index == MOUSE_BUTTON_LEFT:
				# 빌드 모드일 때는 좌클릭 이동을 수행하지 않고 양보
				_is_panning = false
				return
			
			_is_panning = event.pressed
			# 마우스 버튼을 뗐을 때 항상 팬 해제 (팝업 등으로 인해 release 이벤트가 누락되는 경우 대비)
			if not event.pressed:
				_is_panning = false
			return

	if event is InputEventMouseMotion and _is_panning:
		position -= event.relative / zoom * pan_speed
		return

	# 2. 터치 제스처 (모바일용)
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
			# 터치를 떼면 항상 팬 상태를 해제 (팝업이 중간에 뜨면서 터치 해제를 못 받는 경우 대비)
			_is_panning = false
			
		if build_active:
			return

	if event is InputEventScreenDrag:
		# 현재 드래그 이벤트로 해당 손가락의 최신 위치 업데이트
		var cur_pos = event.position
		var prev_pos = _touches.get(event.index, cur_pos - event.relative)
		_touches[event.index] = cur_pos

		var touch_count = _touches.size()
		
		# 1손가락 스와이프: 화면 이동 (Pan) - 빌드 모드가 아니며, 마우스가 패닝 중이 아닐 때
		if touch_count == 1:
			if not build_active and not _is_panning:
				position -= event.relative / zoom * pan_speed
			
		# 2손가락 핀치: 화면 확대/축소 (Pinch-to-Zoom)
		elif touch_count == 2:
			var keys = _touches.keys()
			var p1: Vector2 = _touches[keys[0]]
			var p2: Vector2 = _touches[keys[1]]
			
			var cur_dist = p1.distance_to(p2)
			
			# 이번 이벤트 직전 좌표 역산으로 거리 변화량 측정
			var prev_p1 = p1
			var prev_p2 = p2
			if keys[0] == event.index: prev_p1 = prev_pos
			if keys[1] == event.index: prev_p2 = prev_pos
			
			var prev_dist = prev_p1.distance_to(prev_p2)
			
			# 거리 차이(가까워지면 음수, 멀어지면 양수)에 비례해서 줌 배율 적용
			var dist_delta = cur_dist - prev_dist
			_zoom_camera(dist_delta * pinch_speed)

func _zoom_camera(delta: float) -> void:
	var new_zoom = clamp(zoom.x + delta, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
