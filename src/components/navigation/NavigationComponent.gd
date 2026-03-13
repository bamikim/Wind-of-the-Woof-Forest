class_name NavigationComponent
extends BaseComponent

## 아이소메트릭 그리드 상에서의 경로 탐색 및 이동을 처리하는 컴포넌트입니다.

signal navigation_finished

@export var speed: float = 150.0

var _target_position: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var is_moving: bool:
	get: return _is_moving

var _navigation_agent: NavigationAgent2D = NavigationAgent2D.new()
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# NavigationAgent2D 설정
	_navigation_agent.path_desired_distance = 10.0
	_navigation_agent.target_desired_distance = 60.0 # 타겟에 충분히 가까워지면 도착 판정
	_navigation_agent.radius = 16.0 # 강아지 회피 반경 축소 (건물에 걸리지 않도록)
	_navigation_agent.avoidance_enabled = true
	_navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	# 부모(BaseDog 등)가 Node2D일 때만 정상 작동하므로 부모에 추가
	call_deferred("_add_agent_to_owner")

func _add_agent_to_owner() -> void:
	if not _navigation_agent: return
	if _navigation_agent.get_parent(): return # 이미 부모가 있으면 중단
		
	if owner_entity:
		owner_entity.add_child(_navigation_agent)
		_target_position = owner_entity.global_position
	else:
		add_child(_navigation_agent)

func _on_owner_set() -> void:
	if not _navigation_agent: return
	
	if _navigation_agent.get_parent():
		if _navigation_agent.get_parent() == owner_entity:
			return # 이미 올바른 부모 아래 있음
		_navigation_agent.get_parent().remove_child(_navigation_agent)
	
	if owner_entity:
		owner_entity.add_child(_navigation_agent)

func _physics_process(_delta: float) -> void:
	if not _is_moving or not owner_entity or not _navigation_agent.is_inside_tree():
		return
		
	var dist_to_target = owner_entity.global_position.distance_to(_target_position)
	if _navigation_agent.is_navigation_finished() or dist_to_target < 100.0:
		_is_moving = false
		velocity = Vector2.ZERO
		if _navigation_agent.avoidance_enabled:
			_navigation_agent.set_velocity(Vector2.ZERO)
		navigation_finished.emit()
		return
		
	var next_path_position: Vector2 = _navigation_agent.get_next_path_position()
	var current_agent_position: Vector2 = owner_entity.global_position
	var planned_velocity = (next_path_position - current_agent_position).normalized() * speed
	
	if _navigation_agent.avoidance_enabled:
		_navigation_agent.set_velocity(planned_velocity)
	else:
		_on_velocity_computed(planned_velocity)
		
	# 이동 방향에 따라 스프라이트 반전 등 연출 추가 가능 (BaseDog 등 외부에서 velocity 체크)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if not _is_moving: return
	
	velocity = safe_velocity
	owner_entity.global_position += velocity * get_physics_process_delta_time()

func move_to(target_pos: Vector2) -> void:
	if not _navigation_agent.is_inside_tree():
		return
		
	_target_position = target_pos
	_navigation_agent.target_position = target_pos
	_is_moving = true
